extends Node;
class_name GameScene;

@onready var waveController: WaveController = $WaveController;
@onready var player: Player = $Player
@export var map: MapData = null;

func _ready():
	SpriteLoader.preloadImage("enemy", "res://resources/enemy");
	if (waveController != null):
		waveController.setup(map.waves, Callable(self, "reducePlayerHp"));
		waveController.start();
	pass

func reducePlayerHp(amount: int):
	player.updateHp(-amount);
