class_name SkillActionLibrary

var skillParser: Dictionary = {

};

static func ParseAction(data: Dictionary) -> SkillAction:
	var skillType = data.get("type", "");
	var skill: SkillAction;
	match skillType:
		"apply_status_effect":
			var buff = DamageReductionBuff.new(10, 0.1); #for test
			skill = SkillActionAddBuff.new();
			skill.buff = buff;
		"attack_with_param":
			pass;
		"attack":
			pass;
		"target_self":
			skill = SkillActionSetTargetSelf.new();
		_:
			print("Warning: Unknown skill type:", skillType);
			return null;

	return skill;