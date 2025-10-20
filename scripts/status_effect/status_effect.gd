extends Resource
class_name StatusEffect

@export var duration: float = 5.0
@export var level: int = 1
@export var effectType: String = ""

# var elapsedTime: float = 0.0
var triggeredTime: float = 0.0
var applied: bool = false;
var expired: bool = false;

func _init(duration: float = 5.0, level: int = 1, effectType: String = ""):
	self.duration = duration
	self.level = level
	self.effectType = effectType

func _process_effect(delta: float, target: Node) -> void:
	if not applied:
		triggeredTime = Time.get_ticks_msec() / 1000.0
		applied = true

	if triggeredTime + duration <= Time.get_ticks_msec() / 1000.0:
		_on_expire(target)
		expired = true

func _on_apply(target: Node) -> void:
	pass

func _on_expire(target: Node) -> void:
	pass
