package interpret;

import haxe.macro.Expr.ComplexType;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import haxe.macro.Type.ClassField;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Printer;
#end

import interpret.Types;

using StringTools;

/** Like haxe modules, but resolved at runtime. */
class DynamicModule {

    static var _adding = false;

    static var _nextId = 1;

/// Properties

    public var id(default,null):Int = _nextId++;

    public var items(get,null):Map<String,RuntimeItem> = null;
    function get_items():Map<String,RuntimeItem> {
        if (!_adding && lazyLoad != null) {
            if (lazyLoad != null) {
                var cb = lazyLoad;
                lazyLoad = null;
                cb(this);
            }
        }
        if (this.items == null) this.items = new Map();
        return this.items;
    }

    public var dynamicClasses(default,null):Map<String,DynamicClass> = null;

    public var imports(default,null):ResolveImports = null;

    public var usings(default,null):ResolveUsings = null;

    public var pack:String = null;

    public var aliases(default,null):Map<String,String> = new Map();

    @:noCompletion
    public var lazyLoad:DynamicModule->Void = null;

    @:noCompletion
    public var onLink:Void->Void = null;

    /** Internal map of classes and the superclass they extend (if any) */
    @:noCompletion
    public var superClasses:Map<String,String> = new Map();

    /** Internal map of classes and the interfaces they implement (if any) */
    @:noCompletion
    public var interfaces:Map<String,Map<String,Bool>> = new Map();

    public var typePath:String = null;

/// Lifecycle

    public function new() {

    } //new

    public function add(name:String, rawItem:Dynamic, kind:Int, ?extra1:Dynamic, ?extra2:Dynamic, ?extra3:Dynamic, ?extra4:Dynamic) {

        _adding = true;

        if (items == null) items = new Map();

        switch (kind) {

            case ModuleItemKind.CLASS:
                items.set(name, ClassItem(rawItem, id, name));
            case ModuleItemKind.CLASS_FUNC:
                var isStatic:Bool = extra1;
                var type:String = extra2;
                var argTypes:Array<String> = extra3;
                var extendedType:String = extra4;
                if (extendedType != null) {
                    items.set(name, ExtensionItem(ClassFieldItem(rawItem, id, name, isStatic, type, argTypes), extendedType));
                } else {
                    items.set(name, ClassFieldItem(rawItem, id, name, isStatic, type, argTypes));
                }
            case ModuleItemKind.CLASS_VAR:
                var isStatic:Bool = extra1;
                var type:String = extra2;
                items.set(name, ClassFieldItem(rawItem, id, name, isStatic, type, null));
            
            case ModuleItemKind.ABSTRACT:
                var runtimeType:String = extra1;
                items.set(name, AbstractItem(rawItem, id, name, runtimeType));
            case ModuleItemKind.ABSTRACT_FUNC:
                var isStatic:Bool = extra1;
                var type:String = extra2;
                var argTypes:Array<String> = extra3;
                items.set(name, AbstractFieldItem(rawItem, id, name, isStatic, type, argTypes));
            case ModuleItemKind.ABSTRACT_VAR:
                var isStatic:Bool = extra1;
                var type:String = extra2;
                var readWrite:Int = extra3;
                var accessor:String = readWrite == 0 ? name + '#get' : name + '#set';
                items.set(accessor, AbstractFieldItem(rawItem, id, name, isStatic, type, null));

            // TODO abstract

            case ModuleItemKind.ENUM:
                items.set(name, EnumItem(rawItem, id, name));
            case ModuleItemKind.ENUM_FIELD:
                var numArgs:Int = extra1;
                items.set(name, EnumFieldItem(rawItem, name, numArgs));

            default:
        }

        _adding = false;

    } //add

    public function alias(alias:String, name:String) {

        aliases.set(alias, name);

    } //alias

    public function addSuperClass(child:String, superClass:String) {

        superClasses.set(child, superClass);

    } //addSuperClass

    public function addInterface(child:String, interface_:String) {

        var subItems = interfaces.get(child);
        if (subItems == null) {
            subItems = new Map();
            interfaces.set(child, subItems);
        }
        subItems.set(interface_, true);

    } //addInterface

/// From string

