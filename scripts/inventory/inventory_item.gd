class_name InventoryItem
extends  RefCounted

var id: int = -1
var name: String = ""
var desc: String = ""
var stack: int = 1
var maxStack: int = 64;
var icon: Texture2D = null

func _init(p_id: int, p_name: String, p_desc: String, p_stack: int, p_maxStack: int, p_icon: Texture2D) -> void:
	self.id = p_id
	self.name = p_name
	self.desc = p_desc
	self.stack = p_stack
	self.maxStack = p_maxStack
	self.icon = p_icon