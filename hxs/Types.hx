package hxs;

@:structInit
class TImport {

    public var pos:Int;

    public var path:String;

    public var alias:String = null;

} //TImport

@:structInit
class TUsing {

    public var pos:Int;

    public var path:String;

} //TUsing

@:structInit
class TMeta {

    public var pos:Int;

    public var name:String;

    public var args:Array<String> = null;

} //TMeta

@:structInit
class TComment {

    public var pos:Int;

    public var content:String;

    public var multiline:Bool;

} //TComment

@:structInit
class TField {

    public var pos:Int;

    public var kind:TFieldKind;

    public var args:Array<TArg> = null;

    public var get:String = null;

    public var set:String = null;

    public var expr:String = null;

} //TField

enum TFieldKind {

    METHOD;

    VAR;

} //TFieldKind

@:structInit
class TArg {

    public var pos:Int;

    public var name:String = null;

    public var type:String;

    public var expr:String;

} //TArg
