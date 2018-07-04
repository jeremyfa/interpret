package test;

class SomeClass implements hxs.Scriptable {

    public var name:String = null;

    public function new(name:String) {

        var func = () -> {
            this.name = name;
        }

        func();

    } //name

    public function hello():Void {

        trace('PLOP $name!');

    } //hello

} //SomeClass
