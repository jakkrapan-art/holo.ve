class_name EnemyDataLoader

# Loads a map's enemy roster into id -> EnemyDBData, mirroring the Tower
# one-file-per-entity layout. The roster manifest
# (resources/database/enemy/<map>/enemy_list.yaml) lists ids per tier; each id
# has its own file resources/database/enemy/<map>/<tier>/<id>.yaml holding stats
# + inline skills. Boss-tier ids are owned by BossLibrary and skipped here.

const PREFIX := "res://resources/database/enemy/"
const ENEMY_TIERS := ["normal", "elite"]

static func load_map(mapName: String) -> Dictionary:
	var out: Dictionary = {}
	var manifestPath := PREFIX + mapName + "/enemy_list.yaml"
	var manifest = YamlParser.load_data(manifestPath)
	if typeof(manifest) != TYPE_DICTIONARY:
		push_error("EnemyDataLoader: invalid or missing enemy roster: " + manifestPath)
		return out

	for tier in ENEMY_TIERS:
		var ids = manifest.get(tier, [])
		if not (ids is Array):
			continue
		for id in ids:
			var entry := _load_enemy(mapName, tier, str(id))
			if entry != null:
				out[str(id)] = entry

	return out

# Loads one enemy file (stats + inline skills) into an EnemyDBData.
static func _load_enemy(mapName: String, tier: String, id: String) -> EnemyDBData:
	var path := PREFIX + mapName + "/" + tier + "/" + id + ".yaml"
	var parsed = YamlParser.load_data(path)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("EnemyDataLoader: invalid or missing enemy file: " + path)
		return null

	var stats = parsed.get("stats", {})
	if typeof(stats) != TYPE_DICTIONARY:
		push_error("EnemyDataLoader: enemy '" + id + "' has no stats map in " + path)
		stats = {}

	# `skill` is an inline list of skill dicts (same shape as tower/boss skills).
	var skills: Array[Skill] = []
	var skillRaw = parsed.get("skill", [])
	if skillRaw is Array and skillRaw.size() > 0:
		skills = SkillUtility.ParseSkill(skillRaw)

	return EnemyDBData.new(id, tier, stats, skills)
