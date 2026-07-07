class_name EnemySkillController
extends BaseSkillController

# Dev switch: traces gate wake/sleep, skill readiness, casts, and icon hover
# in the Output log. Keep false in committed builds.
const DEBUG_LOG := false

func _init(p_user: Node, p_skills: Array[Skill]):
	super._init(p_user, p_skills);
	for s in p_skills:
		(s as EnemySkill).initCooldown();

func process(delta: float):
	for skill in skills:
		if skill is EnemySkill:
			var es := skill as EnemySkill
			var was_cooling := es.cooldownRemaining > 0.0
			es.tick(delta)
			if DEBUG_LOG and was_cooling and es.cooldownRemaining <= 0.0:
				print("[EnemySkill] ready: ", es.name, " (", user, ")")

# Enemy cast rules (differ from towers): a hit wakes the enemy for
# Enemy.inCombatWindow seconds (hybrid sleep loop), and ONE random ready skill
# is cast per opportunity instead of every ready skill in order.
func useSkill():
	if(!canUseSkill()):
		return;

	var enemy := user as Enemy
	if(enemy == null || !enemy.isInCombat()):
		return;

	var ready: Array[Skill] = [];
	for skill in skills:
		if(skill is EnemySkill && (skill as EnemySkill).passive):
			continue;
		if(skill != null && skill.isReady()):
			ready.append(skill);
	if(ready.is_empty()):
		return;

	cancelled = false;
	var skill: Skill = ready.pick_random();
	if DEBUG_LOG:
		print("[EnemySkill] cast: ", skill.name, " (", user, ", ready pool ", ready.size(), ")")
	var context = SkillContext.new()
	context.user = user
	context.skillName = skill.name
	context.extra["parameter"] = skill.parameters

	enemy.castLocked = true;
	await execute_skill_actions(skill, context);
	if(is_instance_valid(enemy)):
		enemy.castLocked = false;

func onSuccess(skill: Skill):
	super.onSuccess(skill);
	if skill is EnemySkill:
		(skill as EnemySkill).startCooldown();

# Passive skills (type: passive): apply the action list once at spawn - no
# in-combat gate, no cast_time/busy flag, no cooldown/onSuccess. Called from
# Enemy.setup, fire-and-forget.
func applyPassives():
	for skill in skills:
		if(!(skill is EnemySkill) || !(skill as EnemySkill).passive):
			continue;
		var context = SkillContext.new()
		context.user = user
		context.skillName = skill.name
		context.extra["parameter"] = skill.parameters
		for action in skill.actions:
			if(user == null || !is_instance_valid(user)):
				return;
			await action.execute(context)
