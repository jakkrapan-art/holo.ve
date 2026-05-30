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
			var interval = float(data.get("interval", 1.0));
			var atkPct = float(data.get("attack_percent", 0.10));
			var hpPct = float(data.get("max_hp_percent", 0.01));
			statusEffect = PhoenixFlameEffect.new(float(duration), interval, atkPct, hpPct);
		_:
			push_error("invalid type for status effect, type: ", type);
			return null;

	return statusEffect;