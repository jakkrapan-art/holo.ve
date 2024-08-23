extends CheckBox
class_name PathCheckBox

var index: int;
var object: Object;

func _init(object: Object, index: int):
	self.index = index;
	self.object = object;

func _toggled(toggled_on):
	onToggle.emit(toggled_on, index, object)

signal onToggle(toggled: bool,index: int, object: Object)
