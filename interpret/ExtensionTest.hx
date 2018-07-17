package interpret;

class ExtensionTest {

    public static function print(env:interpret.Env, name:String):String {
        return ('$name $env');
    }

}
