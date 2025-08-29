class_name DamageReductionBuff
extends StatusEffect

@export var reductionAmount: float = 0.1 # Percentage (0.0 to 1.0)
var elapsedTime: float = 0.0

func _init(duration: float = 5.0, reductionAmount: float = 0.1):
	super._init(duration, 1, "DamageReductionBuff")
	self.reductionAmount = reductionAmount

func _process_effect(delta: float, target: Node) -> void:
	elapsedTime += delta
	if elapsedTime >= duration:
		_on_expire(target)

func _on_apply(target: Node) -> void:
	if target.stats != null && target.stats is EnemyStat:
		target.stats.damageReduction += reductionAmount

func _on_expire(target: Node) -> void:
	if target.stats != null && target.stats is EnemyStat:
		target.stats.damageReduction = max(0.0, target.stats.damageReduction - reductionAmount)
