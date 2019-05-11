package test.script;

class WrapTests {

    public static function test1() {

        var dynObj:Dynamic = {};
        dynObj.name = 'test1';

        return dynObj.name;

    } //test1

    public static function test2() {

        var quad = new test.native.Quad();

        var color = quad.color;
        color.red = 128;
        quad.color = color;

        return quad.colorInfo();

    } //test2

} //WrapTests
