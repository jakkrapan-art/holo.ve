class_name SkillParser

static func Parse(data: Dictionary) -> Skill:
	var skill: Skill = Skill.new();

	var skillName := "Skill";
	var skillDesc := "Just a skill";
	var actions = [];
	var parameters = {};

	if data.has("name"):
		skillName = data["name"];

	if data.has("desc"):
		skillDesc = data["desc"];

	if data.has("actions"):
		for actionData in data["actions"]:
			var action := SkillAction.new();
			if actionData.has("type"):
				action.type = actionData["type"];
			if actionData.has("magnitude"):
				action.magnitude = actionData["magnitude"];
			if actionData.has("target"):
				action.target = actionData["target"];
			if actionData.has("duration"):
				action.duration = actionData["duration"];
			actions.append(action);

	skill.name = skillName;
	skill.desc = skillDesc;
	skill.actions = actions;
	skill.parameters = parameters;

	return skill