    static public function fromString(env:Env, moduleName:String, haxe:String, ?options:ModuleOptions) {

        var converter = new ConvertHaxe(haxe);

        var interpretableOnly = false;
        var interpretableOriginalContent = null;
        var allowUnresolvedImports = false;
        var extendingClassName = null;
        var extendedClassName = null;

        if (options != null) {
            interpretableOnly = options.interpretableOnly;
            interpretableOriginalContent = options.interpretableOriginalContent;
            allowUnresolvedImports = options.allowUnresolvedImports;
            extendingClassName = options.extendingClassName;
            extendedClassName = options.extendedClassName;
        }

        // Transform class token if needed
        if (extendingClassName != null && extendedClassName != null) {
            converter.transformToken = function(token) {
                switch (token) {
                    case TType(data):
                        if (data.kind == CLASS && data.name == extendedClassName) {
                            data.parent = {
                                name: extendedClassName,
                                kind: SUPERCLASS
                            };
                            data.name = extendingClassName;
                            data.interfaces = [{
                                name: 'interpret.Interpretable',
                                kind: INTERFACE
                            }];
                            return TType(data);
                        }
                    default:
                }
                return token;
            };
        }

        converter.convert();

        // Skip methods that aren't different from original content, if provided
        var originalFields:Map<String,TField> = null;
        if (interpretableOriginalContent != null) {

            var originalContentConverter = new ConvertHaxe(interpretableOriginalContent);
            originalContentConverter.convert();

            originalFields = new Map();
            var currentClassName:String = null;
            for (token in originalContentConverter.tokens) {
                switch (token) {

                    case TType(data):
                        if (data.kind == CLASS) {
                            currentClassName = data.name;
                            if (interpretableOnly) currentClassName += '_interpretable';
                        }
                        else {
                            currentClassName = null;
                        }
                    
                    case TField(data):
                        if (currentClassName != null) {
                            originalFields.set(currentClassName + '.' + data.name, data);
                        }

                    default:
                }
            }
        }

        var module = new DynamicModule();
        module.dynamicClasses = new Map();

        module.imports = new ResolveImports(env);
        module.usings = new ResolveUsings(env);

        function consumeTokens(shallow:Bool) {

            var toComputeHscript:Array<DynamicClass> = [];

            var currentClassPath:String = null;
            var currentClassName:String = null;
            var currentFieldName:String = null;
            var currentClassSkipFields:Map<String,Bool> = null;
            var dynClass:DynamicClass = null;
            var modifiers = new Map<String,Bool>();
            var interpretableMeta = false;
            var interpretableField = false;
            var interpretableType = false;
            var packagePrefix:String = '';

            for (token in converter.tokens) {
                switch (token) {

                    case TPackage(data):
                        module.imports.pack = data.path;
                        module.pack = data.path;
                        packagePrefix = data.path != null && data.path != '' ? data.path + '.' : '';
                
                    case TImport(data):
                        if (shallow) continue;
                        module.imports.addImport(data, allowUnresolvedImports);
                    
                    case TUsing(data):
                        if (shallow) continue;
                        module.usings.addUsing(data, allowUnresolvedImports);

                    case TModifier(data):
                        modifiers.set(data.name, true);

                    case TType(data):
                        interpretableType = interpretableMeta;
                        interpretableMeta = false;
                        if (data.kind == CLASS) {
                            var classAllowed = false;
                            currentClassName = data.name;
                            if (interpretableOnly) {
                                // If only keeping interpretable classes, skip any that doesn't
                                // implement interpret.Interpretable interface
                                if (data.interfaces != null) {
                                    for (item in data.interfaces) {
                                        if (item.name == 'interpret.Interpretable') {
                                            // We are taking shortcuts here
                                            classAllowed = true;
                                            break;
                                        }
                                        var resolvedType = TypeUtils.toResolvedType(module.imports, item.name);
                                        if (resolvedType == 'Interpretable' || resolvedType == 'interpret.Interpretable') {
                                            classAllowed = true;
                                            break;
                                        }
                                    }
                                }
                            }
                            else {
                                classAllowed = true;
                            }
                            if (classAllowed) {
                                currentClassSkipFields = originalFields != null ? new Map() : null;
                                dynClass = shallow ? null : new DynamicClass(env, {
                                    tokens: converter.tokens,
                                    targetClass: data.name,
                                    moduleOptions: options,
                                    skipFields: currentClassSkipFields,
                                    noComputeHscript: true
                                });
                                if (!shallow) {
                                    toComputeHscript.push(dynClass);
                                    module.dynamicClasses.set(data.name, dynClass);
                                }
                                currentClassPath = packagePrefix + (data.name == moduleName ? data.name : moduleName + '.' + data.name);
                                module.add(currentClassPath, null, ModuleItemKind.CLASS);
                                if (!shallow) {
                                    if (data.parent != null) {
                                        module.addSuperClass(currentClassPath, TypeUtils.toResolvedType(module.imports, data.parent.name));
                                    }
                                    if (data.interfaces != null) {
                                        for (item in data.interfaces) {
                                            module.addInterface(currentClassPath, TypeUtils.toResolvedType(module.imports, item.name));
                                        }
                                    }
                                }
                            }
                            else {
                                currentClassSkipFields = null;
                                currentClassName = null;
                                currentClassPath = null;
                                dynClass = null;
                            }
                        }
                        else {
                            currentClassSkipFields = null;
                            currentClassName = null;
                            currentClassPath = null;
                            dynClass = null;
                        }
                        // Reset modifiers
                        modifiers = new Map<String,Bool>();
                    
                    case TField(data):
                        // If only keeping interpretable fields, skip any that doesn't
                        // have @interpret meta
                        interpretableField = interpretableMeta;
                        interpretableMeta = false;
                        if (currentClassPath != null && (!interpretableOnly || ((interpretableField || interpretableType) && data.name != 'new'))) {
                            currentFieldName = data.name;
                            var isStatic = modifiers.exists('static');
                            
                            // When filtering with interpretableOnly, skip vars, or the ones
                            // that already exist in native class if whole class is interpretable
                            if (data.kind == VAR) {
                                if (!interpretableOnly || (interpretableType && originalFields != null && !originalFields.exists(currentClassName + '.' + data.name))) {
                                    module.add(currentClassPath + '.' + data.name, null, ModuleItemKind.CLASS_VAR, isStatic, data.type);
                                }
                                else if (interpretableOnly) {
                                    if (currentClassSkipFields != null) {
                                        currentClassSkipFields.set(data.name, true);
                                    }
                                }
                            }
                            else if (data.kind == METHOD) {

                                var shouldSkip = false;
                                if (interpretableOnly) {
                                    var key = currentClassName + '.' + data.name;
                                    if (originalFields != null && originalFields.exists(key)) {
                                        var original = originalFields.get(key);
                                        if (original.isEqualToField(data)) {
                                            shouldSkip = true;
                                            if (currentClassSkipFields != null) {
                                                currentClassSkipFields.set(data.name, true);
                                            }
                                        }
                                    }
                                }

                                if (!shouldSkip) {
                                    var extendedType = null;
                                    var argTypes = [];
                                    if (data.args.length > 0) {
                                        for (arg in data.args) {
                                            argTypes.push(arg.type);
                                        }
                                        var firstArg = data.args[0];
                                        if (firstArg.type != null) {
                                            extendedType = firstArg.type;
                                        }
                                    }
                                    if (extendedType != null) {
                                        extendedType = TypeUtils.toResolvedType(module.imports, extendedType);
                                    }
                                    module.add(currentClassPath + '.' + data.name, null, ModuleItemKind.CLASS_FUNC, isStatic, data.type, argTypes, extendedType);
                                }
                            }
                        }
                        // Reset @interpret meta
                        interpretableField = false;
                        interpretableMeta = false;
                    
                    case TMeta(data):
                        if (data.name == 'interpret') {
                            interpretableMeta = true;
                        }

                    default:                
                }
            }

            for (dynClass in toComputeHscript) {
                @:privateAccess dynClass.computeHscript();
            }
        }

        consumeTokens(true);
        module.onLink = function() {
            consumeTokens(false);
        };

        return module;

    } //fromString

/// From static module

