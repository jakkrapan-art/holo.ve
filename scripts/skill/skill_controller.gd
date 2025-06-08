class_name SkillController

var maxMana := 0.0;
var currentMana := 0.0;
var skill: Skill = null;
var user: Node; 
var modifier: Dictionary = {}

func _init(user: Node,maxMana: float, initialMana: float, skill: Skill):
	self.maxMana = maxMana;
	currentMana = initialMana;
	self.skill = skill;
	self.user = user;

func addModifier(key: int, modifier: Callable):
	self.modifier[key] = modifier

func removeModifier(key: int):
	if(!modifier.has(key)):
		return;
	
	modifier.erase(key);

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
		executeModifier();
		
	if user is Tower:
		(user as Tower).usingSkill = false;

func execute_skill_actions(context: SkillContext):
	for action in skill.actions:
		if(context.cancel):
			return false;
		
		context.cancel = false;
		await action.execute(context)
	return true;

func executeModifier():
	for mod in modifier:
		if(mod.has_method("call") && user is Tower):
			mod.call(user as Tower);

signal on_mana_updated(current: float)
