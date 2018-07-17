package interpret;

#if (!macro && interpretable)
@:autoBuild(interpret.macros.InterpretableMacro.build())
#end
interface Interpretable {

    //function reload():Void;

} //Interpretable
