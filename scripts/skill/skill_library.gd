class_name SkillLibrary

# Loads enemy/boss skill definitions from one-file-per-skill YAMLs:
#   res://resources/database/skill/<pool>/<id>.yaml   (pool = "enemy" | "boss")
# Convention-path + cache, mirroring TowerDataLoader/BossLibrary. Caches ONE parsed
# Skill TEMPLATE per (pool, id); spawn paths deep-duplicate it per instance because
# Skill carries mutable runtime state (using / disable / cooldownRemaining).

const PREFIX := "res://resources/database/skill/"

static var _cache: Dictionary = {}  # "pool/id" -> Skill

# Returns the cached skill template for an id, loading it on first use.
static func get_skill(pool: String, id: String) -> Skill:
	var key := pool + "/" + id
	if _cache.has(key):
		return _cache[key]

	var path := PREFIX + pool + "/" + id + ".yaml"
	var parsed = YamlParser.load_data(path)
	if typeof(parsed) != TYPE_DICTIONARY or parsed.is_empty():
		push_error("SkillLibrary: skill not found or invalid: " + path)
		return null

	var skills: Array[Skill] = SkillUtility.ParseSkill([parsed])
	if skills.is_empty():
		push_error("SkillLibrary: failed to parse skill: " + path)
		return null

	_cache[key] = skills[0]
	return skills[0]

# Resolves an id-string list into a typed Array[Skill] of templates. Unknown ids
# fail loud (push_error in get_skill) and are skipped. The typed return is required:
# Godot 4.3 rejects assigning an untyped Array into EnemyDBData/BossDBData.skills.
static func resolve(pool: String, ids) -> Array[Skill]:
	var out: Array[Skill] = []
	if ids == null or not (ids is Array):
		return out
	for id in ids:
		var s := get_skill(pool, str(id))
		if s != null:
			out.append(s)
	return out
