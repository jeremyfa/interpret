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

/// Properties

    var oldLocals:Array<Int> = [];

    var selfName:String;

    var classInterpreter:Interpreter;

    var getters:Map<String,Bool> = null;

    var setters:Map<String,Bool> = null;

    var env:Env = null;

    var dynamicClass:DynamicClass;

    var _self:Map<String,Dynamic> = null;

    var _classSelf:Map<String,Dynamic> = null;

    var _queryingInterpreter:Interpreter = null;

    var _unresolved:Dynamic = null;

/// Lifecycle

    override public function new(dynamicClass:DynamicClass, selfName:String = 'this', ?classInterpreter:Interpreter) {

        super();

        this.dynamicClass = dynamicClass;
        this.env = dynamicClass.env;
        this.selfName = selfName;
        this.classInterpreter = classInterpreter;

        this.variables.set('null', null);
        this.variables.set('false', false);
        this.variables.set('true', true);

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

        if (_queryingInterpreter != null) {
            return _queryingInterpreter.dynamicClass.usings.hasName(name);
        }
        return dynamicClass.usings.hasName(name);

    } //existsAsExtension

/// Overrides

    override function resolve(id:String):Dynamic {

        //trace('RESOLVE $id');

        var l = locals.get(id);
        if (l != null) {
            return l.r;
        }
        var self:Map<String,Dynamic> = _self != null ? _self : locals.get(selfName).r;

        if (hasGetter(id)) {
            if (classInterpreter != null) {
                var classSelf:Map<String,Dynamic> = _classSelf != null ? _classSelf : locals.get(classInterpreter.selfName).r;
                return variables.get('get_' + id)(classSelf, self);
            } else {
                return variables.get('get_' + id)(self);
            }
        }

        if (self.exists(id)) {
            return self.get(id);
        }
        /*if (id == 'super' && variables.exists('super')) {
            return variables.get('super');
        }*/
        if (id == '__super_new' && variables.exists('__super_new')) {
            return variables.get('__super_new');
        }
        if (self.exists('__interpretInstance')) {
            var dynInst:DynamicInstance = self.get('__interpretInstance');
            var result:Dynamic = dynInst.get(id, false);
            if (result != Unresolved.UNRESOLVED) {
                return result;
            }
        }
        var superInstance = self.get('super');
        if (superInstance != null) {
            if (Std.is(superInstance, DynamicInstance)) {
                var dynInst:DynamicInstance = cast superInstance;
                var prevQueryingInterpreter = dynInst.interpreter._queryingInterpreter;
                var prevUnresolved = dynInst.interpreter._unresolved;
                dynInst.interpreter._queryingInterpreter = this;
                dynInst.interpreter._unresolved = Unresolved.UNRESOLVED;
                var result = dynInst.get(id, false);
                dynInst.interpreter._queryingInterpreter = prevQueryingInterpreter;
                dynInst.interpreter._unresolved = prevUnresolved;
                if (result != Unresolved.UNRESOLVED) {
                    return result;
                }
            } else {
                var result = super.get(superInstance, id);
                if (result != null || Reflect.hasField(superInstance, id) || Reflect.hasField(superInstance, 'get_' + id)) {
                    if (Reflect.isFunction(result)) {
                        // Bind superClass context
                        return Reflect.makeVarArgs(function(args) {

                            var prevArgs = args;
                            args = [];
                            for (i in 0...prevArgs.length) {
                                args.push(unwrap(prevArgs[i]));
                            }

                            return Reflect.callMethod(superInstance, result, args);
                        });
                    } else {
                        return result;
                    }
                }
            }
        }
        if (self.exists('__interpretClass')) {
            var dynClass:DynamicClass = self.get('__interpretClass');
            var result = dynClass.get(id, false);
            if (result != Unresolved.UNRESOLVED) {
                return result;
            }
        }
        if (variables.exists(id)) {
            var result = variables.get(id);
            if (id == 'trace') {
                if (env.trace != null) return env.trace;
                else return variables.get('trace');
            }
            else if (Reflect.isFunction(result)) {
                // TODO cache?
                if (classInterpreter != null) {
                    var classSelf:Map<String,Dynamic> = _classSelf != null ? _classSelf : locals.get(classInterpreter.selfName).r;
                    var selfArgs:Array<Dynamic> = [classSelf, self];
                    return Reflect.makeVarArgs(function(args) {
                        return Reflect.callMethod(
                            null,
                            result,
                            args == null || args.length == 0 ? selfArgs : selfArgs.concat(args)
                        );
                    });
                } else {
                    var selfArgs:Array<Dynamic> = [self];
                    return Reflect.makeVarArgs(function(args) {
                        return Reflect.callMethod(
                            null,
                            result,
                            args == null || args.length == 0 ? selfArgs : selfArgs.concat(args)
                        );
                    });
                }
            }
            return result;
        }
        if (classInterpreter != null) {
            var classSelf:Map<String,Dynamic> = locals.get(classInterpreter.selfName).r;
            if (classInterpreter.hasGetter(id)) {
                return classInterpreter.variables.get('get_' + id)(classSelf);
            }
            if (classSelf.exists(id)) {
                return classSelf.get(id);
            }
            if (classSelf.exists('__interpretClass')) {
                var dynClass:DynamicClass = classSelf.get('__interpretClass');
                var result = dynClass.get(id, false);
                if (result != Unresolved.UNRESOLVED) {
                    return result;
                }
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
        return _unresolved;

    } //resolve

	override function assign(e1:Expr, e2:Expr):Dynamic {

		var v = expr(e2);
        
		switch( hscript.Tools.expr(e1) ) {
		case EIdent(id):
			var l = locals.get(id);
			if( l == null ) {
                var self:Map<String,Dynamic> = locals.get(selfName).r;
                if (hasSetter(id)) {
                    if (classInterpreter != null) {
                        var classSelf:Map<String,Dynamic> = _classSelf != null ? _classSelf : locals.get(classInterpreter.selfName).r;
				        return variables.get('set_' + id)(classSelf, self, v);
                    } else {
				        return variables.get('set_' + id)(self, v);
                    }
                }
                else if (self.exists(id)) {
                    self.set(id, v);
                    return v;
                }
                else if (classInterpreter != null) {
                    var classSelf:Map<String,Dynamic> = _classSelf != null ? _classSelf : locals.get(classInterpreter.selfName).r;
                    if (classInterpreter.hasSetter(id)) {
                        return classInterpreter.variables.get('set_' + id)(classSelf, v);
                    }
                    else if (classSelf.exists(id)) {
                        classSelf.set(id, v);
                        return v;
                    }
                }
                var superInstance = self.get('super');
                if (superInstance != null) {
                    if (Std.is(superInstance, DynamicInstance)) {
                        var dynInst:DynamicInstance = cast superInstance;
                        var prevQueryingInterpreter = dynInst.interpreter._queryingInterpreter;
                        var prevUnresolved = dynInst.interpreter._unresolved;
                        dynInst.interpreter._queryingInterpreter = this;
                        dynInst.interpreter._unresolved = Unresolved.UNRESOLVED;
                        var result = dynInst.set(id, v, false);
                        dynInst.interpreter._queryingInterpreter = prevQueryingInterpreter;
                        dynInst.interpreter._unresolved = prevUnresolved;
                        if (result != Unresolved.UNRESOLVED) {
                            return result;
                        }
                    } else {
                        var result = Reflect.field(superInstance, id);
                        var setter_result = Reflect.field(superInstance, 'set_' + id);
                        if (result != null || setter_result != null || Reflect.hasField(superInstance, id) || Reflect.hasField(superInstance, 'set_' + id)) {
                            Reflect.setProperty(superInstance, id, unwrap(v));
                            return v;
                        }
                    }
                }
                else {
                    self.set(id, v);
                    return v;
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

        //trace('GET $o / $f');

        var self:Map<String,Dynamic> = _self != null ? _self : locals.get(selfName).r;
        if (o == self) {
            if (hasGetter(f)) {
                if (classInterpreter != null) {
                    var classSelf:Map<String,Dynamic> = _classSelf != null ? _classSelf : locals.get(classInterpreter.selfName).r;
                    return variables.get('get_' + f)(classSelf, self);
                } else {
                    return variables.get('get_' + f)(self);
                }
            }
            else if (self.exists(f)) {
                return self.get(f);
            }
            else if (variables.exists(f)) {
                var result = variables.get(f);
                //trace('-> $result');
                if (Reflect.isFunction(result)) {
                    // TODO cache?
                    if (classInterpreter != null) {
                        var classSelf:Map<String,Dynamic> = _classSelf != null ? _classSelf : locals.get(classInterpreter.selfName).r;
                        var selfArgs:Array<Dynamic> = [classSelf, self];
                        return Reflect.makeVarArgs(function(args) {
                            //trace('DO CALL 1 null $result $args');
                            return Reflect.callMethod(
                                null,
                                result,
                                args == null || args.length == 0 ? selfArgs : selfArgs.concat(args)
                            );
                        });
                    } else {
                        var selfArgs:Array<Dynamic> = [self];
                        return Reflect.makeVarArgs(function(args) {
                            //trace('DO CALL 2 null $result $args');
                            return Reflect.callMethod(
                                null,
                                result,
                                args == null || args.length == 0 ? selfArgs : selfArgs.concat(args)
                            );
                        });
                    }
                }
                return result;
            }
            if (self.exists('__interpretInstance')) {
                var dynInstance:DynamicInstance = self.get('__interpretInstance');
                if (dynInstance.dynamicClass.instanceMethods.exists(f) || dynInstance.dynamicClass.instanceVars.exists(f)) {
                    return get(dynInstance, f);
                }
            }
            if (self.exists('__interpretClass')) {
                var dynClass:DynamicClass = self.get('__interpretClass');
                if (dynClass.classMethods.exists(f) || dynClass.classVars.exists(f)) {
                    return get(dynClass, f);
                }
            }
            var superInstance = self.get('super');
            if (superInstance != null) {
                if (Std.is(superInstance, DynamicInstance)) {
                    var dynInst:DynamicInstance = cast superInstance;
                    var prevQueryingInterpreter = dynInst.interpreter._queryingInterpreter;
                    var prevUnresolved = dynInst.interpreter._unresolved;
                    dynInst.interpreter._queryingInterpreter = this;
                    dynInst.interpreter._unresolved = Unresolved.UNRESOLVED;
                    var result:Dynamic = dynInst.get(f, false);
                    dynInst.interpreter._queryingInterpreter = prevQueryingInterpreter;
                    dynInst.interpreter._unresolved = prevUnresolved;
                    if (result != Unresolved.UNRESOLVED) {
                        return result;
                    }
                } else {
                    var result = super.get(superInstance, f);
                    if (result != null || Reflect.hasField(superInstance, f) || Reflect.hasField(superInstance, 'get_' + f)) {
                        return result;
                    }
                }
            }
            if (existsAsExtension(f)) {
                if (_queryingInterpreter != null) {
                    // This is needed when querying properties from another interpreter,
                    // because we want to resolve extensions from calling interpreter, not ours.
                    var typePath = _queryingInterpreter.dynamicClass.instanceType;
                    var resolved = _queryingInterpreter.dynamicClass.usings.resolve(typePath, f);
                    if (resolved != null) {
                        return resolved;
                    }
                } else {
                    var typePath = dynamicClass.instanceType;
                    var resolved = dynamicClass.usings.resolve(typePath, f);
                    if (resolved != null) {
                        return resolved;
                    }
                }
            }
            return _unresolved;
        }
        var classSelf:Map<String,Dynamic> = classInterpreter != null ? (_classSelf != null ? _classSelf : locals.get(classInterpreter.selfName).r) : null;
        if (classSelf != null && o == classSelf) {
            if (classInterpreter.hasGetter(f)) {
                return classInterpreter.variables.get('get_' + f)(classSelf);
            }
            else if (classSelf.exists(f)) {
                return classSelf.get(f);
            }
            else if (self.exists('__interpretClass')) {
                var dynClass:DynamicClass = self.get('__interpretClass');
                return get(dynClass, f);
            }
            // TODO static/class interpreter.variables
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
            //trace('is runtime item');
            var moduleItem:RuntimeItem = cast o;
            switch (moduleItem) {
                case ClassFieldItem(rawItem, _, _) | ExtensionItem(ClassFieldItem(rawItem, _, _), _):
                    return super.get(rawItem, f);
                case ClassItem(rawItem, moduleId, name):
                    var module = @:privateAccess env.modulesById.get(moduleId);
                    var key = name + '.' + f;
                    if (module.items.exists(key)) {
                        var item = module.items.get(key);
                        return unwrapExtensionItem(item);
                    }
                    else if (existsAsExtension(f)) {
                        var typePath = TypeUtils.typeOf(o, env);
                        var resolved = dynamicClass.usings.resolve(typePath, f);
                        if (resolved != null) {
                            return resolved;
                        }
                    }
                    return null;
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
                    //trace('IS PACK $pack.$f');
                    return unwrap(pack.getSub(f));
                case AbstractItem(rawItem, moduleId, name, runtimeType):
                    var module = @:privateAccess env.modulesById.get(moduleId);
                    var key = name + '.' + f;
                    if (module.items.exists(key)) {
                        return module.items.get(key);
                    }
                    return null;
                case AbstractFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                    return super.get(rawItem, f);
                case EnumFieldItem(rawItem, name, numArgs):
                    return null;
                case SuperClassItem(item):
                    return null;
                case ExtensionItem(item, extendedType):
                    return null;
            }
        }
        else if (Std.is(o, DynamicInstance)) {
            var dynInst:DynamicInstance = cast o;
            var prevQueryingInterpreter = dynInst.interpreter._queryingInterpreter;
            dynInst.interpreter._queryingInterpreter = this;
            var result = dynInst.get(f);
            dynInst.interpreter._queryingInterpreter = prevQueryingInterpreter;
            return result;
        }
        else if (Std.is(o, DynamicClass)) {
            var dynClass:DynamicClass = cast o;
            dynClass.initIfNeeded();
            var prevQueryingInterpreter = dynClass.interpreter._queryingInterpreter;
            dynClass.interpreter._queryingInterpreter = this;
            var result = dynClass.get(f);
            dynClass.interpreter._queryingInterpreter = prevQueryingInterpreter;
            return result;
        }
        else if (existsAsExtension(f)) {
            var typePath = TypeUtils.typeOf(o, env);
            var resolved = dynamicClass.usings.resolve(typePath, f);
            if (resolved != null) {
                return resolved;
            }
        }
        else if (Std.is(o, DynamicPackage)) {
            var dynPack:DynamicPackage = cast o;
            var sub = dynPack.getSub(f);
            //trace('sub($f) -> $sub');
            return sub;
        }
        else if (Std.is(o, DynamicModule)) {
            var dynMod:DynamicModule = cast o;
            var result = dynMod.items.get(dynMod.typePath + '.' + f);
            return unwrap(result);
        }
        //trace('SUPER GET $o / $f');
        return super.get(o, f);

    } //get

    override function set(o:Dynamic, f:String, v:Dynamic):Dynamic {

        var self:Map<String,Dynamic> = _self != null ? _self : locals.get(selfName).r;
        if (o == self) {
            if (hasSetter(f)) {
                if (classInterpreter != null) {
                    var classSelf:Map<String,Dynamic> = _classSelf != null ? _classSelf : locals.get(classInterpreter.selfName).r;
                    return variables.get('set_' + f)(classSelf, self, v);
                } else {
                    return variables.get('set_' + f)(self, v);
                }
            }
            else {
                if (_unresolved == null) {
                    self.set(f, v);
                }
                else {
                    if (self.exists(f)) {
                        self.set(f, v);
                    }
                    else {
                        // When `unresolved` value is not null, forbid setting new fields
                        // and return `unresolved` instead
                        return _unresolved;
                    }
                }
            }
            return v;
        }
        var classSelf:Map<String,Dynamic> = classInterpreter != null ? (_classSelf != null ? _classSelf : locals.get(classInterpreter.selfName).r) : null;
        if (classSelf != null && o == classSelf) {
            if (classInterpreter.hasSetter(f)) {
                return classInterpreter.variables.get('set_' + f)(classSelf, v);
            } else {
                classSelf.set(f, v);
            }
            return v;
        }
        if (Std.is(o, RuntimeItem)) {
            var moduleItem:RuntimeItem = cast o;
            switch (moduleItem) {
                case ClassFieldItem(rawItem, moduleId, name, isStatic, type, argTypes) | ExtensionItem(ClassFieldItem(rawItem, moduleId, name, isStatic, type, argTypes), _):
                    if (rawItem == null) {
                        var dotIndex = name.lastIndexOf('.');
                        var dynClass = env.resolveDynamicClass(moduleId, name.substring(0, dotIndex));
                        if (dynClass != null) {
                            return set(dynClass.get(name.substring(dotIndex + 1)), f, v);
                        }
                        else {
                            throw 'Failed to set value for class field ' + name;
                        }
                    }
                    return super.set(rawItem, f, unwrap(v));
                case ClassItem(rawItem, moduleId, name):
                    return set(unwrap(o), f, v);
                default:
                    return null;
            }
        }
        else if (Std.is(o, DynamicInstance)) {
            var dynInst:DynamicInstance = cast o;
            var prevQueryingInterpreter = dynInst.interpreter._queryingInterpreter;
            dynInst.interpreter._queryingInterpreter = this;
            var result = dynInst.set(f, v);
            dynInst.interpreter._queryingInterpreter = prevQueryingInterpreter;
            return result;
        }
        else if (Std.is(o, DynamicClass)) {
            var dynClass:DynamicClass = cast o;
            dynClass.initIfNeeded();
            var prevQueryingInterpreter = dynClass.interpreter._queryingInterpreter;
            dynClass.interpreter._queryingInterpreter = this;
            var result = dynClass.set(f, v);
            dynClass.interpreter._queryingInterpreter = prevQueryingInterpreter;
            return result;
        }
        //trace('SUPER SET $o $f $v');
        return super.set(o, f, unwrap(v));

    } //set

    override function call(o:Dynamic, f:Dynamic, args:Array<Dynamic>):Dynamic {

        if (Std.is(f, RuntimeItem)) {
            switch (f) {
                case ExtensionItem(ClassFieldItem(rawItem, moduleId, name, isStatic, type, argTypes), _):
                    if (rawItem == null) {
                        var dotIndex = name.lastIndexOf('.');
                        var dynClass = env.resolveDynamicClass(moduleId, name.substring(0, dotIndex));
                        if (dynClass != null) {
                            return dynClass.call(name.substring(dotIndex + 1), [o].concat(args));
                        }
                        else {
                            throw 'Unresolved dynamic extension: ' + name;
                        }
                    }
                    else {
                        var prevArgs = args;
                        args = [];
                        for (i in 0...prevArgs.length) {
                            args.push(unwrap(prevArgs[i]));
                        }
                    }
                    return Reflect.callMethod(null, rawItem, [o].concat(args));
                case ClassFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                    if (rawItem == null) {
                        var dotIndex = name.lastIndexOf('.');
                        var dynClass = env.resolveDynamicClass(moduleId, name.substring(0, dotIndex));
                        if (dynClass != null) {
                            return dynClass.call(name.substring(dotIndex + 1), args);
                        }
                        else {
                            throw 'Unresolved dynamic class field: ' + name;
                        }
                    }
                    else {
                        var prevArgs = args;
                        args = [];
                        for (i in 0...prevArgs.length) {
                            args.push(unwrap(prevArgs[i]));
                        }
                    }
                    return Reflect.callMethod(o, rawItem, args);
                case EnumFieldItem(rawItem, _, _):
                    if (Std.is(rawItem, DynamicClass)) {
                        return null; // TODO?
                    }
                    return Reflect.callMethod(o, rawItem, args);
                case SuperClassItem(ClassItem(rawItem, moduleId, name)):
                    if (rawItem == null) {
                        var dynClass = env.resolveDynamicClass(moduleId, name);
                        if (dynClass != null) {
                            var self:Map<String,Dynamic> = locals.get(selfName).r;
                            var instance = dynClass.createInstance(args);
                            self.set('super', instance);
                            return instance;
                        }
                        else {
                            throw 'Unresolved dynamic superclass: ' + name;
                        }
                    }
                    else {
                        var prevArgs = args;
                        args = [];
                        for (i in 0...prevArgs.length) {
                            args.push(unwrap(prevArgs[i]));
                        }
                    }
                    var self:Map<String,Dynamic> = locals.get(selfName).r;
                    var instance = Type.createInstance(rawItem, args);
                    self.set('super', instance);
                    return instance;
                default:
                    throw 'Cannot call module item: ' + f;
            }
        }
        //trace('super.call($o, $f, $args)');
        return super.call(o, f, args);
    }

    public function resolveClass(cl:String):Dynamic {

        var parts = cl.split('.');
        var resolved:Dynamic = null;
        var i = 0;
        for (part in parts) {
            if (i++ == 0) {
                resolved = resolve(part);
            } else {
                resolved = get(resolved, part);
            }
        }
        return resolved;

    } //resolveClass

    override function cnew(cl:String, args:Array<Dynamic>):Dynamic {

        // Resolve class
        var clazz = resolveClass(cl);

        // Dynamic class?
        if (Std.is(clazz, DynamicClass)) {
            var dynClass:DynamicClass = cast clazz;
            return dynClass.createInstance(args);
        }
        else if (Std.is(clazz, Class)) {
            return Type.createInstance(clazz, args);
        }

        trace('cnew $clazz $cl $args');
        return super.cnew(cl, args);

    } //cnew

    function unwrapExtensionItem(value:Dynamic):Dynamic {

        if (value == null) return null;
        if (Std.is(value, RuntimeItem)) {
            var item:RuntimeItem = cast value;
            switch (item) {
                case ExtensionItem(subItem, _):
                    // We ensure this won't be considered as an extension item
                    // but just a regular field
                    switch (subItem) {
                        case EnumFieldItem(rawItem, _, _) | EnumItem(rawItem, _, _):
                            // Unwrap
                            return rawItem;
                        case ClassFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                            if (rawItem == null) {
                                var dotIndex = name.lastIndexOf('.');
                                var dynClass = env.resolveDynamicClass(moduleId, name.substring(0, dotIndex));
                                if (dynClass != null) return dynClass.get(name.substring(dotIndex + 1));
                            }
                            return rawItem;
                        case ClassItem(rawItem, moduleId, name):
                            if (rawItem == null) {
                                var dynClass = env.resolveDynamicClass(moduleId, name);
                                if (dynClass != null) return dynClass;
                            }
                            return rawItem;
                        default:
                            return subItem;
                    }
                default:
                    return value;
            }
        }

        return value;

    } //unwrapExtensionItem

    function unwrap(value:Dynamic):Dynamic {

        if (value == null) return null;
        if (value == Unresolved.UNRESOLVED) return null;

        if (Std.is(value, RuntimeItem)) {
            var item:RuntimeItem = cast value;
            switch (item) {
                case ExtensionItem(subItem, _):
                    // We ensure this won't be considered as an extension item
                    // but just a regular field
                    switch (subItem) {
                        case EnumFieldItem(rawItem, _, _) | EnumItem(rawItem, _, _):
                            // Unwrap
                            return rawItem;
                        case ClassFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                            if (rawItem == null) {
                                var dotIndex = name.lastIndexOf('.');
                                var dynClass = env.resolveDynamicClass(moduleId, name.substring(0, dotIndex));
                                if (dynClass != null) return dynClass.get(name.substring(dotIndex + 1));
                            }
                            return rawItem;
                        case ClassItem(rawItem, moduleId, name):
                            if (rawItem == null) {
                                var dynClass = env.resolveDynamicClass(moduleId, name);
                                if (dynClass != null) return dynClass;
                            }
                            return rawItem;
                        default:
                            return subItem;
                    }
                case EnumFieldItem(rawItem, _, _) | EnumItem(rawItem, _, _):
                    // Unwrap
                    return rawItem;
                case ClassFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                    if (rawItem == null) {
                        var dotIndex = name.lastIndexOf('.');
                        var dynClass = env.resolveDynamicClass(moduleId, name.substring(0, dotIndex));
                        if (dynClass != null) return dynClass.get(name.substring(dotIndex + 1));
                    }
                    return rawItem;
                case ClassItem(rawItem, moduleId, name):
                    if (rawItem == null) {
                        var dynClass = env.resolveDynamicClass(moduleId, name);
                        if (dynClass != null) return dynClass;
                    }
                    return rawItem;
                default:
                    return value;
            }
        }
        
        if (Std.is(value, DynamicAbstractValue)) {
            var abstractValue:DynamicAbstractValue = cast value;
            return abstractValue.value;
        }

        return value;

    } //unwrap

} //Interp
