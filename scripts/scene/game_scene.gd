extends Node2D;
class_name GameScene;

# Load the pop-up panel scene
var PopupPanelScene = preload("res://resources/ui_component/tower_select.tscn");

@onready var waveController: WaveController = $WaveController;
@onready var player: Player = $Player
@onready var map: Map = $TileMap
@export var mapData: MapData = null;
@onready var towerFactory: TowerFactory = $TowerFactory;

var mission: Mission = null;
var t: Tower = null
var state: String = ""

func _input(event):
	if state == "tower_placement" and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		t.exitPlaceMode();
		t = null;
		state = "wave"
		if(waveController):
			waveController.start()

func _ready():
	_load_towers_data() # temp
	var camera = get_node("Camera2D")
	camera.make_current()
	print("Camera forced to current:", camera.is_current())
	if(map != null):
		map.setup();

	show_popup_panel();

	SpriteLoader.preloadImage("enemy", "res://resources/enemy");
	
	mission = Mission.new();
	
	if (towerFactory):
		towerFactory.setup(Callable(self, "placeTower"), Callable(self, "removeTower"));
		Utility.ConnectSignal(towerFactory, "onReceiveMission", Callable(mission, "addMission"));

	if (waveController):
		waveController.setup(mapData.waves, Callable(self, "reducePlayerHp"));
		
		waveController.connect("onWaveStart", Callable(towerFactory, "onWaveStart"));
		Utility.ConnectSignal(waveController, "onEnemyDead", Callable(mission, "enemyDeadCheck"));

func placeTower(cell: Vector2):
	map.removeAvailableCell(cell);

func removeTower(cell: Vector2):
	map.addAvailableCell(cell);
	
func checkValidCell(cell: Vector2):
	return !map.grids.has(cell);
func reducePlayerHp(amount: int):
	player.updateHp(-amount);

func show_popup_panel():
	var popup = PopupPanelScene.instantiate()
	# Ensure it's added to the UI layer, not just as a child of the 2D scene
	get_tree().current_scene.add_child(popup)

	# Connect function "_on_option_selected" to the signal "tower_select"
	popup.tower_select.connect(Callable(self, "_on_option_selected"))

# Handle the selection from the popup
func _on_option_selected(selection):
	print("Selected:", selection)
	var tower: Tower = towerFactory.GetTower(selection);
	tower.enterPlaceMode();
	add_child(tower);
	t = tower
	state = "tower_placement"

func _load_towers_data(): #temp
	var selected_deck_file_path = "res://resources/database/" + Global.selected_data_file
	Global.towers_data = YamlParser.load_data(selected_deck_file_path)
