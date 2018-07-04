package hxs;

import hxs.Types;
import hxs.HaxeToHscript;

/** A class loaded at runtime from a haxe-compatible source file.
    Tries to stay as close as possible to haxe syntax.
    Works by converting the provided haxe source code into hscript code,
    then executes it with an extended hscript interpreter. */
class DynamicClass {

/// Properties

    var haxe:String;

    var hscript:String;

    var options:DynamicClassOptions;

    var imports:Array<TImport>;

    var fields:Array<TField>;

    var metas:Array<TMeta>;

    var comments:Array<TComment>;

/// Lifecycle

    public function new(haxe:String, ?options:DynamicClassOptions) {

        this.haxe = haxe;
        this.options = options != null ? options : cast {};

        var converter = new HaxeToHscript(haxe);
        converter.convert();

        imports = converter.imports;
        fields = converter.fields;
        metas = converter.metas;
        comments = converter.comments;

    } //new

} //DynamicClass

typedef DynamicClassOptions = {

} //DynamicClassOptions
