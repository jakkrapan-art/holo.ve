class_name GameResource

var collection: Dictionary = {};

func _init(path: String):
	loadResource(path);

func loadResource(path: String):
	var dir = DirAccess.open(path);
	for file in dir.get_files():
		if !file.ends_with(".tscn"):
			continue;

		var key = file.replace(".tscn", "");

		if(collection.has(key)):
			continue;

		var resource = load(path + "/" + file);
		if resource:
			collection[key] = resource;

	print("Loaded resources. path: ", path, " count: ", collection.size(), " keys: ", collection.keys());

func getResource(key: String):
	return collection.get(key, null);