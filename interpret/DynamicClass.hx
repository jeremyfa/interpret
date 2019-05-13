package interpret;

import interpret.ModuleOptions;
import interpret.ResolveUsings;
import interpret.ResolveImports;
import interpret.Types;
import interpret.ConvertHaxe;
import hscript.Expr as HscriptExpr;
import hscript.Parser as HscriptParser;

using StringTools;

/** A class loaded at runtime from a haxe-compatible source file.
    Tries to stay as close as possible to haxe syntax.
    Works by converting the provided haxe source code into hscript code,
    then executes it with an extended hscript interpreter. */
@:allow(interpret.DynamicInstance)
@:allow(interpret.Interpreter)
@:allow(interpret.TypeUtils)
class DynamicClass {

    @:noCompletion
    public static var _contextType:Class<Dynamic> = null;

    static var NO_ARGS:Array<Dynamic> = [];

/// Properties

    public var classHscript(default,null):String;

    public var instanceHscript(default,null):String;

    public var env(default,null):Env;

    public var skipFields(default,null):Map<String,Bool> = null;

    var didComputeSuperClass:Bool = false;

    var superDynamicClass:DynamicClass = null;

    var superStaticClass:Class<Dynamic> = null;

    var superStaticClassInstanceFields:Map<String,Bool> = null;

    var interpreter:Interpreter = null;

    var classProgram:HscriptExpr;

    var instanceProgram:HscriptExpr;

    var classGetters:Map<String,Bool>;

    var classSetters:Map<String,Bool>;

    var classMethods:Map<String,Bool>;

    var classVars:Map<String,Bool>;

    var instanceGetters:Map<String,Bool>;

    var instanceSetters:Map<String,Bool>;

    var instanceMethods:Map<String,Bool>;

    var instanceVars:Map<String,Bool>;

    var options:DynamicClassOptions;

    var className:String = null;

    var classPropertyList:Array<String>;

    var instanceProperties:Array<String>;

    public var imports(default,null):ResolveImports = null;

    public var usings(default,null):ResolveUsings = null;

    public var packagePath(default,null):String;

    public var instanceType(default,null):String;

    public var classType(default,null):String;

    var context:Map<String,Dynamic> = null;

    var _contextArgs:Array<Dynamic> = null;

/// Lifecycle

    public function new(env:Env, options:DynamicClassOptions) {

        this.env = env;
        this.options = options;

        skipFields = this.options.skipFields;

        computeHscript();

    } //new

/// Public API

    public function createInstance(?args:Array<Dynamic>, ?superInstance:Dynamic) {

        initIfNeeded();

        var instance = new DynamicInstance(this);
        instance.init(args, superInstance);

        return instance;

    } //createInstance

    public function get(name:String, unwrap:Bool = true):Dynamic {

        initIfNeeded();

        if (!classVars.exists(name) && !classMethods.exists(name)) {
            if (superDynamicClass != null || superStaticClass == null) {
                var superClass = this.superDynamicClass;
                var exists = false;
                while (superClass != null) {
                    if (superClass.classVars.exists(name) || superClass.classMethods.exists(name)) {
                        exists = true;
                        break;
                    }
                    if (superClass.superDynamicClass == null && superClass.superStaticClass != null) {
                        exists = true; // We assume we are calling something on native that exists
                        break;
                    }
                    superClass = superClass.superDynamicClass;
                }
                if (!exists) {
                    return unwrap ? null : Unresolved.UNRESOLVED;
                }
            }
            else if (!Reflect.hasField(superStaticClass, name)) {
                return unwrap ? null : Unresolved.UNRESOLVED;
            }
        }

        var prevSelf = interpreter._self;
        interpreter._self = context;

        var rawRes = interpreter.get(context, name);
        var result = unwrap ? TypeUtils.unwrap(rawRes, env) : rawRes;

        interpreter._self = prevSelf;

        return result;

    } //get

    public function isMethod(name:String):Bool {

        return classMethods.exists(name);

    } //isMethod

