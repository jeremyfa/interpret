package test.script;

class BasicClass {

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

    public function bonjour(firstName:String, lastName:String = 'Snow'):Void {

        // Last name with default value
        trace('Bonjour $firstName $lastName.');

    } //bonjour

    public static function staticHello(subject:String):Void {

        // Basic string concatenation
        trace('Static Hello ' + subject);

    } //staticHello

} //BasicClass
