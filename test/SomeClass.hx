package test;

class SomeClass implements hxs.Scriptable {

    public var name:String = null;

    public function new(name:String) {

        this.name = name;

    } //name

    public function hello():Void {

        trace('hello, ' + name);

    } //hello

} //SomeClass
