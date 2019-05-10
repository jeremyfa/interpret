package interpret;

import interpret.Types.RuntimeItem;
@:allow(interpret.TypeUtils)
@:allow(interpret.Interpreter)
class DynamicAbstractValue {

    public var value:Dynamic;

    public var abstractItem:RuntimeItem;

    public function new(abstractItem:RuntimeItem, value:Dynamic) {
        this.value = value;
        this.abstractItem = abstractItem;
    }

} //DynamicAbstractValue
