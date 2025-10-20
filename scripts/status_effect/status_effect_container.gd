class_name StatusEffectContainer

var effects: Dictionary = {}  # key = effect_type, value = Array[StatusEffect]

var host: Node = null

func _init(host: Node):
	self.host = host

func addEffect(effect: StatusEffect) -> void:
	if not effects.has(effect.effectType):
		effects[effect.effectType] = []

	effect._on_apply(host)
	effects[effect.effectType].append(effect)

func removeEffect(effect: StatusEffect) -> void:
	if effects.has(effect.effectType):
		effects[effect.effectType].erase(effect)
		if effects[effect.effectType].is_empty():
			effects.erase(effect.effectType)

func processEffects(delta: float, enemy: Enemy) -> void:
	var expiredEffects = []

	for effect_type in effects:
		# Get effect with the highest level
		var strongest_effect = _getStrongestEffect(effect_type)
		if strongest_effect:
			strongest_effect._process_effect(delta, enemy)

		# Check all effects for expiration
		for effect: StatusEffect in effects[effect_type]:
			if effect.expired:
				expiredEffects.append(effect)

	# Remove expired effects
	for effect in expiredEffects:
		removeEffect(effect)

func _getStrongestEffect(effect_type: String) -> StatusEffect:
	if not effects.has(effect_type):
		return null

	var sorted_effects = effects[effect_type].duplicate()
	sorted_effects.sort_custom(func(a, b): return a.level > b.level)
	return sorted_effects[0] if sorted_effects.size() > 0 else null
