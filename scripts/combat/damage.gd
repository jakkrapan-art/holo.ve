class_name Damage
extends RefCounted

enum DamageType
{
	PHYSIC, MAGIC, TRUE
}

var source: Node2D
var damage: int;
var type: DamageType
var isCritical: bool = false;

func _init(p_source: Node2D, amount: int, p_type: DamageType, p_isCritical: bool = false):
	self.source = p_source;
	self.damage = amount;
	self.type = p_type;
	self.isCritical = p_isCritical;
