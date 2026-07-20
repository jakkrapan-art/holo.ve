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

# Source-side amplifier snapshot, decimal (0.25 = +25%). Taken at FIRE time and
# summed into ΣAmp by Enemy.recvDamage, so it rides the amplifier position of the
# Master Formula and TRUE damage still bypasses it. Frozen on purpose: a
# projectile carries this value through its whole flight, and every enemy a
# piercing shot passes through takes the value derived from the ORIGINAL target
# (Marksman synergy).
var sourceAmp: float = 0.0

# True when a skill authored this damage. Kill attribution reads this instead of
# inferring "not a skill" from a missing source (PassiveSoulHarvest); the old
# inference relied on normal attacks failing to stamp their source, which was a
# bug, not a design.
var isSkillDamage: bool = false

func _init(p_source: Node2D, amount: int, p_type: DamageType, p_isCritical: bool = false):
	self.source = p_source;
	self.damage = amount;
	self.type = p_type;
	self.isCritical = p_isCritical;
