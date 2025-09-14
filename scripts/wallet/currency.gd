class_name Currency

var id: int = -1
var name: String = ""
var desc: String = ""
var icon: Texture2D = null
var value: int = 0

var onUpdate: Dictionary; #key = String, value = Callable

func _init(id: int, name: String, desc: String, icon: Texture2D, value: int) -> void:
	self.id = id
	self.name = name
	self.desc = desc
	self.icon = icon
	self.value = value

func update(value: int):
	self.value = value;
	for key in onUpdate:
		onUpdate[key].call(value);

func subscribeOnUpdate(key: String, callable: Callable):
	onUpdate[key] = callable;

func unsubscribeOnUpdate(key: String):
	onUpdate.erase(key);
