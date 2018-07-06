{

    function new(name:String) {
        
        this.name = name;
        this.name = "WHAT";

        this.someMap = [
            ',)' => [',' => true, ')' => true],
            '}' => ['}' => true],
            ';' => [';' => true]
        ];

    }

    function hello():Void {

        trace('PLOP ' + name + '!');

    } //hello

} //SomeClass
