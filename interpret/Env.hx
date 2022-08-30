package interpret;

import interpret.Types.RuntimeItem;

using StringTools;

class Env {

    /** Mapping of modules (similar to static modules, but at runtime) from type paths. */
    public var modules(default,null) = new Map<String,DynamicModule>();

    /** Aliases */
    public var aliases(default,null) = new Map<String,String>();

    /** Custom trace */
    public var trace:Dynamic = null;

    /** Internal map of modules */
    @:noCompletion
    public var modulesById:Map<Int,DynamicModule> = new Map();

    /** Internal map of packages */
    var packs:Map<String,DynamicPackage> = new Map();

    /** Internal map of allowed root packages (computed from modules) */
    var availablePacks:Map<String,Bool> = new Map();

    /** Internal map of classes and the superclass they extend (if any) */
    var superClasses:Map<String,String> = new Map();

    /** Internal map of classes and the interfaces they implement (if any) */
    var interfaces:Map<String,EnvInterfaces> = new Map();

    /** Resolved dynamic classes */
    var resolvedDynamicClasses:Map<String,DynamicClass> = new Map();

    /** Resolved items */
    var resolvedItems:Map<String,RuntimeItem> = new Map();

    public function new() {

    } //new

    public function link() {

        var allOnLink = [];

        for (module in modules) {
            if (module.onLink != null) {
                var onLink = module.onLink;
                module.onLink = null;
                allOnLink.push(onLink);
            }
        }

        for (onLink in allOnLink) {
            onLink();
        }

        // Needs to be linked twice to ensure reciprocal dependencies
        // are resolved properly
        for (onLink in allOnLink) {
            onLink();
        }

        // Extract updated module info
        for (module in modules) {
            extractModuleInfo(module);
        }

    } //link

    public function addDefaultModules() {

        var stdModule:DynamicModule = DynamicModule.fromStatic(Std);

        // Patch Std.is to work in scripting env
        stdModule.items.set('Std.isOfType', ClassFieldItem(is, stdModule.id, 'Std.isOfType', true, 'Bool', [null, null]));

        addModule('Std', stdModule);
        addModule('String', DynamicModule.fromStatic(String));

    } //addDefaultModules

    /** Helper to simplify usual addModule() calls */
    public macro function add(ethis, typePath:haxe.macro.Expr):haxe.macro.Expr {
        return macro $ethis.addModule(
            $v{haxe.macro.ExprTools.toString(typePath)},
            interpret.DynamicModule.fromStatic($typePath)
        );
    }

    /** Add dynamic module */
    public function addModule(typePath:String, module:DynamicModule):Void {

        modulesById.set(@:privateAccess module.id, module);
        modules.set(typePath, module);

        // Set name if not any provided
        if (module.typePath == null) module.typePath = typePath;

        extractModuleInfo(module);

    } //addModule

    public function getPackage(path:String):DynamicPackage {

        if (!availablePacks.exists(path)) {
            return null;
        }

        if (!packs.exists(path)) {
            var pack = new DynamicPackage(this, path);
            packs.set(path, pack);
        }

        return packs.get(path);

    } //getPackage

    public function getSuperClass(classPath:String):String {

        var parent = superClasses.get(classPath);
        if (parent != null) return parent;
        var alias = aliases.get(classPath);
        if (alias == null) return null;
        return superClasses.get(alias);

    } //getSuperClass

    public function getInterfaces(classPath:String):Map<String,Bool> {

        var subItems = interfaces.get(classPath);
        if (subItems != null) return subItems.mapping;
        var alias = aliases.get(classPath);
        if (alias == null) return null;
        var res = interfaces.get(alias);
        if (res != null) return res.mapping;
        return null;

    } //getInterfaces

    public function resolveItemByTypePath(name:String):RuntimeItem {

        var resolved = resolvedItems.get(name);
        if (resolved != null) return resolved;

        var alias = aliases.get(name);

        for (module in modules) {
            if (module.items.exists(name)) {
                resolved = module.items.get(name);
                resolvedItems.set(name, resolved);
                return resolved;
            }
            if (alias != null) {
                if (module.items.exists(alias)) {
                    resolved = module.items.get(alias);
                    resolvedItems.set(name, resolved);
                    resolvedItems.set(alias, resolved);
                    return resolved;
                }
            }
        }

        return resolved;

    } //resolveItemByTypePath

    @:noCompletion
    public function resolveDynamicClass(moduleId:Int, name:String):DynamicClass {

        // TODO resolve dynamic class of field names

        var resolved = resolvedDynamicClasses.get(name);
        if (resolved != null || resolvedDynamicClasses.exists(name)) return resolved;

        var module = modulesById.get(moduleId);
        if (module != null) {
            var className = name;
            if (module.pack != null && module.pack != '') {
                className = className.substring(module.pack.length + 1);
            }
            var baseClassName = className;
            var dynClass = module.dynamicClasses != null ? module.dynamicClasses.get(className) : null;
            if (dynClass != null) {
                resolvedDynamicClasses.set(name, dynClass);
                return dynClass;
            }
            var alias = aliases.get(name);
            if (alias != null) {
                className = alias;
                if (module.pack != null && module.pack != '') {
                    className = className.substring(module.pack.length + 1);
                }
                dynClass = module.dynamicClasses.get(className);
                if (dynClass != null) {
                    resolvedDynamicClasses.set(name, dynClass);
                    return dynClass;
                }
            }
            var dotIndex = baseClassName.lastIndexOf('.');
            if (dotIndex != -1) {
                className = baseClassName.substr(dotIndex + 1);
                dynClass = module.dynamicClasses.get(className);
                if (dynClass != null) {
                    resolvedDynamicClasses.set(name, dynClass);
                    return dynClass;
                }
            }
        }

        resolvedDynamicClasses.set(name, null);
        return null;

    } //resolveDynamicClass

