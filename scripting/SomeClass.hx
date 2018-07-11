package test;

import hxs.ImportTest.*;

import StringTools.urlEncode;
using StringTools;

/** Some scriptable class */
class SomeClass implements hxs.Scriptable {

    public function new() {

        //hello();

        trace(urlEncode);
        trace(urlEncode('Jérémy'));
        trace('Jérémy'.urlEncode());

    } //new

} //SomeClass
