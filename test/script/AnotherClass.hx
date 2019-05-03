package test.script;

import test.script.InterpretedGroup;
import test.native.NativeClass as TrulyNativeClass;
import test.script.OtherClass as TrulyOtherClass;

class AnotherClass {

    public function new() {

    } //new

    public static function interpretedGroupClass1IsClass1() {

        return new Class1().isClass1();

    } //interpretedGroupClass1IsClass1

    public function someInstanceMethod(lastname:String) {

        return 'instance1 $lastname';

    } //someInstanceMethod

    public function someInstanceMethod2() {

        return Std.is(this, AnotherClass) ? 'true' : 'false';

    } //someInstanceMethod2

    public static function interpretedGroupClass2IsClass1() {

        return new Class2().isClass1();

    } //interpretedGroupClass2IsClass1

    public static function interpretedGroupClass1StaticMethod1() {

        return Class1.staticMethod1();

    } //interpretedGroupClass1StaticMethod1

    public static function interpretedGroupClass2StaticMethod2() {

        return Class2.staticMethod2();

    } //interpretedGroupClass1StaticMethod2

    public static function interpretedGroupClass2StaticMethod3() {

        return test.script.InterpretedGroup.Class2.staticMethod3();

    } //interpretedGroupClass2StaticMethod3

    public static function interpretedGroupClass2InstanceMethod1() {

        var instance = new test.script.InterpretedGroup.Class2();
        return instance.isClass2();

    } //interpretedGroupClass2InstanceMethod1

    public function interpretedGroupFromInstanceClass1StaticMethod1() {

        return AnotherClass.interpretedGroupClass1StaticMethod1();

    } //interpretedGroupFromInstanceClass1StaticMethod1

    public function interpretedGroupFromInstanceClass1StaticMethod2() {

        return interpretedGroupClass1StaticMethod1();

    } //interpretedGroupFromInstanceClass1StaticMethod2

    public static function interpretedGroupFromStaticClass1StaticMethod1() {

        return AnotherClass.interpretedGroupClass1StaticMethod1();

    } //interpretedGroupFromStaticClass1StaticMethod1

    public static function interpretedGroupFromStaticClass1StaticMethod2() {

        return interpretedGroupClass1StaticMethod1();

    } //interpretedGroupFromStaticClass1StaticMethod2

    public function interpretedGroupFromInstanceCallInstanceMethod1() {

        return someInstanceMethod('Doe');

    } //interpretedGroupFromInstanceCallInstanceMethod1

    public function interpretedGroupFromInstanceCallInstanceMethod2() {

        return this.someInstanceMethod2();

    } //interpretedGroupFromInstanceCallInstanceMethod2

    public static function newNativeClass(anOrigin:String) {

        var instance = @:privateAccess new test.native.NativeClass(anOrigin);
        var res = instance.getDoubleOrigin();
        return res;

    } //newNativeClass

    public static function newNativeClass2(anOrigin:String) {

        var instance = @:privateAccess new TrulyNativeClass(anOrigin);
        var res = instance.getDoubleOrigin2();
        return res;

    } //newNativeClass2

    public static function newDynamicClass(anOrigin:String) {

        var instance = new test.script.OtherClass(anOrigin);
        var res = instance.name + '/' + instance.age;
        return res;

    } //newNativeClass

    public static function newDynamicClass2(anOrigin:String) {

        var instance = new TrulyOtherClass(anOrigin);
        var res = instance.getDoubleName();
        return res;

    } //newNativeClass2

} //AnotherClass
