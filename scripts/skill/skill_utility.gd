class_name SkillUtility

var skillParser: Dictionary = {

};

static func ParseSkill(skillDataList: Array) -> Array[Skill]:
	var result: Array[Skill] = [];
	for skill in skillDataList:
		var cooldown = skill.get("cooldown", 1.0);
		var skillName = skill.get("name", "Unnamed Skill");
		var desc = skill.get("desc", "");
		var oneTime = skill.get("oneTime", false);
		# Same key + meaning as the tower skill-level cast_time (idle pre-cast
		# hold); enemies additionally stand still during it (Enemy.castLocked).
		var castTime = float(skill.get("cast_time", 0.0));
		var actions: Array[SkillAction] = [];
		var actionList = skill.get("action", []);
		for actionData in actionList:
			var action = ParseAction(actionData);
			if action != null:
				actions.append(action);
			else:
				push_warning("Failed to parse action in skill ", skillName);

		var s = EnemySkill.new(skillName, desc, actions, {}, oneTime, cooldown, castTime);
		# Post-cast hold (seconds); enemy default 0.0 - a 0.2 default would
		# permanently freeze cooldown-0 every-frame recast skills (aura elites).
		s.recoveryTime = float(skill.get("recovery", 0.0));
		# Skill kinds: active (default, castWait gate) | passive (once at spawn)
		# | triggered (fires itself on its trigger condition, bypassing the gate).
		var typeStr = str(skill.get("type", "active"));
		s.passive = typeStr == "passive";
		s.triggered = typeStr == "triggered";
		var trigger = skill.get("trigger", {});
		s.trigger_hp_below = float(trigger.get("hp_below", 0.0));
		if s.triggered and s.trigger_hp_below <= 0.0:
			push_warning("Triggered skill '", skillName, "' has no trigger condition - it will never fire.");
		# Player-facing summary tags (same controlled registry as tower skills).
		# Append str() per entry - a raw YAML Array can't assign into Array[String].
		for tag in skill.get("tags", []):
			s.tags.append(str(tag));
		if s != null:
			result.append(s);
		else:
			push_warning("Skill ", s, " not found");
	return result

