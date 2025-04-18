class_name SkillController

var maxMana := 0.0;
var currentMana := 0.0;
var skill: Skill = null;
var user: Node;

func _init(user: Node,maxMana: float, initialMana: float, skill: Skill):
	self.maxMana = maxMana;
	currentMana = initialMana;
	self.skill = skill;
	self.user = user;

func updateMana(amount: float):
	currentMana = clamp(currentMana + amount, 0, maxMana)
	on_mana_updated.emit(currentMana);

func useSkill():
	if(currentMana < maxMana):
		return;
	
	var context = SkillContext.new()
	context.user = user

	if user is Tower:
		(user as Tower).usingSkill = true;
	var success = await execute_skill_actions(context);
		
	if(success):
		updateMana(-currentMana);
		
	if user is Tower:
		(user as Tower).usingSkill = false;

func execute_skill_actions(context: SkillContext):
	var index := 0;
	for action in skill.actions:
		if(context.cancel):
			print("cancel skill at:", index);
			return false;
		
		context.cancel = false;
		await action.execute(context)
		print("index:", index, " cancel:", context.cancel);
		index += 1;
	return true;

signal on_mana_updated(current: float)
