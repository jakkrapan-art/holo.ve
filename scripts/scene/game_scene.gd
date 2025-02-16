extends Node;
class_name GameScene;

# Load the pop-up panel scene
var PopupPanelScene = preload("res://scenes/tower_select.tscn");

@onready var waveController: WaveController = $WaveController;
@onready var player: Player = $Player
@export var map: MapData = null;

func _ready():
	SpriteLoader.preloadImage("enemy", "res://resources/enemy");
	if (waveController != null):
		waveController.setup(map.waves, Callable(self, "reducePlayerHp"));
		#waveController.start();
	pass
	show_popup_panel();

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
