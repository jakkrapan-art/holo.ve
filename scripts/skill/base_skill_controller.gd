class_name BaseSkillController

var skills: Array[Skill] = [];
var user: Node;
var modifier: Dictionary = {}

var cancelled = false;

# Emitted after a fully successful (non-cancelled) cast, post onSuccess. Towers
# re-emit this as Tower.skill_cast_succeeded for the synergy system; enemies also
# emit it but nothing listens on the enemy side.
signal cast_succeeded(skill)

func _init(p_user: Node, p_skills: Array[Skill]):
	self.skills = p_skills;
	self.user = p_user;

func useSkill():
	if(!canUseSkill()):
		return;

	cancelled = false;
	for skill in skills:
		if(skill == null || !skill.isReady()):
			continue;
		var context = SkillContext.new()
		context.user = user
		context.skillName = skill.name
		context.extra["parameter"] = skill.parameters
		await execute_skill_actions(skill, context);

func cancel():
	cancelled = true;

func execute_skill_actions(skill: Skill, context: SkillContext):
	if(user is Tower || user is Enemy):
		user.usingSkill = true;

	skill.using = true;

	if skill.castTime > 0:
		await user.get_tree().create_timer(skill.castTime, false).timeout
		if not is_instance_valid(user):
			return
		if context.cancel || cancelled:
			resetUsingSkill(skill);
			return

	for action in skill.actions:
		if(context.cancel || cancelled):
			resetUsingSkill(skill);
			return

		context.cancel = false;
		await action.execute(context)

	# Re-check cancellation after the final action's await. Without this, a skill
	# cancelled mid-await (e.g. wave end during Gura storm) would still reach
	# onSuccess and drain Energy via SkillController.onSuccess's updateMana(-current).
	if(cancelled):
		resetUsingSkill(skill);
		return

	# Recovery hold: keep the caster busy for skill.recoveryTime after the last
	# action so it doesn't snap straight back to attacking/walking (usingSkill
	# stays true for towers, castLocked stays true for enemies). Checks only
	# `cancelled` (not context.cancel - the final play_anim/delay action sets
	# that routinely) so a wave-end cancel here skips onSuccess, same as above.
	if skill.recoveryTime > 0:
		if not is_instance_valid(user):
			return
		await user.get_tree().create_timer(skill.recoveryTime, false).timeout
		if not is_instance_valid(user):
			return
		if(cancelled):
			resetUsingSkill(skill);
			return

	onSuccess(skill);
	cast_succeeded.emit(skill);

func resetUsingSkill(skill: Skill):
	skill.using = false;
	# Valid guard: a cancel can arrive after the host was freed (e.g. an enemy
	# leaking/dying during a long mid-cast delay) - `user is Enemy` alone still
	# passes on a freed instance.
	if(user != null && is_instance_valid(user) && (user is Tower || user is Enemy)):
		user.usingSkill = skills.any(Callable(self, "checkUsingSkill"));

func onSuccess(skill: Skill):
	skill.use();
	resetUsingSkill(skill);

func checkUsingSkill(skill:Skill) -> bool:
	return skill.using;

func canUseSkill() -> bool:
	# NOTE: was has_meta("usingSkill") - dead check, no caller ever set that
	# meta, so overlapping casts were only prevented by Tower's own gate.
	if(user == null || ("usingSkill" in user && user.usingSkill)):
		return false;

	return true;

func addModifier(key: int, p_modifier: Callable):
	self.modifier[key] = p_modifier

func removeModifier(key: int):
	if(!modifier.has(key)):
		return;

	modifier.erase(key);

func executeModifier():
	for mod in modifier.values():
		if(user is Tower):
			mod.call(user as Tower);
