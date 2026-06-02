class_name StaffDataLoader

# Mirror of TowerDataLoader — loads a per-staff YAML into a StaffData Resource.
# Caller passes prefix (folder containing the .yaml) + name (file basename without extension).

static func load_data(prefix: String, name: String) -> StaffData:
	var path = prefix + name + ".yaml"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("StaffDataLoader: failed to open " + path)
		return null

	var parsed = YamlParser.load_data(path)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("StaffDataLoader: invalid YAML format: " + path)
		return null

	var data: Dictionary = parsed
	var staff := StaffData.new()

	staff.data_name = data.get("data_name", name)
	staff.name = data.get("name", name)
	staff.max_hp = int(data.get("max_hp", 100))

	staff.hud_portrait = data.get("hud_portrait", "")
	staff.hud_skill_icon = data.get("hud_skill_icon", "")
	staff.selection_portrait = data.get("selection_portrait", "")
	staff.end_sprite_scene = data.get("end_sprite_scene", "")

	# Skill block — mirror tower_data_loader.gd skill parsing pattern.
	var skill_dict = data.get("skill", {})
	if skill_dict is Dictionary and not skill_dict.is_empty():
		var skill := Skill.new()
		skill.name = skill_dict.get("name", "")
		skill.desc = skill_dict.get("desc", "")
		skill.castTime = float(skill_dict.get("cast_time", 0.0))
		skill.parameters = skill_dict.get("parameters", {})

		var actions: Array[SkillAction] = []
		for action_data in skill_dict.get("actions", []):
			var action = SkillUtility.ParseAction(action_data, skill.parameters)
			if action != null:
				actions.append(action)
			else:
				push_warning("StaffDataLoader: failed to parse action in skill " + skill.name)
		skill.actions = actions
		staff.skill = skill

		# Charge-based use limit (replaces legacy one_time_use boolean).
		# YAML: `use_charges: 1` → 1 charge; omit / 0 / negative → unlimited (-1).
		var raw_charges = skill_dict.get("use_charges", -1)
		var max_charges: int = int(raw_charges)
		if max_charges <= 0:
			max_charges = -1
		staff.skill_max_charges = max_charges

		# AOE footprint (for cast indicator) — read from skill.aoe block.
		var aoe_dict = skill_dict.get("aoe", {})
		if aoe_dict is Dictionary:
			staff.skill_aoe_width = int(aoe_dict.get("width", 4))
			staff.skill_aoe_height = int(aoe_dict.get("height", 4))

		# Cast animation + sound (asset-pending — see VFX TODOs in Phase 2 plan).
		staff.cast_animation = skill_dict.get("cast_animation", "")
		staff.cast_sound = skill_dict.get("cast_sound", "")

	return staff
