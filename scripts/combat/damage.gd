class_name Damage
extends RefCounted

enum DamageType
{
	PHYSIC, MAGIC
}

var source: Node2D
var damage: int;
var type: DamageType

func _init(source: Node2D, amount: int, type: DamageType):
	self.source = source;
	self.damage = amount;
	self.type = type;
