package test;

import sys.io.File;

class Main {

    public static function main() {

        trace('PARSE');

        var nativeObj = new SomeClass('Jérémy');
        nativeObj.hello();

        var content = File.getContent('scripting/SomeClass.hx');
        var parser = new hscript.Parser();
        parser.allowJSON = true;
        parser.allowMetadata = true;
        parser.allowTypes = true;
        var program = parser.parseString(content);
        var interp = new hxs.Interp();

        trace('EXEC');
        interp.execute(program);

        var _new = interp.variables.get('new');
        var hello = interp.variables.get('hello');

        _new('Jean-Paul');

        hello();

        interp.variables.set('name', 'Pierrot');

        hello();

    } //main

} //Main
