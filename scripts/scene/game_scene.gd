extends Node2D;
class_name GameScene;

@onready var waveController: WaveController = $WaveController;
@onready var player: Player = $Player
@onready var map: Map = $TileMap
@export var mapData: MapData = null;
@onready var towerFactory: TowerFactory = $TowerFactory;

var t: Tower = null

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_1 and t == null:
		var tower: Tower = towerFactory.GetTower(null);
		tower.enterPlaceMode();
		add_child(tower);
		t = tower

func _ready():
	if(map != null):
		map.setup();
	
	SpriteLoader.preloadImage("enemy", "res://resources/enemy");
	if (waveController != null):
		waveController.setup(mapData.waves, Callable(self, "reducePlayerHp"));
		waveController.start();
	
	if (towerFactory):
		towerFactory.setup(Callable(self, "placeTower"), Callable(self, "removeTower"));

func placeTower(cell: Vector2):
	map.removeAvailableCell(cell);

func removeTower(cell: Vector2):
	map.addAvailableCell(cell);
	
func checkValidCell(cell: Vector2):
	return !map.grids.has(cell);

func reducePlayerHp(amount: int):
	player.updateHp(-amount);
