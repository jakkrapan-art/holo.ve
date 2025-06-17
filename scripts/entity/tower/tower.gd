extends Node2D
class_name Tower

var isReady = false;

@onready var spr: AnimatedSprite2D = $AnimatedSprite2D
@export var isMoving: bool = false;

@export var id: TowerFactory.TowerId;
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

var synergyBuffs := {}  # key: synergy_id, value: Array of buffs

var enemy: Enemy = null;

var IDLE_ANIMATION = "idle";
var ATTACK_ANIMATION = "n_attack";

func getStat():
	return data.getStat();

func getAttackAnimationSpeed():
	return getStat().getAttackAnimationSpeed(spr, ATTACK_ANIMATION);

func _ready():
	anim = AnimationController.new(spr, IDLE_ANIMATION, [IDLE_ANIMATION, ATTACK_ANIMATION]);
	Utility.ConnectSignal(anim,"on_animation_finished", Callable(self, "animation_finished"));
	
	var stat = getStat();
	
	var maxMana = stat.mana;
	var initMana = stat.intialMana;
	
	if(manaBar != null):
		manaBar.setup(maxMana, false);
		manaBar.updateValue(initMana);
	
	skillController = SkillController.new(self,maxMana, initMana, skill);
	
	if(skillController != null):
		Utility.ConnectSignal(skillController, "on_mana_updated", Callable(self, "update_mana_bar"));
	
	if(attackController != null):
		attackController.setup(self, stat.getAttackDelay());
	
	if(enemyDetector != null):
		enemyDetector.setup(stat.attackRange);
		Utility.ConnectSignal(enemyDetector, "onRemoveTarget", Callable(self, "clearEnemy"))
	
	isReady = true;

func _process(delta):
	var stat = getStat();
	if isMoving:
		position = GridHelper.snapToGrid(get_viewport().size, get_global_mouse_position());
		updateTowerState();

	if skillController && !usingSkill:
		if(skillController.currentMana == skillController.maxMana && !attacking):
			await useSkill();

	if enableAttack && !attacking && !usingSkill:
		attackEnemy();

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_S:
		pass

func setup(id: TowerFactory.TowerId, onPlace: Callable, onRemove: Callable):
	self.onPlace = onPlace;
	self.id = id;
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
	return data.levelUp()

func attackEnemy():
	if(is_instance_valid(enemy) && attackController != null && attackController.canAttack(enemy)):
		attackController.attack(enemy);
		var speed = getAttackAnimationSpeed();		
		play_animation(ATTACK_ANIMATION, speed);
		attacking = true;
	elif(!is_instance_valid(enemy)):
		clearEnemy();

func useSkill():
	if(skillController == null):
		return;
	await skillController.useSkill();
	
func regenMana(regenAmount: int):
	if(skillController == null):
		return;
	skillController.updateMana(regenAmount);

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
	attacking = false;
	usingSkill = false;

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
				attackController.dealDamage(data.getDamage(enemy));
				regenMana(data.getManaRegen());
				play_animation_default();
				attacking = false;

	on_animation_finished.emit(name);
			
func update_mana_bar(current: float):
	if(manaBar == null):
		return;
	
	manaBar.updateValue(current)

func processActiveBuff(buff: Dictionary):
	if(!isReady):
		call_deferred("processActiveBuff", buff);
		return;
	
	var synergy_id = buff.get("synergy_id", null)
	if synergy_id == null:
		return
	
	for key in buff.keys():
		if key == "synergy_id":
			continue

		var value = buff[key]
		match key:
			"attack_bonus":
				data.addPhysicDamageBuff(value)
			"rangeBuff":
				data.addAttackRangeBuff(value)
			"attack_speed_bonus":
				data.addAttackSpeedBuff(value)
			"phys_atk_bonus_percent":
				data.addPhysicDamagePercentBuff(value)
			"magic_atk_bonus_percent":
				data.addMagicDamagePercentBuff(value)
			"mana_regen":
				data.addManaRegen(value)
			"meteor_proc_chance_percent":
				data.addMeteorProcChance(value)
			"meteor_damage_percent":
				data.addMeteorDamagePercent(value)
			"crit_chance_bonus_percent":
				data.addCritChanceBuff(value)
			"on_skill_cast":
				if(skillController):
					skillController.addModifier(synergy_id, value)
			"on_attack":
				if(attackController):
					attackController.addModifier(synergy_id, value)
			_:
				print("Unknown synergy buff key: ", key)

	# Track for removal
	if not synergyBuffs.has(synergy_id):
		synergyBuffs[synergy_id] = []
	synergyBuffs[synergy_id].append(buff)


func clearSynergyBuffs(synergy_id: int):
	if not synergyBuffs.has(synergy_id):
		return

	for buff in synergyBuffs[synergy_id]:
		for key in buff.keys():
			if key == "synergy_id":
				continue
			var value = buff[key]
			match key:
				"damageBuff":
					data.removePhysicDamageBuff(value)
				"rangeBuff":
					data.removeAttackRangeBuff(value)
				"attackSpeedBuff":
					data.removeAttackSpeedBuff(value)
				"phys_atk_bonus_percent":
					data.removePhysicDamagePercentBuff(value)
				"magic_atk_bonus_percent":
					data.removeMagicDamagePercentBuff(value)
				"mana_regen":
					data.removeManaRegen(value)
				"meteor_proc_chance_percent":
					data.removeMeteorProcChance(value)
				"meteor_damage_percent":
					data.removeMeteorDamagePercent(value)
				"crit_chance_bonus_percent":
					data.removeCritChanceBuff(value)
				"on_skill_cast":
					if(skillController):
						skillController.removeModifier(synergy_id)
				"on_attack":
					if(attackController):
						attackController.removeModifier(synergy_id)
				_:
					print("Unknown synergy buff key: ", key)

	synergyBuffs.erase(synergy_id)

signal on_animation_finished(name: String);
