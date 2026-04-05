extends Resource
class_name StatusEffect

@export var duration: float = 5.0
@export var level: int = 1
@export var effectType: String = ""

# var elapsedTime: float = 0.0
var triggeredTime: float = 0.0
var applied: bool = false;
var expired: bool = false;
var appliedTarget: Node = null

func _init(duration: float = 5.0, level: int = 1, effectType: String = ""):
	self.duration = duration
	self.level = level
	self.effectType = effectType

func _process_effect(delta: float, target: Node) -> void:
	if not applied:
		triggeredTime = Time.get_ticks_msec() / 1000.0
		applied = true

func checkExpired() -> bool:
	if triggeredTime + duration > Time.get_ticks_msec() / 1000.0:
		return false;
	_on_expire(appliedTarget)
	expired = true
	print("effect expired: ", effectType, " time used: ", Time.get_ticks_msec() / 1000.0 - triggeredTime)
	return expired

func _on_apply(target: Node) -> void:
	appliedTarget = target

func _on_expire(target: Node) -> void:
	pass
