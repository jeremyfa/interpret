package interpret;

import interpret.Types;

using StringTools;

class ResolveImports {

    var imports:Array<TImport> = [];

    var env:Env;

    var items:Map<String,RuntimeItem> = new Map();

    public var pack:String = null;

    public function new(env:Env) {

        this.env = env;

    } //new

    public function addImport(data:TImport) {

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
            if (!items.exists(name)) items.set(name, item);
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
                    var mainItem:RuntimeItem = module.items.get(moduleKey);
                    if (mainItem != null) {
                        add(moduleKey.substr(moduleKey.lastIndexOf('.')+1), mainItem);
                    }
                }
            }
        } else {
            // Regular import
            var module = env.modules.get(modulePath);
            var prefix = data.path + '.';
            var mainItem:RuntimeItem = module.items.get(data.path);
            var loadSubItems = false;
            if (mainItem == null) {
                loadSubItems = true;
            }
            else {
                switch (mainItem) {
                    case ClassFieldItem(_) | ExtensionItem(_, _) | EnumFieldItem(_, _, _):
                        // Class/Enum field import
                        add(parts[parts.length-1], mainItem);
                    case ClassItem(_, _) | EnumItem(_, _, _):
                        // Class/Enum import
                        add(parts[parts.length-1], mainItem);
                        loadSubItems = true;
                    default:
                        throw 'Invalid module for path: ' + data.path;
                }
            }
            // Sub items
            if (loadSubItems) {
                for (itemPath in module.items.keys()) {
                    var item:RuntimeItem = module.items.get(itemPath);
                    switch (item) {
                        case ClassItem(_, _):
                            var itemParts = itemPath.split('.');
                            if (itemPath == data.path) {
                                add(itemParts[itemParts.length-1], item);
                            } else if (itemPath.startsWith(prefix)) {
                                if (itemParts.length == parts.length + 1) {
                                    add(itemParts[itemParts.length-1], item);
                                }
                            }
                        case EnumItem(_, _, _):
                            var itemParts = itemPath.split('.');
                            if (itemPath == data.path) {
                                add(itemParts[itemParts.length-1], item);
                            } else if (itemPath.startsWith(prefix)) {
                                if (itemParts.length == parts.length + 1) {
                                    add(itemParts[itemParts.length-1], item);
                                }
                            }
                        case EnumFieldItem(_, _, _):
                            var itemParts = itemPath.split('.');
                            if (itemPath == data.path) {
                                add(itemParts[itemParts.length-1], item);
                            } else if (itemPath.startsWith(prefix)) {
                                if (itemParts.length == parts.length + 1 || (mainItem == null && itemParts.length == parts.length + 2)) {
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

    inline public function resolve(name:String):RuntimeItem {

        return items.get(name);

    } //resolve

} //ResolveImports
