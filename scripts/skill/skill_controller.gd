class_name SkillController
extends BaseSkillController

var maxMana := 0.0;
var currentMana := 0.0;

func _init(p_user: Node, p_maxMana: float, initialMana: float, skill: Skill):
	super._init(p_user, [skill]);
	self.maxMana = p_maxMana;
	currentMana = initialMana;

func updateMana(amount: float):
	# Single intake choke: every positive Energy gain (attack regen, synergy
	# grants, refunds) is multiplied by the holder's ENERGY_AMP aggregate here.
	# Drains are negative and must never be amplified. Wave-start refill and the
	# constructor write currentMana directly - a reset, not a gain.
	if amount > 0 and user is Tower:
		amount *= 1.0 + (user as Tower).data.effects.aggregate(EffectTypes.Kind.ENERGY_AMP) / 100.0
	# The clamp must land EXACTLY on maxMana: the skill-ready check compares
	# floats with == (tower.gd), and gains can be non-integral (x1.1).
	currentMana = clamp(currentMana + amount, 0, maxMana)
	on_mana_updated.emit(currentMana);

func canUseSkill() -> bool:
	return currentMana >= maxMana;

func onSuccess(skill: Skill):
	super.onSuccess(skill);
	updateMana(-currentMana);

func executeModifier():
	for mod in modifier.values():
		if(user is Tower):
			mod.call(user as Tower);

signal on_mana_updated(current: float)
