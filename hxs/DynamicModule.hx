package hxs;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Printer;
#end

import hxs.Types;

using StringTools;

/** Like haxe modules, but resolved at runtime. */
class DynamicModule {

    static var _adding = false;

    static var _nextId = 1;

/// Properties

    var id:Int = _nextId++;

    public var items(get,null):Map<String,ModuleItem> = null;
    function get_items():Map<String,ModuleItem> {
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

    @:noCompletion
    public var lazyLoad:DynamicModule->Void = null;

/// Lifecycle

    public function new() {

    } //new

    public function add(name:String, rawItem:Dynamic, isField:Bool, ?extendedType:String) {

        if (Std.is(rawItem, DynamicClass)) trace('add($name, _, $isField, $extendedType)');

        _adding = true;

        if (items == null) items = new Map();

        if (isField) {
            if (extendedType != null) {
                items.set(name, ExtensionItem(FieldItem(rawItem), extendedType));
            } else {
                items.set(name, FieldItem(rawItem));
            }
        } else {
            items.set(name, ClassItem(rawItem, id, name));
        }

        _adding = false;

    } //add

/// From string

    static public function fromString(env:Env, moduleName:String, haxe:String) {

        var converter = new ConvertHaxe(haxe);
        converter.convert();

        var module = new DynamicModule();
        module.dynamicClasses = new Map();

        var currentClassPath:String = null;
        var dynClass:DynamicClass = null;
        var modifiers = new Map<String,Bool>();
        var packagePrefix:String = '';

        module.imports = new ResolveImports(env);
        module.usings = new ResolveUsings(env);

        for (token in converter.tokens) {
            switch (token) {

                case TPackage(data):
                    packagePrefix = data.path != null && data.path != '' ? data.path + '.' : '';
            
                case TImport(data):
                    module.imports.addImport(data);
                
                case TUsing(data):
                    module.usings.addUsing(data);

                case TModifier(data):
                    modifiers.set(data.name, true);

                case TType(data):
                    if (data.kind == CLASS) {
                        dynClass = new DynamicClass(env, {
                            tokens: converter.tokens,
                            targetClass: data.name
                        });
                        module.dynamicClasses.set(data.name, dynClass);
                        currentClassPath = packagePrefix + (data.name == moduleName ? data.name : moduleName + '.' + data.name);
                        module.add(currentClassPath, dynClass, false, null);
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
                                module.add(currentClassPath + '.' + data.name, dynClass, true, null);
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
                                module.add(currentClassPath + '.' + data.name, dynClass, true, extendedType);
                            }
                        }
                    }
                
                default:
            
            }
        }

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
        var name = parts[0];
        var complexType = TPath({pack: pack, name: name});
        var type = Context.resolveType(complexType, pos);

        var module = Context.getModule(typePath);

        var toAdd:Array<Array<Dynamic>> = [];
        
        for (item in module) {
            switch (item) {
                case TInst(t, params):
                    // Type
                    var rawTypePath = t.toString();
                    var subTypePath = rawTypePath;
                    if (rawTypePath != typePath) {
                        subTypePath = typePath + rawTypePath.substring(rawTypePath.lastIndexOf('.'));
                    }
                    toAdd.push([subTypePath, false]);

                    // Static fields
                    for (field in t.get().statics.get()) {
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
                                                true,
                                                extendedType
                                            ]);
                                        } else {
                                            toAdd.push([
                                                subTypePath + '.' + field.name,
                                                false,
                                                null
                                            ]);
                                        }
                                    default:
                                        toAdd.push([
                                            subTypePath + '.' + field.name,
                                            true,
                                            null
                                        ]);
                                }
                            default:
                                toAdd.push([
                                    subTypePath + '.' + field.name,
                                    true,
                                    null
                                ]);
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

        var result = macro function() {
            var module = new hxs.DynamicModule();
            module.lazyLoad = function(mod) $b{addExprs};
            return module;
        }();

        //trace(new haxe.macro.Printer().printExpr(result));

        return result;

    } //fromStatic

} //DynamicModule
