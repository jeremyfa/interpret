package test.script;

import test.script.InterpretedGroup.Class2;

class AltClass {

    public function new() {

    } //new

    public static function interpretedGroupClass1IsClass1() {

        return new test.script.InterpretedGroup.Class1().isClass1();

    } //interpretedGroupClass1IsClass1

    public static function interpretedGroupClass1IsClass2() {

        return new test.script.InterpretedGroup.Class1().isClass2();

    } //interpretedGroupClass1IsClass2

    public static function interpretedGroupClass2IsClass1() {

        return new Class2().isClass1();

    } //interpretedGroupClass2IsClass1

    public static function interpretedGroupClass2IsClass2() {

        return new Class2().isClass2();

    } //interpretedGroupClass2IsClass2

    public static function interpretedGroupClass1StaticMethod1() {

        return test.script.InterpretedGroup.Class1.staticMethod1();

    } //interpretedGroupClass1StaticMethod1

    public static function interpretedGroupClass2StaticMethod2() {

        return Class2.staticMethod2();

    } //interpretedGroupClass2StaticMethod2

} //AltClass
