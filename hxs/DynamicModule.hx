package hxs;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Printer;
#end

import hxs.Types;

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

    @:noCompletion
    public var lazyLoad:DynamicModule->Void = null;

/// Lifecycle

    public function new() {

    } //new

    public function add(name:String, rawItem:Dynamic, isField:Bool, ?extendedType:String) {

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
