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
			var reduction = skillData.get("reduction", 0.0);
			var buff = DamageReductionBuff.new(duration, reduction); #for test
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
			print("increase move spd area: ", duration, ", ", increaseValue, ", ", radius);
			skill.duration = duration;
			skill.increaseValue = increaseValue;
			skill.radius = radius;
		_:
			print("Warning: Unknown skill type:", skillType);
			return null;

	return skill;
