package interpret;

import interpret.Types.RuntimeItem;
@:allow(interpret.TypeUtils)
@:allow(interpret.Interpreter)
class DynamicAbstract {

    public var env(default,null):Env;

    public var value:Dynamic;

    public var abstractItem:RuntimeItem;

    public function new(env:Env, abstractItem:RuntimeItem, ?value:Dynamic) {
        this.env = env;
        this.value = value;
        this.abstractItem = abstractItem;
    }

    public static function createInstance(env:Env, abstractItem:RuntimeItem, args:Array<Dynamic>):DynamicAbstract {

        var abs = new DynamicAbstract(env, abstractItem, null);

        switch (abstractItem) {
            case AbstractItem(rawItem, moduleId, name, runtimeType):
                var module = @:privateAccess env.modulesById.get(moduleId);
                var constructor:RuntimeItem = module.items.get(name + '.new');
                switch (constructor) {
                    case AbstractFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                        var _args:Array<Dynamic> = [abs];
                        for (i in 0...args.length) {
                            _args.push(TypeUtils.unwrap(args[i], env));
                        }
                        Reflect.callMethod(null, rawItem, _args);
                    default:
                        throw "Invalid abstract constructor: " + constructor;
                }

            default:
                throw "Invalid runtime item to create an abstract: " + abstractItem;
        }

        return abs;

    } //createInstance

    inline public function call(methodName:String, args:Array<Dynamic>, unwrap:Bool = true):Dynamic {

        return callStatic(abstractItem, env, this, methodName, args, unwrap);

    } //call

    inline public function get(varName:String, unwrap:Bool = true):Dynamic {

        return getStatic(abstractItem, env, this, varName, unwrap);

    } //get

    inline public function set(varName:String, value:Dynamic, unwrap:Bool = true):Dynamic {

        return setStatic(abstractItem, env, this, varName, value, unwrap);

    } //get

    function toString() {

        // Use original abstract's toString() if any
        switch (abstractItem) {
            case AbstractItem(rawItem, moduleId, name, runtimeType):
                var module = @:privateAccess env.modulesById.get(moduleId);
                var absToString:RuntimeItem = module.items.get(name + '.toString');
                if (absToString != null) {
                    switch (absToString) {
                        case AbstractFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                            var _args:Array<Dynamic> = [this, value];
                            return Reflect.callMethod(null, rawItem, _args);
                        default:
                    }
                }
            default:
        }

        return '' + value;

    } //toString

/// Static helpers

    public static function getStatic(abstractItem:RuntimeItem, env:Env, dynAbstract:DynamicAbstract, varName:String, unwrap:Bool = true):Dynamic {

        var result:Dynamic = null;

        switch (abstractItem) {
            case AbstractItem(rawItem, moduleId, name, runtimeType):
                var module = @:privateAccess env.modulesById.get(moduleId);
                var absVar:RuntimeItem = module.items.get(name + '.' + varName + '#get');
                if (absVar != null) {
                    switch (absVar) {
                        case AbstractFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                            var _args:Array<Dynamic> = isStatic ? [] : [dynAbstract, dynAbstract.value];
                            result = Reflect.callMethod(null, rawItem, _args);
                            if (!unwrap) {
                                result = TypeUtils.wrapIfNeeded(result, type, env);
                            }
                        default:
                    }
                }
                else {
                    var absFunc:RuntimeItem = module.items.get(name + '.' + varName);
                    if (absFunc != null) {
                        return absFunc;
                    }
                }
            default:
        }

        return result;

    } //getStatic

    public static function setStatic(abstractItem:RuntimeItem, env:Env, dynAbstract:DynamicAbstract, varName:String, value:Dynamic, unwrap:Bool = true):Dynamic {

        var result:Dynamic = null;

        switch (abstractItem) {
            case AbstractItem(rawItem, moduleId, name, runtimeType):
                var module = @:privateAccess env.modulesById.get(moduleId);
                var absVar:RuntimeItem = module.items.get(name + '.' + varName + '#set');
                if (absVar != null) {
                    switch (absVar) {
                        case AbstractFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                            var _args:Array<Dynamic> = isStatic ? [] : [dynAbstract, dynAbstract.value];
                            _args.push(TypeUtils.unwrap(value, env));
                            result = Reflect.callMethod(null, rawItem, _args);
                            if (!unwrap) {
                                result = TypeUtils.wrapIfNeeded(result, type, env);
                            }
                        default:
                    }
                }
            default:
        }

        return result;

    } //setStatic

    public static function callStatic(abstractItem:RuntimeItem, env:Env, dynAbstract:DynamicAbstract, methodName:String, args:Array<Dynamic>, unwrap:Bool = true):Dynamic {

        var result:Dynamic = null;

        switch (abstractItem) {
            case AbstractItem(rawItem, moduleId, name, runtimeType):
                var module = @:privateAccess env.modulesById.get(moduleId);
                var absMethod:RuntimeItem = module.items.get(name + '.' + methodName);
                if (absMethod != null) {
                    switch (absMethod) {
                        case AbstractFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                            var _args:Array<Dynamic> = isStatic ? [] : [dynAbstract, dynAbstract.value];
                            for (i in 0...args.length) {
                                _args.push(TypeUtils.unwrap(args[i], env));
                            }
                            result = Reflect.callMethod(null, rawItem, _args);
                            if (!unwrap) {
                                result = TypeUtils.wrapIfNeeded(result, type, env);
                            }
                        default:
                    }
                }
            default:
        }

        return result;

    } //call

} //DynamicAbstract
