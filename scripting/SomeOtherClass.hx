package test;

/** Some scriptable class */
class SomeOtherClass implements hxs.Scriptable {

    public function reload():Void {
        
        trace('RELOAD');

    }

    public function new() {

        trace('new OtherClass()');

    } //new

    public function hello() {

        trace('hello from SOME OTHER CLASS');

    } //hello

} //SomeOtherClass
