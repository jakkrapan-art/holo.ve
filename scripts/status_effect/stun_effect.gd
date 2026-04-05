class_name StunEffect
extends StatusEffect

func _on_apply(target: Node) -> void:
	disableMove(target);
	super._on_apply(target)

func _process_effect(delta: float, target: Node) -> void:
	disableMove(target)
	super._process_effect(delta, target)

func disableMove(target: Node):
	if not target is Enemy:
		return;

	var enemy: Enemy = target as Enemy
	enemy.enableMove = false

func _on_expire(target: Node) -> void:
	if not target is Enemy:
		return;

	var enemy: Enemy = target as Enemy
	enemy.enableMove = true
	super._on_expire(target)
