package test;

import js.node.Path;
import js.node.ChildProcess.spawnSync;

using buddy.Should;
using StringTools;

class Test extends buddy.SingleSuite {

    public function new() {

#if js
        try {
            untyped require('source-map-support').install();
        } catch (e:Dynamic) {}
#end

        describe("Interpret", {

            it("BasicClass.staticHello('Test 01') -> 'Static Hello Test 01'", {
                run('basic_class test_01').should.be('Static Hello Test 01');
            });

            it("new BasicClass().hello('Test 02') -> 'Hello Test 02'", {
                run('basic_class test_02').should.be('Hello Test 02');
            });

            it("new BasicClass().hi('Test 03') -> 'Hi Test 03!'", {
                run('basic_class test_03').should.be('Hi Test 03!');
            });

            it("new ChildClass().hi('Test 04') -> 'Hi Test 04!'", {
                run('basic_class child_class test_04').should.be('Hi Test 04!');
            });

            it("new GrandChildClass().hi('Test 05') -> 'Hi Test 05!'", {
                run('basic_class child_class grand_child_class test_05').should.be('Hi Test 05!');
            });

            it("new GrandChildClass().bonjour('Jon') -> 'Bonjour Jon Snow.'", {
                run('basic_class child_class grand_child_class test_06').should.be('Bonjour Jon Snow.');
            });

            it("new ChildClass().bonjour('Jon', 'Doe') -> 'Bonjour Jon Doe.'", {
                run('basic_class child_class test_07').should.be('Bonjour Jon Doe.');
            });

            it("new NativeChildClass().origin -> 'Native Child'", {
                run('native_child_class test_08').should.be('Native Child');
            });

            it("ExtendedClass.urlEncodeTest('Jérémy') -> 'Encoded: J%C3%A9r%C3%A9my'", {
                run('extending_class extended_class test_09').should.be('Encoded: J%C3%A9r%C3%A9my');
            });

            it("ExtendedClass.gruntTest('Jérémy') -> 'JÉRÉMY!!!'", {
                run('extending_class extended_class test_10').should.be('JÉRÉMY!!!');
            });

            it("new ImplementingClass().isNativeInterface() -> true", {
                run('implementing_class test_11').should.be('true');
            });

            it("new BasicClass().isBasicClass() -> true", {
                run('basic_class test_12').should.be('true');
            });

            it("new BasicClass().isBasicClass2() -> true", {
                run('basic_class test_13').should.be('true');
            });

            it("new ChildClass().isNativeClass() -> false", {
                run('native_class basic_class child_class test_14').should.be('false');
            });

            it("new NativeChildClass().isNativeClass() -> true", {
                run('native_class basic_class native_child_class test_15').should.be('true');
            });

            it("new BasicClass().sVar1 -> null", {
                run('basic_class test_16').should.be('false');
            });

            it("BasicClass.sVar1 -> 451", {
                run('basic_class test_17').should.be('451');
            });

            it("BasicClass.sVar2 -> 1451", {
                run('basic_class test_18').should.be('1451');
            });

            it("BasicClass.sVar2 = 3000; .sVar1 -> 2000", {
                run('basic_class test_19').should.be('2000');
            });

            it("BasicClass.sVar3 = 3000; .sVar1 -> 1999", {
                run('basic_class test_20').should.be('1999');
            });

            it("BasicClass.sVar3 = 3000; .sVar2 -> 2999", {
                run('basic_class test_21').should.be('2999');
            });

            it("BasicClass.sVar2 = 3000; .sVar3 -> 3001", {
                run('basic_class test_22').should.be('3001');
            });

            it("BasicClass.sVar2 = 3000; .sVar2 -> 3000", {
                run('basic_class test_23').should.be('3000');
            });

            it("BasicClass.sVar3 = 3000; .sVar3 -> 3000", {
                run('basic_class test_24').should.be('3000');
            });

            it("BasicClass.mVar1 -> null", {
                run('basic_class test_25').should.be('false');
            });

            it("new BasicClass().mVar1 -> 451.5", {
                run('basic_class test_26').should.be('451.5');
            });

            it("new BasicClass().mVar2 -> 1451", {
                run('basic_class test_27').should.be('10452.25');
            });

            it("new BasicClass().mVar2 = 3000; .mVar1 -> -7000.75", {
                run('basic_class test_28').should.be('-7000.75');
            });

            it("new BasicClass().mVar3 = 3000; .mVar1 -> -7001", {
                run('basic_class test_29').should.be('-7001');
            });

            it("new BasicClass().mVar3 = 3000; .mVar2 -> 2999.75", {
                run('basic_class test_30').should.be('2999.75');
            });

            it("new BasicClass().mVar2 = 3000; .mVar3 -> 3000.25", {
                run('basic_class test_31').should.be('3000.25');
            });

            it("new BasicClass().mVar2 = 3000; .mVar2 -> 3000", {
                run('basic_class test_32').should.be('3000');
            });

            it("new BasicClass().mVar3 = 3000; .mVar3 -> 3000", {
                run('basic_class test_33').should.be('3000');
            });

            it("new BasicClass().mVar4 = 3000; .mVar4 -> 3000", {
                run('basic_class test_34').should.be('3000');
            });

            it("new BasicClass().mVar5 = 3000; BasicClass.sVar1 -> -2000", {
                run('basic_class test_35').should.be('-2000');
            });

            it("new BasicClass().mVar6 = 3000; .mVar6 -> 3000", {
                run('basic_class test_36').should.be('3000');
            });

            // TODO module with multiple types (native)
            // TODO module with multiple types (interpreted)
            // TODO test.script.SomeClass.SomeSubClass
            // TODO call static method from instance method
            // TODO call static method from static method
            // TODO call instance method from instance method
            // TODO instanciate native class in code
            // TODO instanciate dynamic class in code

            /*it("should handle preprocessor defines in script", {
                // TODO
            });*/

        });
        
    } //new

    /** Every `run` is rebuilding and running a new host based on the given preset
        (a preset become a preprocessor define when compiling haxe) */
    function run(preset:String):String {

        var buildArgs:Array<String> = [
            '-main', 'test.Host',
            '-cp', '.',
            '-lib', 'hxnodejs',
            '-lib', 'hscript',
            '-js', 'host.js',
            '-debug',
            '-D', 'interpretable',
            '-dce', 'no'
        ];

        for (item in preset.split(' ')) {
            buildArgs.push('-D');
            buildArgs.push('host_' + item);
        }

        // Compile
        var proc = spawnSync('haxe', buildArgs, {
            cwd: js.Node.__dirname,
            stdio: 'inherit'
        });

        // Run
        proc = spawnSync('node', [
            'host.js'
        ], {
            cwd: js.Node.__dirname
        });

        var out = '' + proc.stdout;
        var err = '' + proc.stderr;

        if (out.trim() != '') {
            return out.trim();
        }
        else if (err.trim() != '') {
            return err.trim();
        }
        else return '';

    } //run

}