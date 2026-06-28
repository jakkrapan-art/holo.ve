class_name ResourceManager

static var resourcePrefix = "res://resources/"
static var towerDirPrefix = resourcePrefix + "tower/object/"

static var towerCollection: GameResource

# sprite storage (from SpriteLoader)
static var _sprites: Dictionary = {}

# -----------------------------
# RESOURCE SYSTEM
# -----------------------------

static func loadResources():
	var towerDatas = [];
	for k in TowerCenter._towers_data.keys():
		var data = TowerCenter._towers_data.get(k, null)
		if(data != null):
			towerDatas.append(data.data_name)

	towerCollection = GameResource.new(towerDirPrefix, towerDatas)

static func getTower(key: String):
	if towerCollection == null:
		return null

	return towerCollection.getResource(key.to_lower())

# -----------------------------
# SPRITE SYSTEM (from SpriteLoader)
# -----------------------------

static func loadImage(group, key, path):
	var fullPath = "%s%s" % [resourcePrefix, path]
	var texture: Texture2D = load(fullPath)
	print("Loaded image: ", fullPath, ", group: ", group, ", key: ", key, ", res:", texture);
	if(texture):
		if(_sprites.has(group) == false):
			_sprites[group] = {}
		_sprites[group][key] = texture

	return texture

static func preloadSynergy():
	var synergyList = TowerTrait.TOWER_CLASS_NAMES.values() + TowerTrait.TOWER_GENERATION_NAMES.values();
	synergyList.append("default");
	var statuses = ["", "_active"];
	for synergy in synergyList:
		for status in statuses:
			var key = synergy.to_lower() + status;
			var path = "ui_asset/synergies/" + key + ".png"
			loadImage("synergy", key, path)

# Synergy definitions (resources/database/synergy/) keyed by TowerTrait enum id.
# Loaded next to preloadSynergy() at each addDeck; rebuilt (not accumulated).
static var _synergy_data: Dictionary = {}

static func loadSynergyData() -> void:
	_synergy_data = SynergyDataLoader.load_all()

static func getSynergyData(synergyId: int) -> SynergyData:
	return _synergy_data.get(synergyId, null)

static var _enemy_db: Dictionary = {}    # id -> EnemyDBData (stats + skills + tier); normal/elite only
static var _enemy_tier: Dictionary = {}  # id -> tier string ("elite"/"normal")

# Loads the map's enemy roster (resources/database/enemy/<map>/enemy_list.yaml +
# per-enemy files) into the stats/skills + tier registries and caches each enemy
# sprite. Only normal/elite tiers are registered here; bosses are owned by
# BossLibrary. The sprite path is tier-foldered
# (resources/enemy/<map>/<tier>/<id>/<id>.png), tier coming from the roster.
static func preloadEnemy(mapName: String) -> void:
	var enemyPrefix := "res://resources/enemy"
	var loaded: Dictionary = {}

	_enemy_db = EnemyDataLoader.load_map(mapName)
	_enemy_tier = {}

	for id in _enemy_db.keys():
		var data: EnemyDBData = _enemy_db[id]
		# Record the tier so spawn-time code resolves the correct Enemy.EnemyType
		# (Elite vs Normal vs Boss) for leak damage (PlayerHealth.DAMAGE_BY_MONSTER_TYPE).
		_enemy_tier[id] = data.tier

		var full_path := "%s/%s/%s/%s/%s.png" % [
			enemyPrefix,
			mapName,
			data.tier,
			id,
			id
		]

		if ResourceLoader.exists(full_path):
			var texture: Texture2D = load(full_path)
			loaded[id] = texture
			print("Loaded: ", full_path)
		else:
			push_warning("Missing texture: " + full_path)

	_sprites["enemy"] = loaded
	print("loaded: ", loaded)


static func getSpriteGroup(group: String):
	if !_sprites.has(group):
		return null
	return _sprites[group]

# Returns the full enemy definition (stats + skills + tier) for an enemy id, or
# null if the id was not in the map's enemy DB.
static func getEnemyData(id: String) -> EnemyDBData:
	return _enemy_db.get(id, null)

# Returns the tier string ("boss"/"elite"/"normal") for an enemy id, defaulting
# to "normal" when the id wasn't registered in the enemy DB.
static func getEnemyTier(id: String) -> String:
	return _enemy_tier.get(id, "normal")

static func getSprite(group: String, key: String):
	if !_sprites.has(group):
		return null
	return _sprites[group].get(key, null)

