class_name Damage
extends RefCounted

enum DamageType
{
	PHYSIC, MAGIC
}

var source: Node2D
var damage: int;
var type: DamageType
var isCritical: bool = false;

func _init(source: Node2D, amount: int, type: DamageType, isCritical: bool = false):
	self.source = source;
	self.damage = amount;
	self.type = type;
	self.isCritical = isCritical;
