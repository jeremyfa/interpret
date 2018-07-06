package hxs;

@:structInit
class TImport {

    public var pos:Int;

    public var path:String;

    @:optional public var alias:String = null;

} //TImport

@:structInit
class TUsing {

    public var pos:Int;

    public var path:String;

} //TUsing

@:structInit
class TModifier {

    public var pos:Int;

    public var name:String;

} //TModifier

@:structInit
class TMeta {

    public var pos:Int;

    public var name:String;

    @:optional public var args:Array<String> = null;

} //TMeta

@:structInit
class TComment {

    public var pos:Int;

    public var content:String;

    public var multiline:Bool;

} //TComment

@:structInit
class TField {

    public var name:String;

    public var pos:Int;

    public var kind:TFieldKind;

    public var type:String;

    @:optional public var args:Array<TArg> = null;

    @:optional public var get:String = null;

    @:optional public var set:String = null;

    @:optional public var expr:String = null;

} //TField

enum TFieldKind {

    VAR;

    METHOD;

} //TFieldKind

@:structInit
class TArg {

    public var pos:Int;

    @:optional public var name:String = null;

    public var type:String;

    @:optional public var opt:Bool = false;

    @:optional public var expr:String;

} //TArg
