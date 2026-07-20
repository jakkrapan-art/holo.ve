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
# Enemy.inCombatWindow seconds (hybrid sleep loop) and arms its castWait
# pacing timer; when the timer elapses ONE random ready skill is cast, then
# the timer re-arms - hit = wait -> cast, never a back-to-back chain.
func useSkill():
	if(!canUseSkill()):
		return;

	var enemy := user as Enemy
	if(enemy == null || !enemy.canCastNow()):
		return;

	var ready: Array[Skill] = [];
	for skill in skills:
		if(skill is EnemySkill && ((skill as EnemySkill).passive || (skill as EnemySkill).triggered)):
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
		# Re-arm the pacing gap AFTER the full cast (incl. recovery). Also runs
		# on a cancelled cast (wave-end teardown) - harmless, kept simpler than
		# splitting it into onSuccess.
		enemy.castWaitRemaining = enemy.castWait;

func onSuccess(skill: Skill):
	super.onSuccess(skill);
	if skill is EnemySkill:
		(skill as EnemySkill).startCooldown();

# Triggered skills (type: triggered): condition checked from Enemy.recvDamage
# after the HP write; check_hp_triggers only flags PENDING - the cast fires
# from useTriggeredSkill() in the Enemy._process hook once the busy flag frees,
# bypassing the castWait pacing gate (the condition is its own telegraph; the
# gate paces gate-driven Actives, not condition reactions).
var pendingTriggered: Array[Skill] = []

func check_hp_triggers(hp_ratio: float):
	for skill in skills:
		if(!(skill is EnemySkill)):
			continue;
		var es := skill as EnemySkill
		if(!es.triggered || es.triggerUsed):
			continue;
		if(es.trigger_hp_below > 0.0 && hp_ratio < es.trigger_hp_below):
			es.triggerUsed = true;
			pendingTriggered.append(es);
			if DEBUG_LOG:
				print("[EnemySkill] trigger pending: ", es.name, " (", user, ", hp ", hp_ratio, ")")

func useTriggeredSkill():
	if(pendingTriggered.is_empty() || !canUseSkill()):
		return;
	var enemy := user as Enemy
	if(enemy == null):
		return;

	cancelled = false;
	var skill: Skill = pendingTriggered.pop_front();
	if DEBUG_LOG:
		print("[EnemySkill] trigger cast: ", skill.name, " (", user, ")")
	var context = SkillContext.new()
	context.user = user
	context.skillName = skill.name
	context.extra["parameter"] = skill.parameters

	enemy.castLocked = true;
	await execute_skill_actions(skill, context);
	if(is_instance_valid(enemy)):
		enemy.castLocked = false;
		# Same re-arm invariant as useSkill: without it a gate Active fires
		# back-to-back right after a long triggered cast (e.g. Thick Skin ~5.5s).
		enemy.castWaitRemaining = enemy.castWait;

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
