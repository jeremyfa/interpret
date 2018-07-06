package test;

import haxe.io.Path;
import haxe.io.Error as HaxeError;

/** Some scriptable class */
class SomeClass implements hxs.Scriptable {

    public var name:String = null;

    public var lastName(default,set):String;

    function set_lastName(val:String):String {
        lastName = 'set:$val';
        return lastName;
    }

    function dummy1() return Math.random() < 0.5 ? true : false;

    function dummy2() {
        return Math.random() < 0.5 ? true : false;
    }

    public function new(name:String = 'Jon Doe') {

        var machin1 = 'truc';
        final machin2:Truc = 'machin';
        var machin3;
        var machin4:Bidule;
        var machin5:Void->Void = cast function() {};
        var machin6:() -> Void = cast (null);
        var machin6:() -> Void = cast null;
        var machin7:() -> Void = cast(null, Array<Dynamic>);
        var machin8:Void = new Map<String,Float->Void,(machin:Truc,bidule:Chouette)->Void>(1,2,3);

        var func = function(name:String = 'Simon') {
            this.name = name;
        }

        func(name);

    } //name

    public function hello():Void {

        trace('PLOP $name!');

    } //hello

} //SomeClass
