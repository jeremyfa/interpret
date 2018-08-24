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

} //AnotherClass
