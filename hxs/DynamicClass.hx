package hxs;

using unifill.Unifill;
using StringTools;

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

        convert();

    } //new

/// Convert

    function convert():Void {

        // Reset data
        imports = [];
        fields = [];
        comments = [];
        metas = [];
        hscript = null;

        // Initialize state
        var output = new StringBuf();
        var i = 0;
        var len = haxe.length;
        var c = '';
        var cc = '';
        var after = '';

        // Declare helpers
        //
        inline function updateC() {

            c = haxe.charAt(i);

        } //updateC

        inline function updateCC() {

            cc = haxe.substr(i, 2);

        } //updateCC

        inline function updateCAndCC() {

            updateC();
            updateCC();

        } //updateCAndCC

        inline function updateAfter() {

            after = haxe.substring(i);

        } //updateAfter

        function consumeSingleLineComment() {

            var content = new StringBuf();
            var comment:TComment = {
                pos: i,
                multiline: false,
                content: null
            };

            i += 2;

            while (i < len) {
                updateC();
                if (c == "\n") {
                    i++;
                    break;
                }
                else {
                    content.add(c);
                    i++;
                }
            }

            comment.content = cleanComment(content.toString());
            comments.push(comment);

        } //consumeSingleLineComment

        function consumeMultiLineComment() {

            var content = new StringBuf();
            var comment:TComment = {
                pos: i,
                multiline: true,
                content: null
            };

            i += 2;

            while (i < len) {
                updateCAndCC();
                if (cc == '*/') {
                    i += 2;
                    break;
                }
                else {
                    i++;
                    content.add(c);
                }
            }

            comment.content = cleanComment(content.toString());
            comments.push(comment);

        } //consumeMultiLineComment

        function consumeMeta() {
            updateAfter();

            if (!RE_META.match(after)) {
                fail('Invalid meta', i);
            }

            // TODO

        } //consumeMeta

        // Iterate over each character and generate output
        //
        while (i < len) {
            updateCAndCC();

            if (cc == '//') {
                consumeSingleLineComment();
            }
            else if (cc == '/*') {
                consumeMultiLineComment();
            }
            else if (c == '@') {
                consumeMeta();
            }

        }

        // Use result
        hscript = output.toString();

    } //convert

/// Helpers

    static function cleanComment(comment:String):String {

        var lines = [];

        // Remove noise (asterisks etc...)
        for (line in comment.split("\n")) {
            var lineLen = line.length;
            line = RE_BEFORE_COMMENT_LINE.replace(line, '');
            while (line.length < lineLen) {
                line = ' ' + line;
            }
            line = RE_AFTER_COMMENT_LINE.replace(line, '');
            lines.push(line);
        }

        if (lines.length == 0) return '';

        // Remove indent common with all lines
        var commonIndent = 99999;
        for (line in lines) {
            if (line.trim() != '') {
                commonIndent = Std.int(Math.min(commonIndent, line.length - line.ltrim().length));
            }
        }
        if (commonIndent > 0) {
            for (i in 0...lines.length) {
                lines[i] = lines[i].substring(commonIndent);
            }
        }

        return lines.join("\n").trim();

    } //cleanComment

    static function fail(error:Dynamic, ?pos:Int) {

        // TODO proper error formatting

        throw '' + error;

    } //fail

/// Regular expressions

    static var RE_BEFORE_COMMENT_LINE = ~/^[\s\*]*(\/\/)?\s*/g;

    static var RE_AFTER_COMMENT_LINE = ~/[\s\*]*$/g;

    static var RE_META = ~/^@(:)?([a-zA-Z_][a-zA-Z_0-9]*)(\s*)(\()?/g;

} //DynamicClass

typedef DynamicClassOptions = {

} //DynamicClassOptions

@:structInit
class TImport {

    public var pos:Int;

    public var path:String;

    public var alias:String = null;

} //TImport

@:structInit
class TMeta {

    public var pos:Int;

    public var name:String;

    public var args:Array<String> = null;

} //TMeta

@:structInit
class TComment {

    public var pos:Int;

    public var content:String;

    public var multiline:Bool;

} //TComment

@:structInit
class TField {

    public var pos:Int;

    public var kind:TFieldKind;

    public var args:Array<TArg> = null;

    public var get:String = null;

    public var set:String = null;

    public var expr:String = null;

} //TField

enum TFieldKind {

    METHOD;

    VAR;

} //TFieldKind

@:structInit
class TArg {

    public var pos:Int;

    public var name:String = null;

    public var type:String;

    public var expr:String;

} //TArg
