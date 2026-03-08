extends Node

var towers_data: Dictionary
#var selected_deck: String = ""
var selected_deck: String = "Myth" #temporary
var selected_data_file: String = "myth.yaml" #temporary
var selected_map_file: String = "forest01.yaml"

func getTowerNames():
	var names = []
	for k in towers_data.keys():
		var data = towers_data.get(k, null)
		if(data != null):
			names.append(data.name)

	return names
