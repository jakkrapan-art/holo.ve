extends Node

var _towers_data: Dictionary
var _towers_data_by_name: Dictionary

var _tower_portrait: Dictionary
var _tower_portrait_by_name: Dictionary

var _own_towers: Dictionary = {}

var _canEvoList = [];

#var selected_deck: String = ""
var selected_deck: String = "Myth" #temporary
var selected_data_file: String = "myth.yaml" #temporary
var selected_map_file: String = "forest01.yaml"

func setTowerData(datas: Dictionary):
	_towers_data = datas
	for k in _towers_data.keys():
		var data = _towers_data.get(k, null)
		if(data != null):
			_towers_data_by_name[data.name.to_lower()] = data

			var portrait = preloadPortrait(data.data_name);

			_tower_portrait[data.data_name] = portrait
			_tower_portrait_by_name[data.name.to_lower()] = portrait

func preloadPortrait(name: String):
	return ResourceManager.loadImage("portrait", name, "tower/portrait/" + name + ".png")

func getTowerData(key: String):
	if _towers_data == null:
		return null

	return _towers_data.get(key, null)

func getTowerDataByName(name: String):
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
		return {"level": data.level, "evoCost": data.evoCost if data.level is String and data.level == "Max" else 0}

	return {"level":0, "evoCost":0}

func validateSelectTower(name: String, evoToken: int):
	if _own_towers == null:
		return false

	var data = _own_towers.get(name.to_lower(), null);
	if(data != null):
		if(data.level is String and (data.level == "Evolved" or (data.level == "Max" and data.evoCost > evoToken))):
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
		if(data.level is String):
			if(data.level == "Evolved"):
				return
			if(data.level == "Max"):
				data.level = "Evolved";
				_canEvoList.erase(name);
		else:
			data.level += 1
			if(data.level >= data.maxLevel):
				data.level = "Max";
				_canEvoList.append(name);
	else:
		var tData = getTowerDataByName(name);
		if(tData == null):
			return
		var d = tData.data;
		var evoCost = d.evolutionCost;
		var maxLevel = d.maxLevel;
		_own_towers[name.to_lower()] = {"level": 1, "maxLevel": maxLevel, "evoCost": evoCost};

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
