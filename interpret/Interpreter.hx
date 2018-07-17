package interpret;

import interpret.Types;
import hscript.Expr;

/** Supercharged interpreter that behave almost like regular haxe.
    While we try not to waste any resource, it is expected that this interpreter
    gives priority to consistency with haxe over performance.
    If you want your code to be fast, your should just compile it with haxe compiler anyway :) */
@:allow(interpret.DynamicClass)
@:allow(interpret.DynamicInstance)
class Interpreter extends hscript.Interp {

    @:noCompletion
    public static var _variablesTypes:Class<Dynamic> = null;

/// Properties

    var oldLocals:Array<Int> = [];

    var selfName:String;

    var classInterpreter:Interpreter;

    var keywords:Map<String,Dynamic> = [
        'null' => null,
        'false' => false,
        'true' => true
    ];

    var getters:Map<String,Bool> = null;

    var setters:Map<String,Bool> = null;

    var env:Env = null;

    var dynamicClass:DynamicClass;

/// Lifecycle

    override public function new(dynamicClass:DynamicClass, selfName:String = 'this', ?classInterpreter:Interpreter) {

        super();

        if (_variablesTypes == null) {
            _variablesTypes = Type.getClass(variables);
        }

        this.dynamicClass = dynamicClass;
        this.env = dynamicClass.env;
        this.selfName = selfName;
        this.classInterpreter = classInterpreter;

        if (selfName == 'this') {
            // Instance
            this.variables.set('__interpret_type', dynamicClass.instanceType);
        }
        else {
            // Statics
            this.variables.set('__interpret_type', dynamicClass.classType);
        }

    } //new

/// Helpers

    public function beginBlock() {

        oldLocals.push(declared.length);

    } //beginBlock

    public function endBlock() {

        restore(oldLocals.pop());

    } //endBlock

    inline public function hasGetter(id:String):Bool {

        return getters != null && getters.exists(id);

    } //hasGetter

    inline public function hasSetter(id:String):Bool {

        return setters != null && setters.exists(id);

    } //hasSetter

    function existsAsExtension(name:String):Bool {

        return dynamicClass.usings.hasName(name);

    } //existsAsExtension

/// Overrides

    override function resolve(id:String):Dynamic {

        if (keywords.exists(id)) return keywords.get(id);
        if (id == selfName) return variables;
        if (classInterpreter != null && id == classInterpreter.selfName) return classInterpreter.variables;
        var l = locals.get(id);
        if (l != null) {
            return l.r;
        }
        if (hasGetter(id)) {
            return variables.get('get_' + id)();
        }
        if (variables.exists(id)) {
            return variables.get(id);
        }
        if (classInterpreter != null) {
            if (classInterpreter.hasGetter(id)) {
                return classInterpreter.variables.get('get_' + id)();
            }
            if (classInterpreter.variables.exists(id)) {
                return classInterpreter.variables.get(id);
            }
        }
        // Resolve module item
        var moduleItem = dynamicClass.imports.resolve(id);
        if (moduleItem != null) {
            return unwrap(moduleItem);
        }
        if (env.modules.exists(id)) {
            var module = env.modules.get(id);
            moduleItem = module.items.get(id);
            if (moduleItem != null) {
                switch (moduleItem) {
                    case ExtensionItem(subItem, _):
                        // We ensure this won't be considered as an extension item
                        // but just a regular field
                        return subItem;
                    default:
                        return moduleItem;
                }
            }
        }
        // Resolve package part
        var pack = env.getPackage(id);
        if (pack != null) {
            return PackageItem(pack);
        }
        return null;

    } //resolve

	override function assign(e1:Expr, e2:Expr):Dynamic {

		var v = expr(e2);
        
		switch( edef(e1) ) {
		case EIdent(id):
			var l = locals.get(id);
			if( l == null ) {
                if (hasSetter(id)) {
				    return variables.get('set_' + id)(v);
                } else if (classInterpreter != null && classInterpreter.hasSetter(id)) {
				    return classInterpreter.variables.get('set_' + id)(v);
                } else {
				    variables.set(id,v);
                }
            }
			else
				l.r = v;
		case EField(e,f):
			v = set(expr(e),f,v);
		case EArray(e, index):
			var arr:Dynamic = expr(e);
			var index:Dynamic = expr(index);
			if (isMap(arr)) {
				setMapValue(arr, index, v);
			}
			else {
				arr[index] = v;
			}

		default:
			error(EInvalidOp("="));
		}
		return v;

	} //assign

