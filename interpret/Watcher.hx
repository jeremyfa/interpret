package interpret;

interface Watcher {

    function watch(path:String, onUpdate:String->Void):Void->Void;

} //Watcher
