package script;

import script.SomeClass;

/** Some scriptable class */
class SomeOtherClass implements interpret.Interpretable {

    var machin:String = 'bidule';

    public function reload():Void {

        trace('RELOAD');

    }

    public function new() {

        trace('new OtherClass() !!! ' + this);

    } //new

    public function hellooo(plop:String = 'Jean-Paul') {

        trace('hellooo from SOME OTHER CLASS: $plop');

    } //hello

    public static function staticStuff() {

        trace('SomeOtherClass.staticStuff() YES');

    } //staticStuff

    public static function staticExt(subject:SomeClass, message:String) {

        trace('SomeOtherClass.staticExt() $message');

    } //staticStuff

} //SomeOtherClass
