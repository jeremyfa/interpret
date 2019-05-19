package interpret;

import interpret.Types;
import interpret.Interpreter;

using StringTools;

@:allow(interpret.DynamicClass)
@:allow(interpret.TypeUtils)
@:allow(interpret.Interpreter)
class DynamicInstance {

    static var NO_ARGS:Array<Dynamic> = [];

/// Properties

    public var interpreter(default,null):Interpreter;

    public var dynamicClass(default,null):DynamicClass;

    public var context(default,null):Map<String,Dynamic> = null;

    var _contextArgs:Array<Dynamic> = null;

/// Lifecycle

    private function new(dynamicClass:DynamicClass) {

        this.dynamicClass = dynamicClass;

    } //new

    private function init(?args:Array<Dynamic>, ?superInstance:Dynamic) {

        // Create instance context
        context = new Map();
        context.set('__interpretType', dynamicClass.instanceType);
        context.set('__interpretInstance', this);
        context.set('__interpretClass', dynamicClass);
        if (superInstance != null) {
            context.set('super', superInstance);
        }
        _contextArgs = [dynamicClass.context, context];

        // Create class interpreter and feed it with our program
        interpreter = new Interpreter(dynamicClass);

        // Add class interpreter to this instance interpreter (for static stuff)
        interpreter.classInterpreter = dynamicClass.interpreter;

        // Feed the interpreter with our program
        interpreter.execute(dynamicClass.instanceProgram);

        // Set all properties to null
        // Will ensure their key exists in variables map
        for (prop in dynamicClass.instanceProperties) {
            context.set(prop, null);
        }

        // Assign getters
        interpreter.getters = dynamicClass.instanceGetters;

        // Generate instance variables
        var __defaults = interpreter.variables.get('__defaults');
        __defaults(dynamicClass.context, context);

        // Assign setters
        interpreter.setters = dynamicClass.instanceSetters;

        // Add super (if any)
        var env = dynamicClass.env;
        var superClassType = env.getSuperClass(dynamicClass.instanceType);
        if (superClassType != null) {
            var module:DynamicModule = null;
            var prefix = superClassType + '.';
            var alias = env.aliases.get(superClassType);
            var aliasPrefix = alias + '.';
            for (modulePath in env.modules.keys()) {
                if (modulePath == superClassType || modulePath.startsWith(prefix)) {
                    module = env.modules.get(modulePath);
                    break;
                }
                if (alias != null) {
                    if (modulePath == alias || modulePath.startsWith(aliasPrefix)) {
                        module = env.modules.get(modulePath);
                        break;
                    }
                }
            }
            if (module != null) {
                var targetItem:RuntimeItem = null;
                targetItem = module.items.get(superClassType);
                if (alias != null) {
                    targetItem = module.items.get(alias);
                }
                if (targetItem != null) {
                    interpreter.variables.set('super', SuperClassItem(targetItem));
                    switch (targetItem) {
                        case ClassItem(rawItem, moduleId, name):
                            //trace('ADD SUPER NEW');
                            var superClass = env.resolveDynamicClass(moduleId, name);
                            interpreter.variables.set('__super_new', Reflect.makeVarArgs(function(args) {
                                var superClassItem:RuntimeItem = interpreter.variables.get('super');
                                switch (superClassItem) {
                                    case SuperClassItem(ClassItem(rawItem, moduleId, name)):
                                        if (rawItem != null) {
                                            var superInstance = Type.createInstance(rawItem, args);
                                            context.set('super', superInstance);
                                            return superInstance;
                                        }
                                    default:
                                }
                                return interpreter.call(null, superClassItem, args);
                            }));
                        default:
                    }
                }
            }
        }

        // Call new()
        var _new = interpreter.variables.get('new');
        if (_new != null) {
            Reflect.callMethod(interpreter.variables, _new, args != null ? _contextArgs.concat(args) : _contextArgs);
        }

    } //init

/// Public API