    /** Return a `DynamicModule` instance from a haxe module as it was at compile time. 
        Allows to easily map a Haxe modules to their scriptable equivalent. */
    macro static public function fromStatic(e:Expr) {

        function typeAsString(t:Null<Type>):String {
            if (t == null) return null;
            switch (t) {
                case TLazy(f):
                    return typeAsString(f());
                default:
                    var res:String = t != null ? TypeTools.toString(t) : null;
                    return res != null ? res.replace(' ', '') : null;
            }
        }

        var pos = Context.currentPos();
        var typePath = new Printer().printExpr(e);
        var pack = [];
        var parts = typePath.split('.');
        while (parts.length > 1) {
            pack.push(parts.shift());
        }
        var packString = pack.join('.');
        var name = parts[0];
        var complexType = TPath({pack: pack, name: name});
        var type = null;
        try {
            Context.resolveType(complexType, pos);
        } catch (e:Dynamic) {
            // Module X does not define type X, which is fine
        }

        var module = Context.getModule(typePath);

        var abstractTypes:Array<String> = [];

        var toAdd:Array<Array<Dynamic>> = [];
        var toAbstract:Array<Array<Dynamic>> = [];
        var toAlias:Array<Array<String>> = [];
        var toSuperClass:Array<Array<String>> = [];
        var toInterface:Array<Array<String>> = [];

        var abstractInfos:Map<String,Array<Dynamic>> = new Map();
        
        var currentPos = Context.currentPos();
        
        for (item in module) {
            switch (item) {
                case TInst(t, params):
                    // add a meta to prevent that class to be altered by dce
                    t.get().meta.add(":keepSub", [], currentPos);

                    // Type
                    var rawTypePath = t.toString();

                    // Sys class workarounds
                    // Is there a cleaner way to handle this?
                    if (typePath == 'Sys' && rawTypePath.startsWith('_Sys.')) continue;
                    if (typePath == 'Sys' && rawTypePath == 'SysError') continue;

                    // Compute sub type paths and alias
                    var alias = null;
                    var subTypePath = rawTypePath;
                    if (rawTypePath != typePath) {
                        subTypePath = typePath + rawTypePath.substring(rawTypePath.lastIndexOf('.'));
                        alias = [rawTypePath, subTypePath];
                    }

                    // Abstract implementation?
                    var abstractType = null;
                    if (rawTypePath.endsWith('_Impl_')) {
                        for (aType in abstractTypes) {
                            var implName = aType;
                            var dotIndex = implName.lastIndexOf('.');
                            if (dotIndex != -1) {
                                implName = implName.substring(0, dotIndex) + '._' + implName.substring(dotIndex + 1) + '.' + implName.substring(dotIndex + 1) + '_Impl_';
                            }
                            else {
                                implName = '_' + implName + '.' + implName + '_Impl_';
                            }
                            if (rawTypePath == implName) {
                                abstractType = aType;
                                break;
                            }
                        }

                        if (abstractType == null) {
                            continue;
                        }
                    }

                    if (abstractType != null) {
                        // Abstract implementation code
                        //trace('ABSTRACT IMPL $abstractType');

                        for (field in t.get().statics.get()) {
    #if !interpret_keep_deprecated
                            if (field.meta.has(':deprecated')) continue;
    #end
                            //trace('field: ' + field.name);
                            if (!field.isPublic) continue;

                            var metas = field.meta.get();
                            var hasImplMeta = false;
                            for (meta in metas) {
                                if (meta.name == ':impl') {
                                    hasImplMeta = true;
                                    break;
                                }
                            }
                            var isStatic = !hasImplMeta;

                            var fieldType = field.type;
                            switch (fieldType) {
                                case TLazy(f):
                                    fieldType = f();
                                default:
                            }

                            //trace('   hasImpl: $hasImplMeta');
                            //trace('type: ' + field.type);
                            //trace(field);
                            switch (field.kind) {

                                case FMethod(k):
                                    switch (fieldType) {
                                        case TFun(args, ret):
                                            var _args = [];
                                            var _ret = null;
                                            if (ret != null) {
                                                _ret = TypeTools.toComplexType(ret);
                                            }

                                            if (!isStatic && args.length > 0) {
                                                var info = abstractInfos.get(abstractType);
                                                if (info != null && info[2] == null) {
                                                    info[2] = typeAsString(args[0].t);
                                                }
                                            }
                                                
                                            var argTypes = [];
                                            for (arg in args) {
                                                argTypes.push(typeAsString(arg.t));
                                            }
                                            var retType = typeAsString(ret);
                                            
                                            for (arg in args) {

                                                var complexType = TypeTools.toComplexType(arg.t);
                                                /*switch (complexType) {
                                                    case TPath(p):
                                                        trace('TPath: name=' + p.name + ' pack=' + p.pack + ' sub=' + p.sub);
                                                    default:
                                                }*/

                                                _args.push({
                                                    name: arg.name,
                                                    type: complexType,
                                                    opt: arg.opt,
                                                    value: null
                                                });
                                            }
                                            toAbstract.push([
                                                abstractType + '.' + field.name,
                                                ModuleItemKind.ABSTRACT_FUNC,
                                                _ret, _args,
                                                retType, argTypes,
                                                isStatic
                                            ]);
                                        default:
                                    }
                                case FVar(read, write):
                                    var readable = switch (read) {
                                        case AccNormal | AccCall | AccInline: true;
                                        default: false;
                                    }
                                    var writable = switch (write) {
                                        case AccNormal | AccCall: true;
                                        default: false;
                                    }
                                    //if (isStatic) {
                                        // In that case, that's a static var access
                                        toAbstract.push([
                                            abstractType + '.' + field.name,
                                            ModuleItemKind.ABSTRACT_VAR,
                                            readable, writable, isStatic,
                                            fieldType
                                        ]);
                                    //s}
                                default:
                            }
                        } 
                    }
                    else {
                        // Regular class

                        // Add alias if any
                        if (alias != null) {
                            toAlias.push(alias);
                        }

                        var subTypePath = rawTypePath;
                        if (rawTypePath != typePath) {
                            subTypePath = typePath + rawTypePath.substring(rawTypePath.lastIndexOf('.'));
                            toAlias.push([rawTypePath, subTypePath]);
                        }
                        toAdd.push([subTypePath, ModuleItemKind.CLASS]);

                        // Superclass
                        var prevParent = t;
                        var parentHold = t.get().superClass;
                        var parent = parentHold != null ? parentHold.t : null;
                        while (parent != null) {
                            toSuperClass.push([prevParent.toString(), parent.toString()]);
                            parentHold = parent.get().superClass;
                            parent = parentHold != null ? parentHold.t : null;
                        }

                        // Interfaces
                        for (item in t.get().interfaces) {
                            toInterface.push([subTypePath, item.t.toString()]);
                        }

                        inline function processField(field:ClassField, isStatic:Bool) {

                            //if (!field.isPublic) continue;
                            
    #if !interpret_keep_deprecated
                            if (field.meta.has(':deprecated')) continue;
    #end

                            var fieldType = field.type;
                            switch (fieldType) {
                                case TLazy(f):
                                    fieldType = f();
                                default:
                            }

                            switch (field.kind) {
                                case FMethod(k):
                                    switch (fieldType) {
                                        case TFun(args, ret):
                                            var argTypes = [];
                                            for (arg in args) {
                                                argTypes.push(typeAsString(arg.t));
                                            }
                                            var retType = typeAsString(ret);
                                            if (args.length > 0 && isStatic && field.isPublic) {
                                                var extendedType:String = null;
                                                switch (args[0].t) {
                                                    case TInst(t, params):
                                                        extendedType = t.toString();
                                                    case TAbstract(t, params):
                                                        extendedType = t.toString();
                                                    default:
                                                }
                                                toAdd.push([
                                                    subTypePath + '.' + field.name,
                                                    ModuleItemKind.CLASS_FUNC,
                                                    isStatic,
                                                    retType,
                                                    argTypes,
                                                    extendedType,
                                                    field.isPublic
                                                    #if (haxe_ver >= "4.0.0"), field.isExtern #end
                                                ]);
                                            } else {
                                                toAdd.push([
                                                    subTypePath + '.' + field.name,
                                                    ModuleItemKind.CLASS_FUNC,
                                                    isStatic,
                                                    retType,
                                                    argTypes,
                                                    null,
                                                    field.isPublic
                                                    #if (haxe_ver >= "4.0.0"), field.isExtern #end
                                                ]);
                                            }
                                        default:
                                    }
                                default:
                                    var strType = typeAsString(fieldType);
                                    toAdd.push([
                                        subTypePath + '.' + field.name,
                                        ModuleItemKind.CLASS_VAR,
                                        isStatic,
                                        strType,
                                        null,
                                        null,
                                        field.isPublic
                                    ]);
                            }

                        } //processField

                        // Static fields
                        for (field in t.get().statics.get()) {
                            processField(field, true);
                        }
                        // Instance fields
                        for (field in t.get().fields.get()) {
                            processField(field, false);
                        }
                    }
                
                case TEnum(t, params):
                    // Type
                    var rawTypePath = t.toString();
                    var subTypePath = rawTypePath;
                    if (rawTypePath != typePath) {
                        subTypePath = typePath + rawTypePath.substring(rawTypePath.lastIndexOf('.'));
                        toAlias.push([rawTypePath, subTypePath]);
                    }

                    toAdd.push([
                        subTypePath,
                        ModuleItemKind.ENUM,
                        null,
                        null
                    ]);

                    for (item in t.get().constructs) {
                        switch (item.type) {
                            case TEnum(t, params):
                                toAdd.push([
                                    subTypePath + '.' + item.name,
                                    ModuleItemKind.ENUM_FIELD,
                                    -1,
                                    null
                                ]);
                            case TFun(args, ret):
                                /*var argNames = [];
                                for (arg in args) {
                                    argNames.push(arg.name);
                                }*/
                                toAdd.push([
                                    subTypePath + '.' + item.name,
                                    ModuleItemKind.ENUM_FIELD,
                                    args.length,
                                    null
                                ]);
                            default:
                        }
                    }
                case TAbstract(t, params):
                    // Type
                    var rawTypePath = t.toString();

                    var subTypePath = rawTypePath;
                    if (rawTypePath != typePath) {
                        subTypePath = typePath + rawTypePath.substring(rawTypePath.lastIndexOf('.'));
                        toAlias.push([rawTypePath, subTypePath]);
                    }
                    var info:Array<Dynamic> = [subTypePath, ModuleItemKind.ABSTRACT];
                    abstractInfos.set(subTypePath, info);
                    toAdd.push(info);

                    abstractTypes.push(subTypePath);

                default:
            }
        }

        var addExprs:Array<Expr> = [];
        for (item in toAdd) {
            if (item[1] == ModuleItemKind.ABSTRACT) {
                var expr = macro mod.add($v{item[0]}, null, $v{item[1]}, $v{item[2]}, $v{item[3]});
                addExprs.push(expr);
            }
            else if (item[1] == ModuleItemKind.CLASS_FUNC || item[1] == ModuleItemKind.CLASS_VAR) {
                var isStatic:Bool = item[2];
                var retType:String = item[3];
                var argTypes:String = item[4];
                var isPublic:Bool = item[6];
                var isExtern:Bool = #if (haxe_ver >= "4.0.0") item[7] #else false #end;
                if (item[1] == ModuleItemKind.CLASS_FUNC && isExtern) {
                    if (isStatic) {
                        if (isPublic) {
                            // Static class field (public)
                            if (item[0] == 'Std.int') {
                                // Kind of hardcoded case for now
                                var expr = macro mod.add($v{item[0]}, function(value:Dynamic):Int { return Std.int(value); }, $v{item[1]}, $v{item[2]}, $v{item[3]}, $v{item[4]}, $v{item[5]});
                                addExprs.push(expr);
                            }
                            else {
                                // Skip any other extern function for now
                            }
                        }
                        else {
                            // Static class field (private)
                            var expr = macro mod.add($v{item[0]}, null, $v{item[1]}, $v{item[2]}, $v{item[3]}, $v{item[4]}, $v{item[5]});
                            addExprs.push(expr);
                        }
                    }
                    else {
                        // Instance class field
                        var expr = macro mod.add($v{item[0]}, null, $v{item[1]}, $v{item[2]}, $v{item[3]}, $v{item[4]});
                        addExprs.push(expr);
                    }
                }
                else {
                    if (isStatic) {
                        if (isPublic) {
                            // Static class field (public)
                            var expr = macro mod.add($v{item[0]}, $p{item[0].split('.')}, $v{item[1]}, $v{item[2]}, $v{item[3]}, $v{item[4]}, $v{item[5]});
                            addExprs.push(expr);
                        }
                        else {
                            // Static class field (private)
                            var expr = macro mod.add($v{item[0]}, null, $v{item[1]}, $v{item[2]}, $v{item[3]}, $v{item[4]}, $v{item[5]});
                            addExprs.push(expr);
                        }
                    }
                    else {
                        // Instance class field
                        var expr = macro mod.add($v{item[0]}, null, $v{item[1]}, $v{item[2]}, $v{item[3]}, $v{item[4]});
                        addExprs.push(expr);
                    }
                }
            }
            else {
                var expr = macro mod.add($v{item[0]}, $p{item[0].split('.')}, $v{item[1]}, $v{item[2]}, $v{item[3]}, $v{item[4]}, $v{item[5]});
                addExprs.push(expr);
            }
        }
        var aliasExprs:Array<Expr> = [];
        for (item in toAlias) {
            var expr = macro module.alias($v{item[0]}, $v{item[1]});
            aliasExprs.push(expr);
        }
        var superClassExprs:Array<Expr> = [];
        for (item in toSuperClass) {
            var expr = macro module.addSuperClass($v{item[0]}, $v{item[1]});
            superClassExprs.push(expr);
        }
        var interfaceExprs:Array<Expr> = [];
        for (item in toInterface) {
            var expr = macro module.addInterface($v{item[0]}, $v{item[1]});
            interfaceExprs.push(expr);
        }

        var abstractExprs:Array<Expr> = [];
        for (item in toAbstract) {
            var fullName:String = item[0];
            var abstractType:String = fullName;
            var abstractName:String = fullName;
            var abstractPack = [];
            var name:String = fullName;
            var dotIndex = fullName.lastIndexOf('.');
            if (dotIndex != -1) {
                name = fullName.substring(dotIndex + 1);
                abstractType = fullName.substring(0, dotIndex);
                abstractName = abstractType;
                dotIndex = abstractType.lastIndexOf('.');
                if (dotIndex != -1) {
                    abstractName = abstractType.substring(dotIndex + 1);
                    abstractPack = abstractType.substring(0, dotIndex).split('.');
                }
            }
            if (item[1] == ModuleItemKind.ABSTRACT_FUNC) {
                var ret:ComplexType = item[2];
                var args:Array<FunctionArg> = item[3];
                var retType:String = item[4];
                var argTypes:Array<String> = item[5];
                var isStatic:Bool = item[6];
                var instanceArgs:Array<FunctionArg> = [].concat(args);
                var callArgs = [for (arg in args) macro $i{arg.name}];
                var isConstructor = (name == '_new' || name == 'new');
                if (isConstructor) {
                    name = 'new';
                    var fullName:String = item[0];
                    if (fullName.endsWith('_new')) fullName = fullName.substring(0, fullName.length - 4) + 'new';
                    item[0] = fullName;
                }
                if (!isStatic) {
                    args = [{
                        name: '_hold',
                        type: macro :interpret.DynamicAbstract,
                        opt: false,
                        value: null
                    }].concat(args);
                    if (!isConstructor) instanceArgs.shift();
                    callArgs = [for (arg in instanceArgs) macro $i{arg.name}];
                }
                var isGetter = name.startsWith('get_');
                var isSetter = name.startsWith('set_');
                if (isGetter || isSetter) continue; // Skip getters/setters, handled as ABSTRACT_VAR

                var isVoidRet = false;
                if (ret == null) {
                    isVoidRet = true;
                }
                else {
                    switch (ret) {
                        case TPath(p):
                            if (p.name == 'Void') {
                                isVoidRet = true;
                            }
                        default:
                    }
                }

                if (!isStatic && !isConstructor) {
                    var thisArg = args[1];
                    thisArg.name = '_this';
                    thisArg.type = TPath({
                        name: abstractName,
                        pack: abstractPack,
                        params: []
                    });
                }

                //trace('args: ' + args);
                /*var fnExpr0 = macro function(a:Int) {
                    
                };
                trace('fn0: ' + fnExpr0);*/
                /*var varExpr_ = macro var _this:ceramic.Color = this;
                trace('varExpr: $varExpr_');

                var varExpr = {
                    expr: EVars([{
                        expr: {
                            expr: EConst(CIdent('this')),
                            pos: currentPos,
                            name: '_this'
                        },
                        pos: currentPos
                    }]),
                    pos: currentPos
                }*/

                var newExpr = null;
                if (isConstructor) {
                    args = [].concat(args);
                    newExpr = {
                        expr: ENew({
                            name: abstractName,
                            pack: abstractPack,
                            params: []
                        }, callArgs),
                        pos: currentPos
                    }
                }

                var fnBody = switch [isConstructor, isStatic, isVoidRet] {
                    case [true, _, _]: macro {
                        var _this = $newExpr;
                        _hold.value = _this;
                        return _this;
                    };
                    case [_, true, true]: macro {
                        $p{item[0].split('.')}($a{callArgs});
                    };
                    case [_, true, false]: macro {
                        return $p{item[0].split('.')}($a{callArgs});
                    };
                    case [_, false, true]: macro {
                        $p{['_this', name]}($a{callArgs});
                        _hold.value = _this;
                    };
                    case [_, false, false]: macro {
                        var _res = $p{['_this', name]}($a{callArgs});
                        _hold.value = _this;
                        return _res;
                    };
                };

                var fnExpr = {
                    expr: EFunction(null, {
                        args: args,
                        expr: {
                            expr: fnBody.expr,
                            pos: pos
                        },
                        params: [],
                        ret: null
                    }),
                    pos: pos
                };
                //trace('fn: ' + fnExpr);
                var printer = new haxe.macro.Printer();
                //trace('$name: ' + printer.printExpr(fnExpr));
                var expr = macro mod.add($v{item[0]}, $fnExpr, $v{item[1]}, $v{isStatic}, $v{retType}, $v{argTypes});
                abstractExprs.push(expr);
            }
            else { // ABSTRACT_VAR
                //trace('item[0]: ' + item[0]);
                var readable:Bool = item[2];
                var writable:Bool = item[3];
                var isStatic:Bool = item[4];
                var complexType:ComplexType = TypeTools.toComplexType(item[5]);
                var type:String = typeAsString(item[5]);
                if (isStatic) {
                    if (readable) {
                        var expr = macro mod.add($v{item[0]}, function() {
                            return $p{item[0].split('.')};
                        }, $v{item[1]}, $v{isStatic}, $v{type}, 0);
                        abstractExprs.push(expr);
                    }
                    if (writable) {
                        var expr = macro mod.add($v{item[0]}, function(value) {
                            return $p{item[0].split('.')} = value;
                        }, $v{item[1]}, $v{isStatic}, $v{type}, 1);
                        abstractExprs.push(expr);
                    }
                }
                else {
                    var args = [{
                        name: '_hold',
                        type: macro :interpret.DynamicAbstract,
                        opt: false,
                        value: null
                    },{
                        name: '_this',
                        type: TPath({
                            name: abstractName,
                            pack: abstractPack,
                            params: []
                        }),
                        opt: false,
                        value: null
                    }];

                    if (readable) {

                        var fnBody = macro {
                            var _res = $p{['_this', name]};
                            _hold.value = _this;
                            return _res;
                        };

                        var fnExpr = {
                            expr: EFunction(null, {
                                args: args,
                                expr: {
                                    expr: fnBody.expr,
                                    pos: pos
                                },
                                params: [],
                                ret: null
                            }),
                            pos: pos
                        };

                        var expr = macro mod.add($v{item[0]}, $fnExpr, $v{item[1]}, $v{isStatic}, $v{type}, 0);
                        abstractExprs.push(expr);
                    }
                    if (writable) {
                        args = args.concat([{
                            name: 'value',
                            type: complexType,
                            opt: false,
                            value: null
                        }]);

                        var fnBody = macro {
                            var _res = $p{['_this', name]} = value;
                            _hold.value = _this;
                            return _res;
                        };

                        var fnExpr = {
                            expr: EFunction(null, {
                                args: args,
                                expr: {
                                    expr: fnBody.expr,
                                    pos: pos
                                },
                                params: [],
                                ret: null
                            }),
                            pos: pos
                        };

                        var expr = macro mod.add($v{item[0]}, $fnExpr, $v{item[1]}, $v{isStatic}, $v{type}, 1);
                        abstractExprs.push(expr);
                    }
                }
            }
        }

        var result = macro (function() {
            var module = new interpret.DynamicModule();
            module.pack = $v{packString};
            $b{aliasExprs};
            $b{superClassExprs};
            $b{interfaceExprs};
            module.lazyLoad = function(mod) {
                $b{addExprs};
                $b{abstractExprs};
            }
            return module;
        })();

        //trace(new haxe.macro.Printer().printExpr(result));

        return result;

    } //fromStatic

/// Print

    public function toString() {

        return 'DynamicModule($typePath)';

    } //toString

} //DynamicModule
