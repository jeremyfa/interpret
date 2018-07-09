package test;

import hxs.ImportTest.*;

using StringTools;

/** Some scriptable class */
class SomeClass implements hxs.Scriptable {

    public function new() {

        hello();

        trace('Jérémy'.urlEncode());

    } //new

} //SomeClass
