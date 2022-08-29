package test.script;

class ChildClass extends BasicClass {

    public function new() {

        // Calling super class
        super();

    } //new

    public function isNativeClass() {

        return Std.isOfType(this, test.native.NativeClass);

    } //isNativeClass

} //ChildClass
