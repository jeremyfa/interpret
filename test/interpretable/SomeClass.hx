package test.interpretable;

import interpret.Interpretable;

class SomeClass implements Interpretable {

    public var someProp = 'some prop';

    public function new() {}

    @interpret public function script(a:String, b:Int, c:Bool) {

        trace('hello $someProp');

    } //script

} //SomeClass
