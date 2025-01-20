extends Node
class_name SpriteLoader

static var _sprites = {}

static func preloadImage(group: String, path: String):
	var dir = DirAccess.open(path)
	if !dir:
		print("Failed to open directory:", path)		
		return;
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var loaded: Dictionary = {}
	while file_name != "":
		if dir.current_is_dir() == false and file_name.ends_with(".png"):
			var image_path = path + "/" + file_name
			var texture = load(image_path)
			loaded[file_name.substr(0, file_name.length() - 4)] = texture
		file_name = dir.get_next()

	_sprites[group] = loaded
	dir.list_dir_end()
	print("Preloaded" + group + "Sprites:", loaded)

static func getSpriteGroup(group: String):
	if(!_sprites.has(group)):
		return null
	return _sprites[group];
