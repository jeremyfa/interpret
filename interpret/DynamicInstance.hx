package interpret;

import interpret.Interpreter;

@:allow(interpret.DynamicClass)
@:allow(interpret.TypeUtils)
class DynamicInstance {

/// Properties

    var interpreter:Interpreter;

    var dynamicClass:DynamicClass;

/// Lifecycle

    private function new(dynamicClass:DynamicClass) {

        this.dynamicClass = dynamicClass;

    } //new

    private function init(?args:Array<Dynamic>) {

        // Create class interpreter and feed it with our program
        interpreter = new Interpreter(dynamicClass);

        // Add class interpreter to this instance interpreter (for static stuff)
        interpreter.classInterpreter = dynamicClass.interpreter;

        // Feed the interpreter with our program
        interpreter.execute(dynamicClass.instanceProgram);

        // Set all properties to null
        // Will ensure their key exists in variables map
        for (prop in dynamicClass.instanceProperties) {
            interpreter.variables.set(prop, null);
        }

        // Assign getters
        interpreter.getters = dynamicClass.instanceGetters;

        // Generate instance variables
        var __defaults = interpreter.variables.get('__defaults');
        __defaults();

        // Assign setters
        interpreter.setters = dynamicClass.instanceSetters;

        // Call new()
        var _new = interpreter.variables.get('new');
        if (_new != null) {
            Reflect.callMethod(interpreter.variables, _new, args != null ? cast args : []);
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
        return TypeUtils.unwrap(Reflect.callMethod(null, method, args));

    } //call

} //DynamicInstance
