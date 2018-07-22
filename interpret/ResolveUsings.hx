package interpret;

import interpret.Types;

using StringTools;

class ResolveUsings {

    var usings:Array<TUsing> = [];

    var env:Env;

    var addedItems:Map<String,Map<String,RuntimeItem>> = new Map();

    public function new(env:Env) {

        this.env = env;

    } //new

    public function addUsing(data:TUsing) {

        var parts = data.path.split('.');
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

        if (resolvedModule == null) {
            throw 'Module not found: ' + data.path;
        }

        inline function add(name, extendedType, item) {
            if (name == 'staticExt') trace('ADD USING $name $extendedType');
            var extendedTypesForName = addedItems.get(name);
            if (extendedTypesForName == null) {
                extendedTypesForName = new Map();
                addedItems.set(name, extendedTypesForName);
            }
            extendedTypesForName.set(extendedType, item);
        }

        var prefix = data.path + '.';
        for (itemPath in resolvedModule.items.keys()) {
            var item:RuntimeItem = resolvedModule.items.get(itemPath);
            switch (item) {
                case ExtensionItem(ClassFieldItem(rawItem, _, _), extendedType):
                    if (itemPath.startsWith(prefix)) {
                        var itemParts = itemPath.split('.');
                        if (itemParts.length == parts.length + 1) {
                            add(itemParts[itemParts.length-1], extendedType, item);
                        }
                    }
                default:
            }
        }

        usings.push(data);

    } //addUsing

    inline public function hasName(name:String) {

        return addedItems.exists(name);

    } //hasName

    public function resolve(extendedType:String, name:String):RuntimeItem {

        var extendedTypesForName = addedItems.get(name);

        if (extendedTypesForName != null) {

            var type = extendedType;
            while (type != null) {

                if (extendedTypesForName.exists(type)) {
                    return extendedTypesForName.get(type);
                }
                var alias = env.aliases.get(type);
                if (alias != null && extendedTypesForName.exists(alias)) {
                    return extendedTypesForName.get(alias);
                }

                // Implemented interfaces have extension?
                var interfaces = env.getInterfaces(type);
                if (interfaces != null) {
                    for (item in interfaces.keys()) {
                        var iActive = item;
                        while (iActive != null) {

                            if (extendedTypesForName.exists(iActive)) {
                                return extendedTypesForName.get(iActive);
                            }

                            var iAlias = env.aliases.get(iActive);
                            if (iAlias != null && extendedTypesForName.exists(iAlias)) {
                                return extendedTypesForName.get(iAlias);
                            }

                            // Parent interface has extension?
                            iActive = env.getSuperClass(iActive);
                        }
                    }
                }

                // Superclass has extension?
                type = env.getSuperClass(type);
            }
        }

        return null;

    } //resolve

} //ResolveUsings
