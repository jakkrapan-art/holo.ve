class_name EffectDef
extends RefCounted

# Static definition of one effect, loaded from the registry
# (resources/database/effect/effects.yaml). Skills reference an EffectDef by id
# and supply value/duration; identity/stacking/icon live here (single source).

var id: String = ""
var display_name: String = ""
# Player-facing tooltip line. Numbers are NEVER typed
# in: the "{value}" token resolves to the instance's real applied magnitude
# (stacks included) at display time - same single-source rule as the
# tokenized skill desc.
var desc: String = ""
var icon_path: String = ""
var category: EffectTypes.Category = EffectTypes.Category.BUFF
var kind: EffectTypes.Kind = EffectTypes.Kind.ATTACK_SPEED
var stack_rule: EffectTypes.StackRule = EffectTypes.StackRule.REFRESH
var max_stacks: int = 0                 # STACK rule only; 0 = unlimited
var default_duration: float = 0.0      # <= 0 = no self-expiry
var lifetime: EffectTypes.Lifetime = EffectTypes.Lifetime.WAVE
# Sign convention: ids ending in "_down" negate the (positive) authored value
# at instantiate time, so designers always enter positive magnitudes.
var negate_value: bool = false
# Behavior extras (dot interval, tint_modulate, ...); kept generic so new
# knobs stay YAML-only.
var params: Dictionary = {}
