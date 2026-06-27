class_name SkillController
extends BaseSkillController

var maxMana := 0.0;
var currentMana := 0.0;

func _init(p_user: Node, p_maxMana: float, initialMana: float, skill: Skill):
	super._init(p_user, [skill]);
	self.maxMana = p_maxMana;
	currentMana = initialMana;

func updateMana(amount: float):
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
