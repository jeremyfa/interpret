package test;

import hxs.ImportTest;
import hxs.Types;
//import hxs.*;

using StringTools;

/** Some scriptable class */
class SomeClass implements hxs.Scriptable extends hxs.ParentClass {

    var myName = 'Jean Dupont';

    public function reload():Void {
        trace('RELOAD');
    }

    public function new() {

        trace('Jérémy'.urlEncode());

        //var truc = CLASS;
        //var bidule = YOUPI('plop');
        var chouette = YOUPI('plop');
        trace(chouette);

        trace(hxs.Scriptable);
        trace(hxs.TypeUtils.typeOf(hxs.ParentClass));
        trace('IS TTypeKind: ' + Std.is(chouette, TTypeKind));
        trace('IS Scriptable: ' + Std.is(this, hxs.Scriptable));
        trace('IS ParentClass: ' + Std.is(this, hxs.ParentClass));

        someParentStuff();

        //trace(ImportTest);
        //ImportTest.hello();

    } //new

    public function hello(name:String) {
        trace('hello $name, not $myName');
    }

    public static function selfHello(value:String) {
        trace('hello $value');
    }

} //SomeClass

/*abstract AbstractFloat(Float) {
    
}

abstract AbstractInt((Int,Float)->Void) from Int to Int {
    
}

typedef MachinTruc = Bidule;
typedef MachinTruc<Truc> = Bidule<Chouette>;

typedef SomeTruc = {
    > Test;
    var machin:Bidule = '';
    @:optional var bidule:Machin;
}*/
