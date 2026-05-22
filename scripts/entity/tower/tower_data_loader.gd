class_name TowerDataLoader
static func load_data(prefix: String, name: String) -> TowerData:
	# print("load tower from yaml: ", path);
	var path = prefix + name + ".yaml";
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Failed to open YAML: " + path + " try loading default.")
		path = prefix + "default_tower.yaml";
		file = FileAccess.open(path, FileAccess.READ);
		if file == null:
			push_error("Failed to open default tower data");
			return null

	# var text := file.get_as_text()
	var parsed = YamlParser.load_data(path)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid YAML format: " + path)
		return null

	var data: Dictionary = parsed

	var tower := TowerData.new()

	# Basic config (SAFE: only exported data)
	tower.maxLevel = data.get("maxLevel", 1)

	# Parse enum safely (string or int)
	tower.towerClass = Utility.parse_string_to_enum(TowerData.TowerClass, data.get("towerClass", "Assassin"))
	tower.generation = Utility.parse_string_to_enum(TowerData.TowerGeneration, data.get("generation", "Myth"))
	if data.has("attackType"):
		tower.attackType = Utility.parse_string_to_enum(Damage.DamageType, data["attackType"])
	else:
		push_warning("Tower YAML '" + name + "': missing 'attackType' field — defaulting to PHYSIC. Add 'attackType: physic' or 'attackType: magic' to suppress this warning.")
		tower.attackType = Damage.DamageType.PHYSIC

	tower.evolutionCost = data.get("evolutionCost", 1)

	# Load stats array
	var stat_list: Array[TowerStat] = []
	for stat_dict in data.get("stats", []):
		var stat := TowerStat.new()
		stat.damage = stat_dict.get("damage", 0)
		stat.attackRange = stat_dict.get("attackRange", 1.0)
		stat.attackSpeed = stat_dict.get("attackSpeed", 1.0)
		stat.critChance = stat_dict.get("critChance", 0.0)
		stat.critMultiplier = stat_dict.get("critMultiplier", 1.0)
		stat.mana = stat_dict.get("mana", 0)
		stat.intialMana = stat_dict.get("intialMana", 0)

		stat_list.append(stat)

	tower.stats = stat_list

	# Optional evolution stat
	if data.has("evolutionStat"):
		var evo_dict: Dictionary = data["evolutionStat"]
		var evo := TowerStat.new()
		evo.damage = evo_dict.get("damage", 0)
		evo.attackRange = evo_dict.get("attackRange", 1.0)
		evo.attackSpeed = evo_dict.get("attackSpeed", 1.0)
		evo.critChance = evo_dict.get("critChance", 0.0)
		evo.critMultiplier = evo_dict.get("critMultiplier", 1.0)
		evo.mana = evo_dict.get("mana", 0)
		evo.intialMana = evo_dict.get("intialMana", 0)

		tower.evolutionStat = evo

	tower.attack_sound = data.get("attack_sound", "default");
	tower.attack_vfx = data.get("attack_vfx", "default");
	tower.open_sound = data.get("open_sound", "default");
	tower.evolve_sound = data.get("evolve_sound", "");

	var skillData = data.get("skill", {"actions": []});
	var skill = Skill.new();
	var skillActions: Array[SkillAction] = [];
	for act in skillData.get("actions", []):
		var action = SkillUtility.ParseAction(act);
		if action != null:
			skillActions.append(action);
		else:
			print("Warning: Failed to parse action in skill for tower", name);

	skill.actions = skillActions;
	_apply_skill_data(skill, skillData, "Unnamed Skill");

	tower.skill = skill

	if data.has("evolution_skill"):
		var evoSkillData = data["evolution_skill"]
		var evoSkill := Skill.new()
		var evoActions: Array[SkillAction] = []
		for act in evoSkillData.get("actions", []):
			var action = SkillUtility.ParseAction(act)
			if action != null:
				evoActions.append(action)
		evoSkill.actions = evoActions
		_apply_skill_data(evoSkill, evoSkillData, "Evolved Skill")
		tower.evolutionSkill = evoSkill

	return tower

static func _apply_skill_data(skill: Skill, skill_data: Dictionary, default_name: String) -> void:
	skill.names = _parse_skill_names(skill_data)
	skill.name = skill_data.get("name", default_name)
	if not skill_data.has("name") and skill.names.size() > 0:
		skill.name = skill.names[0]
	skill.desc = skill_data.get("desc", "")
	skill.desc_template = skill_data.get("desc_template", "")
	skill.parameters = skill_data.get("parameters", {})
	skill.castTime = skill_data.get("cast_time", 0.0)

static func _parse_skill_names(skill_data: Dictionary) -> Array[String]:
	var parsed_names: Array[String] = []
	for display_name in skill_data.get("names", []):
		parsed_names.append(str(display_name))
	return parsed_names
