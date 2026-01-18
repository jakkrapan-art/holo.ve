extends Area2D
class_name Tower

var isReady = false;

@onready var spr: AnimatedSprite2D = $AnimatedSprite2D
@export var isMoving: bool = false;

@export var id: String;
@export var data: TowerData;

var enableAttack: bool = true;
var enableRegenMana: bool = true;
var isOnValidCell: bool = false;
var inPlaceMode: bool = false;

@onready var attackController: AttackController = $AttackController;
@onready var enemyDetector: EnemyDetector = $EnemyDetector;
@onready var levelLabel: Label = $LevelLabel;

var anim: AnimationController;

var attacking: bool = false;
var usingSkill: bool = false;

var skillController: SkillController
@onready var manaBar = $ManaBar

var onPlace: Callable;
var onRemove: Callable;

var synergyBuffs := {}  # key: synergy_id, value: Array of buffs

var enemy: Enemy = null;

var IDLE_ANIMATION = "idle";
var ATTACK_ANIMATION = "n_attack";
var noActionKey = ["synergy_id", "syn_attack_percent", "tier"];


func getAttackAnimationSpeed():
	return data.getAttackAnimationSpeed(spr, ATTACK_ANIMATION);

func _ready():
	anim = AnimationController.new(spr, IDLE_ANIMATION, [IDLE_ANIMATION, ATTACK_ANIMATION]);
	Utility.ConnectSignal(anim,"on_animation_finished", Callable(self, "animation_finished"));

	var stat = data.getStat();

	var maxMana = stat.mana;
	var initMana = stat.intialMana;

	if(manaBar != null):
		manaBar.setup(maxMana, false);
		manaBar.updateValue(initMana);

	skillController = SkillController.new(self,maxMana, initMana, data.skill);

	if(skillController != null):
		Utility.ConnectSignal(skillController, "on_mana_updated", Callable(self, "update_mana_bar"));

	if(attackController != null):
		attackController.setup(self, Callable(stat, "getAttackDelay"));

	if(enemyDetector != null):
		enemyDetector.setup(stat.attackRange);
		Utility.ConnectSignal(enemyDetector, "onRemoveTarget", Callable(self, "clearEnemy"))
		if inPlaceMode:
			showAttackRange(true);
	

	isReady = true;

func _process(delta):
	if isMoving:
		position = GridHelper.snapToGrid(get_viewport().size, get_global_mouse_position());
		updateTowerState();

	if skillController && !usingSkill:
		if(skillController.currentMana == skillController.maxMana && !attacking):
			await useSkill();

	if enableAttack && !attacking && !usingSkill:
		attackEnemy();

func setup(id: String, onPlace: Callable, onRemove: Callable):
	self.onPlace = onPlace;
	self.name = name;
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
	showAttackRange(false);
	onPlace.call(cell);

func upgrade():
	var success = data.levelUp()
	print("upgrade to level ", data.level);
	if levelLabel:
		levelLabel.text = str(data.level)

	return success

func evolve():
	var success = data.evolve()
	if levelLabel && success:
		levelLabel.text = str(data.level) + "E"
	return success

func canEvolve():
	return data.level >= data.maxLevel && !data.isEvolved;

func isEvolved():
	return data.isEvolved

func attackEnemy():
	if(is_instance_valid(enemy) && attackController != null && attackController.canAttack(enemy)):
		attackController.attack(enemy, data.getDamage(enemy, self));
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
	if(skillController == null || !enableRegenMana || isMoving):
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

	if self.enemy != null:
		clearEnemy();

	self.enemy = enemy;
	if(enemy != null):
		Utility.ConnectSignal(self.enemy, "onDead", Callable(self, "clearEnemy"));
		Utility.ConnectSignal(self.enemy, "onReachEndPoint", Callable(self, "clearEnemy"));

func clearEnemy():
	if(enemy == null):
		return;

	enemy = null;
	play_animation_default();
	attacking = false;

	usingSkill = false;
	skillController.cancel();

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
				attackController.attackAnimFinish();
				regenMana(data.getManaRegen());
				play_animation_default();
				attacking = false;

	on_animation_finished.emit(name);

