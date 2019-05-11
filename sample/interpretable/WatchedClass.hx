package sample.interpretable;

import interpret.Interpretable;

class WatchedClass implements Interpretable {

    public function new() {

    } //new

    public static function getClassNameFromNativeStatic(stuff:String):String {

        return Type.getClassName(WatchedClass);

    } //getClassNameFromNativeStatic

    /** This is a native (non-interpreted) method. Modifying it when the app is running
        will have no effect on the running code. */
    public function getClassNameFromNative():String {

        return Type.getClassName(Type.getClass(this));

    } //getClassNameFromNative

    /** This is an interpretable method. It is compiled as native haxe code with the app,
        but if the method is updated while the app is running, its new content will be live-reloaded
        and the code will be executed with `interpret`. */
    @interpret public function printSomething() {

        // Just testing calling a native (non-interpreted) method
        // and get its return value
        var className = getClassNameFromNative();

        // Then printing something (note that string interpolation works :))
        trace('Just printing something from $className.printSomething()');

    } //printSomething

} //WatchedClass