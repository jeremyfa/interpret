package hxs;

class Env {

    /** Mapping of modules (similar to static modules, but at runtime) from type paths. */
    public var modules(default,null) = new Map<String,DynamicModule>();

    /** Aliases */
    public var aliases(default,null) = new Map<String,String>();

    /** Internal map of modules */
    var modulesById:Map<Int,DynamicModule> = new Map();

    /** Internal map of packages */
    var packs:Map<String,DynamicPackage> = new Map();

    /** Internal map of allowed root packages (computed from modules) */
    var availableRootPacks:Map<String,Bool> = new Map();

    public function new() {

    } //new

    /** Add dynamic module */
    public function addModule(typePath:String, module:DynamicModule):Void {

        modulesById.set(@:privateAccess module.id, module);
        modules.set(typePath, module);

        // Update available root packs
        if (module.pack != null) {
            var parts = module.pack.split('.');
            availableRootPacks.set(parts[0], true);
        }

        // Update aliases
        for (key in module.aliases) {
            if (!aliases.exists(key)) {
                aliases.set(key, module.aliases.get(key));
            }
        }

    } //addModule

    public function getPackage(path:String, checkAvailability:Bool = true):DynamicPackage {

        if (checkAvailability && !availableRootPacks.exists(path)) {
            return null;
        }

        if (!packs.exists(path)) {
            var pack = new DynamicPackage(this, path);
            packs.set(path, pack);
        }

        return packs.get(path);

    } //get

    /** Load script code for the given class.
        This will update the code of any living instance
        as well as the newly created ones. */
    public function patchScriptableClass(scriptableClass:Class<Scriptable>, dynamicClass:DynamicClass):Void {

        // TODO

    } //patchScriptableClass

} //Env
