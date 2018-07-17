package interpret;

import interpret.ResolveUsings;
import interpret.ResolveImports;
import interpret.Types;
import interpret.ConvertHaxe;
import hscript.Expr as HscriptExpr;
import hscript.Parser as HscriptParser;

/** A class loaded at runtime from a haxe-compatible source file.
    Tries to stay as close as possible to haxe syntax.
    Works by converting the provided haxe source code into hscript code,
    then executes it with an extended hscript interpreter. */
@:allow(interpret.DynamicInstance)
@:allow(interpret.Interpreter)
@:allow(interpret.TypeUtils)
class DynamicClass {

/// Properties

    public var classHscript(default,null):String;

    public var instanceHscript(default,null):String;

    public var env(default,null):Env;

    var interpreter:Interpreter = null;

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

    } //new

/// Public API

    public function createInstance(?args:Array<Dynamic>) {

        if (interpreter == null) initInterpreter();

        var instance = new DynamicInstance(this);
        instances.push(instance);
        instance.init(args);
        return instance;

    } //createInstance

    public function get(name:String):Dynamic {

        if (interpreter == null) initInterpreter();

        return TypeUtils.unwrap(interpreter.resolve(name));

    } //get

    public function call(name:String, args:Array<Dynamic>):Dynamic {

        if (interpreter == null) initInterpreter();

        var method = interpreter.resolve(name);
        if (method == null) {
            throw 'Method not found: $name';
        }
        return TypeUtils.unwrap(Reflect.callMethod(null, method, args));

    } //call

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
                        var isStatic = modifiers.exists('static');
                        var result = isStatic ? classResult : instanceResult;
                        result.add(indent);
                        result.add('function ');
                        result.add(data.name);
                        result.add('(');
                        /*result.add(className);
                        if (!isStatic) {
                            result.add(', this');
                        }*/
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

        Sys.println(classHscript);
        Sys.println('-------');
        Sys.println(instanceHscript);
        Sys.println('-------');
        Sys.exit(0);

    } //computeHscript

    function initInterpreter() {

        // Create class interpreter
        interpreter = new Interpreter(this, className);

        // Feed the interpreter with our program
        interpreter.execute(classProgram);

        // Set all properties to null
        // Will ensure their key exists in variables map
        for (prop in classProperties) {
            interpreter.variables.set(prop, null);
        }

        // Assign getters
        interpreter.getters = classGetters;

        // Generate instance variables
        var __defaults = interpreter.variables.get('__defaults');
        __defaults();

        // Assign setters
        interpreter.setters = classSetters;

    } //initInterpreter

} //DynamicClass

typedef DynamicClassOptions = {

    @:optional var targetClass:String;

    @:optional var indent:String;

    @:optional var haxe:String;

    @:optional var tokens:Array<Token>;

    @:optional var imports:ResolveImports;

    @:optional var usings:ResolveUsings;

} //DynamicClassOptions
