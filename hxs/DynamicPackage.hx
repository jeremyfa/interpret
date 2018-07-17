package hxs;

// TODO use per-env dynamic packages
// TODO only allow dynamic packages on available ones

@:allow(hxs.Env)
class DynamicPackage {

    public var env(default,null):Env;

    public var path(default,null):String;

    var resolvedSubs = new Map<String,Dynamic>();

    function new(env:Env, path:String) {

        this.env = env;
        this.path = path;

    } //new

    public function getSub(subPath:String):Dynamic {

        if (resolvedSubs.exists(subPath)) {
            return resolvedSubs.get(subPath);
        }

        // Resolve type
        var fullPath = path + '.' + subPath;
        
        var module = env.modules.get(fullPath);
        if (module != null) {
            var resolved = module.items.get(fullPath);
            if (resolved != null) {
                resolvedSubs.set(subPath, resolved);
                return resolved;
            }
        }

        // Resolve sub-package
        // There is no check at this stage to determine whether the package is valid or not.
        // The check is done only when importing {package}.SomeModule, which is fine so far.
        var resolved = env.getPackage(fullPath);
        resolvedSubs.set(subPath, resolved);
        return resolved;

    } //getSub

} //DynamicPackage
