package test;

import hxs.ImportTest;

using StringTools;

/** Some scriptable class */
class SomeClass implements hxs.Scriptable {

    public function new() {

        trace('Jérémy'.urlEncode());

    } //new

    public static function hello(test:Class<ImportTest>) {
        trace('hello');
    }

    public static function selfHello(value:String) {
        trace('hello $value');
    }

} //SomeClass

abstract AbstractFloat(Float) {
    
}

abstract AbstractInt((Int,Float)->Void) from Int to Int {
    
}

typedef MachinTruc = Bidule;
typedef MachinTruc<Truc> = Bidule<Chouette>;

typedef SomeTruc = {
    > Test;
    var machin:Bidule = '';
    @:optional var bidule:Machin;
}
