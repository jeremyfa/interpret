package hxs;

import hxs.ResolveUsings;
import hxs.ResolveImports;
import hxs.Types;
import hxs.ConvertHaxe;
import hscript.Expr as HscriptExpr;
import hscript.Parser as HscriptParser;

/** A class loaded at runtime from a haxe-compatible source file.
    Tries to stay as close as possible to haxe syntax.
    Works by converting the provided haxe source code into hscript code,
    then executes it with an extended hscript interpreter. */
@:allow(hxs.DynamicInstance)
@:allow(hxs.Interp)
class DynamicClass {

/// Properties

    public var classHscript(default,null):String;

    public var instanceHscript(default,null):String;

    public var env(default,null):Env;

    var interp:Interp;

    var classProgram:HscriptExpr;

    var instanceProgram:HscriptExpr;

    var classGetters:Map<String,Bool>;

    var classSetters:Map<String,Bool>;

    var instanceGetters:Map<String,Bool>;

    var instanceSetters:Map<String,Bool>;

    var options:DynamicClassOptions;

    var instances:Array<DynamicInstance> = [];

    var className:String = null;

    var classProperties:Array<String>;

    var instanceProperties:Array<String>;

    var imports:ResolveImports = null;

    var usings:ResolveUsings = null;

    var packagePath:String;

    var instanceType:String;

    var classType:String;

/// Lifecycle

    public function new(env:Env, options:DynamicClassOptions) {

        this.env = env;
        this.options = options;

        computeHscript();
        initStatics();

    } //new

/// Public API

    public function createInstance(?args:Array<Dynamic>) {

        var instance = new DynamicInstance(this);
        instances.push(instance);
        instance.init(args);
        return instance;

    } //createInstance

    public function get(name:String):Dynamic {

        return interp.resolve(name);

    } //get

/// Internal

