package test.native;

class NativeClass {

    public var origin:String = null;

    private function new(origin:String) {

        this.origin = origin;

    } //new

    public function getDoubleOrigin() {

        return this.origin + ' ' + origin;

    } //getDoubleOrigin

    public function getDoubleOrigin2() {

        return '${this.origin} ' + origin;

    } //getDoubleOrigin

} //NativeClass
