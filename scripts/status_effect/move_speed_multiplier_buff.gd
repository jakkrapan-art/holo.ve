class_name MoveSpeedMultiplierBuff
extends StatusEffect

@export var multiplierValue: float = 0.5 # Decimal: +0.5 = +50% haste, -0.5 = 50% slow
var elapsedTime: float = 0.0

func _init(duration: float = 5.0, multiplierValue: float = 0.5):
	super._init(duration, 1, "MoveSpeedMultiplierBuff")
	self.multiplierValue = multiplierValue

func _process_effect(delta: float, target: Node) -> void:
	elapsedTime += delta
	if elapsedTime >= duration:
		_on_expire(target)

func _buffKey() -> String:
	return "moveSpeedMultiplierBuff_" + str(get_instance_id())

func _on_apply(target: Node) -> void:
	if target.stats != null && target.stats is EnemyStat:
		target.stats.addMoveSpeedMultiplier(multiplierValue, _buffKey())

func _on_expire(target: Node) -> void:
	if(!is_instance_valid(target)):
		return;

	if target.stats != null && target.stats is EnemyStat:
		target.stats.removeMoveSpeedMultiplier(_buffKey())
