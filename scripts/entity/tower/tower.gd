extends Node2D
class_name Tower

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
var anim: AnimationController;

var attacking: bool = false;
var usingSkill: bool = false;

@export var skill: Skill;
var skillController: SkillController
@onready var manaBar = $ManaBar

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
	anim.connect("on_animation_finished", Callable(self, "on_animation_finished"));
	
	var maxMana := 20.0;
	var initMana := 10.0;
	
	if(manaBar != null):
		manaBar.setup(maxMana, false);
		manaBar.updateValue(initMana);
	
	skillController = SkillController.new(self,maxMana, initMana, skill);
	skillController.connect("on_mana_updated", Callable(self, "update_mana_bar"));
	
	if(attackController != null):
		var stat = getStat();
		attackController.setup(stat.pDamage, stat.getAttackDelay());
	
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

	if enableAttack && !attacking:
		attackEnemy();
	
	if skillController && !usingSkill:
		skillController.updateMana(2 * delta);

		if(skillController.currentMana == skillController.maxMana && !attacking):
			skillController.useSkill();

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
		attacking = true;
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
	if(self.enemy != null || enemy == self.enemy):
		return;
	
	clearEnemy();
	
	self.enemy = enemy;	
	if(enemy != null):
		Utility.ConnectSignal(self.enemy, "onDead", Callable(self, "clearEnemy"));
		Utility.ConnectSignal(self.enemy, "onReachEndPoint", Callable(self, "clearEnemy"));

func clearEnemy():
	enemy = null;
	if(anim != null):
		anim.playDefault();
		
func on_animation_finished(name: String):
	match name:
		ATTACK_ANIMATION:
			attackController.dealDamage();
			anim.playDefault();
			attacking = false;
			
func update_mana_bar(current: float):
	if(manaBar == null):
		return;
	
	manaBar.updateValue(current)
