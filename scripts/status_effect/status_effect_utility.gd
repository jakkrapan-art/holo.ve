class_name StatusEffectUtility

static func ParseStatusEffect(data: Dictionary, parameters: Dictionary = {}):
	var type = data.get("type", "");
	# Numeric fields prefer parameters[<field>_param] when present (single source
	# shared with desc_template tokens), else the literal.
	var duration = _resolveField(data, parameters, "duration", "duration_param", 0);
	var statusEffect: StatusEffect;
	match (type):
		"stun":
			statusEffect = StunEffect.new(duration);
		"DamageReductionBuff":
			var reduction = data.get("reduction", 0.0);
			statusEffect = DamageReductionBuff.new(duration, reduction);
		"IncreaseDefBuff":
			var increaseValue = data.get("increaseValue", 0.0);
			statusEffect = IncreaseDefBuff.new(duration, increaseValue);
		"IncreaseMArmorPercentBuff":
			var increaseValue = data.get("increaseValue", 0.0);
			statusEffect = IncreaseMArmorPercentBuff.new(duration, increaseValue);
		"IncreaseArmorFlatBuff":
			var increaseValue = data.get("increaseValue", 0);
			statusEffect = IncreaseArmorFlatBuff.new(duration, int(increaseValue));
		"IncreaseMArmorFlatBuff":
			var increaseValue = data.get("increaseValue", 0);
			statusEffect = IncreaseMArmorFlatBuff.new(duration, int(increaseValue));
		"MoveSpeedMultiplierBuff":
			var multiplierValue = data.get("multiplierValue", 0.0);
			statusEffect = MoveSpeedMultiplierBuff.new(duration, multiplierValue);
		"phoenix_flame":
			# Kiara's DOT debuff. Damage formula resolves at tick time using
			# snapshot of caster attack captured in _on_apply (set_applier
			# is called by the cast site between duplicate() and addStatusEffect).
			# interval stays a fixed default tick; duration / attack% / max-hp% can
			# bind to parameters via *_param for single-source retuning.
			var interval = float(data.get("interval", 1.0));
			var atkPct = float(_resolveField(data, parameters, "attack_percent", "attack_percent_param", 0.10));
			var hpPct = float(_resolveField(data, parameters, "max_hp_percent", "max_hp_percent_param", 0.01));
			statusEffect = PhoenixFlameEffect.new(float(duration), interval, atkPct, hpPct);
		_:
			push_error("invalid type for status effect, type: ", type);
			return null;

	return statusEffect;

# Resolve a numeric field: when data has <param_key>, read a SCALAR from
# parameters[name] (keeps desc + runtime in sync); arrays aren't valid for a
# status-effect scalar, so warn and fall back to the literal field.
static func _resolveField(data: Dictionary, parameters: Dictionary, literal_key: String, param_key: String, default_value):
	if data.has(param_key):
		var pname = data[param_key];
		if parameters.has(pname):
			var pval = parameters[pname];
			if typeof(pval) == TYPE_ARRAY:
				push_warning("Status effect param '" + str(pname) + "' is an array; expected scalar — using literal '" + literal_key + "'.");
			else:
				return pval;
		else:
			push_warning("Status effect param '" + str(pname) + "' not in skill parameters — using literal '" + literal_key + "'.");
	return data.get(literal_key, default_value);