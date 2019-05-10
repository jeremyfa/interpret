package test.script;

import test.native.Color;

class AbstractTests {

    public static function test1() {

        var color = new Color(0xFF00FF);

        return '' + color;

    } //test1

    public static function test2() {

        var color = Color.RED;

        return '' + color;

    } //test2

    public static function test3() {

        var color = Color.PURPLE;

        return '' + color.blue;

    } //test3

    public static function test4() {

        var color = Color.PURPLE;

        color.redFloat = 0;
        color.blue = 255;

        return '' + color;

    } //test4

    public static function test5() {

        var prevNone = Color.NONE;

        Color.NONE = -2;

        return '' + prevNone + ' / ' + Color.NONE;

    } //test5

    public static function test6() {

        var color = Color.fromRGB(0, 255, 0);

        return '' + color;

    } //test6

    public static function test7() {

        var color = Color.fromRGB(0, 255, 0);

        var str = color.toWebString();

        return '' + color + ' / ' + str;

    } //test7

} //AbstractTests
