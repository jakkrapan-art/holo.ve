extends Resource
class_name StatusEffect

@export var duration: float = 5.0
@export var level: int = 1
@export var effectType: String = ""
# When true, container.addEffect() removes existing entries of same effectType
# before appending self (refresh-on-apply semantics; e.g., DOT debuffs).
# Default false preserves legacy stack-without-replace behavior (e.g., Gura stun).
@export var refresh_on_apply: bool = false

# var elapsedTime: float = 0.0
var triggeredTime: float = 0.0
var scaledAge: float = 0.0
var applied: bool = false;
var expired: bool = false;
var appliedTarget: Node = null

func _init(duration: float = 5.0, level: int = 1, effectType: String = ""):
	self.duration = duration
	self.level = level
	self.effectType = effectType

func _process_effect(delta: float, target: Node) -> void:
	if not applied:
		triggeredTime = scaledAge
		applied = true

func checkExpired(delta: float) -> bool:
	scaledAge += delta
	if triggeredTime + duration > scaledAge:
		return false;
	_on_expire(appliedTarget)
	expired = true
	print("effect expired: ", effectType, " time used: ", scaledAge - triggeredTime)
	return expired

func _on_apply(target: Node) -> void:
	appliedTarget = target

func _on_expire(target: Node) -> void:
	pass

# Optional hook for effects that need the casting tower at apply time
# (e.g., PhoenixFlameEffect snapshots applier.totalAttack). Default no-op.
# Call sites: SkillActionAttack apply loop + Projectile.hitTarget — both
# pass the shooter Tower so effects can snapshot caster-side state before
# the Tower ref goes stale.
func set_applier(_applier: Node) -> void:
	pass
