class_name StunEffect
extends StatusEffect

func _process_effect(delta: float, target: Node) -> void:
	if not target is Enemy:
		return;

	var enemy: Enemy = target as Enemy
	enemy.enableMove = false

	super._process_effect(delta, target)

func _on_expire(target: Node) -> void:
	if not target is Enemy:
		return;

	var enemy: Enemy = target as Enemy
	enemy.enableMove = true
	super._on_expire(target)
