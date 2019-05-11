package sample;

import haxe.Timer;
import interpret.Env;
import interpret.DynamicModule;
import interpret.LiveReload;
import sample.interpretable.WatchedClass;

/** A sample that instanciate a native class and automatically watch the source file.
    When the source file changes, the interpretable method (marked with @interpret) is updated on the fly
    without restarting the app. */
class LiveReloadSample {

    public static function main() {

#if js
        try {
            untyped require('source-map-support').install();
        } catch (e:Dynamic) {}
#end

        // Assign a callback that will expose the modules we want to
        // interpretable code
        Env.configureInterpretableEnv = function(env) {
            // We expose this class because it need to be accessible
            // from its interpretable methods when they are reloaded as script
            env.addModule('sample.interpretable.WatchedClass', DynamicModule.fromStatic(sample.interpretable.WatchedClass));
            // sample.native.NativeClass can be imported and used from interpretable code because we exposed it
            env.addModule('sample.native.NativeClass', DynamicModule.fromStatic(sample.native.NativeClass));
            // StringTools can be used with `using` in dynamic classes because we exposed it as well
            env.addModule('StringTools', DynamicModule.fromStatic(StringTools));
        };

        // Optional: provide a custom file watcher
        // that will be used to watch interpreted files
        //LiveReload.defaultWatcher = new MyCustomWatcher();

        // Start live reload
        LiveReload.start();

        // Regularly call LiveReload.tick as it is necessary
        // to make it check files regularly
        var interval = 0.5; // Time in seconds between each tick
        var timer = new Timer(Math.round(interval * 1000));
        timer.run = function() LiveReload.tick(interval); // We call LiveReload.tick() with the elapsed time delta as

        // Create a (native) instance of WatchedClass
        var watchedClassInstance = new WatchedClass();

        // Call printSomething() once every second
        var timer2 = new Timer(1000);
        timer2.run = watchedClassInstance.printSomething;

        // Log some info
        Sys.println('interpret is watching changes at path: sample/interpretable/WatchedClass.hx');
        Sys.println('Try to change its content to see it get updated');
        Sys.println('press CTRL+C to exit program.');

    } //main

} //LiveReloadSample