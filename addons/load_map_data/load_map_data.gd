@tool
extends EditorPlugin

const API_KEY: String = "AIzaSyCO9nduvwoJWHB9CvSJpvHGrOd8wapo0Nk";
const URL: String = "https://sheets.googleapis.com/v4/spreadsheets/1E2rBOTbbp86NMzjD4M9Pik0iZujyYqPWDcricRiEhAM?key=" + API_KEY;

enum FETCH_DATA_STATE {NONE, SPREADSHEET, MAP_LIST, WAVE_DATA}

var fetch_state: FETCH_DATA_STATE = FETCH_DATA_STATE.NONE;
var http_request: HTTPRequest;
var map_datas: Dictionary = {};
var map_fetching_name: String = "";
var request_map_data_queue: Array = [];

func _enter_tree():
	# Create a PopupMenu
	var popup = PopupMenu.new()
	popup.name = "CustomPopupMenu"
	popup.add_item("map data", 0)

	# Connect the signal
	popup.connect("id_pressed", Callable(self, "_on_popup_menu_id_pressed"))

	# Add the popup as a tool submenu
	add_tool_submenu_item("load data", popup)

func _exit_tree():
	# Remove the submenu item
	remove_tool_menu_item("load data")

func _on_popup_menu_id_pressed(id):
	match id:
		0:
			load_google_sheet_script();

func load_google_sheet_script():
	map_datas = {};
	map_fetching_name = "";
	if http_request == null:
		http_request = HTTPRequest.new()
		add_child(http_request);
		http_request.connect("request_completed", Callable(self, "_on_request_completed"));

	fetch_state = FETCH_DATA_STATE.SPREADSHEET;
	http_request.request(URL)

func _on_request_completed(result, response_code, headers, body):
	match fetch_state:
		FETCH_DATA_STATE.SPREADSHEET:
			_on_request_completed_metadata(result, response_code, headers, body)
			pass
		FETCH_DATA_STATE.MAP_LIST:
			_on_request_completed_maplist(result, response_code, headers, body)
			pass
		FETCH_DATA_STATE.WAVE_DATA:
			_on_request_completed_wave(result, response_code, headers, body)
			pass

func _on_request_completed_metadata(result, response_code, headers, body):
	reset_fetch_state();
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data.has("sheets"):
			var sheets: Array = data.sheets
			for sheet in sheets:
				var props = sheet.properties
				if props.title == "MapList":
					request_maplist_data(props.title)
					break
		else:
			print("No sheets found in the response")
	else:
		print("Failed to load Google Sheet data. Response code:", response_code, "\nBody:", body.get_string_from_utf8())

func request_maplist_data(sheet_name: String):
	var sheet_data_url = URL + "&ranges=" + sheet_name + "&includeGridData=true"
	fetch_state = FETCH_DATA_STATE.MAP_LIST;
	http_request.request(sheet_data_url)

func _on_request_completed_maplist(result, response_code, headers, body):
	reset_fetch_state();
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data.has("sheets"):
			var sheet_data = data.sheets[0]
			if sheet_data.has("data"):
				parse_maplist_data(sheet_data.data[0])
		else:
			print("No data found for MapList sheet")
	else:
		print("Failed to load MapList data. Response code:", response_code, "\nBody:", body.get_string_from_utf8())

func parse_maplist_data(grid_data):
	var is_first_row = true;
	request_map_data_queue = [];
	if grid_data.has("rowData"):
		for row in grid_data.rowData:
			if is_first_row:
				is_first_row = false;
				continue;

			if row.has("values") and row.values.size() > 0:
				var map_name_cell = row.values[0]
				var map_key_cell = row.values[1];
				var wave_count_cell = row.values[2]
				if !map_name_cell.has("userEnteredValue") || !wave_count_cell.has("userEnteredValue") || !map_key_cell.has("userEnteredValue"):
					continue;
				
				var wave_count = wave_count_cell.userEnteredValue.numberValue;
				for i in range(0, wave_count):
					request_map_data_queue.append(Callable(self, "get_map_wave_data").bind(map_key_cell.userEnteredValue.stringValue, i + 1));

	execute_get_wave_data_queue();

