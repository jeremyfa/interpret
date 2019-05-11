package sample;

import sys.io.File;
import interpret.Env;
import interpret.DynamicModule;

/** A sample that loads and instanciate a dynamic class
    from file system and call `hello()` method on it. */
class DynamicClassSample {

    public static function main() {

#if js
        try {
            untyped require('source-map-support').install();
        } catch (e:Dynamic) {}
#end

        // Create env
        var env = new Env();
        env.addDefaultModules();

        // Expose some native modules
        // sample.native.NativeClass can be imported and used from interpretable code because we exposed it
        env.addModule('sample.native.NativeClass', DynamicModule.fromStatic(sample.native.NativeClass));
        // StringTools can be used with `using` in dynamic classes because we exposed it as well
        env.addModule('StringTools', DynamicModule.fromStatic(StringTools));

        // Read HelloWorld.hx as raw text and add it as dynamic module
        env.addModule('sample.script.HelloWorld', DynamicModule.fromString(env, 'HelloWorld', File.getContent('sample/script/HelloWorld.hx')));

        // Link every modules
        env.link();

        // Load `HelloWorld` dynamic class
        var helloWorldClass = env.modules.get('sample.script.HelloWorld').dynamicClasses.get('HelloWorld');

        // Create instance
        var helloWorldInstance = helloWorldClass.createInstance();

        // Call hello() on this dynamic instance
        // (this should print `hello Jeremy`)
        helloWorldInstance.call('hello', ['Jeremy']);

        // Call hello without providing a name, should pick a random one
        helloWorldInstance.call('hello');

    } //main

} //DynamicClassSample
