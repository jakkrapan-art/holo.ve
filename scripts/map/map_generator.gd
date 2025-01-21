extends Node2D
class_name MapGenerator

@onready var tilemap: TileMap = $TileMap
@onready var http_request: HTTPRequest = $HTTPRequest

var sheet_id = "1E2rBOTbbp86NMzjD4M9Pik0iZujyYqPWDcricRiEhAM" # Replace with your Google Sheet ID
var sheet_range = "Map1!A1:E10" # The range you want to fetch
var api_key = "AIzaSyCO9nduvwoJWHB9CvSJpvHGrOd8wapo0Nk" # Replace with your Google API key

func _ready():
	var mapData: MapData = loadData();
	generate(mapData, 11, 11);
	pass

func _process(delta):
	pass

func generate(data: MapData, width: int, height: int):
	if(data == null):
		return;
	
	var currentCol: int = 0;
	var currentRow: int = 0;	
	for t in data.path:
		
		currentCol += 1;
		if (currentCol == width):
			currentRow += 1;
			currentCol = 0;

func setTile(layer: int, cell: Vector2i, sourceId: int, atlasCoord: Vector2i):
	tilemap.set_cell(layer, cell, sourceId, atlasCoord);
	pass
	
func loadData():
	# Construct the URL to fetch data from Google Sheets
	var url = "https://sheets.googleapis.com/v4/spreadsheets/" + sheet_id + "/values/" + sheet_range + "?key=" + api_key
	# Send a request to the Google Sheets API
	var err = http_request.request(url)
	if err != OK:
		print("Failed to send request: ", err)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	if response_code == 200:  # HTTP OK
		var response = JSON.parse_string(body.get_string_from_utf8())
		var data = response.values
		process_sheet_data(data)
	else:
		print("HTTP Request failed with response code:", response_code)

func process_sheet_data(data):
	var mapData: MapData = MapData.new();
	var result: Array[bool] = [];
	var index: int = 0
	for row in data:
		for col in row:
			result.append(col == "TRUE");
			index += 1;