func update_mana_bar(current: float):
	if(manaBar == null):
		return;

	manaBar.updateValue(current)

func processActiveBuff(buff: Dictionary, extraKey: String = ""):
	if(!isReady):
		call_deferred("processActiveBuff", buff, extraKey);
		return;

	var synergy_id = buff.get("synergy_id", null)
	if synergy_id == null:
		return

	for key in buff.keys():
		if noActionKey.has(key):
			continue;

		var value = buff[key]
		match key:
			"attack_bonus":
				data.addPhysicDamageBuff(value, str(synergy_id) + extraKey)
			"attack_bonus_percent":
				data.addAttackBonusPercentBuff(value, str(synergy_id) + extraKey)
			"rangeBuff":
				data.addAttackRangeBuff(value, str(synergy_id) + extraKey)
			"attack_speed_bonus":
				data.addAttackSpeedBuff(value, str(synergy_id) + extraKey)
			"mana_regen":
				data.addManaRegen(value, str(synergy_id) + extraKey)
			"crit_chance_bonus_percent":
				data.addCritChanceBuff(value, str(synergy_id) + extraKey)
			"on_skill_cast":
				if(skillController):
					skillController.addModifier(synergy_id, value)
			"on_attack":
				if(attackController):
					attackController.addModifier(synergy_id, value)
			"mission":
				onReceiveMission.emit(value);
			"interval_action":
				var isBonus = (value.get("bonus").condition as Callable).call(synergy_id);
				addIntervalAction(str(synergy_id), value.interval, value.action, value.value if !isBonus else value.bonus.value);
			"syn_attack_percent":
				pass;
			"tier":
				pass;
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
			if noActionKey.has(key):
				continue
			var value = buff[key]
			match key:
				"damageBuff":
					data.removePhysicDamageBuff(synergy_id)
				"attack_bonus_percent":
					data.removeAttackBonusPercentBuff(synergy_id);
				"rangeBuff":
					data.removeAttackRangeBuff(synergy_id)
				"attackSpeedBuff":
					data.removeAttackSpeedBuff(synergy_id)
				"phys_atk_bonus_percent":
					data.removePhysicDamagePercentBuff(synergy_id)
				"magic_atk_bonus_percent":
					data.removeMagicDamagePercentBuff(synergy_id)
				"mana_regen":
					data.removeManaRegen(synergy_id)
				"meteor_proc_chance_percent":
					data.removeMeteorProcChance(synergy_id)
				"meteor_damage_percent":
					data.removeMeteorDamagePercent(synergy_id)
				"crit_chance_bonus_percent":
					data.removeCritChanceBuff(synergy_id)
				"on_skill_cast":
					if(skillController):
						skillController.removeModifier(synergy_id)
				"on_attack":
					if(attackController):
						attackController.removeModifier(synergy_id)
				_:
					print("Unknown synergy buff key: ", key)

	synergyBuffs.erase(synergy_id)

func addIntervalAction(key,interval: float, action: String, value: float):
	var callable: Callable;
	match action:
		"regen_mana":
			callable = Callable(self, "regenMana").bind(value);

	if not callable:
		printerr("invalid interval action: ", action);
		return

	var exist = find_child(key);

	if(exist):
		exist.queue_free();

	var timer = Timer.new();
	timer.name = key;
	timer.set_wait_time(interval);
	timer.set_one_shot(false);
	timer.connect("timeout", callable);
	add_child(timer);
	timer.start();

func showAttackRange(show: bool):
	if enemyDetector != null:
		enemyDetector.setEnabledDrawRange(show);

func addDecreaseAtkSpeed(value: float, key: String = ""):
	data.addAttackSpeedDebuff(value, key);

func removeDecreaseAtkSpeed(key: String):
	data.removeAttackSpeedDebuff(key);

func addDecreaseDmgAllPercent(value: float, key: String = ""):
	data.addAttackBonusPercentBuff(value, key);

func removeDecreaseDmgAllPercent(key: String):
	data.removeDecreaseDmgAllPercent(key);

signal onReceiveMission(mission: MissionDetail);
signal on_animation_finished(name: String);
