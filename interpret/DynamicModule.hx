package interpret;

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

    public function add(name:String, rawItem:Dynamic, kind:Int, ?extra:Dynamic) {

        _adding = true;

        if (items == null) items = new Map();

        switch (kind) {
            case ModuleItemKind.CLASS:
                items.set(name, ClassItem(rawItem, id, name));
            case ModuleItemKind.CLASS_FIELD:
                var extendedType:String = extra;
                if (extendedType != null) {
                    items.set(name, ExtensionItem(ClassFieldItem(rawItem, id, name), extendedType));
                } else {
                    items.set(name, ClassFieldItem(rawItem, id, name));
                }
            case ModuleItemKind.ENUM:
                items.set(name, EnumItem(rawItem, id, name));
            case ModuleItemKind.ENUM_FIELD:
                var numArgs:Int = extra;
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

    static public function fromString(env:Env, moduleName:String, haxe:String) {

        var converter = new ConvertHaxe(haxe);
        converter.convert();

        var module = new DynamicModule();
        module.dynamicClasses = new Map();

        module.imports = new ResolveImports(env);
        module.usings = new ResolveUsings(env);

        function consumeTokens(shallow:Bool) {

            var currentClassPath:String = null;
            var dynClass:DynamicClass = null;
            var modifiers = new Map<String,Bool>();
            var packagePrefix:String = '';

            for (token in converter.tokens) {
                switch (token) {

                    case TPackage(data):
                        module.pack = data.path;
                        packagePrefix = data.path != null && data.path != '' ? data.path + '.' : '';
                
                    case TImport(data):
                        if (shallow) continue;
                        module.imports.addImport(data);
                    
                    case TUsing(data):
                        if (shallow) continue;
                        module.usings.addUsing(data);

                    case TModifier(data):
                        modifiers.set(data.name, true);

                    case TType(data):
                        if (data.kind == CLASS) {
                            dynClass = shallow ? null : new DynamicClass(env, {
                                tokens: converter.tokens,
                                targetClass: data.name
                            });
                            if (!shallow) module.dynamicClasses.set(data.name, dynClass);
                            currentClassPath = packagePrefix + (data.name == moduleName ? data.name : moduleName + '.' + data.name);
                            module.add(currentClassPath, null, ModuleItemKind.CLASS, null);
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
                            currentClassPath = null;
                            dynClass = null;
                        }
                        // Reset modifiers
                        modifiers = new Map<String,Bool>();
                    
                    case TField(data):
                        if (currentClassPath != null) {
                            if (modifiers.exists('static')) {
                                if (data.kind == VAR) {
                                    module.add(currentClassPath + '.' + data.name, null, ModuleItemKind.CLASS_FIELD, null);
                                }
                                else if (data.kind == METHOD) {
                                    var extendedType = null;
                                    if (data.args.length > 0) {
                                        var firstArg = data.args[0];
                                        if (firstArg.type != null) {
                                            extendedType = firstArg.type;
                                        }
                                    }
                                    if (extendedType != null) {
                                        extendedType = TypeUtils.toResolvedType(module.imports, extendedType);
                                    }
                                    module.add(currentClassPath + '.' + data.name, null, ModuleItemKind.CLASS_FIELD, extendedType);
                                }
                            }
                        }
                    
                    default:
                
                }
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

        var toAdd:Array<Array<Dynamic>> = [];
        var toAlias:Array<Array<String>> = [];
        var toSuperClass:Array<Array<String>> = [];
        var toInterface:Array<Array<String>> = [];
        
        for (item in module) {
            switch (item) {
                case TInst(t, params):
                    // Type
                    var rawTypePath = t.toString();
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

                    // Static fields
                    for (field in t.get().statics.get()) {
                        if (!field.isPublic) continue;
                        switch (field.kind) {
                            case FMethod(k):
                                switch (field.type) {
                                    case TFun(args, ret):
                                        if (args.length > 0) {
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
                                                ModuleItemKind.CLASS_FIELD,
                                                extendedType
                                            ]);
                                        } else {
                                            toAdd.push([
                                                subTypePath + '.' + field.name,
                                                ModuleItemKind.CLASS,
                                                null
                                            ]);
                                        }
                                    default:
                                        toAdd.push([
                                            subTypePath + '.' + field.name,
                                            ModuleItemKind.CLASS_FIELD,
                                            null
                                        ]);
                                }
                            default:
                                toAdd.push([
                                    subTypePath + '.' + field.name,
                                    ModuleItemKind.CLASS_FIELD,
                                    null
                                ]);
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
                        null
                    ]);

                    for (item in t.get().constructs) {
                        switch (item.type) {
                            case TEnum(t, params):
                                toAdd.push([
                                    subTypePath + '.' + item.name,
                                    ModuleItemKind.ENUM_FIELD,
                                    -1
                                ]);
                            case TFun(args, ret):
                                /*var argNames = [];
                                for (arg in args) {
                                    argNames.push(arg.name);
                                }*/
                                toAdd.push([
                                    subTypePath + '.' + item.name,
                                    ModuleItemKind.ENUM_FIELD,
                                    args.length
                                ]);
                            default:
                        }
                    }

                default:
            }
        }

        var addExprs:Array<Expr> = [];
        for (item in toAdd) {
            var expr = macro mod.add($v{item[0]}, $p{item[0].split('.')}, $v{item[1]}, $v{item[2]});
            addExprs.push(expr);
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

        var result = macro function() {
            var module = new interpret.DynamicModule();
            module.pack = $v{packString};
            $b{aliasExprs};
            $b{superClassExprs};
            $b{interfaceExprs};
            module.lazyLoad = function(mod) $b{addExprs};
            return module;
        }();

        //trace(new haxe.macro.Printer().printExpr(result));

        return result;

    } //fromStatic

/// Print

    public function toString() {

        return 'DynamicModule($typePath)';

    } //toString

} //DynamicModule
