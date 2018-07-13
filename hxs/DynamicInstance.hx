package hxs;

import hxs.Interp;

@:allow(hxs.DynamicClass)
class DynamicInstance {

/// Properties

    var interp:Interp;

    var dynamicClass:DynamicClass;

/// Lifecycle

    private function new(dynamicClass:DynamicClass) {

        this.dynamicClass = dynamicClass;

    } //new

    private function init(?args:Array<Dynamic>) {

        // Create class interpreter and feed it with our program
        interp = new Interp(dynamicClass);

        // Add class interpreter to this instance interpreter (for static stuff)
        interp.classInterp = dynamicClass.interp;

        // Feed the interpreter with our program
        interp.execute(dynamicClass.instanceProgram);

        // Set all properties to null
        // Will ensure their key exists in variables map
        for (prop in dynamicClass.instanceProperties) {
            interp.variables.set(prop, null);
        }

        // Assign getters
        interp.getters = dynamicClass.instanceGetters;

        // Generate instance variables
        var __defaults = interp.variables.get('__defaults');
        __defaults();

        // Assign setters
        interp.setters = dynamicClass.instanceSetters;

        // Call new()
        var _new = interp.variables.get('new');
        if (_new != null) {
            Reflect.callMethod(interp.variables, _new, args != null ? cast args : []);
        }

    } //init

/// Public API

    public function get(name:String):Dynamic {

        return DynamicClass.unwrap(interp.resolve(name));

    } //get

    public function call(name:String, args:Array<Dynamic>):Dynamic {

        var method = interp.resolve(name);
        if (method == null) {
            throw 'Method not found: $name';
        }
        return DynamicClass.unwrap(Reflect.callMethod(null, method, args));

    } //call

} //DynamicInstance
