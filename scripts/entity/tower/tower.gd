extends Node2D
class_name Tower
var GRID_SIZE = 512;

@onready var spr: AnimatedSprite2D = $AnimatedSprite2D
@export var isMoving: bool = false;

@export var stats: Array[TowerStat];

var currentStatIndex: int = 0;

var towerName: TowerFactory.TowerName;

var enableAttack: bool = true;
var isOnValidCell: bool = false;
var inPlaceMode: bool = false;

@onready var attackController: AttackController = $AttackController;
@onready var enemyDetector: EnemyDetector = $EnemyDetector;
@onready var anim: AnimationController

var onPlace: Callable;
var onRemove: Callable;

var enemy: Enemy = null;

var IDLE_ANIMATION = "idle";
var ATTACK_ANIMATION = "n_attack";

func getStat():
	var index = currentStatIndex if currentStatIndex < (stats.size() - 1) else stats.size() - 1
	return stats[currentStatIndex]

func getAttackAnimationSpeed():
	return getStat().getAttackAnimationSpeed(spr, ATTACK_ANIMATION);

func _ready():
	anim = AnimationController.new(spr, IDLE_ANIMATION, [IDLE_ANIMATION, ATTACK_ANIMATION]);
	if(attackController != null):
		var stat = getStat();
		attackController.setup(stat.pDamage, getAttackAnimationSpeed(), stat.getAttackDelay());
	
	enemyDetector.connect("onRemoveTarget", Callable(self, "clearEnemy"))

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if(!inPlaceMode):
			enterPlaceMode();
		else:
			exitPlaceMode();

func _process(delta):
	if isMoving:
		position = GridHelper.snapToGrid(get_viewport().size, get_global_mouse_position());
		updateTowerState();

	if enableAttack:
		attackEnemy();

func setup(towerName: TowerFactory.TowerName, onPlace: Callable, onRemove: Callable):
	self.onPlace = onPlace;
	self.towerName = towerName;
	self.onRemove = onRemove;

func enterPlaceMode():
	isMoving = true;
	enableAttack = false;
	
	inPlaceMode = true;
	var cell = GridHelper.WorldToCell(position);
	onRemove.call(cell);
	
func exitPlaceMode():
	if(!isOnValidCell):
		return;
	
	isMoving = false;
	enableAttack = true;
	inPlaceMode = false;
	
	var cell = GridHelper.WorldToCell(position);
	onPlace.call(cell);

func upgrade():
	if currentStatIndex >= stats.size() - 1:
		return false;
	
	currentStatIndex += 1;
	return true;

func attackEnemy():
	if(enemy != null && attackController != null && attackController.canAttack(enemy)):
		attackController.attack(enemy);
		var speed = getAttackAnimationSpeed();		
		anim.play(ATTACK_ANIMATION, speed);
func isAvailable():
	return true;

func updateTowerState():
	var cellPos = GridHelper.WorldToCell(position);
	var valid = Map.isCellAvailable(cellPos);
	updateSpriteColor(valid);
	isOnValidCell = valid;

func updateSpriteColor(available: bool):
	if (available):
		spr.self_modulate = Color("#ffffff", 1);
	else:
		spr.self_modulate = Color("#ff0000", 1);

func _onEnemyDetected(enemy: Enemy):
	clearEnemy();
	
	self.enemy = enemy;	
	if(enemy != null):
		Utility.ConnectSignal(self.enemy, "onDead", Callable(self, "clearEnemy"));
		Utility.ConnectSignal(self.enemy, "onReachEndPoint", Callable(self, "clearEnemy"));

func clearEnemy():
	enemy = null;
	if(anim != null):
		anim.playDefault();
