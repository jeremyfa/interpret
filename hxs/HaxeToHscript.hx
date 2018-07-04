package hxs;

import hxs.Types;

using StringTools;

class HaxeToHscript {

    var haxe(default,null):String;

    var hscript(default,null):String;

    public var imports(default,null):Array<TImport>;

    public var fields(default,null):Array<TField>;

    public var metas(default,null):Array<TMeta>;

    public var comments(default,null):Array<TComment>;

    public function new(haxe:String) {

        this.haxe = haxe;

    } //new

/// Convert

    var output:StringBuf = null;

    var i = 0;

    var len = 0;

    var c = '';

    var cc = '';

    var after = '';

    var openBraces = 0;

    var openParens = 0;

    var openBrackets = 0;

    public function convert():Void {

        // Reset data
        //
        imports = [];
        fields = [];
        comments = [];
        metas = [];
        hscript = null;

        output = new StringBuf();
        i = 0;
        len = 0;
        c = '';
        cc = '';
        after = '';

        openBraces = 0;
        openParens = 0;
        openBrackets = 0;

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

    function consumeExpression(until:String):{stop:String, expr:String} {

        var untilMap = UNTIL_MAPS[until];
        if (untilMap == null) fail('Invalid expression until: $until');

        var expr = new StringBuf();

        var openParensStart = openParens;
        var openBracesStart = openBraces;
        var openBracketsStart = openBrackets;
        var stop:String = null;

        var stopAtParenClose = untilMap.exists(')');
        var stopAtBraceClose = untilMap.exists('}');
        var stopAtBracketClose = untilMap.exists(']');
        var stopAtComa = untilMap.exists(',');

        while (i < len) {
            updateCAndCC();

            if (cc == '//') {
                consumeSingleLineComment(expr);
            }
            else if (cc == '/*') {
                consumeMultiLineComment(expr);
            }
            else if (c == '@') {
                consumeMeta(expr);
            }
            else if (c == '\'') {
                consumeSingleQuotedString(expr);
            }
            else if (c == '"') {
                consumeDoubleQuotedString(expr);
            }
            else if (c == '(') {
                openParens++;
                i++;
            }
            else if (c == '{') {
                openBraces++;
                i++;
            }
            else if (c == '[') {
                openBrackets++;
                i++;
            }
            else if (c == ')') {
                if (stopAtParenClose && openParens == openParensStart && openBraces == openBracesStart && openBrackets == openBracketsStart) {
                    stop = c;
                    break;
                }
                openParens--;
                i++;
            }
            else if (c == '}') {
                if (stopAtBraceClose && openParens == openParensStart && openBraces == openBracesStart && openBrackets == openBracketsStart) {
                    stop = c;
                    break;
                }
                openBraces--;
                i++;
            }
            else if (c == ']') {
                if (stopAtBracketClose && openParens == openParensStart && openBraces == openBracesStart && openBrackets == openBracketsStart) {
                    stop = c;
                    break;
                }
                openBrackets--;
                i++;
            }
            else if (c == ',') {
                if (stopAtComa && openParens == openParensStart && openBraces == openBracesStart && openBrackets == openBracketsStart) {
                    stop = c;
                    break;
                }
                i++;
            }
            else {
                expr.add(c);
                i++;
            }
        }

        return {
            stop: stop,
            expr: expr.toString()
        };

    } //consumeExpression

    function consumeSingleLineComment(?expr:StringBuf) {

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

        if (expr != null) {
            // Nothing to add
        } else {
            comment.content = cleanComment(content.toString());
            comments.push(comment);
        }

    } //consumeSingleLineComment

    function consumeMultiLineComment(?expr:StringBuf) {

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

        if (expr != null) {
            // Nothing to add
        } else {
            comment.content = cleanComment(content.toString());
            comments.push(comment);
        }

    } //consumeMultiLineComment

    function consumeSingleQuotedString(?expr:StringBuf) {

        // TODO
        // convert string interpolation

    } //consumeSingleQuotedString

    function consumeDoubleQuotedString(?expr:StringBuf) {

        // TODO

    } //consumeDoubleQuotedString

    function consumeMeta(?expr:StringBuf) {
        updateAfter();

        if (!RE_META.match(after)) {
            fail('Invalid meta', i);
        }

        var name = (RE_META.matched(1) != null ? RE_META.matched(1) : '') + RE_META.matched(2);
        var spaces = RE_META.matched(3);
        var paren = RE_META.matched(4);

        var meta:TMeta = {
            pos: i,
            name: (RE_META.matched(1) != null ? RE_META.matched(1) : '') + RE_META.matched(2),
            args: null
        };

        i += RE_META.matched(0).length;

        if (paren == '(') {
            openParens++;
            meta.args = [];
            var result;
            do {
                result = consumeExpression(',)');
                if (result.expr != '') {
                    meta.args.push(result.expr);
                }
                i++;
            }
            while (result.stop == ',');
            openParens--;
        }

        if (expr != null) {
            // Nothing to add
        } else {
            metas.push(meta);
        }

    } //consumeMeta

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

/// Until maps

    static var UNTIL_MAPS = [
        ',)' => [',' => true, ')' => true]
    ];

/// Regular expressions

    static var RE_BEFORE_COMMENT_LINE = ~/^[\s\*]*(\/\/)?\s*/g;

    static var RE_AFTER_COMMENT_LINE = ~/[\s\*]*$/g;

    static var RE_META = ~/^@(:)?([a-zA-Z_][a-zA-Z_0-9]*)(\s*)(\()?/g;

} //HaxeToHscript
