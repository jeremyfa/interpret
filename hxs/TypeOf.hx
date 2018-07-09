package hxs;

class TypeOf {

    public static function typeOf(obj:Dynamic):String {

        if (Std.is(obj, String)) return 'String';
        if (Std.is(obj, Int)) return 'Int';
        if (Std.is(obj, Float)) return 'Float';
        if (Std.is(obj, Bool)) return 'Bool';
        if (Std.is(obj, Array)) return 'Array';
        if (Std.is(obj, Map)) return 'Map';

        if (Std.is(obj, Class)) {
            return 'Class<'+Type.getClassName(obj)+'>';
        }

        var clazz = Type.getClass(obj);
        if (clazz != null) {
            return Type.getClassName(clazz);
        }

        return 'Dynamic';

    } //String

} //TypeOf
