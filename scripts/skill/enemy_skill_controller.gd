class_name EnemySkillController
extends BaseSkillController

func _init(p_user: Node, p_skills: Array[Skill]):
	super._init(p_user, p_skills);
	for s in p_skills:
		(s as EnemySkill).initCooldown();

func process(delta: float):
	for skill in skills:
		if skill is EnemySkill:
			(skill as EnemySkill).tick(delta)

func onSuccess(skill: Skill):
	super.onSuccess(skill);
	print("Enemy used skill: ", skill.name);
	if skill is EnemySkill:
		(skill as EnemySkill).startCooldown();
