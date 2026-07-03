class_name EffectSpec
extends RefCounted

# Parsed reference from skill YAML to a registry effect: def + resolved
# value/duration. instantiate() builds a fresh EffectInstance per target
# (per-target isolation - replaces the legacy duplicate(true) pattern).

var def: EffectDef = null
var source_id: String = ""
var value: float = 0.0        # authored positive magnitude
var duration: float = 0.0
var extra_params: Dictionary = {}   # per-application def.params overrides

func instantiate(applier: Node = null) -> EffectInstance:
	var inst := EffectUtility.make_instance(def.id, source_id, value, duration, null)
	if inst == null:
		return null
	inst.params = extra_params
	# capture runs after params so behaviors snapshot with final knobs.
	if applier != null:
		inst.set_applier(applier)
	return inst
