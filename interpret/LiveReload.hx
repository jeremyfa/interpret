package interpret;

@:allow(interpret.StandardWatcher)
class LiveReload {

/// Statics

    public static var defaultWatcher:Watcher = null;

    static var started:Bool = false;

    static var onceStart:Array<?Watcher->Void> = [];

    static var tickCallbacks:Array<Float->Void> = [];

    static var _tickCallbacks:Array<Float->Void> = [];

    public static function start():Void {

        if (started) return;
        started = true;

        if (defaultWatcher == null) {
            defaultWatcher = new StandardWatcher();
        }

        var toStart = [].concat(onceStart);
        onceStart = null;
        for (cb in toStart) {
            cb();
        }

    } //start

    public static function tick(delta:Float):Void {

        // We call tick callbacks when iterating on a copy,
        // to ensure the callback list won't be modified when iterating on it

        var len = tickCallbacks.length;

        for (i in 0...len) {
            _tickCallbacks[i] = tickCallbacks[i];
        }

        for (i in 0...len) {
            _tickCallbacks[i](delta);
        }

    } //tick

/// Public properties

    public var path(default,null):String;

    public var onUpdate(default,null):String->Void;

    public var stop(default,null):Void->Void;

/// Lifecycle

    public function new(path:String, onUpdate:String->Void) {

        this.path = path;
        this.onUpdate = onUpdate;

        if (started) {
            watch();
        }
        else {
            onceStart.push(watch);
        }

    } //new

/// Public API

    public function watch(?watcher:Watcher):Void {

        if (watcher == null) {
            watcher = defaultWatcher;
        }

        stop = watcher.watch(path, onUpdate);

    } //watch

} //LiveReload
