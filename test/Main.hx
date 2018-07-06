package test;

import sys.io.File;
import hxs.HaxeToHscript;

class Main {

    public static function main() {

#if js
        try {
            untyped require('source-map-support').install();
        } catch (e:Dynamic) {}
#end

/*
        trace('PARSE');

        var nativeObj = new SomeClass('Jérémy');
        nativeObj.hello();

        var content = File.getContent('scripting/SomeClassCleaned.hx');
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

        _new('Jon Doe');

        hello();

        interp.variables.set('name', 'Pierrot');

        hello();

        return;
        //*/

        var content = File.getContent('scripting/SomeClass.hx');
        var converter = new HaxeToHscript(content);
        converter.convert();

        trace(@:privateAccess converter.cleanedHaxe);
        for (item in converter.imports) {
            Sys.println('TImport '+item);
        }
        for (item in converter.usings) {
            Sys.println('TUsing '+item);
        }
        for (item in converter.fields) {
            Sys.println('TField '+item);
        }
        for (item in converter.comments) {
            Sys.println('TComment '+item);
        }
        for (item in converter.modifiers) {
            Sys.println('TModifier '+item);
        }

    } //main

} //Main