# -----------------------------
# SKILL-EFFECT SHADER WARM-UP
# -----------------------------

# A skill-effect shader compiles its GPU pipeline the first time it is drawn,
# which lands on the visible cast frame → a one-time hitch (worst on heavy
# shaders like Kiara's evolved Hinotori). Warm every deck skill-effect shader
# once here at load (behind the deck / loading screen) so the first in-run cast
# is smooth. Data-driven: reads each tower's normal + evolved play_effect
# actions and resolves the effect script's `SHADER_PATH` const — no per-tower
# hardcoding. Fire-and-forget coroutine; needs a host Node for the scene tree.
#
# Process-wide guard: a shader path warmed once stays warmed (its compiled GPU
# pipeline persists because we keep the Shader ref alive here), so repeated calls
# - e.g. a mid-run deck unlock via addDeck - only warm genuinely-new shaders.
static var _warmed_shaders: Dictionary = {}
static func warmSkillEffectShaders(host: Node) -> void:
	if host == null or not is_instance_valid(host):
		return

	var shaderPaths: Dictionary = {}
	for k in TowerCenter._towers_data.keys():
		var entry = TowerCenter._towers_data.get(k, null)
		# _towers_data values are YAML wrapper dicts; the TowerData is under "data".
		var data = entry.get("data", null) if entry is Dictionary else entry
		if data == null:
			continue
		for skill in [data.skill, data.evolutionSkill]:
			if skill == null:
				continue
			for action in skill.actions:
				if action is SkillActionPlayEffect and action.effectScriptPath != "":
					var sp := _shaderPathFromEffectScript(action.effectScriptPath)
					if sp != "":
						shaderPaths[sp] = true

		# Passive-fired effect shaders (e.g. Shinri's crit pierce arrow): a passive spawns its own
		# effect controller, so it never shows up as a play_effect action above. Read effect_script
		# off the passive + evolutionPassive param dicts and resolve its SHADER_PATH the same way.
		for passive in [data.passive, data.evolutionPassive]:
			if passive is Dictionary and str(passive.get("effect_script", "")) != "":
				var psp := _shaderPathFromEffectScript(str(passive["effect_script"]))
				if psp != "":
					shaderPaths[psp] = true

		# Normal-attack projectile bullet shader (not a skill effect) — warm it too
		# so the first shot doesn't hitch on pipeline compile. Its shader lives in a
		# ShaderMaterial inside the bullet .tscn, invisible to the SHADER_PATH scan, so
		# the path is declared explicitly in the tower's attack_config.vfx_shader.
		if data.attack_config != null and data.attack_config.vfx_shader != "":
			shaderPaths[data.attack_config.vfx_shader] = true

	# Skip shaders already warmed this process; only compile genuinely-new ones.
	var toWarm: Array = []
	for sp in shaderPaths.keys():
		if not _warmed_shaders.has(sp):
			toWarm.append(sp)
	if toWarm.is_empty():
		return

	# Draw each pipeline for two frames on a throwaway CanvasLayer, then free.
	# Must actually rasterize (not visible=false, and on-screen so it isn't
	# culled) so the RenderingServer compiles the pipeline; the real shader +
	# render_mode is used so the key matches the in-run cast. At the shaders'
	# default `progress`=0 the output is ~invisible, and a 2px alpha-low rect
	# for two frames is imperceptible.
	var layer := CanvasLayer.new()
	host.add_child(layer)
	for sp in toWarm:
		var shader = load(sp)
		# Mark the resolved path warmed regardless of load result (a missing file
		# must not retry every unlock); keep the Shader ref so its compiled
		# pipeline survives scene changes and the skip stays valid next run.
		if shader == null:
			_warmed_shaders[sp] = true
			continue
		_warmed_shaders[sp] = shader
		var mat := ShaderMaterial.new()
		mat.shader = shader
		var rect := ColorRect.new()
		rect.size = Vector2(2, 2)
		rect.position = Vector2.ZERO
		rect.modulate = Color(1, 1, 1, 0.01)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.material = mat
		layer.add_child(rect)

	await host.get_tree().process_frame
	await host.get_tree().process_frame

	if is_instance_valid(layer):
		layer.queue_free()

# Reads the `SHADER_PATH` const off an effect controller script without
# instantiating it. Returns "" if the script has no such const (warm skipped).
static func _shaderPathFromEffectScript(scriptPath: String) -> String:
	var script = load(scriptPath)
	if script == null:
		return ""
	var consts: Dictionary = script.get_script_constant_map()
	return consts.get("SHADER_PATH", "")
