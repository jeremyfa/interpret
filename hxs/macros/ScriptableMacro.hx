package hxs.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

class ScriptableMacro {

    macro static public function build():Array<Field> {

        var fields = Context.getBuildFields();

        // TODO

        return fields;

    } //build

} //ScriptableMacro
