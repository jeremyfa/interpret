package interpret;

using StringTools;

class InterpretableTools {

    public static function createInterpretClass(content:String):DynamicClass {

        // Create env
        var env = new Env();
        env.addDefaultModules();

        // TODO remove hardcoded logic
        
        content = content.replace('class Project extends Entity implements Interpretable', 'class Project_interpretable extends Project implements Interpretable');

        env.addModule('Project', DynamicModule.fromStatic(Project));

        env.addModule('Project_interpretable', DynamicModule.fromString(env, 'Project_interpretable', content, {
            interpretableOnly: true,
            allowUnresolvedImports: true
        }));

        env.link();

        var dynClass = env.modules.get('Project_interpretable').dynamicClasses.get('Project_interpretable');

        return dynClass;

    } //createInterpretClass

} //InterpretableTools
