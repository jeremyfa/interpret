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
