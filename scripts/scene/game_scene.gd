extends Node2D;
class_name GameScene;

# Load the pop-up panel scene
var PopupPanelScene = preload("res://resources/ui_component/tower_select.tscn");

@onready var waveController: WaveController = $WaveController;
@onready var player: Player = $Player
@onready var map: Map = $TileMap
@export var mapData: MapData = null;
@onready var towerFactory: TowerFactory = $TowerFactory;

var t: Tower = null

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_1 and t == null:
		var tower: Tower = towerFactory.GetTower(TowerFactory.TowerId.Test);
		tower.enterPlaceMode();
		add_child(tower);
		t = tower
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		t.exitPlaceMode();
		t = null;

func _ready():
	if(map != null):
		map.setup();

	show_popup_panel();

	SpriteLoader.preloadImage("enemy", "res://resources/enemy");
	if (towerFactory):
		towerFactory.setup(Callable(self, "placeTower"), Callable(self, "removeTower"));

	if (waveController != null):
		waveController.setup(mapData.waves, Callable(self, "reducePlayerHp"));

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
	if(waveController):
		waveController.start();
	# Run different logic based on the selection
	match selection:
		"Button1":
			run_option_1_logic()
		"Button2":
			run_option_2_logic()
		"Button3":
			run_option_3_logic()

# Example logic for each option
func run_option_1_logic():
	print("Running logic for Option 1")

func run_option_2_logic():
	print("Running logic for Option 2")

func run_option_3_logic():
	print("Running logic for Option 3")