func _on_request_completed_wave(result, response_code, headers, body):
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data.has("sheets"):
			var sheetData = data.sheets[0]
			if sheetData.has("data"):
				var waveData = parse_wave_data(sheetData.data[0]);
				print("wave data:", waveData, ", map", map_fetching_name)
				if waveData != null && !map_fetching_name.is_empty():
					print("adding to dict");
					if map_datas.has(map_fetching_name):
						map_datas[map_fetching_name].waves.append(waveData);
					else:
						var map = MapData.new();
						map.setWave([waveData]);
						map_datas[map_fetching_name] = map
				
			delay_call_function(Callable(self, "execute_get_wave_data_queue"));
		else:
			print("No data found for WaveData sheet")
	else:
		print("Failed to load WaveData sheet. Response code:", response_code, "\nBody:", body.get_string_from_utf8())

func execute_get_wave_data_queue():
	if request_map_data_queue.size() <= 0:
		reset_fetch_state();
		for key in map_datas.keys():
			var waves = map_datas[key];
			var path = "res://resources/database/map/" + key + ".tres";
			if(FileAccess.file_exists(path)):
				waves.take_over_path(path);

			var saveResult = ResourceSaver.save(waves, path);
			print("save result:", saveResult);
		
		print("load ", map_datas.size(), " map data success.");
		return;
	
	fetch_state = FETCH_DATA_STATE.WAVE_DATA;
	var f = request_map_data_queue.pop_front();
	f.call();

func get_map_wave_data(mapKey: String, mapIndex: int):
	var wave_data_url = URL + "&ranges=" + mapKey + "_" + String.num(mapIndex) + "&includeGridData=true"
	http_request.request(wave_data_url);
	print("getting: " + mapKey + "_", mapIndex)
	map_fetching_name = mapKey;
	
func parse_wave_data(grid_data):
	var is_first_row = true;
	var waveData: WaveData = WaveData.new();
	if grid_data.has("rowData"):
		for row in grid_data.rowData:
			if is_first_row:
				is_first_row = false;
				continue;

			if row.has("values") and row.values.size() > 0:
				var texture_raw = row.values[0] if row.values.size() > 1 else { userEnteredValue = {stringValue = "default"} }
				var type_raw = row.values[1] if row.values.size() > 2 else { userEnteredValue = {stringValue = "Normal"} }
				var health_raw = row.values[2] if row.values.size() > 3 else { userEnteredValue = {numberValue = 20} }
				var def_raw = row.values[3] if row.values.size() > 4 else { userEnteredValue = {numberValue = 1} }
				var m_def_raw = row.values[4] if row.values.size() > 5 else { userEnteredValue = {numberValue = 1} }
				var move_speed_raw = row.values[5] if row.values.size() > 6 else { userEnteredValue = {numberValue = 5} }
				var count_raw = row.values[6] if row.values.size() > 7 else { userEnteredValue = {numberValue = 20} }

				if !texture_raw.has("userEnteredValue") || !health_raw.has("userEnteredValue") || !def_raw.has("userEnteredValue") || !m_def_raw.has("userEnteredValue") || !move_speed_raw.has("userEnteredValue") || !count_raw.has("userEnteredValue"):
					continue;

				var texture = texture_raw.userEnteredValue.stringValue;
				var type = type_raw.userEnteredValue.stringValue;
				var health = health_raw.userEnteredValue.numberValue;
				var def = def_raw.userEnteredValue.numberValue;
				var m_def = m_def_raw.userEnteredValue.numberValue;
				var move_speed = move_speed_raw.userEnteredValue.numberValue;
				var count = count_raw.userEnteredValue.numberValue;
				
				var group: WaveEnemyGroup = WaveEnemyGroup.new();
				group.setup(texture, health, def, m_def, move_speed, count);
				waveData.addGroup(group);
	if (waveData.groupList.size() == 0):
		return null;

	return waveData;

func reset_fetch_state():
	fetch_state = FETCH_DATA_STATE.NONE;	

func delay_call_function(function: Callable, delay: int = 1):
	var timer: Timer = null;
	const timer_name = "delay_call_timer";
	
	timer = find_child("./" + timer_name) as Timer;

	if(timer == null):
		timer = Timer.new();
		timer.name = timer_name;
		add_child(timer);
	
	timer.wait_time = delay;
	timer.one_shot = true;
	timer.start();
	
	await timer.timeout;
	function.call();
	remove_child(timer);
