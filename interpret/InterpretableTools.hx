package interpret;

using StringTools;

class InterpretableTools {

    public static function createInterpretClass(classPack:Array<String>, className:String, content:String, originalContent:String):DynamicClass {

        // Create env
        var env = new Env();
        env.addDefaultModules();
        env.addModule('interpret.Interpretable', DynamicModule.fromStatic(interpret.Interpretable));

        var extendingClassName = className + '_interpretable';
        var extendingClassPath = extendingClassName;
        if (classPack.length > 0) extendingClassPath = classPack.join('.') + '.' + extendingClassPath;

        Env.configureInterpretableEnv(env);

        env.addModule(extendingClassPath, DynamicModule.fromString(env, extendingClassName, content, {
            interpretableOnly: true,
            interpretableOriginalContent: originalContent,
            allowUnresolvedImports: true,
            extendingClassName: extendingClassName,
            extendedClassName: className
        }));

        env.link();

        var dynClass = env.modules.get(extendingClassPath).dynamicClasses.get(extendingClassName);

        return dynClass;

    } //createInterpretClass

} //InterpretableTools
