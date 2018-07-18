package interpret;

class ParentClass {

    var someParentProp:String = null;

    function new() {}

    public function someParentStuff() {
        trace('HELLO FROM PARENT ' + this);
    }

    public static function somParentStaticStuff() {
        trace('HELLO FROM STATIC PARENT');
    }

} //ParentClass
