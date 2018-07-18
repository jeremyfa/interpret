package interpret;

import interpret.Types;
import interpret.Interpreter;

using StringTools;

@:allow(interpret.DynamicClass)
@:allow(interpret.TypeUtils)
@:allow(interpret.Interpreter)
class DynamicInstance {

/// Properties

    var interpreter:Interpreter;

    var dynamicClass:DynamicClass;

    var context:Map<String,Dynamic> = null;

    var _contextArgs:Array<Dynamic> = null;

/// Lifecycle

    private function new(dynamicClass:DynamicClass) {

        this.dynamicClass = dynamicClass;

    } //new

    private function init(?args:Array<Dynamic>) {

        // Create instance context
        context = new Map();
        context.set('__interpretType', dynamicClass.instanceType);
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

    public function get(name:String):Dynamic {

        return TypeUtils.unwrap(interpreter.resolve(name));

    } //get

    public function call(name:String, args:Array<Dynamic>):Dynamic {

        var method = interpreter.resolve(name);
        if (method == null) {
            throw 'Method not found: $name';
        }
        return TypeUtils.unwrap(Reflect.callMethod(null, method, args != null ? _contextArgs.concat(args) : _contextArgs));

    } //call

} //DynamicInstance
