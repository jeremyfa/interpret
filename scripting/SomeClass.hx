package test;

import hxs.ImportTest;
import hxs.Types;
//import hxs.*;

using StringTools;

/** Some scriptable class */
class SomeClass implements hxs.Scriptable {

    var myName = 'Jean Dupont';

    public function new() {

        trace('Jérémy'.urlEncode());

        //var truc = CLASS;
        //var bidule = YOUPI('plop');
        var chouette = YOUPI('plop');
        trace(chouette);

        trace(ImportTest);
        ImportTest.hello();

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
