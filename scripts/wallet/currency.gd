class_name Currency

var id: int = -1
var name: String = ""
var desc: String = ""
var icon: Texture2D = null
var value: int = 0

var onUpdate: Dictionary; #key = String, value = Callable

func _init(p_id: int, p_name: String, p_desc: String, p_icon: Texture2D, p_value: int) -> void:
	self.id = p_id
	self.name = p_name
	self.desc = p_desc
	self.icon = p_icon
	self.value = p_value

func update(updateAmount: int):
	if updateAmount == 0:
		return
	self.value += updateAmount;
	for key in onUpdate:
		onUpdate[key].call(self.value);

func subscribeOnUpdate(key: String, callable: Callable):
	onUpdate[key] = callable;

func unsubscribeOnUpdate(key: String):
	onUpdate.erase(key);
