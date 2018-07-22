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
        env.addDefaultModules();

        // Modules from static (native) code
        env.addModule('StringTools', DynamicModule.fromStatic(StringTools));

        // Modules from interpreted code
        env.addModule('script.SomeClass', DynamicModule.fromString(env, 'SomeClass', File.getContent('script/SomeClass.hx')));
        env.addModule('script.SomeOtherClass', DynamicModule.fromString(env, 'SomeOtherClass', File.getContent('script/SomeOtherClass.hx')));

        env.link();

    } //main

} //Host
