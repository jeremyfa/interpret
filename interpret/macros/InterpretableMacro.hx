package interpret.macros;

import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

class InterpretableMacro {

    macro static public function build():Array<Field> {

        var fields = Context.getBuildFields();

        var hasFieldsWithInterpretMeta = false;

        var currentPos = Context.currentPos();

        for (field in fields) {

            if (hasInterpretMeta(field)) {

                switch (field.kind) {
                    case FFun(fn):
                        hasFieldsWithInterpretMeta = true;

                        if (field.name == 'new') {
                            throw "@interpret is not allowed on constructor";
                        }

                        // Is it a static call?
                        var isStatic = field.access.indexOf(AStatic) != -1;

                        // Do we return something or is this a Void method?
                        var isVoidRet = false;
                        if (fn.ret == null) {
                            // Need to check content to find return type
                            isVoidRet = true; 
                            var printer = new haxe.macro.Printer();
                            var lines = printer.printExpr(fn.expr).split("\n");
                            for (i in 0...lines.length) {
                                var line = lines[i];
                                if (line.ltrim().startsWith('return ')) {
                                    isVoidRet = false;
                                    break;
                                }
                                else if (line.trim() == 'return;') {
                                    break;
                                }
                            }
                        }
                        else {
                            switch (fn.ret) {
                                case TPath(p):
                                    if (p.name == 'Void') {
                                        isVoidRet = true;
                                    }
                                default:
                            }
                        }

                        // Compute dynamic call args
                        var dynCallArgsArray = [for (arg in fn.args) macro $i{arg.name}];
                        var dynCallArgs = fn.args.length > 0 ? macro $a{dynCallArgsArray} : macro null;
                        var dynCallName = field.name;

                        // Ensure expr is surrounded with a block
                        switch (fn.expr.expr) {
                            case EBlock(exprs):
                            default:
                                fn.expr.expr = EBlock([{
                                    pos: fn.expr.pos,
                                    expr: fn.expr.expr
                                }]);
                        }

                        // Compute (conditional) dynamic call expr
                        var dynCallExpr = switch [isStatic, isVoidRet] {
                            case [true, true]: macro if (__interpretClass != null) {
                                __interpretClass.call($v{dynCallName}, $dynCallArgs);
                                return;
                            };
                            case [true, false]: macro if (__interpretClass != null) {
                                return __interpretClass.call($v{dynCallName}, $dynCallArgs);
                            };
                            case [false, true]: macro if (__interpretInstance != null) {
                                __interpretInstance.call($v{dynCallName}, $dynCallArgs);
                                return;
                            };
                            case [false, false]: macro if (__interpretInstance != null) {
                                return __interpretInstance.call($v{dynCallName}, $dynCallArgs);
                            };
                        }

                        // Add dynamic call expr
                        switch (fn.expr.expr) {
                            case EBlock(exprs):
                                exprs.unshift(dynCallExpr);
                            default:
                        }

                        // TODO remove
                        //var printer = new Printer();
                        //trace(printer.printExpr(fn.expr));

                    default:
                        throw "@interpret meta only works on functions";
                }
            }

        }

        if (hasFieldsWithInterpretMeta) {

            // Add dynamic class field
            fields.push({
                pos: currentPos,
                name: '__interpretClass',
                kind: FVar(macro :interpret.DynamicClass, macro null),
                access: [AStatic],
                doc: '',
                meta: [{
                    name: ':noCompletion',
                    params: [],
                    pos: currentPos
                }]
            });

            // Add dynamic instance field
            fields.push({
                pos: currentPos,
                name: '__interpretInstance',
                kind: FVar(
                    macro :interpret.DynamicInstance,
                    macro __interpretClass != null ? __interpretClass.createInstance() : null
                ),
                access: [],
                doc: '',
                meta: [{
                    name: ':noCompletion',
                    params: [],
                    pos: currentPos
                }]
            });

        }

        return fields;

    } //build

    static function hasInterpretMeta(field:Field):Bool {

        if (field.meta == null || field.meta.length == 0) return false;

        for (meta in field.meta) {
            if (meta.name == 'interpret') {
                return true;
            }
        }

        return false;

    } //hasInterpretMeta

} //InterpretableMacro
