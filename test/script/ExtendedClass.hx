package test.script;

using StringTools;
using test.script.ExtendingClass;

class ExtendedClass {

    public static function urlEncodeTest(input:String) {

        trace('Encoded: ' + input.urlEncode());

    } //urlEncodeTest

    public static function gruntTest(input:String) {

        input.grunt();

    } //gruntTest

} //ExtendedClass
