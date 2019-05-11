package interpret;

import haxe.Constraints.IMap;
import interpret.Types;

using StringTools;

class TypeUtils {

    static var _stdTypes = [
        'String' => true,
        'Int' => true,
        'Float' => true,
        'Bool' => true,
        'Array' => true,
        'Map' => true
    ];

    /** Return a type string (with dot path if any) from the given object */
    public static function typeOf(obj:Dynamic, ?env:Env):String {

        if (Std.is(obj, String)) return 'String';
        if (Std.is(obj, Int)) return 'Int';
        if (Std.is(obj, Float)) return 'Float';
        if (Std.is(obj, Bool)) return 'Bool';
        if (Std.is(obj, Array)) return 'Array';
        if (Std.is(obj, IMap)) return 'Map';

        if (Std.is(obj, DynamicClass)) {
            var c:DynamicClass = cast obj;
            return c.classType;
        }
        if (Std.is(obj, DynamicInstance)) {
            var i:DynamicInstance = cast obj;
            return i.dynamicClass.instanceType;
        }

        if (Std.is(obj, RuntimeItem)) {
            var item:RuntimeItem = cast obj;
            switch (item) {
                case ExtensionItem(item, extendedType):
                    return typeOf(item);
                case ClassFieldItem(rawItem, _, _):
                    return typeOf(rawItem);
                case ClassItem(rawItem, moduleId, name):
                    return 'Class<' + name + '>';
                case EnumItem(rawItem, moduleId, name):
                    return 'Enum<' + name + '>';
                case EnumFieldItem(rawItem, name, numArgs):
                    return name.substring(0, name.lastIndexOf('.'));
                case PackageItem(pack):
                    return 'Dynamic';
                case AbstractItem(rawItem, moduleId, name, runtimeType):
                    return runtimeType;
                case AbstractFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                    return typeOf(rawItem);
                case SuperClassItem(item):
            }
        }

        if (Std.is(obj, Class)) {
            var classType = Type.getClassName(obj);
            if (classType == null) classType = 'Dynamic';
            return 'Class<'+classType+'>';
        }

        if (Std.is(obj, Enum)) {
            var enumType = Type.getEnumName(obj);
            if (enumType == null) enumType = 'Dynamic';
            return 'Enum<'+enumType+'>';
        }

        if (Reflect.isEnumValue(obj)) {
            var enu = Type.getEnum(obj);
            if (enu != null) {
                return Type.getEnumName(enu);
            }
        }

        var clazz = Type.getClass(obj);
        if (clazz != null) {
            return Type.getClassName(clazz);
        }

        return 'Dynamic';

    } //String

    /** Return a resolved type string from the given imports and raw type.
        Imports will be used to resolve types to their complete dot path. */
    public static function toResolvedType(imports:ResolveImports, rawType:String):String {

        var result = rawType;

        // Use imports to resolve extended type full dot path
        var resolveClassType = rawType.startsWith('Class<');
        if (resolveClassType) {
            var classType = rawType.substring(6, rawType.length-1);
            var resolvedType = imports.resolve(classType);
            if (resolvedType != null) {
                switch (resolvedType) {
                    case ClassItem(rawItem, moduleId, name):
                        result = 'Class<' + name + '>';
                    default:
                }
            }
            else if (imports.pack != null) {
                result = 'Class<' + imports.pack + '.' + rawType + '>';
            }
        } else {
            var resolvedType = imports.resolve(rawType);
            if (resolvedType != null) {
                switch (resolvedType) {
                    case ClassItem(rawItem, moduleId, name):
                        result = name;
                    default:
                }
            }
            else if (_stdTypes.exists(rawType)) {
                return rawType;
            }
            else if (imports.pack != null) {
                result = imports.pack + '.' + rawType;
            }
        }

        return result;

    } //toResolvedType

    public static function unwrap(value:Dynamic, ?env:Env):Dynamic {

        if (value == null) return null;
        if (value == Unresolved.UNRESOLVED) return null;

        if (Std.is(value, RuntimeItem)) {
            var item:RuntimeItem = cast value;
            switch (item) {
                case ExtensionItem(item, _) | SuperClassItem(item):
                    return unwrap(item, env);
                case ClassFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                    if (rawItem == null && env != null) {
                        var dotIndex = name.lastIndexOf('.');
                        var dynClass = env.resolveDynamicClass(moduleId, name.substring(0, dotIndex));
                        if (dynClass != null) {
                            return dynClass.get(name.substring(dotIndex + 1));
                        }
                    }
                    return rawItem;
                case ClassItem(rawItem, moduleId, name):
                    if (rawItem == null && env != null) {
                        var dynClass = env.resolveDynamicClass(moduleId, name);
                        if (dynClass != null) {
                            return dynClass;
                        }
                    }
                    return rawItem;
                case EnumItem(rawItem, _, _):
                    return rawItem;
                case EnumFieldItem(rawItem, _, _):
                    return rawItem;
                
                // These cases cannot (and should not) be unwrapped
                // as there is no raw equivalent at runtime
                //
                case AbstractItem(rawItem, moduleId, name, runtimeType):
                    return value;
                case AbstractFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                    return value;
                case PackageItem(pack):
                    return value;
            }
        }

        if (Std.is(value, DynamicAbstract)) {
            var abs:DynamicAbstract = cast value;
            return abs.value;
        }

        return value;

    } //unwrap

    public static function wrapIfNeeded(value:Dynamic, type:String, ?env:Env):Dynamic {

        if (value != null && Std.is(value, RuntimeItem)) {
            // Already wrapped
            return value;
        }

        if (type == null) {
            // No type specified, there is nothing we can do
            return value;
        }

        var cleanType = type;
        var opt = false;
        if (cleanType.startsWith('?')) {
            opt = true;
            cleanType = cleanType.substring(1);
        }
        if (cleanType.startsWith('Null<') && cleanType.endsWith('>')) {
            opt = true;
            cleanType = cleanType.substring(5, cleanType.length - 1);
        }

        if (env != null) {
            var resolved = env.resolveItemByTypePath(cleanType);
            if (resolved != null) {
                switch (resolved) {
                    // Abstract value need to be wrapped to be recognizable by interpret
                    case AbstractItem(rawItem, moduleId, name, runtimeType):
                        if (opt && value == null) return null;
                        return new DynamicAbstract(env, resolved, value);
                    
                    // These don't need wrapping
                    //
                    case ClassItem(rawItem, moduleId, name):
                        return value;
                    case EnumItem(rawItem, moduleId, name):
                        return value;
                    case ExtensionItem(item, extendedType):
                        return value;
                    case ClassFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                        return value;
                    case AbstractFieldItem(rawItem, moduleId, name, isStatic, type, argTypes):
                        return value;
                    case EnumFieldItem(rawItem, name, numArgs):
                        return value;
                    case PackageItem(pack):
                        return value;
                    case SuperClassItem(item):
                        return value;
                }
            }
        }

        return value;

    } //wrapIfNeeded

    /*public static function shouldWrapFromType(value:Dynamic, forType:String, ?env:Env):Bool {

        if (env != null) {
            // TODO
        }

        return false;

    } //shouldWrapFromType

    public static function shouldUnwrapForType(value:Dynamic, forType:String, ?env:Env):Bool {

        if (env != null) {
            // TODO
        }

        return false;

    } //shouldUnwrapForType*/

} //TypeUtils
