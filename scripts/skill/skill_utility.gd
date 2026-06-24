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
		var actions: Array[SkillAction] = [];
		var actionList = skill.get("action", []);
		for actionData in actionList:
			var action = ParseAction(actionData);
			if action != null:
				actions.append(action);
			else:
				print("Warning: Failed to parse action in skill", skillName);

		var s = EnemySkill.new(skillName, desc, actions, {}, oneTime, cooldown);
		if s != null:
			result.append(s);
		else:
			print("Warning: Skill", s, "not found");
	return result

static func ParseAction(data: Dictionary, parameters: Dictionary = {}) -> SkillAction:
	var skillType = data.get("type", "");
	var skill: SkillAction;
	match skillType:
		"apply_status_effect":
			var skillData = data.get("data", {});
			var duration = skillData.get("duration", 0);
			var type = skillData.get("type", "");
			if(type == ""):
				push_error("invalid type for apply_status_effect");
				return null;
			var buff: StatusEffect;
			match type:
				"DamageReductionBuff":
					var reduction = skillData.get("reduction", 0.0);
					buff = DamageReductionBuff.new(duration, reduction); #for test
				"IncreaseDefBuff":
					var increaseValue = skillData.get("increaseValue", 0.0);
					buff = IncreaseDefBuff.new(duration, increaseValue);
				_:
					push_error("invalid type for apply_status_effect, type: ", type);
					return null;

			skill = SkillActionAddBuff.new();
			skill.buff = buff;
		"attack_with_param":
			pass;
		"target_self":
			skill = SkillActionSetTargetSelf.new();
		"decrease_atk_spd_area":
			skill = SkillActionDecreaseAtkSpdArea.new();
			var skillData = data.get("data", {});
			var duration = skillData.get("duration", 0);
			var decreaseValue = skillData.get("value", 0.0);
			var radius = skillData.get("radius", 0.0);
			skill.duration = duration;
			skill.decreaseValue = decreaseValue;
			skill.radius = radius;
		"increase_move_spd_area":
			skill = SkillActionIncreaseMoveSpdArea.new();
			var skillData = data.get("data", {});
			var duration = skillData.get("duration", 0);
			var increaseValue = skillData.get("value", 0.0);
			var radius = skillData.get("radius", 0.0);
			skill.duration = duration;
			skill.increaseValue = increaseValue;
			skill.radius = radius;
		"increase_def_area":
			skill = SkillActionIncreaseDefArea.new();
			var skillData = data.get("data", {});
			var duration = skillData.get("duration", 0);
			var increaseValue = skillData.get("value", 0.0);
			var radius = skillData.get("radius", 0.0);
			skill.duration = duration;
			skill.increaseValue = increaseValue;
			skill.radius = radius;
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
		"decrease_damage_all_area":
			skill = DecreaseDamageAllArea.new();
			var skillData = data.get("data", {});
			var duration = skillData.get("duration", 3);
			var radius = skillData.get("radius", 1.0);
			var decreaseValue = skillData.get("decreaseValue", 0.0);
			skill.duration = duration;
			skill.radius = radius;
			skill.decreaseValue = decreaseValue;
		"atk_speed_buff_aoe":
			skill = SkillActionAtkSpeedBuffAOE.new()
			var skillData = data.get("data", {})
			skill.duration = skillData.get("duration", 4.0)
			# ATTACK_SPEED is decimal scale (0.5 = +50%) — see tower_data.getAttackSpeed.
			skill.percent = skillData.get("percent", 0.5)
			skill.paramName = skillData.get("param_name", "")
			skill.range_cells = skillData.get("range", 1)
		"crit_chance_buff":
			skill = SkillActionCritChanceBuff.new()
			var skillData = data.get("data", {})
			skill.duration = skillData.get("duration", 4.0)
			skill.percent = skillData.get("percent", 100.0)
			skill.paramName = skillData.get("param_name", "")
		"play_effect":
			skill = SkillActionPlayEffect.new()
			var skillData = data.get("data", {})
			skill.effectScriptPath = skillData.get("effect_script", "")
		"atk_speed_buff":
			skill = SkillActionAtkSpeedBuff.new()
			var skillData = data.get("data", {})
			skill.duration = skillData.get("duration", 4.0)
			skill.paramName = skillData.get("param_name", "attackSpeedBuff")
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
			if skillData.has("damage_type"):
				skill.damageType = Utility.parse_string_to_enum(Damage.DamageType, skillData["damage_type"])
				skill.damageTypeOverride = true
			# Status effects applied to each target after damage (e.g., Kiara
			# Phoenix Flame DOT). Same shape as create_circle_projectile.
			var attackStatusEffectDataList = skillData.get("status_effects", []);
			if attackStatusEffectDataList.size() > 0:
				var attackStatusEffects: Array[StatusEffect] = [];
				for statusEffectData in attackStatusEffectDataList:
					var se: StatusEffect = StatusEffectUtility.ParseStatusEffect(statusEffectData, parameters);
					if se:
						attackStatusEffects.append(se);
				skill.statusEffects = attackStatusEffects;
		"clear_enemy":
			skill = SkillActionClearEnemy.new();
		"find_multi_enemy":
			skill = SkillActionFindMultipleInRange.new();
			var skillData = data.get("data", {});
			skill.width = skillData.get("width", 1);
			skill.height = skillData.get("height", 1);
			skill.cancel_when_empty = skillData.get("cancel_when_empty", true);
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
			var statusEffects: Array[StatusEffect] = [];
			var statusEffectDataList = skillData.get("status_effects", []);
			if(statusEffectDataList.size() > 0):
				for statusEffectData in statusEffectDataList:
					var se: StatusEffect = StatusEffectUtility.ParseStatusEffect(statusEffectData, parameters);
					if se:
						statusEffects.append(se);
				skill.statusEffects = statusEffects;
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
			var dirStatusEffectDataList = skillData.get("status_effects", []);
			if dirStatusEffectDataList.size() > 0:
				var dirStatusEffects: Array[StatusEffect] = [];
				for statusEffectData in dirStatusEffectDataList:
					var se: StatusEffect = StatusEffectUtility.ParseStatusEffect(statusEffectData, parameters);
					if se:
						dirStatusEffects.append(se);
				skill.statusEffects = dirStatusEffects;
			skill.projectileTemplate = load(skillData.get("projectile", "res://resources/combat/bullets/gawr_gura_skill_projectile.tscn"));
		_:
			print("Warning: Unknown skill type:", skillType);
			return null;

	return skill;
