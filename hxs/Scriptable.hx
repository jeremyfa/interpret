package hxs;

#if (!macro && hxs_scriptable)
@:autoBuild(hxs.macros.ScriptableMacro.build())
#end
interface Scriptable {

    //function reload():Void;

} //Scriptable