    function computeHscript() {

        var tokens:Array<Token> = null;
        if (options.tokens != null) {
            tokens = options.tokens;
        }
        else if (options.haxe != null) {
            var converter = new ConvertHaxe(options.haxe);
            converter.convert();
            tokens = converter.tokens;
        }
        else {
            throw 'Cannot create dynamic class without haxe code or tokens';
        }

        var instanceResult = new StringBuf();
        var classResult = new StringBuf();
        var targetClass = options.targetClass != null ? options.targetClass : null;
        var inTargetClass = false;
        var modifiers = new Map<String,Bool>();
        var indent = options.indent != null ? options.indent : '    ';
        var classTokens = [];
        var importsReady = false;
        var usingsReady = false;
        classGetters = new Map();
        classSetters = new Map();
        instanceGetters = new Map();
        instanceSetters = new Map();
        classProperties = [];
        instanceProperties = [];
        packagePath = null;

        if (options.imports != null) {
            importsReady = true;
            imports = options.imports;
        } else {
            imports = new ResolveImports(env);
        }

        if (options.usings != null) {
            usingsReady = true;
            usings = options.usings;
        } else {
            usings = new ResolveUsings(env);
        }

        // Extract target class token (their could be other types/classes in the same content)
        // Extract imports (shared by all classes in file)
        // Extract package
        for (token in tokens) {
            if (!inTargetClass) {
                switch (token) {

                    case TType(data):
                        if (data.kind == CLASS && (targetClass == null || data.name == targetClass)) {
                            inTargetClass = true;
                            className = data.name;
                            classTokens.push(token);
                        }
                    
                    case TPackage(data):
                        if (packagePath == null) packagePath = data.path;
                
                    case TImport(data):
                        if (!importsReady) imports.addImport(data);
                    
                    case TUsing(data):
                        if (!usingsReady) usings.addUsing(data);

                    default:
                }
            } else {
                switch (token) {

                    case TType(data):
                        inTargetClass = false;
                        break;

                    default:
                        classTokens.push(token);
                }
            }
        }

        classResult.add('{\n');
        instanceResult.add('{\n');

        // Generate properties default values
        var staticDefaults = [];
        var defaults = [];
        for (token in classTokens) {
            switch (token) {

                case TModifier(data):
                    modifiers.set(data.name, true);

                case TField(data):
                    if (data.kind == VAR) {
                        if (modifiers.exists('static')) {
                            classProperties.push(data.name);
                            if (data.get == 'get') {
                                classGetters.set(data.name, true);
                            }
                            if (data.set == 'set') {
                                classSetters.set(data.name, true);
                            }
                            if (data.expr != null) staticDefaults.push([data.name, data.expr]);
                        } else {
                            instanceProperties.push(data.name);
                            if (data.get == 'get') {
                                instanceGetters.set(data.name, true);
                            }
                            if (data.set == 'set') {
                                instanceSetters.set(data.name, true);
                            }
                            if (data.expr != null) defaults.push([data.name, data.expr]);
                        }
                    }
                    // Reset modifiers
                    modifiers = new Map<String,Bool>();

                default:
            }
        }

        // Static/Class defaults, to be executed once and
        // then shared by interpreted to all instances
        classResult.add(indent);
        classResult.add('function __defaults() {\n');
        for (item in staticDefaults) {
            classResult.add(indent);
            classResult.add(indent);
            classResult.add(className);
            classResult.add('.');
            classResult.add(item[0]);
            classResult.add(' = ');
            classResult.add(item[1]);
            classResult.add(';\n');
        }
        classResult.add(indent);
        classResult.add('}\n');

        // Instance defaults, to be executed when creating a new instance (calling new())
        instanceResult.add(indent);
        instanceResult.add('function __defaults() {\n');
        for (item in defaults) {
            instanceResult.add(indent);
            instanceResult.add(indent);
            instanceResult.add('this.');
            instanceResult.add(item[0]);
            instanceResult.add(' = ');
            instanceResult.add(item[1]);
            instanceResult.add(';\n');
        }
        instanceResult.add(indent);
        instanceResult.add('}\n');

        // Methods & Imports
        modifiers = new Map<String,Bool>();
        for (token in classTokens) {
            switch (token) {

                case TModifier(data):
                    modifiers.set(data.name, true);

                case TField(data):
                    if (data.kind == METHOD) {
                        var result = modifiers.exists('static') ? classResult : instanceResult;
                        result.add(indent);
                        result.add('function ');
                        result.add(data.name);
                        result.add('(');
                        var i = 0;
                        var hasDefaultValues = false;
                        for (arg in data.args) {
                            if (i > 0) result.add(', ');
                            if (arg.opt) {
                                if (arg.expr != null) hasDefaultValues = true;
                                result.add('?');
                            }
                            result.add(arg.name);
                        }
                        result.add(') ');
                        if (hasDefaultValues) {
                            result.add('{');
                            for (arg in data.args) {
                                if (arg.expr != null) {
                                    result.add(' if (');
                                    result.add(arg.name);
                                    result.add(' == null) ');
                                    result.add(arg.name);
                                    result.add(' = ');
                                    result.add(arg.expr);
                                    result.add(';');
                                }
                            }
                            result.add(' ');
                        }
                        result.add(data.expr);
                        if (hasDefaultValues) {
                            result.add('}');
                        }
                        result.add('\n');

                    }
                    // Reset modifiers
                    modifiers = new Map<String,Bool>();

                default:
            }
        }

        classResult.add('}\n');
        instanceResult.add('}\n');

        // Get resulting hscript code
        classHscript = classResult.toString();
        instanceHscript = instanceResult.toString();

        // Create class path
        instanceType = className;
        if (packagePath != null && packagePath != '') {
            instanceType = packagePath + '.' + instanceType;
        }
        classType = 'Class<' + instanceType + '>';

        // Create hscript programs
        var parser = new HscriptParser();
        parser.allowJSON = true;
        parser.allowMetadata = true;
        parser.allowTypes = true;
        classProgram = parser.parseString(classHscript);
        instanceProgram = parser.parseString(instanceHscript);

    } //computeHscript

    function initStatics() {

        // Create class interpreter
        interp = new Interp(this, className);

        // Feed the interpreter with our program
        interp.execute(classProgram);

        // Set all properties to null
        // Will ensure their key exists in variables map
        for (prop in classProperties) {
            interp.variables.set(prop, null);
        }

        // Assign getters
        interp.getters = classGetters;

        // Generate instance variables
        var __defaults = interp.variables.get('__defaults');
        __defaults();

        // Assign setters
        interp.setters = classSetters;

    } //initStatics

} //DynamicClass

typedef DynamicClassOptions = {

    @:optional var targetClass:String;

    @:optional var indent:String;

    @:optional var haxe:String;

    @:optional var tokens:Array<Token>;

    @:optional var imports:ResolveImports;

    @:optional var usings:ResolveUsings;

} //DynamicClassOptions