    public function get(name:String, unwrap:Bool = true):Dynamic {

        //trace('DYN INST GET $name');

        var useSuperClass = null;

        if (!dynamicClass.instanceVars.exists(name) && !dynamicClass.instanceMethods.exists(name)) {
            //trace('NEED CHECK');
            if (dynamicClass.superDynamicClass != null || dynamicClass.superStaticClass == null) {
                //trace('has field / ' + dynamicClass.superDynamicClass + ' / ' + dynamicClass.superStaticClass);
                var superClass = dynamicClass.superDynamicClass;
                //trace('super $superClass');
                var exists = false;
                while (superClass != null) {
                    if (superClass.instanceVars.exists(name) || superClass.instanceMethods.exists(name)) {
                        exists = true;
                        useSuperClass = superClass;
                        break;
                    }
                    if (superClass.superDynamicClass == null && superClass.superStaticClass != null) {
                        exists = true; // We assume we are calling something on native that exists
                        break;
                    }
                    superClass = superClass.superDynamicClass;
                }
                if (!exists) {
                    return unwrap ? null : Unresolved.UNRESOLVED;
                }
            }
            else if (!dynamicClass.superStaticClassHasInstanceField(name)) {
                return unwrap ? null : Unresolved.UNRESOLVED;
            }
        }

        var prevSelf = interpreter._self;
        var prevClassSelf = interpreter._classSelf;
        interpreter._self = context;
        interpreter._classSelf = useSuperClass != null ? useSuperClass.context : dynamicClass.context;

        var rawRes = interpreter.get(context, name);
        var result = unwrap ? TypeUtils.unwrap(rawRes, dynamicClass.env) : rawRes;

        interpreter._self = prevSelf;
        interpreter._classSelf = prevClassSelf;

        return result;

    } //get

    public function isMethod(name:String):Bool {

        return dynamicClass.instanceMethods.exists(name);

    } //isMethod

    public function exists(name:String):Bool {

        if (!dynamicClass.instanceVars.exists(name) && !dynamicClass.instanceMethods.exists(name)) {
            if (dynamicClass.superDynamicClass != null || dynamicClass.superStaticClass == null) {
                var superClass = dynamicClass.superDynamicClass;
                var exists = false;
                while (superClass != null) {
                    if (superClass.instanceVars.exists(name) || superClass.instanceMethods.exists(name)) {
                        exists = true;
                        break;
                    }
                    if (superClass.superDynamicClass == null && superClass.superStaticClass != null) {
                        exists = true; // We assume we are calling something on native that exists
                        break;
                    }
                    superClass = superClass.superDynamicClass;
                }
                if (!exists) {
                    return false;
                }
            }
            else if (!dynamicClass.superStaticClassHasInstanceField(name)) {
                return false;
            }
        }

        var prevUnresolved = interpreter._unresolved;
        interpreter._unresolved = Unresolved.UNRESOLVED;

        var result = get(name);

        interpreter._unresolved = prevUnresolved;

        return result != Unresolved.UNRESOLVED;

    } //exists

    public function set(name:String, value:Dynamic, unwrap:Bool = true):Dynamic {

        var prevSelf = interpreter._self;
        var prevClassSelf = interpreter._classSelf;
        interpreter._self = context;
        interpreter._classSelf = dynamicClass.context;

        var rawRes = interpreter.set(context, name, value);
        var result = unwrap ? TypeUtils.unwrap(rawRes, dynamicClass.env) : rawRes;

        interpreter._self = prevSelf;
        interpreter._classSelf = prevClassSelf;

        return result;

    } //set

    public function call(name:String, ?args:Array<Dynamic>, unwrap:Bool = true, ?argTypes:Array<String>):Dynamic {

        var prevSelf = interpreter._self;
        var prevClassSelf = interpreter._classSelf;
        
        interpreter._self = context;
        interpreter._classSelf = dynamicClass.context;

        //trace('call $this / $name / $args');

        var method:Dynamic = interpreter.get(context, name);

        interpreter._self = prevSelf;
        interpreter._classSelf = prevClassSelf;

        if (method == null) {
            throw 'Instance method not found: $this $name';
        }

        if (args != null && args.length > 0 && argTypes != null) {
            var _args = [];
            for (i in 0...args.length) {
                _args.push(TypeUtils.wrapIfNeeded(args[i], argTypes[i], dynamicClass.env));
            }
            args = _args;
        }

        var rawRes:Dynamic = Reflect.callMethod(null, method, args != null ? args : NO_ARGS);
        return unwrap ? TypeUtils.unwrap(rawRes, dynamicClass.env) : rawRes;

    } //call

/// Print

    public function toString() {

        return 'DynamicInstance(${dynamicClass.instanceType})';

    } //toString

} //DynamicInstance
