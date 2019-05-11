package sample.native;

/** This haxe class is compiled with haxe compiler,
    its code is thus not interpreted. It is regular natively compiled haxe code.
    Then it is exposed to `interpret` Env so that scripts
    code can use it, call methods, instanciate it etc... */
class NativeClass {

    public function new() {

    } //new

    /** Pick and return a random name */
    public static function randomName() {

        var names = ['John', 'Joanna', 'Jimmy', 'Julie'];
        return names[Std.random(names.length)];
        
    } //randomName

} //NativeClass
