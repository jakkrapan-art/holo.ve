class_name EffectUtility

# Builders shared by skill actions, areas, passives, and (PR2) on-hit effect
# lists. All instances are built here so the sign convention, behavior
# attachment, and lifetime defaults live in one place.

# Build one instance from a registry def. `value` is the authored (positive)
# magnitude; "_down" defs negate it here. duration <= 0 = no self-expiry.
static func make_instance(effect_id: String, source_id: String, value: float, duration: float, applier: Node = null, authored_title: String = "") -> EffectInstance:
	var def := EffectRegistry.get_def(effect_id)
	if def == null:
		return null
	if source_id == "":
		push_error("EffectUtility: empty source_id for effect '" + effect_id + "'")
		return null
	var inst := EffectInstance.new()
	inst.def = def
	inst.source_id = source_id
	# Synergy board buffs (source_id "synergy_...") aggregate like any effect but
	# are surfaced in the synergy panel, never as a per-unit status icon.
	inst.show_icon = not source_id.begins_with("synergy_")
	inst.value = -value if def.negate_value else value
	inst.duration = duration
	inst.lifetime = def.lifetime
	inst.behavior = _behavior_for(def)
	inst.authored_title = authored_title
	if applier != null:
		inst.set_applier(applier)
	return inst

# Parse a skill-YAML `effects:` list into EffectSpecs (on-hit effects on
# attack/projectile actions). Numeric fields support the *_param single-source
# binding, same rules as the legacy status_effect_utility parser. Any entry
# key beyond effect/value/duration becomes a def.params override (literal, or
# `<name>_param` binding), e.g. Kiara's max_hp_percent_param.
const _SPEC_BASE_KEYS := ["effect", "value", "value_param", "duration", "duration_param", "title"]

static func parse_effect_list(list: Array, parameters: Dictionary, source_id: String) -> Array[EffectSpec]:
	var result: Array[EffectSpec] = []
	for entry in list:
		if not (entry is Dictionary):
			continue
		var effect_id := str(entry.get("effect", ""))
		var def := EffectRegistry.get_def(effect_id)
		if def == null:
			continue
		var spec := EffectSpec.new()
		spec.def = def
		spec.source_id = source_id
		spec.authored_title = str(entry.get("title", ""))
		spec.value = float(_resolve_field(entry, parameters, "value", "value_param", 0.0))
		spec.duration = float(_resolve_field(entry, parameters, "duration", "duration_param", def.default_duration))
		for key in entry.keys():
			if key in _SPEC_BASE_KEYS:
				continue
			if str(key).ends_with("_param"):
				var base := str(key).trim_suffix("_param")
				spec.extra_params[base] = _resolve_field(entry, parameters, base, str(key), def.params.get(base, 0.0))
			elif not spec.extra_params.has(key):
				spec.extra_params[key] = entry[key]
		result.append(spec)
	return result

# Resolve a numeric field: prefer parameters[<param_key>] (scalar; single
# source with desc_template tokens), else the literal field.
static func _resolve_field(data: Dictionary, parameters: Dictionary, literal_key: String, param_key: String, default_value):
	if data.has(param_key):
		var pname = data[param_key]
		if parameters.has(pname):
			var pval = parameters[pname]
			if typeof(pval) == TYPE_ARRAY:
				push_warning("Effect param '" + str(pname) + "' is an array; expected scalar - using literal '" + literal_key + "'.")
			else:
				return pval
		else:
			push_warning("Effect param '" + str(pname) + "' not in skill parameters - using literal '" + literal_key + "'.")
	return data.get(literal_key, default_value)

# Behavior kinds get their strategy object here. Stat kinds and MARK_ONLY
# need none. (Stun/DOT behaviors land with the enemy-side migration.)
static func _behavior_for(def: EffectDef) -> EffectBehavior:
	match def.kind:
		EffectTypes.Kind.STUN:
			return StunBehavior.new()
		EffectTypes.Kind.DOT:
			return DotBehavior.new()
		EffectTypes.Kind.HOT:
			return HotBehavior.new()
		EffectTypes.Kind.INVINCIBLE:
			return InvincibleBehavior.new()
		_:
			if def.params.has("tint_modulate"):
				return EffectBehavior.new()
			return null
