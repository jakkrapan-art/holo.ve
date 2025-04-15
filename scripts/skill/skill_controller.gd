class_name SkillController

var maxMana := 0.0;
var currentMana := 0.0;
var skill: Skill = null;

func _init(maxMana: float, initialMana: float, skill: Skill):
	self.maxMana = maxMana;
	currentMana = initialMana;
	self.skill = skill;

func updateMana(amount: float):
	currentMana = clamp(currentMana + amount, 0, maxMana)
	print("update mana:", amount, " current:", currentMana, "/", maxMana);

func useSkill():
	if(currentMana < maxMana):
		return;
	
	updateMana(-currentMana);
