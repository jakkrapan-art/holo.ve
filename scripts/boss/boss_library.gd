class_name BossLibrary

# Loads a map's bosses from the shared enemy roster: the `boss` tier of
# resources/database/enemy/<map>/enemy_list.yaml lists boss ids; each has its own
# file resources/database/enemy/<map>/boss/<id>.yaml (stats + boss fields + inline
# skills). The sprite path mirrors the enemy tree (.../boss/<id>/<id>.png).

const ENEMY_PREFIX := "res://resources/database/enemy/"
const SPRITE_PREFIX := "res://resources/enemy/"

var bossPool: Dictionary = {}

func _init(mapName: String):
	var bossList: Array[BossDBData] = []
	var manifestPath := ENEMY_PREFIX + mapName + "/enemy_list.yaml"
	var manifest = YamlParser.load_data(manifestPath)
	if typeof(manifest) == TYPE_DICTIONARY:
		var ids = manifest.get("boss", [])
		if ids is Array:
			for id in ids:
				var boss := _load_boss(mapName, str(id))
				if boss != null:
					bossList.append(boss)
	else:
		push_error("BossLibrary: invalid or missing enemy roster: " + manifestPath)

	bossPool[mapName] = {"boss": bossList}

# Loads one boss file (stats + boss fields + inline skills) into a BossDBData.
func _load_boss(mapName: String, id: String) -> BossDBData:
	var path := ENEMY_PREFIX + mapName + "/boss/" + id + ".yaml"
	var bd = YamlParser.load_data(path)
	if typeof(bd) != TYPE_DICTIONARY:
		push_error("BossLibrary: invalid or missing boss file: " + path)
		return null

	var bossName = bd.get("name", id)
	var wave: Array = bd.get("wave", [])
	var scale = bd.get("scale", 1.0)
	var stats = bd.get("stats", {})

	var texturePath := SPRITE_PREFIX + mapName + "/boss/" + id + "/" + id + ".png"
	var texture = load(texturePath)
	if texture == null:
		push_error("Failed to load texture at path: ", texturePath)

	var bossSkills: Array[Skill] = []
	var skillRaw = bd.get("skill", [])
	if skillRaw is Array and skillRaw.size() > 0:
		bossSkills = SkillUtility.ParseSkill(skillRaw)

	return BossDBData.new(bossName, wave, texture, scale, stats, bossSkills)

func getBossList(key: String) -> Array[BossDBData]:
	if bossPool.has(key):
		return bossPool[key]["boss"]
	return []
