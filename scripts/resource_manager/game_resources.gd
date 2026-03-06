class_name GameResource

var collection: Dictionary = {};

func _init(prefix: String, resourceList: Array):
	loadResource(prefix, resourceList);

func loadResource(prefix: String, resourceList: Array):
	for resource in resourceList:
		var full_path := "%s/%s.tscn" % [
			prefix,
			resource.to_lower()
		]

		if(ResourceLoader.exists(full_path)):
			var key = resource.to_lower();
			if(collection.has(key)):
				continue;

			var r = load(full_path);
			if r:
				collection[key] = r;
		else:
			push_warning("Missing resource: " + full_path)

	print("Loaded resources. prefix: ", prefix, " count: ", collection.size(), " keys: ", collection.keys());

func getResource(key: String):
	return collection.get(key, null);
