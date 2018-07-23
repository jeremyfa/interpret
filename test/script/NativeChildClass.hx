package test.script;

import test.native.NativeClass;

class NativeChildClass extends NativeClass {

    public function new() {

        // Calling super class
        super('Native Child');

    } //new

    public function isNativeClass() {

        return Std.is(this, test.native.NativeClass);

    } //isNativeClass

} //NativeChildClass
