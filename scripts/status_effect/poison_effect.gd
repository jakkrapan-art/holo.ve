class_name PoisonEffect
extends StatusEffect

@export var interval: float = 1.0  # Time between position updates
@export var damage: int = 1

var elapsedTime: float = 0.0
var lastTriggered: float = 0.0

func _process_effect(delta: float, target: Node) -> void:
	elapsedTime += delta
	if elapsedTime >= duration:
		_on_expire(target)
	else:
		if elapsedTime - lastTriggered >= interval:  # Check if it's time to update position
			if(target is Enemy):
				var enemy: Enemy = target as Enemy
				enemy.recvDamage(Damage.new(null, damage, Damage.DamageType.MAGIC));