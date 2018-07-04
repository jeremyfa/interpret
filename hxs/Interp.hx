package hxs;

class Interp extends hscript.Interp {

/// Properties

    var oldLocals:Array<Int> = [];

/// Helpers

    public function beginBlock() {

        oldLocals.push(declared.length);

    } //beginBlock

    public function endBlock() {

        restore(oldLocals.pop());

    } //endBlock

/// Overrides

    override function resolve(id:String):Dynamic {
        if (id == 'this') return variables;
        var l = locals.get(id);
        if (l != null) {
            return l.r;
        }
        var v = variables.get(id);
        if (v == null) return null;
        return v;
    }

    override function get(o:Dynamic, f:String):Dynamic {
        if (o == variables) {
            return variables.get(f);
        }
        return super.get(o, f);
    }

    override function set(o:Dynamic, f:String, v:Dynamic):Dynamic {
        if (o == variables) {
            variables.set(f, v);
        }
        return super.set(o, f, v);
    }

} //Interp
