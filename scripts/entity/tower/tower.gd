extends Node2D
class_name Tower

@onready var spr: AnimatedSprite2D = $AnimatedSprite2D
@export var isMoving: bool = false;

@export var stats: Array[TowerStat];

var currentStatIndex: int = 0;

var towerName: TowerFactory.TowerName;
@export var data: TowerData;

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
	Utility.ConnectSignal(anim,"on_animation_finished", Callable(self, "animation_finished"));
	
	var maxMana := 20.0;
	var initMana := 10.0;
	
	if(manaBar != null):
		manaBar.setup(maxMana, false);
		manaBar.updateValue(initMana);
	
	skillController = SkillController.new(self,maxMana, initMana, skill);
	Utility.ConnectSignal(skillController, "on_mana_updated", Callable(self, "update_mana_bar"));
	
	var stat = getStat();
	if(attackController != null):
		attackController.setup(stat.pDamage, stat.getAttackDelay());
	
	if(enemyDetector != null):
		enemyDetector.setup(stat.attackRange);
		Utility.ConnectSignal(enemyDetector, "onRemoveTarget", Callable(self, "clearEnemy"))

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if(!inPlaceMode):
			enterPlaceMode();
		else:
			exitPlaceMode();

func _process(delta):
	var stat = getStat();
	if isMoving:
		position = GridHelper.snapToGrid(get_viewport().size, get_global_mouse_position());
		updateTowerState();

	if skillController && !usingSkill:
		if(skillController.currentMana == skillController.maxMana && !attacking):
			await skillController.useSkill();

	if enableAttack && !attacking && !usingSkill:
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
		play_animation(ATTACK_ANIMATION, speed);
		attacking = true;
		if(skillController != null):
			skillController.updateMana(10);			
		
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
	play_animation_default();

func play_animation(name: String, speed: float = 1):
	if(anim != null):
		return anim.play(name, speed);
	return false;

func play_animation_default():
	if(anim != null):
		anim.playDefault();

func animation_finished(name: String):
	match name:
		ATTACK_ANIMATION:
			if attacking:
				attackController.dealDamage();
				play_animation_default();
				attacking = false;

	on_animation_finished.emit(name);
			
func update_mana_bar(current: float):
	if(manaBar == null):
		return;
	
	manaBar.updateValue(current)

signal on_animation_finished(name: String);
