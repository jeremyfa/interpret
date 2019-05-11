package sample.script;

// Imports are working on modules that have been exposed to Env
import sample.native.NativeClass;

// Usings are working on exposed modules as well
using StringTools;

/** This haxe class is not compiled with haxe compiler.
    Instead, it is loaded from file system as string and
    executed as script at runtime. */
class HelloWorld {

    public function new() {

    } //new

    // Optional arguments (and arguments default value like `arg:Int = 123`)
    // are working fine with interpretable code
    public function hello(?name:String):Void {

        // If name is not provided, pick a random one from NativeClass
        if (name == null) {
            name = NativeClass.randomName();
        }

        // Test trimming text with StringTools extension
        var sentence = '    hello $name'.trim();

        // Print result
        trace(sentence);

    } //hello

} //HelloWorld
