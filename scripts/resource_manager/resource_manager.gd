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
	for k in Global.towers_data.keys():
		var data = Global.towers_data.get(k, null)
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

static func preloadImage(group: String, path: String):
	var dir = DirAccess.open(path)
	if !dir:
		print("Failed to open directory:", path)
		return

	dir.list_dir_begin()

	var file_name = dir.get_next()
	var loaded: Dictionary = {}

	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".png"):
			var image_path = path + "/" + file_name
			var texture = load(image_path)
			loaded[file_name.substr(0, file_name.length() - 4)] = texture

		file_name = dir.get_next()

	_sprites[group] = loaded

	dir.list_dir_end()


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
