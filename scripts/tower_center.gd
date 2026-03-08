extends Node

var towers_data: Dictionary
var towers_data_by_name: Dictionary
#var selected_deck: String = ""
var selected_deck: String = "Myth" #temporary
var selected_data_file: String = "myth.yaml" #temporary
var selected_map_file: String = "forest01.yaml"

func setTowerData(datas: Dictionary):
	towers_data = datas
	for k in towers_data.keys():
		var data = towers_data.get(k, null)
		if(data != null):
			towers_data_by_name[data.name.to_lower()] = data

func getTowerData(key: String):
	if towers_data == null:
		return null

	return towers_data.get(key, null)

func getTowerDataByName(name: String):
	if towers_data_by_name == null:
		return null

	return towers_data_by_name.get(name.to_lower(), null)

func getTowerNames():
	var names = []
	for k in towers_data.keys():
		var data = towers_data.get(k, null)
		if(data != null):
			names.append(data.name)

	return names
