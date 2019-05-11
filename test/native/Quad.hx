package test.native;

class Quad {

    public var color:Color = Color.WHITE;

    public function new() {
        //
    }

    public function colorInfo():String {
        return 'isInt=' + (Std.is(color, Int) ? '1' : '0') + ' / ' + color.toWebString();
    }

} //Quad
