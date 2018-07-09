package hxs;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Printer;
#end

import hxs.Types;

/** Like static extensions, but resolved at runtime. */
class DynamicExtension {

    static var _adding = false;

/// Properties

    public var names(get,null):Map<String,Map<String,ModuleItem>> = null;

    function get_names():Map<String,Map<String,ModuleItem>> {
        if (!_adding && lazyLoad != null) {
            if (lazyLoad != null) {
                var cb = lazyLoad;
                lazyLoad = null;
                cb(this);
            }
        }
        return this.names;
    }

    public var lazyLoad:DynamicExtension->Void = null;

/// Lifecycle

    public function new() {

    } //new

    public function add(name:String, extendedType:String, field:Dynamic) {

        _adding = true;

        if (names == null) names = new Map();

        var extendedTypesForName = names.get(name);
        if (extendedTypesForName == null) {
            extendedTypesForName = new Map();
            names.set(name, extendedTypesForName);
        }
        extendedTypesForName.set(extendedType, FieldItem(field));

        _adding = false;

    } //add

    public function resolve(name:String, extendedType:String) {

        if (names == null) return null;

        var extendedTypesForName = names.get(name);
        if (extendedTypesForName != null && extendedTypesForName.exists(extendedType)) {
            return extendedTypesForName.get(extendedType);
        }
        return null;

    } //has

/// From static extension

    /** Return a `DynamicExtension` instance from a static extension as it was at compile time. 
        Allows to easily map a Haxe static extension to scriptable side as a dynamic extension. */
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
        var toAdd:Array<Array<Dynamic>> = [];

        switch (type) {
            case TInst(t, params):
                // Iterate over every static field
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
                                        if (extendedType != null) {
                                            toAdd.push([
                                                field.name,
                                                extendedType,
                                                typePath.split('.').concat([field.name])
                                            ]);
                                        }
                                    }
                                default:
                            }
                        default:
                    }
                }

            default:
                throw "Invalid type: " + type;
        }

        var addExprs:Array<Expr> = [];
        for (item in toAdd) {
            var expr = macro ext.add($v{item[0]}, $v{item[1]}, $p{item[2]});
            addExprs.push(expr);
        }

        var result = macro function() {
            var extension = new hxs.DynamicExtension();
            extension.lazyLoad = function(ext) $b{addExprs};
            return extension;
        }();

        return result;

    } //fromStatic

} //DynamicExtension
