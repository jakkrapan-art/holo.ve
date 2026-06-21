class_name EnemyDataLoader

# Loads a per-map enemy DB (resources/database/enemy/<map>.yaml) into id -> EnemyDBData.
# The file is a block-style map keyed by enemy id; each entry has tier + stats + skill.
# Mirrors the boss DB loading pattern (BossLibrary).

static func load_map(mapName: String) -> Dictionary:
	var path := "res://resources/database/enemy/" + mapName + ".yaml"
	var parsed = YamlParser.load_data(path)
	var out: Dictionary = {}

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("EnemyDataLoader: invalid or missing enemy DB: " + path)
		return out

	for id in parsed.keys():
		var entry = parsed[id]
		if typeof(entry) != TYPE_DICTIONARY:
			push_error("EnemyDataLoader: enemy '" + str(id) + "' is not a map in " + path)
			continue

		var tier := str(entry.get("tier", "normal"))
		var stats = entry.get("stats", {})
		if typeof(stats) != TYPE_DICTIONARY:
			push_error("EnemyDataLoader: enemy '" + str(id) + "' has no stats map in " + path)
			stats = {}

		# `skill` is a list of skill ids resolved from the skill library (enemy pool).
		var skills: Array[Skill] = []
		var skillRaw = entry.get("skill", [])
		if skillRaw is Array and skillRaw.size() > 0:
			skills = SkillLibrary.resolve("enemy", skillRaw)

		out[str(id)] = EnemyDBData.new(str(id), tier, stats, skills)

	return out
