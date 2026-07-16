class_name TowerDataLoader
static func load_data(prefix: String, name: String) -> TowerData:
	# print("load tower from yaml: ", path);
	var path = prefix + name + ".yaml";
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Failed to open YAML: " + path + " try loading default.")
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
		stat.initialMana = stat_dict.get("initialMana", 0)

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
		evo.initialMana = evo_dict.get("initialMana", 0)

		tower.evolutionStat = evo

	tower.attack_sound = data.get("attack_sound", "default");
	tower.attack_vfx = data.get("attack_vfx", "default");
	tower.open_sound = data.get("open_sound", "default");
	tower.evolve_sound = data.get("evolve_sound", "");

	# Optional normal-attack block (absent = hitscan, back-compat).
	if data.has("attack") and data["attack"] is Dictionary:
		tower.attack_config = TowerAttackConfig.from_dict(data["attack"])

	tower.passive = _resolve_passive_block(data, "skills")
	tower.evolutionPassive = _resolve_passive_block(data, "evolution_skills")

	var skillData := _resolve_skill_block(data, "skills", "skill", name, {"actions": []})
	tower.skill = _parse_skill_data(skillData, "Unnamed Skill", name, "active skill")

	var evoSkillData := _resolve_skill_block(data, "evolution_skills", "evolution_skill", name, {})
	if not evoSkillData.is_empty():
		tower.evolutionSkill = _parse_skill_data(evoSkillData, "Evolved Skill", name, "evolved active skill")

	return tower

static func _resolve_skill_block(data: Dictionary, slot_root_key: String, legacy_key: String, tower_name: String, default_block: Dictionary) -> Dictionary:
	var has_new_slot := false
	var new_skill_data: Dictionary = {}
	if data.has(slot_root_key):
		var slot_root = data[slot_root_key]
		if slot_root is Dictionary:
			if slot_root.has("active") and slot_root["active"] != null:
				if slot_root["active"] is Dictionary:
					new_skill_data = slot_root["active"]
					has_new_slot = true
				else:
					push_warning("Tower YAML '" + tower_name + "': '" + slot_root_key + ".active' must be a dictionary.")
		elif slot_root != null:
			push_warning("Tower YAML '" + tower_name + "': '" + slot_root_key + "' must be a dictionary.")

	var has_legacy := false
	var legacy_skill_data: Dictionary = {}
	if data.has(legacy_key) and data[legacy_key] != null:
		if data[legacy_key] is Dictionary:
			legacy_skill_data = data[legacy_key]
			has_legacy = true
		else:
			push_warning("Tower YAML '" + tower_name + "': '" + legacy_key + "' must be a dictionary.")

	if has_new_slot:
		if has_legacy:
			push_warning("Tower YAML '" + tower_name + "': both '" + legacy_key + "' and '" + slot_root_key + ".active' exist; using the new slot.")
		return new_skill_data
	if has_legacy:
		return legacy_skill_data
	return default_block

# Display-only Skill built from a passive params block (no runtime actions):
# passives are stored as raw Dictionaries, so this gives UI consumers (stats
# panel tooltip) the same metadata surface as an active skill. Runtime passive
# behavior is untouched.
static func build_passive_display_skill(passive_data: Dictionary) -> Skill:
	if passive_data == null or passive_data.is_empty():
		return null
	var skill := Skill.new()
	_apply_skill_data(skill, passive_data, "Passive")
	return skill

static func _resolve_passive_block(data: Dictionary, slot_root_key: String) -> Dictionary:
	if not data.has(slot_root_key):
		return {}
	var slot_root = data[slot_root_key]
	if not (slot_root is Dictionary):
		return {}
	var passive = slot_root.get("passive", null)
	if passive is Dictionary:
		return passive
	return {}

static func _parse_skill_data(skill_data: Dictionary, default_name: String, tower_name: String, source_name: String) -> Skill:
	var skill := Skill.new()
	var skillActions: Array[SkillAction] = []
	var action_data_list = skill_data.get("actions", [])
	# Read parameters before the action loop so actions can bind to them
	# (skill.parameters is set later in _apply_skill_data).
	var parameters = skill_data.get("parameters", {})
	if action_data_list is Array:
		for act in action_data_list:
			var action = SkillUtility.ParseAction(act, parameters)
			if action != null:
				skillActions.append(action)
			else:
				push_warning("Tower YAML '" + tower_name + "': failed to parse action in " + source_name + ".")
	else:
		push_warning("Tower YAML '" + tower_name + "': actions in " + source_name + " must be an array.")

	skill.actions = skillActions
	_apply_skill_data(skill, skill_data, default_name)
	return skill

static func _apply_skill_data(skill: Skill, skill_data: Dictionary, default_name: String) -> void:
	skill.names = _parse_skill_names(skill_data)
	skill.name = skill_data.get("name", default_name)
	if not skill_data.has("name") and skill.names.size() > 0:
		skill.name = skill.names[0]
	# Custom YAML parser preserves backslash escapes literally; translate "\n" tokens
	# from skill copy into real newlines so designers can split notes onto their own line.
	# Single tokenized desc key; a stale file still carrying the removed
	# desc_template key warns and its tokenized text wins.
	skill.desc = str(skill_data.get("desc", "")).replace("\\n", "\n")
	if skill_data.has("desc_template"):
		push_warning("Skill '" + skill.name + "': 'desc_template' was merged into 'desc' - rename the key (its tokenized text is used).")
		skill.desc = str(skill_data.get("desc_template", "")).replace("\\n", "\n")
	skill.parameters = skill_data.get("parameters", {})
	skill.castTime = skill_data.get("cast_time", 0.0)
	skill.recoveryTime = skill_data.get("recovery", 0.2)
	skill.tags = _parse_string_array(skill_data.get("tags", []))
	skill.target_summary = _parse_dictionary(skill_data.get("target_summary", {}))
	skill.icon = str(skill_data.get("icon", ""))
	skill.effects = _parse_array(skill_data.get("effects", []))

static func _parse_skill_names(skill_data: Dictionary) -> Array[String]:
	var parsed_names: Array[String] = []
	for display_name in skill_data.get("names", []):
		parsed_names.append(str(display_name))
	return parsed_names

static func _parse_string_array(value) -> Array[String]:
	var parsed_values: Array[String] = []
	if not (value is Array):
		return parsed_values
	for item in value:
		parsed_values.append(str(item))
	return parsed_values

static func _parse_dictionary(value) -> Dictionary:
	if value is Dictionary:
		return value
	return {}

static func _parse_array(value) -> Array:
	if value is Array:
		return value
	return []
