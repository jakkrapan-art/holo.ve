extends Node

# Autoload registry for Staff data — mirrors TowerCenter's role for towers.
# Boot: reads staffs.yaml manifest (lightweight pointer table).
# loadAllStaffs(): expands manifest → loads per-staff YAML → caches as StaffData.

const STAFFS_DIR := "res://resources/database/staffs/"
const MANIFEST_PATH := STAFFS_DIR + "staffs.yaml"

var _staff_registry: Dictionary = {}   # key -> { name, data_file }
var _staff_data: Dictionary = {}        # key -> StaffData (loaded on demand or via loadAllStaffs)

# Selected staff for the current run. Currently hardcoded to "a_chan" (demo).
# Deck Selection UI updates this when the player picks a bullet.
var selected_staff: String = "a_chan"

func _ready():
	_staff_registry = YamlParser.load_data(MANIFEST_PATH)
	if typeof(_staff_registry) != TYPE_DICTIONARY:
		push_error("StaffCenter: failed to load manifest " + MANIFEST_PATH)
		_staff_registry = {}

func loadAllStaffs():
	# Idempotent — safe to call multiple times. Loads every staff defined in the manifest.
	_staff_data = {}
	for key in _staff_registry.keys():
		var entry = _staff_registry[key]
		var data_file = entry.get("data_file", key + ".yaml") if entry is Dictionary else (key + ".yaml")
		var basename = data_file.replace(".yaml", "")
		var staff = StaffDataLoader.load_data(STAFFS_DIR, basename)
		if staff != null:
			_staff_data[key] = staff

func getStaffData(key: String) -> StaffData:
	return _staff_data.get(key, null)

func getSelectedStaff() -> StaffData:
	return getStaffData(selected_staff)

func getAvailableStaffs() -> Array:
	# Returns array of { key, name } for UI population (selection bullets).
	var result := []
	for key in _staff_registry.keys():
		var entry = _staff_registry[key]
		var display_name: String = entry.get("name", key) if entry is Dictionary else key
		result.append({"key": key, "name": display_name})
	return result
