package hxs;

class Env {

    /** Mapping of modules (similar to static modules, but at runtime) from type paths. */
    public var modules = new Map<String,DynamicModule>();

    /** Internal of modules */
    var modulesById = new Map<Int,DynamicModule>();

    /** Mapping of extensions (similar to static extensions, but at runtime) from type paths. */
    public var extensions = new Map<String,DynamicExtension>();

    /** If defined, will limit the top level search to the ones specified in the map. */
    /*public var allowedPackages:Map<String,Bool> = [
        'haxe' => true
    ];*/

    public function new() {

        // Add default extensions

    } //new

    /** Add dynamic module */
    public function addModule(typePath:String, module:DynamicModule):Void {

        modulesById.set(@:privateAccess module.id, module);
        modules.set(typePath, module);

    } //addModule

    /** Add dynamic extension */
    public function addExtension(typePath:String, extension:DynamicExtension):Void {

        extensions.set(typePath, extension);

    } //addExtension

    /** Allow a package */
    /*public function allowPackage(pack:String):Void {

        allowedPackages.set(pack, true);

    } //allowPackage*/

    /** Load script code for the given class.
        This will update the code of any living instance
        as well as the newly created ones. */
    public function patchScriptableClass(scriptableClass:Class<Scriptable>, dynamicClass:DynamicClass):Void {

        // TODO

    } //patchScriptableClass

} //Env