    public function exists(name:String):Bool {

        initIfNeeded();

        if (!classVars.exists(name) && !classMethods.exists(name)) {
            if (superDynamicClass != null || superStaticClass == null) {
                var superClass = this.superDynamicClass;
                var exists = false;
                while (superClass != null) {
                    if (superClass.classVars.exists(name) || superClass.classMethods.exists(name)) {
                        exists = true;
                        break;
                    }
                    if (superClass.superDynamicClass == null && superClass.superStaticClass != null) {
                        exists = true; // We assume we are calling something on native that exists
                        break;
                    }
                    superClass = superClass.superDynamicClass;
                }
                if (!exists) {
                    return false;
                }
            }
            else if (!Reflect.hasField(superStaticClass, name)) {
                return false;
            }
        }

        var prevUnresolved = interpreter._unresolved;
        interpreter._unresolved = Unresolved.UNRESOLVED;

        var result = get(name);

        interpreter._unresolved = prevUnresolved;

        return result != Unresolved.UNRESOLVED;

    } //exists

    public function set(name:String, value:Dynamic, unwrap:Bool = true):Dynamic {

        initIfNeeded();

        var prevSelf = interpreter._self;
        interpreter._self = context;

        var rawRes = interpreter.set(context, name, value);
        var result = unwrap ? TypeUtils.unwrap(rawRes, env) : rawRes;

        interpreter._self = prevSelf;

        return result;

    } //set

