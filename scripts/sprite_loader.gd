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

	_sprites[group] = loaded;
	dir.list_dir_end();

static func preloadEnemy(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Failed to open directory: %s" % path)
		return

	var loaded: Dictionary = {}

	dir.list_dir_begin()
	var folder := dir.get_next()

	while folder != "":
		# Skip system entries
		if folder != "." and folder != ".." and dir.current_is_dir():
			var sub_path := path + "/" + folder
			var sub_dir := DirAccess.open(sub_path)

			if sub_dir:
				sub_dir.list_dir_begin()
				var file := sub_dir.get_next()

				while file != "":
					if !sub_dir.current_is_dir() and file.ends_with(".png"):
						var full_path := sub_path + "/" + file
						var texture: Texture2D = load(full_path)

						# key = file name without .png
						loaded[folder] = texture

					file = sub_dir.get_next()

				sub_dir.list_dir_end()

		folder = dir.get_next()

	dir.list_dir_end()

	# Store ALL enemies here (as you requested)
	_sprites["enemy"] = loaded

static func getSpriteGroup(group: String):
	if(!_sprites.has(group)):
		return null
	return _sprites[group];
