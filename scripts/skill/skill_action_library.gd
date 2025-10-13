class_name SkillActionLibrary

var skillParser: Dictionary = {

};

static func ParseAction(data: Dictionary) -> SkillAction:
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
		"attack":
			pass;
		"target_self":
			skill = SkillActionSetTargetSelf.new();
		"decrease_atk_spd_area":
			skill = SkillActionDecreaseAtkSpdArea.new();
			var skillData = data.get("data", {});
			var duration = skillData.get("duration", 0);
			var decreaseValue = skillData.get("decreaseValue", 0.0);
			var radius = skillData.get("radius", 0.0);
			skill.duration = duration;
			skill.decreaseValue = decreaseValue;
			skill.radius = radius;
		"increase_move_spd_area":
			skill = SkillActionIncreaseMoveSpdArea.new();
			var skillData = data.get("data", {});
			var duration = skillData.get("duration", 0);
			var increaseValue = skillData.get("increaseValue", 0.0);
			var radius = skillData.get("radius", 0.0);
			skill.duration = duration;
			skill.increaseValue = increaseValue;
			skill.radius = radius;
		"increase_def_area":
			skill = SkillActionIncreaseDefArea.new();
			var skillData = data.get("data", {});
			var duration = skillData.get("duration", 0);
			var increaseValue = skillData.get("increaseValue", 0.0);
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
		_:
			print("Warning: Unknown skill type:", skillType);
			return null;

	return skill;
