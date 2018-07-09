package hxs;

import hxs.Types;

class ResolveUsings {

    var usings:Array<TUsing> = [];

    var env:Env;

    var addedNames:Map<String,Bool> = new Map();

    public function new(env:Env) {

        this.env = env;

    } //new

    public function addUsing(data:TUsing) {

        // Ensure the requested type path is allowed
        /*if (env.allowedPackages != null) {
            var parts = data.path.split('.');
            if (parts.length > 1 && !env.allowedPackages.exists(parts[0])) {
                throw 'Package ' + parts[0] + ' is not allowed. Allow it with `env.allowPackage(\'' + parts[0] + '\')`';
            }
        }*/

        if (!env.extensions.exists(data.path)) {
            throw 'Extension not found: ' + data.path;
        }

        var extension = env.extensions.get(data.path);
        for (name in extension.names.keys()) {
            addedNames.set(name, true);
        }

        usings.push(data);

    } //addUsing

    inline public function hasName(name:String) {

        return addedNames.exists(name);

    } //hasName

    public function resolve(extendedType:String, name:String):ModuleItem {

        for (data in usings) {
            
            var extension = env.extensions.get(data.path);
            
            var resolved = extension.resolve(name, extendedType);
            if (resolved != null) return resolved;

        }

        return null;

    } //resolve

} //ResolveUsings
