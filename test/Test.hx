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
        /*
        describe("Static method calls", {

            it("BasicClass.staticHello('Test 01') -> 'Static Hello Test 01'", {
                run('basic_class test_01').should.be('Static Hello Test 01');
            });

        });

        describe("Instance method calls", {

            it("new BasicClass().hello('Test 02') -> 'Hello Test 02'", {
                run('basic_class test_02').should.be('Hello Test 02');
            });

            it("new BasicClass().hi('Test 03') -> 'Hi Test 03!'", {
                run('basic_class test_03').should.be('Hi Test 03!');
            });

        });

        describe("Field access in subclasses", {

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

        });

        describe("Static extensions", {

            it("ExtendedClass.urlEncodeTest('Jérémy') -> 'Encoded: J%C3%A9r%C3%A9my'", {
                run('extending_class extended_class test_09').should.be('Encoded: J%C3%A9r%C3%A9my');
            });

            it("ExtendedClass.gruntTest('Jérémy') -> 'JÉRÉMY!!!'", {
                run('extending_class extended_class test_10').should.be('JÉRÉMY!!!');
            });

        });

        describe("Interfaces", {

            it("new ImplementingClass().isNativeInterface() -> true", {
                run('implementing_class test_11').should.be('true');
            });

        });

        describe("Inheritance", {

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

        });

        describe("Properties, getters and setters", {

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
        
        });

        describe('Constructor and arguments', {

            it("new OtherClass().name -> 'Paul'", {
                run('other_class test_47').should.be('Paul');
            });

            it("new OtherClass().age -> -1", {
                run('other_class test_48').should.be('-1');
            });

            it("new OtherClass('Jon', 21).name -> 'Jon'", {
                run('other_class test_49').should.be('Jon');
            });

            it("new OtherClass('Jon', 21).age -> 21", {
                run('other_class test_50').should.be('21');
            });

        });

        describe("Native module with multiple types", {

            it("new test.native.NativeGroup.Class1().isClass1() -> true", {
                run('native_group basic_class test_37').should.be('true');
            });

            it("new test.native.NativeGroup.Class1().isClass2() -> false", {
                run('native_group basic_class test_38').should.be('false');
            });

            it("new Class2().isClass1() -> false", {
                run('native_group basic_class test_39').should.be('false');
            });

            it("new Class2().isClass2() -> true", {
                run('native_group basic_class test_40').should.be('true');
            });

            it("new Class1().isClass1() -> true", {
                run('native_group other_class test_41').should.be('true');
            });

            it("new Class2().isClass1() -> false", {
                run('native_group other_class test_42').should.be('false');
            });

            it("test.native.NativeGroup.Class1.staticMethod1() -> 'static1'", {
                run('native_group basic_class test_43').should.be('static1');
            });

            it("Class2.staticMethod2() -> 'static2'", {
                run('native_group basic_class test_44').should.be('static2');
            });

            it("Class1.staticMethod1() -> 'static1'", {
                run('native_group other_class test_45').should.be('static1');
            });

            it("Class2.staticMethod2() -> 'static2'", {
                run('native_group other_class test_46').should.be('static2');
            });

        });

        describe("Interpreted module with multiple types", {

            it("new test.script.InterpretedGroup.Class1().isClass1() -> true", {
                run('interpreted_group alt_class test_51').should.be('true');
            });

            it("new test.script.InterpretedGroup.Class1().isClass2() -> false", {
                run('interpreted_group alt_class test_52').should.be('false');
            });

            it("new Class2().isClass1() -> false", {
                run('interpreted_group alt_class test_53').should.be('false');
            });

            it("new Class2().isClass2() -> true", {
                run('interpreted_group alt_class test_54').should.be('true');
            });

            it("new Class1().isClass1() -> true", {
                run('interpreted_group another_class test_55').should.be('true');
            });

            it("new Class2().isClass1() -> false", {
                run('interpreted_group another_class test_56').should.be('false');
            });

            it("test.script.InterpretedGroup.Class1.staticMethod1() -> 'static1'", {
                run('interpreted_group alt_class test_57').should.be('static1');
            });

            it("Class2.staticMethod2() -> 'static2'", {
                run('interpreted_group alt_class test_58').should.be('static2');
            });

            it("Class1.staticMethod1() -> 'static1'", {
                run('interpreted_group another_class test_59').should.be('static1');
            });

            it("Class2.staticMethod2() -> 'static2'", {
                run('interpreted_group another_class test_60').should.be('static2');
            });

        });

        describe("Various calls", {

            it("test.script.InterpretedGroup.Class2.staticMethod3() -> 'static3'", {
                run('interpreted_group another_class test_61').should.be('static3');
            });

            it("test.script.InterpretedGroup.Class2.instanceMethod1() -> true", {
                run('interpreted_group another_class test_62').should.be('true');
            });

            it("new AnotherClass().interpretedGroupFromInstanceClass1StaticMethod1() -> 'static1'", {
                run('interpreted_group another_class test_63').should.be('static1');
            });

            it("new AnotherClass().interpretedGroupFromInstanceClass1StaticMethod2() -> 'static1'", {
                run('interpreted_group another_class test_64').should.be('static1');
            });

            it("AnotherClass.interpretedGroupFromStaticClass1StaticMethod1() -> 'static1'", {
                run('interpreted_group another_class test_65').should.be('static1');
            });

            it("AnotherClass.interpretedGroupFromStaticClass1StaticMethod2() -> 'static1'", {
                run('interpreted_group another_class test_66').should.be('static1');
            });

            it("new AnotherClass().interpretedGroupFromInstanceCallInstanceMethod1() -> 'instance1 Doe'", {
                run('interpreted_group another_class test_67').should.be('instance1 Doe');
            });

            it("new AnotherClass().interpretedGroupFromInstanceCallInstanceMethod2() -> 'true'", {
                run('interpreted_group another_class test_68').should.be('true');
            });

        });

        describe("Instanciate", {

            it("AnotherClass.newNativeClass('another') -> 'another another'", {
                run('interpreted_group another_class test_69').should.be('another another');
            });

            it("AnotherClass.newNativeClass2('another2') -> 'another2 another2'", {
                run('interpreted_group another_class test_70').should.be('another2 another2');
            });

            it("AnotherClass.newDynamicClass('another3') -> 'another3/-1'", {
                run('interpreted_group another_class other_class test_71').should.be('another3/-1');
            });

            it("AnotherClass.newDynamicClass2('another4') -> 'another4 another4'", {
                run('interpreted_group another_class other_class test_72').should.be('another4 another4');
            });

        });
        */

        describe("Interpretable macro", {

            it("new SomeClass() -> 'some prop'", {
                run('interpretable_some_class test_73').should.be('some prop');
            });

        });

            // OK constructor with arguments
            // OK module with multiple types (native)
            // OK module with multiple types (interpreted)

            // OK? module with multiple types and module type included (native & interpreted)

            // OK test.script.SomeClass.SomeSubClass
            // OK call static method from instance method
            // OK call static method from static method
            // OK call instance method from instance method
            // OK instanciate native class in code (with args)
            // OK instanciate dynamic class in code (with args)

            // TODO? get property from extension getter
            // TODO? assign property from extension setter

            // TODO should handle preprocessor defines in script
        
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