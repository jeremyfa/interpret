package interpret;

class LiveReload {

    public static var defaultWatcher:Watcher = null;

    public static function watch(path:String, onUpdate:String->Void, ?watcher:Watcher):Void->Void {

        if (watcher == null) {
            if (defaultWatcher == null) {
                defaultWatcher = new StandardWatcher();
            }
            watcher = defaultWatcher;
        }

        return watcher.watch(path, onUpdate);

    } //watch

} //LiveReload