static func ParseAction(data: Dictionary, parameters: Dictionary = {}) -> SkillAction:
	var skillType = data.get("type", "");
	var skill: SkillAction;
	match skillType:
		"attack_with_param":
			pass;
		"target_self":
			skill = SkillActionSetTargetSelf.new();
		"apply_effect":
			# Unified registry effect (self / allied towers / context targets).
			skill = SkillActionApplyEffect.new();
			var skillData = data.get("data", {});
			skill.effectId = skillData.get("effect", "");
			skill.targetMode = skillData.get("target", "self");
			skill.value = float(skillData.get("value", 0.0));
			skill.valueParam = skillData.get("value_param", "");
			skill.duration = float(skillData.get("duration", 0.0));
			skill.durationParam = skillData.get("duration_param", "");
			skill.range_cells = skillData.get("range", 1);
			skill.authoredTitle = skillData.get("title", "");
			skill.showArea = skillData.get("show_area", true);
		"effect_area":
			# Aura zone applying a registry effect while hosts stay inside.
			skill = SkillActionEffectArea.new();
			var skillData = data.get("data", {});
			skill.effectId = skillData.get("effect", "");
			skill.value = float(skillData.get("value", 0.0));
			skill.duration = float(skillData.get("duration", 3.0));
			skill.radius = float(skillData.get("radius", 1.0));
			skill.affects = skillData.get("affects", "enemies");
			skill.authoredTitle = skillData.get("title", "");
		"summon_enemy":
			# Mid-wave reinforcements from the caster's path position (boss skills).
			skill = SkillActionSummonEnemy.new();
			var skillData = data.get("data", {});
			skill.enemyId = str(skillData.get("enemy", ""));
			skill.count = int(skillData.get("count", 1));
			skill.interval = float(skillData.get("interval", 0.2));
		"delay":
			skill = SkillActionDelay.new();
			var skillData = data.get("data", {});
			var delay = skillData.get("delay", 1.0);
			skill.delay = delay;
		"set_speed":
			skill = SkillActionSetSpeed.new();
			var skillData = data.get("data", {});
			var speed = skillData.get("speed", 1.0);
			skill.speed = speed;
		"play_effect":
			skill = SkillActionPlayEffect.new()
			var skillData = data.get("data", {})
			skill.effectScriptPath = skillData.get("effect_script", "")
		"block_damage":
			skill = SkillActionBlockDamage.new();
			var skillData = data.get("data", {});
			skill.blockCount = skillData.get("count", 0);
		"play_animation":
			skill = SkillActionPlayAnimation.new();
			var skillData = data.get("data", {});
			skill.animationName = skillData.get("animation", "");
			skill.duration = float(skillData.get("duration", 0.0));
		"attack":
			skill = SkillActionAttack.new();
			var skillData = data.get("data", {});
			skill.damage = skillData.get("damage", 0);
			# Phase 3 Block C — Skill Multiplier. A param-name (single source with
			# desc) wins over a literal; resolved here at parse time into
			# damageMultiplierPerLevel/damageMultiplier. (The projectile actions
			# instead resolve via context.getParameter at runtime — both give
			# correct per-level behavior.)
			if skillData.has("damage_multiplier_param_name"):
				var pname = skillData["damage_multiplier_param_name"]
				if parameters.has(pname):
					var pval = parameters[pname]
					if typeof(pval) == TYPE_ARRAY:
						var pArr: Array[float] = []
						for v in pval:
							pArr.append(float(v))
						skill.damageMultiplierPerLevel = pArr
					else:
						skill.damageMultiplier = float(pval)
				else:
					push_warning("attack: damage_multiplier_param_name '" + str(pname) + "' not in skill parameters.")
			elif skillData.has("damage_multiplier"):
				var dm = skillData["damage_multiplier"]
				if typeof(dm) == TYPE_ARRAY:
					var dmArr: Array[float] = []
					for v in dm:
						dmArr.append(float(v))
					skill.damageMultiplierPerLevel = dmArr
				else:
					skill.damageMultiplier = float(dm)
			if skillData.has("hit_distribution"):
				var hd = skillData["hit_distribution"]
				var hdArr: Array[float] = []
				for v in hd:
					hdArr.append(float(v))
				skill.hitDistribution = hdArr
			skill.canCrit = skillData.get("can_crit", true)
			skill.forcedCrit = skillData.get("force_crit", false)
			# Stack-scaling bonus (e.g. Calliope Souls): + stacks x per-stack
			# value on the multiplier, count read live at execute time.
			skill.stackBonusEffectId = str(skillData.get("stack_bonus_effect", ""))
			var sbParam = skillData.get("stack_bonus_per_stack_param_name", "")
			if sbParam != "" and parameters.has(sbParam):
				skill.stackBonusPerStack = float(parameters[sbParam])
			else:
				skill.stackBonusPerStack = float(skillData.get("stack_bonus_per_stack", 0.0))
			if skillData.has("damage_type"):
				skill.damageType = Utility.parse_string_to_enum(Damage.DamageType, skillData["damage_type"])
				skill.damageTypeOverride = true
			# Registry effects applied to each target after damage (e.g., Kiara
			# Phoenix Flame DOT). Same shape as create_circle_projectile.
			var attackEffectList = skillData.get("effects", []);
			if attackEffectList.size() > 0:
				skill.statusEffects = EffectUtility.parse_effect_list(attackEffectList, parameters, "action_" + str(skill.get_instance_id()));
		"aftershock":
			# Delayed non-blocking re-hit of a snapshotted area ("aftershock"
			# pattern - tower_skill.md). The inner find/attack are built from
			# this same data block via this parser, so damage_multiplier_param_name,
			# damage_type, can_crit, and stack_bonus_* all work in the explosion.
			skill = SkillActionAftershock.new();
			var skillData = data.get("data", {});
			skill.width = int(skillData.get("width", 3));
			skill.height = int(skillData.get("height", 3));
			var delayParam = skillData.get("delay_param_name", "");
			if delayParam != "" and parameters.has(delayParam):
				skill.delay = float(parameters[delayParam]);
			else:
				skill.delay = float(skillData.get("delay", 0.5));
			var findAction := SkillActionFindMultipleInRange.new();
			findAction.width = skill.width;
			findAction.height = skill.height;
			findAction.cancel_when_empty = false;
			skill.find_action = findAction;
			skill.attack_action = ParseAction({"type": "attack", "data": skillData}, parameters) as SkillActionAttack;
		"clear_enemy":
			skill = SkillActionClearEnemy.new();
		"find_multi_enemy":
			skill = SkillActionFindMultipleInRange.new();
			var skillData = data.get("data", {});
			skill.width = skillData.get("width", 1);
			skill.height = skillData.get("height", 1);
			skill.cancel_when_empty = skillData.get("cancel_when_empty", true);
			# Self-centered axis-aligned box (no aim rotation/forward extend).
			skill.center_on_self = skillData.get("center_on_self", false);
		"dash":
			# Path dash: slide the casting enemy forward along its path.
			skill = SkillActionDash.new();
			var skillData = data.get("data", {});
			skill.cells = float(skillData.get("cells", 1.0));
			skill.duration = float(skillData.get("duration", 0.3));
		"heal_percent_maxhp":
			# Instant heal = target.maxHp x percent (enemy self heals).
			skill = SkillActionHealPercentMaxHp.new();
			var skillData = data.get("data", {});
			skill.percent = float(skillData.get("percent", 0.0));
		"damage_percent_maxhp":
			# Staff-style TRUE damage = enemy.maxHp × percent (boss vs non-boss split).
			# First caller: A-Chan "Hard Worker Ghost Release!!!".
			skill = SkillActionDamagePercentMaxHp.new();
			var skillData = data.get("data", {});
			skill.boss_percent = float(skillData.get("boss_percent", 0.25));
			skill.non_boss_percent = float(skillData.get("non_boss_percent", 1.0));
		"create_circle_projectile":
			skill = SkillCreateCircleProjectile.new();
			var skillData = data.get("data", {});
			# Designer-facing key is "circle_radius" (in tile units); accept legacy "radius" as a fallback.
			skill.circle_radius = skillData.get("circle_radius", skillData.get("radius", 1.0));
			skill.count = skillData.get("count", 1);
			skill.angular_speed = skillData.get("angular_speed", 90.0);
			skill.initial_angle = skillData.get("initial_angle", 0.0);
			skill.angle_offset = skillData.get("angle_offset", 0.0);
			skill.lifetime = skillData.get("lifetime", 1.0);
			skill.damageMultiplier = skillData.get("damage_multiplier", 1.0);
			skill.damageType = Utility.parse_string_to_enum(Damage.DamageType, skillData.get("damage_type", "physic"));
			skill.damageMultiplierParamName = skillData.get("damage_multiplier_param_name", "damageMultiplier");
			skill.projectile_size_w = skillData.get("projectile_size_w", 1.0);
			skill.projectile_size_h = skillData.get("projectile_size_h", 1.0);
			var circleEffectList = skillData.get("effects", []);
			if(circleEffectList.size() > 0):
				skill.statusEffects = EffectUtility.parse_effect_list(circleEffectList, parameters, "action_" + str(skill.get_instance_id()));
			skill.projectileTemplate = load(skillData.get("projectile", "res://resources/combat/bullets/gawr_gura_skill_projectile.tscn"));
		"create_directional_projectile":
			# Linear projectile that travels from caster toward primary target.
			# First user: Kiara evolved Hinotori (3×5 forward pierce AOE).
			skill = SkillCreateDirectionalProjectile.new();
			var skillData = data.get("data", {});
			skill.speed = float(skillData.get("speed", 12.0));
			skill.max_range = float(skillData.get("max_range", -1.0));
			skill.count = skillData.get("count", 1);
			skill.lifetime = float(skillData.get("lifetime", 1.5));
			skill.damageMultiplier = float(skillData.get("damage_multiplier", 1.0));
			skill.damageType = Utility.parse_string_to_enum(Damage.DamageType, skillData.get("damage_type", "physic"));
			skill.damageMultiplierParamName = skillData.get("damage_multiplier_param_name", "damageMultiplier");
			var dirEffectList = skillData.get("effects", []);
			if dirEffectList.size() > 0:
				skill.statusEffects = EffectUtility.parse_effect_list(dirEffectList, parameters, "action_" + str(skill.get_instance_id()));
			skill.projectileTemplate = load(skillData.get("projectile", "res://resources/combat/bullets/gawr_gura_skill_projectile.tscn"));
		_:
			push_warning("Unknown skill type: ", skillType);
			return null;

	return skill;
