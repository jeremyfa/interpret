package test;

import js.node.Path;
import js.node.ChildProcess.spawnSync;

using buddy.Should;
using StringTools;

class Test extends buddy.SingleSuite {

    public function new() {

#if js
        try {
            untyped require('source-map-support').install();
        } catch (e:Dynamic) {}
#end

        describe("Interpret", {

            it("should load and run a basic dynamic class", {
                run('basic_class').should.be('hello');
            });

            it("should handle preprocessor defines in script", {
                // TODO
            });

        });
        
    } //new

    /** Every `run` is rebuilding and running a new host based on the given preset
        (a preset become a preprocessor define when compiling haxe) */
    function run(preset:String):String {

        // Compile
        var proc = spawnSync('haxe', [
            '-main', 'test.Host',
            '-D', preset,
            '-cp', '.',
            '-lib', 'hxnodejs',
            '-lib', 'hscript',
            '-js', 'host.js',
            '-debug',
            '-D', 'interpretable',
            '-dce', 'no'
        ], {
            cwd: js.Node.__dirname,
            stdio: 'inherit'
        });

        // Run
        proc = spawnSync('node', [
            'host.js'
        ], {
            cwd: js.Node.__dirname
        });

        var out = '' + proc.stdout;
        var err = '' + proc.stderr;

        if (out.trim() != '') {
            return out.trim();
        }
        else if (err.trim() != '') {
            return err.trim();
        }
        else return '';

    } //run

}