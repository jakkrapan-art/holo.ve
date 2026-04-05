class_name StatusEffectUtility

static func ParseStatusEffect(data: Dictionary):
	var type = data.get("type", "");
	var duration = data.get("duration", 0);
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
		_:
			push_error("invalid type for status effect, type: ", type);
			return null;

	return statusEffect;