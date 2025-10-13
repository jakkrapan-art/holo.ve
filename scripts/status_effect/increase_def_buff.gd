class_name IncreaseDefBuff
extends StatusEffect

@export var increaseAmount: float = 0.1 # Percentage (0.0 to 1.0)
var elapsedTime: float = 0.0
var originColor: Color
var buffKey: String = ""

func _init(duration: float = 5.0, increaseAmount: float = 0.1):
	super._init(duration, 1, "IncreaseDefBuff")
	self.increaseAmount = increaseAmount

func _process_effect(delta: float, target: Node) -> void:
	elapsedTime += delta
	if elapsedTime >= duration:
		_on_expire(target)

func _on_apply(target: Node, buffKey: String = "") -> void:
	self.buffKey = buffKey if buffKey != "" else ""
	if target.stats != null && target.stats is EnemyStat:
		var stats := target.stats as EnemyStat
		stats.addArmorPercent(increaseAmount, buffKey);

func _on_expire(target: Node) -> void:
	if target.stats != null && target.stats is EnemyStat:
		var stats:= target.stats as EnemyStat
		stats.removeArmorPercent(self.buffKey);