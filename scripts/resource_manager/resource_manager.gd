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

static func preloadEnemy(mapName: String, types: Array[String]) -> void:
	var enemyPrefix := "res://resources/enemy"
	var loaded: Dictionary = {}

	var enemies = YamlParser.load_data(enemyPrefix + "/" + mapName + "/enemy_list.yaml")

	for type in types:
		var enemyNames: Array = enemies.get(type, [])
		for enemy in enemyNames:
			var full_path := "%s/%s/%s/%s/%s.png" % [
				enemyPrefix,
				mapName,
				type,
				enemy,
				enemy
			]

			if ResourceLoader.exists(full_path):
				var texture: Texture2D = load(full_path)
				loaded[enemy] = texture
				print("Loaded: ", full_path)
			else:
				push_warning("Missing texture: " + full_path)

	_sprites["enemy"] = loaded
	print("loaded: ", loaded)


static func getSpriteGroup(group: String):
	if !_sprites.has(group):
		return null
	return _sprites[group]

static func getSprite(group: String, key: String):
	if !_sprites.has(group):
		return null
	return _sprites[group].get(key, null)
