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
	tower.towerClass = Utility.parse_tower_trait_enum(TowerData.TowerClass, data.get("towerClass", "Assassin"))
	tower.generation = Utility.parse_tower_trait_enum(TowerData.TowerGeneration, data.get("generation", "Myth"))

	tower.evolutionCost = data.get("evolutionCost", 1)

	# Load skill resource
	var skill_path: String = data.get("skill", "")
	if skill_path != "":
		tower.skill = load(skill_path)

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
		stat.manaRegen = stat_dict.get("manaRegen", 0.0)
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
		evo.manaRegen = evo_dict.get("manaRegen", 0.0)
		evo.intialMana = evo_dict.get("intialMana", 0)

		tower.evolutionStat = evo

	return tower
