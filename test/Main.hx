package test;

import interpret.ParentClass;
import interpret.Interpretable;
import interpret.Types.ModuleItemKind;
// TODO add DynamicEnum/Enum support

// TODO parse dynamic typedefs (alias only)
// TODO parse static typedefs (alias only)

// TODO handle inheritance to parent native class
// TODO handle inheritance to parent dynamic class

// TODO convert arrow functions () -> { }
// TODO convert combined switches switch [a, b] { case [_, 'something']: ... }

// TODO parse new & old function types and clean them

// TODO remove type params in cleanType() because they are useless at runtime

// TODO convert haxe code into DynamicModule instead of DynamicClass
// TODO use DynamicModule instances to get classes and enums, just like in regular Haxe
//      - add DynamicModule.fromString('... some haxe string ...')
//        -> move imports & usings at module level

import sys.io.File;
import interpret.DynamicClass;
import interpret.ConvertHaxe;
import interpret.Env;
import interpret.DynamicModule;

import haxe.io.Path;

import interpret.ExtensionTest;

import interpret.Types;

class TestNativeClass implements Interpretable extends ParentClass {

    public function reload() {}

    public function new() {

        super();

        //trace('Jérémy'.urlEncode());

        //var truc = CLASS;
        //var bidule = YOUPI('plop');
        var chouette = YOUPI('plop');
        trace(chouette);

        trace(interpret.Interpretable);
        trace(interpret.TypeUtils.typeOf(interpret.ParentClass));
        trace('IS TTypeKind: ' + Std.is(chouette, TTypeKind));
        trace('IS Interpretable: ' + Std.is(this, interpret.Interpretable));
        trace('IS ParentClass: ' + Std.is(this, interpret.ParentClass));

        someParentStuff();

    }

}

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
        var interpreter = new interpret.Interp();

        trace('EXEC');
        interpreter.execute(program);

        var _new = interpreter.variables.get('new');
        var hello = interpreter.variables.get('hello');

        _new('Jon Doe');

        hello();

        interpreter.variables.set('name', 'Pierrot');

        hello();

        return;
        //*/

        // Create env
        var env = new Env();
        env.addDefaultModules();
        //env.allowPackage('interpret');

        // Modules from static (native) code
        env.addModule('interpret.ImportTest', DynamicModule.fromStatic(interpret.ImportTest));
        env.addModule('interpret.Types', DynamicModule.fromStatic(interpret.Types));
        env.addModule('interpret.Interpretable', DynamicModule.fromStatic(interpret.Interpretable));
        env.addModule('interpret.TypeUtils', DynamicModule.fromStatic(interpret.TypeUtils));
        env.addModule('interpret.SomClassWithParent', DynamicModule.fromStatic(interpret.SomeClassWithParent));
        env.addModule('interpret.ParentClass', DynamicModule.fromStatic(interpret.ParentClass));
        env.addModule('StringTools', DynamicModule.fromStatic(StringTools));

        // Modules from interpreted code
        env.addModule('script.SomeClass', DynamicModule.fromString(env, 'SomeClass', File.getContent('script/SomeClass.hx')));
        env.addModule('script.SomeOtherClass', DynamicModule.fromString(env, 'SomeOtherClass', File.getContent('script/SomeOtherClass.hx')));

        env.link();

        trace(env.modules.get('script.SomeOtherClass').dynamicClasses);

        var dynClass = env.modules.get('script.SomeClass').dynamicClasses.get('SomeClass');

        //var that = new TestNativeClass();
         
        //var dynClass = dynModule.

        // Expose StringTools static extension
        //env.addExtension('StringTools', DynamicExtension.fromStatic(StringTools));

        // Create dynamic class from env and haxe content
        //var dynClass = new DynamicClass(env, content);

        // Print some static property from this class
        //trace(dynClass.get('someStaticProperty'));

        trace('ENV SUPERCLASSES ' + @:privateAccess env.superClasses);
        trace('ENV INTERFACES ' + @:privateAccess env.interfaces);

        // Create instance
        var dynInstance = dynClass.createInstance();

        // Call instance method
        //dynInstance.get('someInstanceMethod')('some', 'args');

        //interpret.ImportTest.SomeOtherType.hi();

        //dynInstance.call('hello', ['Jon Snow']);

        //env.extensions.set('Extensions', DynamicExtension.fromStatic(ceramic.Extensions));
/*
        var dynClass = new DynamicClass(env, content);

        trace(dynClass.instanceHscript);
        //trace(dynClass.classHscript);

        trace('lastName: ' + dynClass.get('lastName'));
        trace('_defaultName: ' + dynClass.get('defaultNamee'));*/

        /*for (i in 0...10) {
            trace('dummy2: ' + dynClass.get('dummy2')());
        }*/

        /*var dynObj = dynClass.createInstance();
        trace('obj.name = ' + dynObj.get('name'));
        trace('obj.lastName = ' + dynObj.get('lastName'));*/

    } //main

} //Main
