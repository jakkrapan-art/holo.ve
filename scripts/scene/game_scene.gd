extends Node;
class_name GameScene;

@onready var waveController: WaveController = $WaveController;
@export var map: MapData = null;

func _ready():
	SpriteLoader.preloadImage("enemy", "res://resources/enemy");
	if (waveController != null):
		waveController.setup(map.waves);
		waveController.start();
	pass