    /** Like Std.is(), but accepts dynamic/scriptable types as well. */
    public function is(v:Dynamic, t:Dynamic):Bool {

        // Unwrap v & t if needed
        v = TypeUtils.unwrap(v, this);
        t = TypeUtils.unwrap(t, this);
        var vType:String = null;
        var tClassType:String = null;
        
        if (Std.isOfType(v, DynamicClass._contextType) && v.exists('__interpretType')) {
            vType = v.get('__interpretType');
        }
        else if (Std.isOfType(v, DynamicClass) || Std.isOfType(v, DynamicInstance)) {
            vType = TypeUtils.typeOf(v, this);
        }

        if (Std.isOfType(t, DynamicClass._contextType) && t.exists('__interpretType')) {
            tClassType = t.get('__interpretType');
        }
        else if (Std.isOfType(t, DynamicClass)) {
            tClassType = TypeUtils.typeOf(t, this);
        }

        if (vType == null && tClassType == null) {
            // Nothing dynamic, use standard Std.is()
            return Std.isOfType(v, t);
        }
        else {
            // Need to do runtime checks
            if (vType == null) vType = TypeUtils.typeOf(v);
            if (tClassType == null) tClassType = TypeUtils.typeOf(t);
            return isKindOfClass(vType, tClassType);
        }

    } //is

    function isKindOfClass(vType:String, tClassType:String):Bool {

        if (tClassType.indexOf(' ') != -1) tClassType = tClassType.replace(' ', '');
        if (!tClassType.startsWith('Class<')) return false;
        return isKindOf(vType, tClassType.substring(6, tClassType.length-1));

    } //isKindOfClass

    function isKindOf(vType:String, tType:String):Bool {

        var tAlias = aliases.get(tType);
        var vActive = vType;
        
        while (vActive != null) {

            if (vActive == tType) return true;
            if (tAlias != null && vActive == tAlias) return true;

            var vAlias = aliases.get(vActive);

            if (vAlias != null) {
                if (vAlias == tType) return true;
                if (vAlias == tAlias) return true;
            }

            // Interfaces?
            var interfaces = getInterfaces(vActive);
            if (interfaces != null) {
                for (item in interfaces.keys()) {
                    var iActive = item;
                    while (iActive != null) {

                        if (iActive == tType) return true;
                        if (iActive == tAlias) return true;

                        var iAlias = aliases.get(iActive);

                        if (iAlias != null) {
                            if (iAlias == tType) return true;
                            if (iAlias == tAlias) return true;
                        }

                        // Parent interface?
                        iActive = getSuperClass(iActive);
                    }
                }
            }

            // Parent class?
            vActive = getSuperClass(vActive);
        }

        return false;

    } //isKindOf

    function extractModuleInfo(module:DynamicModule):Void {

        // Update available root packs
        if (module.pack != null && module.pack != '') {
            var parts = module.pack.split('.');
            for (i in 1...parts.length+1) {
                var subPath = parts.slice(0, i).join('.');
                availablePacks.set(subPath, true);
            }
        }

        // Update aliases
        if (module.aliases != null) {
            for (key in module.aliases.keys()) {
                var val = module.aliases.get(key);
                if (!aliases.exists(key)) {
                    aliases.set(key, val);
                }
                if (!aliases.exists(val)) {
                    aliases.set(val, key);
                }
            }
        }

        // Update superclasses
        if (module.superClasses != null) {
            for (key in module.superClasses.keys()) {
                var val = module.superClasses.get(key);
                if (!superClasses.exists(key)) {
                    superClasses.set(key, val);
                }
            }
        }

        // Update interfaces
        if (module.interfaces != null) {
            for (key in module.interfaces.keys()) {
                var subItems = module.interfaces.get(key);
                var envSubItems = interfaces.get(key);
                if (envSubItems == null) {
                    var aliasKey = aliases.get(key);
                    if (aliasKey != null) {
                        envSubItems = interfaces.get(aliasKey);
                    }
                    if (envSubItems == null) {
                        envSubItems = new EnvInterfaces();
                        interfaces.set(key, envSubItems);
                    }
                }
                for (subKey in subItems.keys()) {
                    envSubItems.mapping.set(subKey, true);
                }
            }
        }

    } //extractModuleInfo

/// Interpretable additions

    dynamic static public function configureInterpretableEnv(env:Env):Void {

        // Replace this method at runtime with a custom one

    } //configureInterpretableEnv

    dynamic static public function catchInterpretableException(e:Dynamic, ?dynClass:DynamicClass, ?dynInstance:DynamicInstance):Void {

        // Override this method if you want to do specifing handling
        // (like, rethrow some catched exception, do different logging);

        Errors.handleInterpretableError(e);

    } //catchInterpretableException

/// Print

    public function toString() {

        return 'Env()';

    } //toString

} //Env

class EnvInterfaces {

    public var mapping:Map<String,Bool> = new Map();

    public function new() {

    } //new

} //EnvInterfaces
