package hxs;

import hxs.Types;

using StringTools;

class TypeUtils {

    /** Return a type string (with dot path if any) from the given object */
    public static function typeOf(obj:Dynamic):String {

        if (Std.is(obj, String)) return 'String';
        if (Std.is(obj, Int)) return 'Int';
        if (Std.is(obj, Float)) return 'Float';
        if (Std.is(obj, Bool)) return 'Bool';
        if (Std.is(obj, Array)) return 'Array';
        if (Std.is(obj, Map)) return 'Map';

        if (Std.is(obj, RuntimeItem)) {
            var item:RuntimeItem = cast obj;
            switch (item) {
                case ExtensionItem(item, extendedType):
                    return typeOf(item);
                case ClassFieldItem(rawItem):
                    return typeOf(rawItem);
                case ClassItem(rawItem, moduleId, name):
                    return 'Class<' + name + '>';
                case EnumItem(rawItem, moduleId, name):
                    return 'Enum<' + name + '>';
                case EnumFieldItem(rawItem, name, numArgs):
                    return name.substring(0, name.lastIndexOf('.'));
                case PackageItem(pack):
                    return 'Dynamic';
                default:
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
            var resolvedType = imports.resolve(rawType.substring(6, rawType.length-1));
            if (resolvedType != null) {
                switch (resolvedType) {
                    case ClassItem(rawItem, moduleId, name):
                        result = 'Class<' + name + '>';
                    default:
                }
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
        }

        return result;

    } //toResolvedType

} //TypeUtils
