package interpret;

@:structInit
class ModuleOptions {

    public var interpretableOnly:Bool = false;

    public var allowUnresolvedImports:Bool = false;

    public var extendingClassName:String = null;

    public var extendedClassName:String = null;

} //ModuleOptions
