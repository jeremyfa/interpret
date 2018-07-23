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

            it("should run BasicClass.staticHello(subject)", {
                run('basic_class test_01').should.be('Static Hello Test 01');
            });

            it("should run new BasicClass().hello(subject)", {
                run('basic_class test_02').should.be('Hello Test 02');
            });

            it("should run new BasicClass().hi(subject)", {
                run('basic_class test_03').should.be('Hi Test 03!');
            });

            it("should run new ChildClass().hi(subject)", {
                run('basic_class child_class test_04').should.be('Hi Test 04!');
            });

            it("should run new GrandChildClass().hi(subject)", {
                run('basic_class child_class grand_child_class test_05').should.be('Hi Test 05!');
            });

            it("should run new GrandChildClass().bonjour(firstName)", {
                run('basic_class child_class grand_child_class test_06').should.be('Bonjour Jon Snow.');
            });

            it("should run new ChildClass().bonjour(firstName, lastName)", {
                run('basic_class child_class test_07').should.be('Bonjour Jon Doe.');
            });

            it("should run new NativeChildClass()", {
                run('native_child_class test_08').should.be('Native Child');
            });

            it("should run ExtendedClass.urlEncodeTest(input)", {
                run('extending_class extended_class test_09').should.be('Encoded: J%C3%A9r%C3%A9my');
            });

            it("should run ExtendedClass.gruntTest(input)", {
                run('extending_class extended_class test_10').should.be('JÉRÉMY!!!');
            });

            it("should run new ImplementingClass().isNativeInterface()", {
                run('implementing_class test_11').should.be('true');
            });

            it("should run new BasicClass().isBasicClass()", {
                run('basic_class test_12').should.be('true');
            });

            it("should run new BasicClass().isBasicClass2()", {
                run('basic_class test_13').should.be('true');
            });

            // TODO interfaces, Std.is()
            // TODO getter/setter
            // TODO module with multiple types (native)
            // TODO module with multiple types (interpreted)
            // TODO test.script.SomeClass.SomeSubClass

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