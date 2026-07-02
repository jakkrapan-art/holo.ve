class_name EffectInstance
extends RefCounted

# One live buff/debuff/mark on a host. Identity = source_id + "/" + def.id:
# the same skill re-applying refreshes/stacks its own record, while a
# different skill applying the same def coexists and sums (Decision 2).

var def: EffectDef = null
var source_id: String = ""
var value: float = 0.0            # per-stack value; sign already resolved
var duration: float = 0.0         # <= 0 = no self-expiry (aura/permanent)
var remaining: float = 0.0
var stacks: int = 1
var lifetime: EffectTypes.Lifetime = EffectTypes.Lifetime.WAVE
var behavior: EffectBehavior = null
# Caster-dependent data captured at apply time (e.g. DOT attack snapshot);
# effects must never hold a live caster reference past apply.
var snapshot: Dictionary = {}

func key() -> String:
	return source_id + "/" + def.id

func effective_value() -> float:
	return value * stacks

func set_applier(applier: Node) -> void:
	if behavior != null:
		behavior.capture(applier, self)
