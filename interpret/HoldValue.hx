package interpret;

@:structInit
class HoldValue {

    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
    };  

} //HoldValue
