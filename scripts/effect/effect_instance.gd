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
# false = applied normally (still aggregates) but hidden from the overhead
# status-icon row; synergy board buffs use this - they show in the synergy panel.
var show_icon: bool = true
# Per-application overrides of def.params (skill YAML can rebind e.g. a DOT's
# max_hp_percent); read through param().
var params: Dictionary = {}
# Caster-dependent data captured at apply time (e.g. DOT attack snapshot);
# effects must never hold a live caster reference past apply.
var snapshot: Dictionary = {}

func param(name: String, default_value):
	return params.get(name, def.params.get(name, default_value))

func key() -> String:
	return source_id + "/" + def.id

func effective_value() -> float:
	return value * stacks

func set_applier(applier: Node) -> void:
	if behavior != null:
		behavior.capture(applier, self)

# Player-facing tooltip line: def.desc with the {value} token resolved to the
# REAL applied magnitude (stacks included) - numbers are never hand-typed.
func display_desc() -> String:
	if def.desc == "":
		return ""
	return def.desc.replace("{value}", EffectTypes.format_value(def.kind, effective_value()))
