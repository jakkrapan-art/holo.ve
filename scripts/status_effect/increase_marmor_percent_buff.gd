class_name IncreaseMArmorPercentBuff
extends StatusEffect

@export var increaseAmount: float = 0.1 # Percentage (0.0 to 1.0)
var elapsedTime: float = 0.0

func _init(p_duration: float = 5.0, p_increaseAmount: float = 0.1):
	super._init(p_duration, 1, "IncreaseMArmorPercentBuff")
	self.increaseAmount = p_increaseAmount

func _process_effect(delta: float, target: Node) -> void:
	elapsedTime += delta
	if elapsedTime >= duration:
		_on_expire(target)

func _buffKey() -> String:
	return "increaseMArmorPercentBuff_" + str(get_instance_id())

func _on_apply(target: Node) -> void:
	if target.stats != null && target.stats is EnemyStat:
		target.stats.addMArmorPercent(increaseAmount, _buffKey())

func _on_expire(target: Node) -> void:
	if(!is_instance_valid(target)):
		return;

	if target.stats != null && target.stats is EnemyStat:
		target.stats.removeMArmorPercent(_buffKey())
