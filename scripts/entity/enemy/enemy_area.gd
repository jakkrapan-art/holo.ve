extends Area2D
class_name  EnemyArea

@onready var enemy: Enemy = $"..";

# Zones and actions hit this child Area2D, not the PathFollow2D - forward the
# uniform effect surface to the owning enemy.
func apply_effect(inst: EffectInstance) -> void:
	enemy.apply_effect(inst);

func remove_effect_source(source_id: String) -> void:
	enemy.remove_effect_source(source_id);

func addBlockDamageCount(value: int):
	enemy.addBlockDamageCount(value);
