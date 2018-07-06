{

    function new(name) {
        
        this.name = name;

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
