package hxs;

import hxs.Types;

using StringTools;

class ResolveImports {

    var imports:Array<TImport> = [];

    var env:Env;

    var addedItems:Map<String,ModuleItem> = new Map();

    public function new(env:Env) {

        this.env = env;

    } //new

    public function addImport(data:TImport) {

        // Ensure the requested type path is allowed
        /*if (env.allowedPackages != null) {
            var parts = data.path.split('.');
            if (parts.length > 1 && !env.allowedPackages.exists(parts[0])) {
                throw 'Package ' + parts[0] + ' is not allowed. Allow it with `env.allowPackage(\'' + parts[0] + '\')`';
            }
        }*/

        var parts = data.path.split('.');
        var lastPart = parts[parts.length-1];
        var isWildcard = lastPart == '*';
        var resolvedModule:DynamicModule = null;
        var i = parts.length;
        var modulePath = data.path;
        while (i > 0) {
            modulePath = parts.slice(0, i).join('.');
            if (env.modules.exists(modulePath)) {
                resolvedModule = env.modules.get(modulePath);
                break;
            }
            i--;
        }

        var wildcardModules:Array<String> = null;
        if (resolvedModule == null) {
            if (isWildcard) {
                wildcardModules = [];
                // Look for every module matching wildcard
                var modulePrefix = data.path.substr(0, data.path.length-1);
                for (moduleKey in env.modules.keys()) {
                    var moduleParts = moduleKey.split('.');
                    var moduleLastPart = moduleParts[moduleParts.length-1];
                    if (moduleKey == modulePrefix + moduleLastPart) {
                        wildcardModules.push(moduleKey);
                    }
                }
            }
            else {
                throw 'Module not found: ' + data.path;
            }
        }

        inline function add(name, item) {
            if (!addedItems.exists(name)) addedItems.set(name, item);
        }

        if (isWildcard) {
            // Wildcard import
            var prefix = parts.slice(0, parts.length-1).join('.') + '.';
            if (wildcardModules == null) {
                // Wildcard import of symbols inside a module
                var module = env.modules.get(modulePath);
                for (itemPath in module.items.keys()) {
                    if (itemPath.startsWith(prefix)) {
                        var itemParts = itemPath.split('.');
                        if (itemParts.length == parts.length) {
                            add(itemParts[itemParts.length-1], module.items.get(itemPath));
                        }
                    }
                }
            }
            else {
                // Wildcard import of modules inside a package
                for (moduleKey in wildcardModules) {
                    var module = env.modules.get(moduleKey);
                    var mainItem:ModuleItem = module.items.get(moduleKey);
                    if (mainItem != null) {
                        add(moduleKey.substr(moduleKey.lastIndexOf('.')+1), mainItem);
                    }
                }
            }
        } else {
            // Regular import
            var module = env.modules.get(modulePath);
            var prefix = data.path + '.';
            var mainItem:ModuleItem = module.items.get(data.path);
            if (mainItem == null) {
                throw 'Invalid module for path: ' + data.path;
            }
            switch (mainItem) {
                case FieldItem(rawItem):
                    // Static field import
                    add(parts[parts.length-1], mainItem);
                case ClassItem(rawItem, _):
                    // Class import
                    add(parts[parts.length-1], mainItem);
                    for (itemPath in module.items.keys()) {
                        var item:ModuleItem = module.items.get(itemPath);
                        switch (item) {
                            case ClassItem(rawItem, _):
                                var itemParts = itemPath.split('.');
                                if (itemPath == data.path) {
                                    add(itemParts[itemParts.length-1], item);
                                } else if (itemPath.startsWith(prefix)) {
                                    if (itemParts.length == parts.length + 1) {
                                        add(itemParts[itemParts.length-1], item);
                                    }
                                }
                            default:
                        }
                    }
            }
        }

        imports.push(data);

    } //addImport

    public function resolve(name:String):ModuleItem {

        var item = addedItems.get(name);

        if (item != null) {

            return item;

        }

        return null;

        /*var matched:TImport = null;

        for (data in imports) {
            if (data.alias != null) {
                if (typeName == data.alias) {
                    matched = data;
                    break;
                }
            }
            else {
                if (typeName == data.name) {
                    matched = data;
                    break;
                }
            }
        }

        if (matched != null) {
            if (env.types.exists(matched.path)) {
                return env.types.get(matched.path);
            }
            var resolved = Type.resolveClass(matched.path);
            // TODO if null try enum...
            return resolved;
        }
        else {
            return null;
        }*/

    } //resolve

} //ResolveImports
