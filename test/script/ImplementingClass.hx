package test.script;

import test.native.NativeInterface;

class ImplementingClass implements NativeInterface {

    public function new() {}

    public function interfaceMethodInt():Int {

        return Std.int(Math.random() * 1000);

    } //interfaceMethodInt

    public function isNativeInterface() {

        return Std.isOfType(this, NativeInterface);

    } //isNativeInterface

} //ImplementingClass
