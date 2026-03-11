extends Node

var _towers_data: Dictionary
var _towers_data_by_name: Dictionary

var _tower_portrait: Dictionary
var _tower_portrait_by_name: Dictionary
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

			if portrait:
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

func getTowerPortraitByName(name: String):
	if _tower_portrait_by_name == null:
		return null

	return _tower_portrait_by_name.get(name.to_lower(), null)
