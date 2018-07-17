package test;

import interpret.ImportTest;
import interpret.Types;
import interpret.Interpretable;
//import interpret.*;

using StringTools;

/** Some interpretable class */
class SomeClass implements Interpretable extends interpret.ParentClass {

    var myName = 'Jean Dupont';

    public function reload():Void {
        trace('RELOAD');
    }

    public function new() {

        trace('Jérémy'.urlEncode());

        var chouette = YOUPI('plop');
        trace(chouette);

        trace(interpret.Interpretable);
        trace(interpret.TypeUtils.typeOf(interpret.ParentClass));
        trace('IS TTypeKind: ' + Std.is(chouette, TTypeKind));
        trace('IS Interpretable: ' + Std.is(this, interpret.Interpretable));
        trace('IS ParentClass: ' + Std.is(this, interpret.ParentClass));

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
