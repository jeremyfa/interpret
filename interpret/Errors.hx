package interpret;

import haxe.CallStack;

// Some snippets from https://github.com/larsiusprime/crashdumper/blob/24e28e8fd664de922bd480502efe596665d905b8/crashdumper/CrashDumper.hx

class Errors {

    dynamic public static function handleInterpretableError(e:Dynamic):Void {

        inline function print(data:Dynamic) {
            #if sys
            Sys.println(''+data);
            #else
            trace(data);
            #end
        }

        // Get stack trace
        var stack = CallStack.exceptionStack();

        // Reverse stack
        var reverseStack = [].concat(stack);
        reverseStack.reverse();

        // Print stack trace and error
        for (item in reverseStack) {
            print(stackItemToString(item));
        }
        print('[error] ' + e);

    } //handleInterpretableError

    public static function stackItemToString(item:StackItem):String {

        var str:String = "";
        switch (item) {
            case CFunction:
                str = "a C function";
            case Module(m):
                str = "module " + m;
            case FilePos(itm,file,line):
                if (itm != null) {
                    str = stackItemToString(itm) + " (";
                }
                str += file;
                #if HXCPP_STACK_LINE
                    str += " line ";
                    str += line;
                #end
                if (itm != null) str += ")";
            case Method(cname,meth):
                str += (cname);
                str += (".");
                str += (meth);
            #if (haxe_ver >= "3.1.0")
            case LocalFunction(n):
            #else
            case Lambda(n):
            #end
                str += ("local function #");
                str += (n);
        }

        return str;

    } //stackItemToString

} //Errors
