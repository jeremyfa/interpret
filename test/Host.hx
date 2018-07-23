package test;

import interpret.Env;
import interpret.DynamicModule;

import sys.io.File;

class Host {

    public static function main():Void {

#if js
        try {
            untyped require('source-map-support').install();
        } catch (e:Dynamic) {}
#end

        // Create env
        var env = new Env();

        // Add default modules (Std)
        env.addDefaultModules();

        // Route script `trace` to Sys.println
        env.trace = function(input) Sys.println(''+input);

        // Modules from static (native) code
        env.addModule('StringTools', DynamicModule.fromStatic(StringTools));
        env.addModule('Math', DynamicModule.fromStatic(Math));
        env.addModule('test.native.NativeClass', DynamicModule.fromStatic(test.native.NativeClass));
        env.addModule('test.native.NativeInterface', DynamicModule.fromStatic(test.native.NativeInterface));
        #if (sys || nodejs)
        env.addModule('Sys', DynamicModule.fromStatic(Sys));
        #end

        // Modules from interpreted code
        #if host_basic_class
        env.addModule('test.script.BasicClass', DynamicModule.fromString(env, 'BasicClass', File.getContent('test/script/BasicClass.hx')));
        #end

        #if host_child_class
        env.addModule('test.script.ChildClass', DynamicModule.fromString(env, 'ChildClass', File.getContent('test/script/ChildClass.hx')));
        #end

        #if host_grand_child_class
        env.addModule('test.script.GrandChildClass', DynamicModule.fromString(env, 'GrandChildClass', File.getContent('test/script/GrandChildClass.hx')));
        #end

        #if host_native_child_class
        env.addModule('test.script.NativeChildClass', DynamicModule.fromString(env, 'NativeChildClass', File.getContent('test/script/NativeChildClass.hx')));
        #end

        #if host_extended_class
        env.addModule('test.script.ExtendedClass', DynamicModule.fromString(env, 'ExtendedClass', File.getContent('test/script/ExtendedClass.hx')));
        #end

        #if host_extending_class
        env.addModule('test.script.ExtendingClass', DynamicModule.fromString(env, 'ExtendingClass', File.getContent('test/script/ExtendingClass.hx')));
        #end

        #if host_implementing_class
        env.addModule('test.script.ImplementingClass', DynamicModule.fromString(env, 'ImplementingClass', File.getContent('test/script/ImplementingClass.hx')));
        #end

        env.link();

        #if host_test_01
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        dynClass.call('staticHello', ['Test 01']);
        #end

        #if host_test_02
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        dynInst.call('hello', ['Test 02']);
        #end

        #if host_test_03
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        dynInst.call('hi', ['Test 03']);
        #end

        #if host_test_04
        var dynClass = env.modules.get('test.script.ChildClass').dynamicClasses.get('ChildClass');
        var dynInst = dynClass.createInstance();
        dynInst.call('hi', ['Test 04']);
        #end

        #if host_test_05
        var dynClass = env.modules.get('test.script.GrandChildClass').dynamicClasses.get('GrandChildClass');
        var dynInst = dynClass.createInstance();
        dynInst.call('hi', ['Test 05']);
        #end

        #if host_test_06
        var dynClass = env.modules.get('test.script.GrandChildClass').dynamicClasses.get('GrandChildClass');
        var dynInst = dynClass.createInstance();
        dynInst.call('bonjour', ['Jon']);
        #end

        #if host_test_07
        var dynClass = env.modules.get('test.script.ChildClass').dynamicClasses.get('ChildClass');
        var dynInst = dynClass.createInstance();
        dynInst.call('bonjour', ['Jon', 'Doe']);
        #end

        #if host_test_08
        var dynClass = env.modules.get('test.script.NativeChildClass').dynamicClasses.get('NativeChildClass');
        var dynInst = dynClass.createInstance();
        Sys.println(dynInst.get('origin'));
        #end

        #if host_test_09
        var dynClass = env.modules.get('test.script.ExtendedClass').dynamicClasses.get('ExtendedClass');
        dynClass.call('urlEncodeTest', ['Jérémy']);
        #end

        #if host_test_10
        var dynClass = env.modules.get('test.script.ExtendedClass').dynamicClasses.get('ExtendedClass');
        dynClass.call('gruntTest', ['Jérémy']);
        #end

        #if host_test_11
        var dynClass = env.modules.get('test.script.ImplementingClass').dynamicClasses.get('ImplementingClass');
        var dynInst = dynClass.createInstance();
        Sys.println('' + dynInst.call('isNativeInterface'));
        #end

        #if host_test_12
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        Sys.println('' + dynInst.call('isBasicClass'));
        #end

        #if host_test_13
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        Sys.println('' + dynInst.call('isBasicClass2'));
        #end

    } //main

} //Host