    public function call(name:String, ?args:Array<Dynamic>, unwrap:Bool = true, ?argTypes:Array<String>):Dynamic {

        initIfNeeded();

        var prevSelf = interpreter._self;
        
        interpreter._self = context;

        var method = interpreter.get(context, name);

        interpreter._self = prevSelf;

        if (method == null) {
            throw 'Class method not found: $this $name';
        }

        if (args != null && args.length > 0 && argTypes != null) {
            var _args = [];
            for (i in 0...args.length) {
                _args.push(TypeUtils.wrapIfNeeded(args[i], argTypes[i], env));
            }
            args = _args;
        }

        var rawRes = Reflect.callMethod(null, method, args != null ? args : NO_ARGS);
        return unwrap ? TypeUtils.unwrap(rawRes, env) : rawRes;

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
        var interpretableOnly = options.moduleOptions != null ? options.moduleOptions.interpretableOnly : false;
        var allowUnresolvedImports = options.moduleOptions != null ? options.moduleOptions.allowUnresolvedImports : false;
        var interpretableField = false;
        classGetters = new Map();
        classSetters = new Map();
        classMethods = new Map();
        classVars = new Map();
        instanceGetters = new Map();
        instanceSetters = new Map();
        instanceMethods = new Map();
        instanceVars = new Map();
        classPropertyList = [];
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
                        if (!importsReady) imports.pack = data.path;
                
                    case TImport(data):
                        if (!importsReady) imports.addImport(data, allowUnresolvedImports);
                    
                    case TUsing(data):
                        if (!usingsReady) usings.addUsing(data, allowUnresolvedImports);

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
                    if (data.kind == VAR && !interpretableOnly && (skipFields == null || !skipFields.exists(data.name))) {
                        if (modifiers.exists('static')) {
                            classVars.set(data.name, true);
                            classPropertyList.push(data.name);
                            if (data.get == 'get') {
                                classGetters.set(data.name, true);
                            }
                            if (data.set == 'set') {
                                classSetters.set(data.name, true);
                            }
                            if (data.expr != null) staticDefaults.push([data.name, data.expr]);
                        } else {
                            instanceVars.set(data.name, true);
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
                    // Reset modifiers and meta
                    modifiers = new Map<String,Bool>();
                    interpretableField = false;

                default:
            }
        }

        // Static/Class defaults, to be executed once and
        // then shared by interpreted to all instances
        classResult.add(indent);
        classResult.add('function __defaults(');
        classResult.add(className);
        classResult.add(') {\n');
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
        instanceResult.add('function __defaults(');
        instanceResult.add(className);
        instanceResult.add(', this) {\n');
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
        interpretableField = false;
        for (token in classTokens) {
            switch (token) {

                case TModifier(data):
                    modifiers.set(data.name, true);
                
                case TMeta(data):
                    if (data.name == 'interpret') {
                        interpretableField = true;
                    }

                case TField(data):
                    if (data.kind == METHOD && (!interpretableOnly || interpretableField) && (skipFields == null || !skipFields.exists(data.name))) {
                        var isStatic = modifiers.exists('static');
                        var result = isStatic ? classResult : instanceResult;
                        if (isStatic) {
                            classMethods.set(data.name, true);
                        }
                        else {
                            instanceMethods.set(data.name, true);
                        }
                        result.add(indent);
                        result.add('function ');
                        result.add(data.name);
                        result.add('(');
                        result.add(className);
                        if (!isStatic) {
                            result.add(', this');
                        }
                        var i = 0;
                        var hasDefaultValues = false;
                        for (arg in data.args) {
                            result.add(', ');
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
                    // Reset modifiers and meta
                    modifiers = new Map<String,Bool>();
                    interpretableField = false;

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

        /*Sys.println('-- BEGIN INST --');
        Sys.println(instanceHscript);
        Sys.println('-- END INST --');
        Sys.println('-- BEGIN STATIC --');
        Sys.println(classHscript);
        Sys.println('-- END STATIC --');*/

    } //computeHscript

    function computeSuperClass() {

        didComputeSuperClass = true;
        var superClassType = env.getSuperClass(instanceType);
        if (superClassType != null) {
            var module:DynamicModule = null;
            var prefix = superClassType + '.';
            var alias = env.aliases.get(superClassType);
            var aliasPrefix = alias + '.';
            for (modulePath in env.modules.keys()) {
                if (modulePath == superClassType || modulePath.startsWith(prefix)) {
                    module = env.modules.get(modulePath);
                    break;
                }
                if (alias != null) {
                    if (modulePath == alias || modulePath.startsWith(aliasPrefix)) {
                        module = env.modules.get(modulePath);
                        break;
                    }
                }
            }
            if (module != null) {
                var targetItem:RuntimeItem = null;
                targetItem = module.items.get(superClassType);
                if (alias != null) {
                    targetItem = module.items.get(alias);
                }
                if (targetItem != null) {
                    switch (targetItem) {
                        case ClassItem(rawItem, moduleId, name):
                            superDynamicClass = env.resolveDynamicClass(moduleId, name);

                            if (superDynamicClass == null) {
                                var prevSelf = interpreter._self;
                                interpreter._self = context;
                                superStaticClass = TypeUtils.unwrap(interpreter.resolveInstanciable(name), env);
                                interpreter._self = prevSelf;
                            }

                        default:
                    }
                }
            }
        }

    } //computeSuperClass

    function superStaticClassHasInstanceField(name:String):Bool {

        if (superStaticClass == null) return false;

        if (superStaticClassInstanceFields == null) {
            var list = Type.getInstanceFields(superStaticClass);
            superStaticClassInstanceFields = new Map();
            for (i in 0...list.length) {
                superStaticClassInstanceFields.set(list[i], true);
            }
        }

        return superStaticClassInstanceFields.exists(name);

    } //superStaticClassHasInstanceField

    inline public function initIfNeeded() {

        if (interpreter == null) init();

    } //initIfNeeded

    function init() {

        // Don't init multiple times but cope with calling init multiple times
        if (interpreter != null) return;

        // Create context
        context = new Map();
        context.set('__interpretType', classType);
        context.set('__interpretClass', this);
        if (_contextType == null) _contextType = Type.getClass(context);
        _contextArgs = [context];

        // Create class interpreter
        interpreter = new Interpreter(this, className);

        // Feed the interpreter with our program
        interpreter.execute(classProgram);

        // Set all properties to null
        // Will ensure their key exists in variables map
        for (prop in classPropertyList) {
            context.set(prop, null);
        }

        // Assign getters
        interpreter.getters = classGetters;

        // Generate instance variables
        var __defaults = interpreter.variables.get('__defaults');
        __defaults(context);

        // Assign setters
        interpreter.setters = classSetters;

        // Compute super class
        if (!didComputeSuperClass) computeSuperClass();
        if (superDynamicClass != null) {
            instanceVars.set('super', true);
        }

    } //init

/// Print

    public function toString() {

        return 'DynamicClass($instanceType)';

    } //toString

} //DynamicClass

typedef DynamicClassOptions = {

    @:optional var targetClass:String;

    @:optional var indent:String;

    @:optional var haxe:String;

    @:optional var tokens:Array<Token>;

    @:optional var imports:ResolveImports;

    @:optional var usings:ResolveUsings;

    @:optional var moduleOptions:ModuleOptions;

    @:optional var skipFields:Map<String,Bool>;

} //DynamicClassOptions
