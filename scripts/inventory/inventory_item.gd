class_name InventoryItem
extends  RefCounted

var id: int = -1
var name: String = ""
var desc: String = ""
var stack: int = 1
var maxStack: int = 64;
var icon: Texture2D = null

func _init(id: int, name: String, desc: String, stack: int, maxStack: int, icon: Texture2D) -> void:
	self.id = id
	self.name = name
	self.desc = desc
	self.stack = stack
	self.maxStack = maxStack
	self.icon = icon