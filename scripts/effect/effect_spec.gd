class_name EffectSpec
extends RefCounted

# Parsed reference from skill YAML to a registry effect: def + resolved
# value/duration. instantiate() builds a fresh EffectInstance per target
# (per-target isolation - replaces the legacy duplicate(true) pattern).

var def: EffectDef = null
var source_id: String = ""
var value: float = 0.0        # authored positive magnitude
var duration: float = 0.0

func instantiate(applier: Node = null) -> EffectInstance:
	return EffectUtility.make_instance(def.id, source_id, value, duration, applier)