    override function get(o:Dynamic, f:String):Dynamic {

        if (o == variables) {
            if (hasGetter(f)) {
                return variables.get('get_' + f)();
            }
            else if (variables.exists(f)) {
                return variables.get(f);
            }
            else if (existsAsExtension(f)) {
                var typePath = dynamicClass.instanceType;
                var resolved = dynamicClass.usings.resolve(typePath, f);
                if (resolved != null) {
                    return resolved;
                }
            }
            return null;
        }
        else if (classInterpreter != null && o == classInterpreter.variables) {
            if (classInterpreter.hasGetter(f)) {
                return classInterpreter.variables.get('get_' + f)();
            }
            else if (classInterpreter.variables.exists(f)) {
                return classInterpreter.variables.get(f);
            }
            else if (existsAsExtension(f)) {
                var typePath = dynamicClass.classType;
                var resolved = dynamicClass.usings.resolve(typePath, f);
                if (resolved != null) {
                    return resolved;
                }
            }
            return null;
        }
        else if (Std.is(o, RuntimeItem)) {
            var moduleItem:RuntimeItem = cast o;
            switch (moduleItem) {
                case ClassFieldItem(rawItem) | ExtensionItem(ClassFieldItem(rawItem), _):
                    return super.get(rawItem, f);
                case ClassItem(rawItem, moduleId, name):
                    var module = @:privateAccess env.modulesById.get(moduleId);
                    return unwrap(module.items.get(name + '.' + f));
                case EnumItem(rawItem, moduleId, name):
                    var module = @:privateAccess env.modulesById.get(moduleId);
                    var resolved = module.items.get(name + '.' + f);
                    switch (resolved) {
                        case EnumFieldItem(rawItem, name, numArgs):
                            // Raw enum field
                            return rawItem;
                        default:
                            return resolved;
                    }
                case PackageItem(pack):
                    return unwrap(pack.getSub(f));
                default:
                    return null;
            }
        }
        else if (existsAsExtension(f)) {
            var typePath = TypeUtils.typeOf(o);
            var resolved = dynamicClass.usings.resolve(typePath, f);
            if (resolved != null) {
                return resolved;
            }
        }
        return super.get(o, f);

    } //get

    override function call(o:Dynamic, f:Dynamic, args:Array<Dynamic>):Dynamic {
        if (Std.is(f, RuntimeItem)) {
            switch (f) {
                case ExtensionItem(ClassFieldItem(rawItem), _):
                    return Reflect.callMethod(null, rawItem, [o].concat(args));
                case ClassFieldItem(rawItem):
                    return Reflect.callMethod(o, rawItem, args);
                case EnumFieldItem(rawItem, _, _):
                    return Reflect.callMethod(o, rawItem, args);
                default:
                    throw 'Cannot call module item: ' + f;
            }
        }
        return super.call(o, f, args);
    }

    override function set(o:Dynamic, f:String, v:Dynamic):Dynamic {

        if (o == variables) {
            variables.set(f, v);
            return v;
        }
        else if (classInterpreter != null && o == classInterpreter.variables) {
            classInterpreter.variables.set(f, v);
            return v;
        }
        else if (hasSetter(f)) {
            return variables.get('set_' + f)(v);
        }
        else if (classInterpreter != null && classInterpreter.hasSetter(f)) {
            return classInterpreter.variables.get('set_' + f)(v);
        }
        return super.set(o, f, v);

    } //set

    inline function unwrap(value:Dynamic):Dynamic {

        if (value == null) return null;

        if (Std.is(value, RuntimeItem)) {
            var item:RuntimeItem = cast value;
            switch (item) {
                case ExtensionItem(subItem, _):
                    // We ensure this won't be considered as an extension item
                    // but just a regular field
                    switch (subItem) {
                        case EnumFieldItem(rawItem, _, _) | EnumItem(rawItem, _, _) | ClassItem(rawItem, _, _) | ClassFieldItem(rawItem):
                            // Unwrap
                            return rawItem;
                        default:
                            return subItem;
                    }
                case EnumFieldItem(rawItem, _, _) | EnumItem(rawItem, _, _) | ClassItem(rawItem, _, _) | ClassFieldItem(rawItem):
                    // Unwrap
                    return rawItem;
                default:
                    return value;
            }
        }

        return value;

    } //unwrap

} //Interp
