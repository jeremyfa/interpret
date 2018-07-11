package hxs;

class Env {

    /** Mapping of modules (similar to static modules, but at runtime) from type paths. */
    public var modules = new Map<String,DynamicModule>();

    /** Internal of modules */
    var modulesById = new Map<Int,DynamicModule>();

    public function new() {

    } //new

    /** Add dynamic module */
    public function addModule(typePath:String, module:DynamicModule):Void {

        modulesById.set(@:privateAccess module.id, module);
        modules.set(typePath, module);

    } //addModule

    /** Load script code for the given class.
        This will update the code of any living instance
        as well as the newly created ones. */
    public function patchScriptableClass(scriptableClass:Class<Scriptable>, dynamicClass:DynamicClass):Void {

        // TODO

    } //patchScriptableClass

} //Env
