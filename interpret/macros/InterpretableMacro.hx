package interpret.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

class InterpretableMacro {

    macro static public function build():Array<Field> {

        var fields = Context.getBuildFields();

        // TODO

        return fields;

    } //build

} //InterpretableMacro
