extends Node

var _towers_data: Dictionary
var _default_tower_data: Object;
var _towers_data_by_name: Dictionary

var _tower_portrait: Dictionary
var _tower_portrait_by_name: Dictionary

var _own_towers: Dictionary = {}

var _canEvoList = [];
var _evolvedList = [];

#var selected_deck: String = ""
var selected_deck: String = "Myth" #temporary
var selected_data_file: String = "myth.yaml" #temporary
var selected_map_file: String = "forest01.yaml"

# Deck registry: static metadata from decks.yaml, loaded once at autoload init.
# added_decks tracks which decks have been merged into the live tower pool during a run.
var _decks_registry: Dictionary = {}
var added_decks: Array[String] = []

func _ready():
	_decks_registry = YamlParser.load_data("res://resources/database/towers/decks/decks.yaml")

func clearData():
	_towers_data = {}
	_default_tower_data = null

	_towers_data_by_name = {}

	_tower_portrait = {}
	_tower_portrait_by_name = {}

	_own_towers = {}

	_canEvoList = []
	_evolvedList = []

	added_decks = []

func addDeck(deck_key: String) -> bool:
	if added_decks.has(deck_key):
		return false
	var deck_info = _decks_registry.get(deck_key, null)
	if deck_info == null:
		push_error("TowerCenter.addDeck: unknown deck_key " + deck_key)
		return false

	var data_file_path = "res://resources/database/towers/decks/" + deck_info.data_file
	var tower_list = YamlParser.load_data(data_file_path)
	for k in tower_list:
		var td = tower_list[k]
		td.data = TowerDataLoader.load_data("res://resources/database/towers/", td.data_name.to_lower())

	setTowerData(tower_list)
	added_decks.append(deck_key)

	ResourceManager.preloadSynergy();
	ResourceManager.loadSynergyData();
	# Rebuild the tower-scene cache so a deck added mid-run (the wave-clear deck
	# unlock) has its tower .tscn loaded; otherwise getTower misses and the new
	# deck's towers fall back to the default/placeholder scene.
	ResourceManager.loadResources();
	# Pre-compile this deck's skill/bullet shaders (behind the deck / loading
	# screen, or the wave-clear popup for a mid-run unlock) so the first in-run
	# cast doesn't hitch. self (TowerCenter autoload) is the in-tree host; the
	# _warmed guard makes repeat calls only warm new shaders. Fire-and-forget.
	ResourceManager.warmSkillEffectShaders(self);
	return true

func getAvailableDecks() -> Array:
	var result := []
	for key in _decks_registry.keys():
		if !added_decks.has(key):
			result.append({"key": key, "info": _decks_registry[key]})
	return result

func setTowerData(datas: Dictionary):
	for k in datas.keys():
		var data = datas.get(k, null)
		if(data != null):
			_towers_data[data.data_name] = data;
			_towers_data_by_name[data.name.to_lower()] = data

			var portrait = preloadPortrait(data.data_name);

			_tower_portrait[data.data_name] = portrait
			_tower_portrait_by_name[data.name.to_lower()] = portrait

func setDefaultTowerData(data):
	_default_tower_data = data

func preloadPortrait(name: String):
	return ResourceManager.loadImage("portrait", name, "tower/portrait/" + name + ".png")

func getTowerData(key: String):
	if(key == "default"):
		return _default_tower_data;

	if _towers_data == null:
		return null

	return _towers_data.get(key, null)

func getTowerDataByName(name: String):
	if(name == "default"):
		return _default_tower_data;

	if _towers_data_by_name == null:
		return null

	return _towers_data_by_name.get(name.to_lower(), null)

func getTowerNames():
	var names = []
	for k in _towers_data.keys():
		var data = _towers_data.get(k, null)
		if(data != null):
			names.append(data.name)

	return names

func getTowerSelectDataByName(name: String):
	if _own_towers == null:
		return null

	var data = _own_towers.get(name.to_lower(), null);
	if(data != null):
		var maxed: bool = data.level >= data.maxLevel and not data.isEvolved
		return {"level": data.level, "evoCost": data.evoCost if maxed else 0}

	return {"level":0, "evoCost":0}

func validateSelectTower(name: String, evoToken: int):
	if(_evolvedList.find(name) >= 0):
		return false

	if _own_towers == null:
		return false

	var data = _own_towers.get(name.to_lower(), null);
	if(data != null):
		var maxed: bool = data.level >= data.maxLevel and not data.isEvolved
		if(data.isEvolved or (maxed and data.evoCost > evoToken)):
			return false

		return true

	return true

func getTowerEvolutionCostByName(name: String):
	if _own_towers == null:
		return null

	var data = _own_towers.get(name.to_lower(), null);
	if(data != null):
		if(data.level >= data.maxLevel):
			return data.evoCost
		else:
			return 0;

	return 0

func upgradeTowerLevelByName(name: String):
	if _own_towers == null:
		return null

	var data = _own_towers.get(name.to_lower(), null);
	if(data != null):
		if(data.isEvolved):
			return
		if(data.level >= data.maxLevel):
			data.isEvolved = true;
			_canEvoList.erase(name);
		else:
			data.level += 1
			if(data.level >= data.maxLevel):
				_canEvoList.append(name);
	else:
		var tData = getTowerDataByName(name);
		if(tData == null):
			return
		var d = tData.data;
		var evoCost = d.evolutionCost;
		var maxLevel = d.maxLevel;
		_own_towers[name.to_lower()] = {"level": 1, "maxLevel": maxLevel, "evoCost": evoCost, "isEvolved": false};

func getTowerPortraitByName(name: String):
	if _tower_portrait_by_name == null:
		return null
	var portrait = _tower_portrait_by_name.get(name.to_lower(), null);
	if(portrait != null):
		return portrait

	return null

func getEvolutionList(count: int):
	if(_canEvoList.size() <= count):
		return _canEvoList;

	var temp = _canEvoList.duplicate();
	var result = []
	for i in range(count):
		var index = randi_range(0, temp.size() - 1);
		var towerName = temp[index];
		result.append(towerName);
		temp.remove_at(index);
	return result;
