package test.script;

class BasicClass {

    public static var sVar1:Int = 451;

    public static var sVar2(get,set):Int;

    static function get_sVar2():Int {
        return sVar1 + 1000;
    }

    static function set_sVar2(value:Int):Int {
        BasicClass.sVar1 = value - 1000;
        return value;
    }

    public static var sVar3(get,set):Int;

    static function get_sVar3():Int {
        return sVar1 + 1001;
    }

    static function set_sVar3(value:Int):Int {
        sVar1 = value - 1001;
        return value;
    }

    public var mVar1:Float = 451.5;

    public var mVar2(get,set):Float;

    function get_mVar2():Float {
        return mVar1 + 10000.75;
    }

    function set_mVar2(value:Float):Float {
        this.mVar1 = value - 10000.75;
        return value;
    }

    public var mVar3(get,set):Float;

    function get_mVar3():Float {
        return mVar1 + 10001;
    }

    function set_mVar3(value:Float):Float {
        mVar1 = value - 10001;
        return value;
    }

    public var mVar4(get,set):Float;

    function get_mVar4():Float {
        return sVar1 + 4000;
    }

    function set_mVar4(value:Float):Float {
        sVar1 = Std.int(value - 4000);
        return value;
    }

    public var mVar5(get,set):Float;

    function get_mVar5():Float {
        return BasicClass.sVar1 + 5000;
    }

    function set_mVar5(value:Float):Float {
        BasicClass.sVar1 = Std.int(value - 5000);
        return value;
    }

    public var mVar6(get,set):Float;

    function get_mVar6():Float {
        return test.script.BasicClass.sVar1 + 6000;
    }

    function set_mVar6(value:Float):Float {
        test.script.BasicClass.sVar1 = Std.int(value - 6000);
        return value;
    }

    public function new() {

    } //new

    public function hello(subject:String):Void {

        // Basic string interpolation
        trace('Hello $subject');

    } //hello

    public function hi(subject:String):Void {

        // More advanced string interpolation
        trace('Hi ${subject+'!'}');

    } //hi

    public function isBasicClass() {

        return Std.is(this, BasicClass);

    } //isBasicClass

    public function isBasicClass2() {

        return Std.is(this, test.script.BasicClass);

    } //isBasicClass2

    public function bonjour(firstName:String, lastName:String = 'Snow'):Void {

        // Last name with default value
        trace('Bonjour $firstName $lastName.');

    } //bonjour

    public static function staticHello(subject:String):Void {

        // Basic string concatenation
        trace('Static Hello ' + subject);

    } //staticHello

} //BasicClass
