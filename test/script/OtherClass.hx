package test.script;

import test.native.NativeGroup;

class OtherClass {

    public var name:String;

    public var age:Int = -1;

    public function new(name:String = 'Paul', ?age:Int) {

        this.name = name;
        if (age != null) this.age = age;

    } //new

    public function getDoubleName():String {

        return name + ' $name';

    } //getDoubleName

    public static function nativeGroupClass1IsClass1() {

        return new Class1().isClass1();

    } //nativeGroupClass1IsClass1

    public static function nativeGroupClass2IsClass1() {

        return new Class2().isClass1();

    } //nativeGroupClass2IsClass1

    public static function nativeGroupClass1StaticMethod1() {

        return Class1.staticMethod1();

    } //nativeGroupClass1StaticMethod1

    public static function nativeGroupClass2StaticMethod2() {

        return Class2.staticMethod2();

    } //nativeGroupClass1StaticMethod2

} //OtherClass
