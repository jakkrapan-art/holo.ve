class_name BaseSkillController

var skills: Array[Skill] = [];
var user: Node;
var modifier: Dictionary = {}

var cancelled = false;

func _init(user: Node, skills: Array[Skill]):
	self.skills = skills;
	self.user = user;

func useSkill():
	if(!canUseSkill()):
		return;

	cancelled = false;
	for skill in skills:
		if(skill == null || !skill.isReady()):
			continue;
		var context = SkillContext.new()
		context.user = user
		context.extra["parameter"] = skill.parameters
		await execute_skill_actions(skill, context);

func cancel():
	cancelled = true;

func execute_skill_actions(skill: Skill, context: SkillContext):
	if user.has_meta("usingSkill"):
		user.usingSkill = true;

	skill.using = true;
	for action in skill.actions:
		if(context.cancel || cancelled):
			resetUsingSkill(skill);
			return

		context.cancel = false;
		await action.execute(context)
	executeModifier();
	onSuccess(skill);

func resetUsingSkill(skill: Skill):
	skill.using = false;
	if user.has_meta("usingSkill"):
		user.usingSkill = skills.any(Callable(self, "checkUsingSkill"));

func onSuccess(skill: Skill):
	resetUsingSkill(skill);

func checkUsingSkill(skill:Skill) -> bool:
	return skill.using;

func canUseSkill() -> bool:
	if(user == null || user.has_meta("usingSkill") && user.usingSkill):
		return false;

	return true;

func addModifier(key: int, modifier: Callable):
	self.modifier[key] = modifier

func removeModifier(key: int):
	if(!modifier.has(key)):
		return;

	modifier.erase(key);

func executeModifier():
	for mod in modifier.values():
		if(user is Tower):
			mod.call(user as Tower);
