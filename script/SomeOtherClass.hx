package script;

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

} //SomeOtherClass
