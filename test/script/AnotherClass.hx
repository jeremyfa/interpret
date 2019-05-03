package test.script;

import test.script.InterpretedGroup;

class AnotherClass {

    public function new() {

    } //new

    public static function interpretedGroupClass1IsClass1() {

        return new Class1().isClass1();

    } //interpretedGroupClass1IsClass1

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

} //AnotherClass
