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
        env.addModule('test.native.NativeGroup', DynamicModule.fromStatic(test.native.NativeGroup));
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

        #if host_other_class
        env.addModule('test.script.OtherClass', DynamicModule.fromString(env, 'OtherClass', File.getContent('test/script/OtherClass.hx')));
        #end
        
        #if host_alt_class
        env.addModule('test.script.AltClass', DynamicModule.fromString(env, 'AltClass', File.getContent('test/script/AltClass.hx')));
        #end
        
        #if host_another_class
        env.addModule('test.script.AnotherClass', DynamicModule.fromString(env, 'AnotherClass', File.getContent('test/script/AnotherClass.hx')));
        #end
        
        #if host_interpreted_group
        env.addModule('test.script.InterpretedGroup', DynamicModule.fromString(env, 'InterpretedGroup', File.getContent('test/script/InterpretedGroup.hx')));
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

        #if host_test_14
        var dynClass = env.modules.get('test.script.ChildClass').dynamicClasses.get('ChildClass');
        var dynInst = dynClass.createInstance();
        Sys.println('' + dynInst.call('isNativeClass'));
        #end

        #if host_test_15
        var dynClass = env.modules.get('test.script.NativeChildClass').dynamicClasses.get('NativeChildClass');
        var dynInst = dynClass.createInstance();
        Sys.println('' + dynInst.call('isNativeClass'));
        #end

        #if host_test_16
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        Sys.println('' + dynInst.exists('sVar1'));
        #end

        #if host_test_17
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        Sys.println('' + dynClass.get('sVar1'));
        #end

        #if host_test_18
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        Sys.println('' + dynClass.get('sVar2'));
        #end

        #if host_test_19
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        dynClass.set('sVar2', 3000);
        Sys.println('' + dynClass.get('sVar1'));
        #end

        #if host_test_20
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        dynClass.set('sVar3', 3000);
        Sys.println('' + dynClass.get('sVar1'));
        #end

        #if host_test_21
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        dynClass.set('sVar3', 3000);
        Sys.println('' + dynClass.get('sVar2'));
        #end

        #if host_test_22
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        dynClass.set('sVar2', 3000);
        Sys.println('' + dynClass.get('sVar3'));
        #end

        #if host_test_23
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        dynClass.set('sVar2', 3000);
        Sys.println('' + dynClass.get('sVar2'));
        #end

        #if host_test_24
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        dynClass.set('sVar3', 3000);
        Sys.println('' + dynClass.get('sVar3'));
        #end

        #if host_test_25
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        Sys.println('' + dynClass.exists('mVar1'));
        #end

        #if host_test_26
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        Sys.println('' + dynInst.get('mVar1'));
        #end

        #if host_test_27
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        Sys.println('' + dynInst.get('mVar2'));
        #end

        #if host_test_28
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        dynInst.set('mVar2', 3000);
        Sys.println('' + dynInst.get('mVar1'));
        #end

        #if host_test_29
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        dynInst.set('mVar3', 3000);
        Sys.println('' + dynInst.get('mVar1'));
        #end

        #if host_test_30
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        dynInst.set('mVar3', 3000);
        Sys.println('' + dynInst.get('mVar2'));
        #end

        #if host_test_31
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        dynInst.set('mVar2', 3000);
        Sys.println('' + dynInst.get('mVar3'));
        #end

        #if host_test_32
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        dynInst.set('mVar2', 3000);
        Sys.println('' + dynInst.get('mVar2'));
        #end

        #if host_test_33
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        dynInst.set('mVar3', 3000);
        Sys.println('' + dynInst.get('mVar3'));
        #end

        #if host_test_34
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        dynInst.set('mVar4', 3000);
        Sys.println('' + dynInst.get('mVar4'));
        #end

        #if host_test_35
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        dynInst.set('mVar5', 3000);
        Sys.println('' + dynClass.get('sVar1'));
        #end

        #if host_test_36
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        var dynInst = dynClass.createInstance();
        dynInst.set('mVar6', 3000);
        Sys.println('' + dynInst.get('mVar6'));
        #end

        #if host_test_37
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        Sys.println('' + dynClass.call('nativeGroupClass1IsClass1'));
        #end

        #if host_test_38
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        Sys.println('' + dynClass.call('nativeGroupClass1IsClass2'));
        #end

        #if host_test_39
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        Sys.println('' + dynClass.call('nativeGroupClass2IsClass1'));
        #end

        #if host_test_40
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        Sys.println('' + dynClass.call('nativeGroupClass2IsClass2'));
        #end

        #if host_test_41
        var dynClass = env.modules.get('test.script.OtherClass').dynamicClasses.get('OtherClass');
        Sys.println('' + dynClass.call('nativeGroupClass1IsClass1'));
        #end

        #if host_test_42
        var dynClass = env.modules.get('test.script.OtherClass').dynamicClasses.get('OtherClass');
        Sys.println('' + dynClass.call('nativeGroupClass2IsClass1'));
        #end

        #if host_test_43
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        Sys.println('' + dynClass.call('nativeGroupClass1StaticMethod1'));
        #end

        #if host_test_44
        var dynClass = env.modules.get('test.script.BasicClass').dynamicClasses.get('BasicClass');
        Sys.println('' + dynClass.call('nativeGroupClass2StaticMethod2'));
        #end

        #if host_test_45
        var dynClass = env.modules.get('test.script.OtherClass').dynamicClasses.get('OtherClass');
        Sys.println('' + dynClass.call('nativeGroupClass1StaticMethod1'));
        #end

        #if host_test_46
        var dynClass = env.modules.get('test.script.OtherClass').dynamicClasses.get('OtherClass');
        Sys.println('' + dynClass.call('nativeGroupClass2StaticMethod2'));
        #end

        #if host_test_47
        var dynClass = env.modules.get('test.script.OtherClass').dynamicClasses.get('OtherClass');
        Sys.println('' + dynClass.createInstance().get('name'));
        #end

        #if host_test_48
        var dynClass = env.modules.get('test.script.OtherClass').dynamicClasses.get('OtherClass');
        Sys.println('' + dynClass.createInstance().get('age'));
        #end

        #if host_test_49
        var dynClass = env.modules.get('test.script.OtherClass').dynamicClasses.get('OtherClass');
        var args:Array<Dynamic> = ['Jon', 21];
        Sys.println('' + dynClass.createInstance(args).get('name'));
        #end

        #if host_test_50
        var dynClass = env.modules.get('test.script.OtherClass').dynamicClasses.get('OtherClass');
        var args:Array<Dynamic> = ['Jon', 21];
        Sys.println('' + dynClass.createInstance(args).get('age'));
        #end

        #if host_test_51
        var dynClass = env.modules.get('test.script.AltClass').dynamicClasses.get('AltClass');
        Sys.println('' + dynClass.call('interpretedGroupClass1IsClass1'));
        #end

        #if host_test_52
        var dynClass = env.modules.get('test.script.AltClass').dynamicClasses.get('AltClass');
        Sys.println('' + dynClass.call('interpretedGroupClass1IsClass2'));
        #end

        #if host_test_53
        var dynClass = env.modules.get('test.script.AltClass').dynamicClasses.get('AltClass');
        Sys.println('' + dynClass.call('interpretedGroupClass2IsClass1'));
        #end

        #if host_test_54
        var dynClass = env.modules.get('test.script.AltClass').dynamicClasses.get('AltClass');
        Sys.println('' + dynClass.call('interpretedGroupClass2IsClass2'));
        #end

        #if host_test_55
        var dynClass = env.modules.get('test.script.AnotherClass').dynamicClasses.get('AnotherClass');
        Sys.println('' + dynClass.call('interpretedGroupClass1IsClass1'));
        #end

        #if host_test_56
        var dynClass = env.modules.get('test.script.AnotherClass').dynamicClasses.get('AnotherClass');
        Sys.println('' + dynClass.call('interpretedGroupClass2IsClass1'));
        #end

        #if host_test_57
        var dynClass = env.modules.get('test.script.AltClass').dynamicClasses.get('AltClass');
        Sys.println('' + dynClass.call('interpretedGroupClass1StaticMethod1'));
        #end

        #if host_test_58
        var dynClass = env.modules.get('test.script.AltClass').dynamicClasses.get('AltClass');
        Sys.println('' + dynClass.call('interpretedGroupClass2StaticMethod2'));
        #end

        #if host_test_59
        var dynClass = env.modules.get('test.script.AnotherClass').dynamicClasses.get('AnotherClass');
        Sys.println('' + dynClass.call('interpretedGroupClass1StaticMethod1'));
        #end

        #if host_test_60
        var dynClass = env.modules.get('test.script.AnotherClass').dynamicClasses.get('AnotherClass');
        Sys.println('' + dynClass.call('interpretedGroupClass2StaticMethod2'));
        #end

    } //main

} //Host
