package interpret.macros;

import haxe.macro.TypeTools;
import haxe.io.Path;
import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

class InterpretableMacro {

    macro static public function build():Array<Field> {

        var fields = Context.getBuildFields();

#if (!display && !completion)

        var hasFieldsWithInterpretMeta = false;

        var currentPos = Context.currentPos();

        var localClass = Context.getLocalClass().get();

        var filePath = Context.getPosInfos(localClass.pos).file;
        if (!Path.isAbsolute(filePath)) {
            filePath = Path.join([Sys.getCwd(), filePath]);
        }
        filePath = Path.normalize(filePath);

        var classPack:Array<String> = localClass.pack;
        var className:String = localClass.name;

        var extraFields:Array<Field> = null;

        var dynCallBrokenNames:Array<String> = [];

        for (field in fields) {

            if (hasInterpretMeta(field)) {

                switch (field.kind) {
                    case FFun(fn):
                        hasFieldsWithInterpretMeta = true;
                        if (extraFields == null) extraFields = [];

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

                        var argTypes = [];
                        for (arg in fn.args) {
                            var type = Context.resolveType(arg.type, field.pos);
                            var typeStr = TypeTools.toString(type).replace(' ', '');
                            if (arg.opt) typeStr = '?' + typeStr;
                            argTypes.push(typeStr);
                        }

                        // Compute dynamic call args
                        var dynCallArgsArray = [for (arg in fn.args) macro $i{arg.name}];
                        var dynCallArgs = fn.args.length > 0 ? macro $a{dynCallArgsArray} : macro null;
                        var dynCallName = field.name;
                        var dynCallBrokenName = '__interpretBroken_' + field.name;
                        
                        dynCallBrokenNames.push(dynCallBrokenName);

                        extraFields.push({
                            pos: currentPos,
                            name: dynCallBrokenName,
                            kind: FVar(macro :Bool, macro false),
                            access: [APrivate, AStatic],
                            doc: '',
                            meta: [{
                                name: ':noCompletion',
                                params: [],
                                pos: currentPos
                            }]
                        });

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
                                if (!$i{dynCallBrokenName}) {
                                    try {
                                        __interpretClass.call($v{dynCallName}, $dynCallArgs, true, $v{argTypes});
                                        return;
                                    }
                                    catch (e:Dynamic) {
                                        interpret.Env.catchInterpretableException(e, __interpretClass);
                                        $i{dynCallBrokenName} = true;
                                    }
                                }
                            };
                            case [true, false]: macro if (__interpretClass != null) {
                                if (!$i{dynCallBrokenName}) {
                                    try {
                                        var res = __interpretClass.call($v{dynCallName}, $dynCallArgs, true, $v{argTypes});
                                        return res;
                                    }
                                    catch (e:Dynamic) {
                                        interpret.Env.catchInterpretableException(e, __interpretClass);
                                        $i{dynCallBrokenName} = true;
                                    }
                                }
                            };
                            case [false, true]: macro if (__interpretClass != null) {
                                if (!$i{dynCallBrokenName}) {
                                    try {
                                        if (__interpretInstance == null || __interpretInstance.dynamicClass != __interpretClass) {
                                            __interpretInstance = __interpretClass.createInstance(null, this);
                                        }
                                        __interpretInstance.call($v{dynCallName}, $dynCallArgs, true, $v{argTypes});
                                        return;
                                    }
                                    catch (e:Dynamic) {
                                        interpret.Env.catchInterpretableException(e, __interpretClass, __interpretInstance);
                                        $i{dynCallBrokenName} = true;
                                    }
                                }
                            };
                            case [false, false]: macro if (__interpretClass != null) {
                                if (!$i{dynCallBrokenName}) {
                                    try {
                                        if (__interpretInstance == null || __interpretInstance.dynamicClass != __interpretClass) {
                                            __interpretInstance = __interpretClass.createInstance(null, this);
                                        }
                                        var res = __interpretInstance.call($v{dynCallName}, $dynCallArgs, true, $v{argTypes});
                                        return res;
                                    }
                                    catch (e:Dynamic) {
                                        interpret.Env.catchInterpretableException(e, __interpretClass, __interpretInstance);
                                        $i{dynCallBrokenName} = true;
                                    }
                                }
                            };
                        }

                        // Add dynamic call expr
                        switch (fn.expr.expr) {
                            case EBlock(exprs):
                                exprs.unshift(dynCallExpr);
                            default:
                        }

                    default:
                        throw "@interpret meta only works on functions";
                }
            }

        }

        if (hasFieldsWithInterpretMeta) {

            // Add reset state
            //
            var resetBrokenCalls = [];
            for (dynCallBrokenName in dynCallBrokenNames) {
                resetBrokenCalls.push(macro $i{dynCallBrokenName} = false);
            }

            fields.push({
                pos: currentPos,
                name: '__interpretResetState',
                kind: FFun({
                    args: [],
                    ret: macro :Void,
                    expr: {
                        expr: EBlock(resetBrokenCalls),
                        pos: currentPos
                    }
                }),
                access: [APrivate, AStatic],
                doc: '',
                meta: [{
                    name: ':noCompletion',
                    params: [],
                    pos: currentPos
                }]
            });

            // Add dynamic class field
            fields.push({
                pos: currentPos,
                name: '__interpretClass',
                kind: FVar(macro :interpret.DynamicClass, macro null),
                access: [APrivate, AStatic],
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
                    macro null
                ),
                access: [APrivate],
                doc: '',
                meta: [{
                    name: ':noCompletion',
                    params: [],
                    pos: currentPos
                }]
            });

            #if interpret_watch
            // Add watcher
            fields.push({
                pos: currentPos,
                name: '__interpretWatch',
                kind: FVar(
                    macro :interpret.LiveReload,
                    macro new interpret.LiveReload($v{filePath}, function(content:String) {
                        trace('File changed at path ' + $v{filePath});
                        try {
                            __interpretClass = interpret.InterpretableTools.createInterpretClass($v{classPack}, $v{className}, content);
                        }
                        catch (e:Dynamic) {
                            interpret.Errors.handleInterpretableError(e);
                            __interpretClass = null;
                        }
                        __interpretResetState();
                    })
                ),
                access: [APrivate, AStatic],
                doc: '',
                meta: [{
                    name: ':noCompletion',
                    params: [],
                    pos: currentPos
                }]
            });
            #end

        }

        if (extraFields != null) {
            for (field in extraFields) {
                fields.push(field);
            }
        } 

#end

        return fields;

    } //build

    static function complexTypeToString(type:ComplexType):String {

        var typeStr:String = null;

        if (type != null) {
            switch (type) {
                case TPath(p):
                    typeStr = p.name;
                    if (p.pack != null && p.pack.length > 0) {
                        typeStr = p.pack.join('.') + '.' + typeStr;
                    }
                default:
                    typeStr = 'Dynamic';
            }
        }
        else {
            typeStr = 'Dynamic';
        }

        return typeStr;
    }

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
