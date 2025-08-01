class_name ResourceManager

static var resourcePrefix = "res://resources/"
static var towerDirPath = "tower/object"

static var towerCollection: GameResource;

static func loadResources():
	towerCollection = GameResource.new(resourcePrefix + towerDirPath);

static func getTower(key: String):
	if(towerCollection == null):
		return null;

	return towerCollection.getResource(key.to_lower());
