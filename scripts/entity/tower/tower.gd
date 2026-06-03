extends Area2D
class_name Tower

var isReady = false;

@onready var spr: AnimatedSprite2D = $AnimatedSprite2D
@export var isMoving: bool = false;

@export var id: String;
var data: TowerData;
var towerName: String = "";

var enableAttack: bool = true;
var enableRegenMana: bool = true;
var isOnValidCell: bool = false;
var inPlaceMode: bool = false;

@onready var attackController: AttackController = $AttackController;
@onready var enemyDetector: EnemyDetector = $EnemyDetector;
@onready var towerStar: TowerStarUI = $TowerStarUI;

var anim: AnimationController;

var attacking: bool = false;
var attackCooldownRemaining: float = 0.0;
var usingSkill: bool = false;
# Bumped on wave reset / death so in-flight skill timers (e.g. SkillActionProjectile
# lifetime await re-enabling enableRegenMana) can skip work tied to a stale cast.
var skill_lock_generation: int = 0;

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
	add_to_group("tower")
	anim = AnimationController.new(spr, IDLE_ANIMATION);
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

	if(towerStar != null):
		towerStar.setStar(data.level);

	isReady = true;

func _process(delta):
	if attackCooldownRemaining > 0.0:
		attackCooldownRemaining = maxf(0.0, attackCooldownRemaining - delta)
		if attackCooldownRemaining <= 0.0:
			attacking = false

	if isMoving:
		position = GridHelper.snapToGrid(get_viewport().size, get_global_mouse_position());
		updateTowerState();

	if skillController && !usingSkill:
		if(skillController.currentMana == skillController.maxMana && !attacking):
			await useSkill();
			if not is_instance_valid(self):
				return

	if enableAttack && !attacking && !usingSkill:
		attackEnemy();

func setup(id: String, onPlace: Callable, onRemove: Callable):
	self.id = id;
	self.name = id;
	towerName = id;
	self.onPlace = onPlace;
	self.onRemove = onRemove;

	var towerData = TowerCenter._towers_data.get(id.to_lower(), null);

	if towerData == null:
		printerr("tower data not found: " + id + ", exists: " + str(TowerCenter._towers_data.keys()));
		return;

	self.data = towerData.data;

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

	AudioManager.playVoice(Utility.parse_string_to_enum(SoundDatabase.VOICE_NAME, data.open_sound))

func upgrade():
	var success = data.levelUp()
	setTowerStar(data.level);
	return success

func evolve():
	var success = data.evolve()
	if success:
		_play_evolve_sound()
		setTowerStar(4)
		if data.evolutionSkill != null:
			if skillController != null:
				skillController.cancel()
			usingSkill = false
			var stat = data.getStat()
			skillController = SkillController.new(self, stat.mana, stat.intialMana, data.evolutionSkill)
			Utility.ConnectSignal(skillController, "on_mana_updated", Callable(self, "update_mana_bar"))
			# Refresh manaBar visual to match the new evolved stat:
			# - setup() re-applies the new max so the bar's full-bar fills at the
			#   evolved cap (e.g., Kiara 50 -> 80) instead of the base cap.
			# - updateValue() shows the new initial mana (e.g., Kiara 10 -> 40)
			#   immediately; no on_mana_updated signal fires from the constructor.
			if manaBar != null:
				manaBar.setup(stat.mana, false)
				manaBar.updateValue(stat.intialMana)
	return success

func _play_evolve_sound():
	if data.evolve_sound == "":
		return

	var target := data.evolve_sound.to_lower()
	for key in SoundDatabase.VOICE_NAME.keys():
		if str(key).to_lower() == target:
			AudioManager.playVoice(SoundDatabase.VOICE_NAME[key])
			return

	push_warning("Tower evolve voice not found: " + data.evolve_sound)

func canEvolve():
	return data.level >= data.maxLevel && !data.isEvolved;

func isEvolved():
	return data.isEvolved

func attackEnemy():
	if attackCooldownRemaining > 0.0:
		return;

	if(is_instance_valid(enemy) && attackController != null && attackController.canAttack(enemy)):
		var targetDir = (enemy.global_position - global_position).normalized().x;
		var attackDir = Global.DIRECTION.LEFT if targetDir < 0 else Global.DIRECTION.RIGHT

		if(spr):
			spr.flip_h = attackDir == Global.DIRECTION.RIGHT

		# attack() deals damage synchronously. If this is the killing blow on the
		# wave's last enemy, the onDead cascade runs endWave -> resetForWave INSIDE
		# this call (bumping skill_lock_generation). If so, skip the post-attack
		# state writes so mana/cooldown/attacking don't leak into the next wave.
		var gen := skill_lock_generation
		attackController.attack(enemy, attackDir, data.getDamage(enemy, self), data.attack_sound, data.attack_vfx);
		if skill_lock_generation != gen:
			return
		attacking = true;
		regenMana(data.getManaRegen());
		attackCooldownRemaining = data.getAttackDelay()
	elif(!is_instance_valid(enemy)):
		clearEnemy(null, null, null);

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
	if self.enemy != null:
		clearEnemy(null, null, null);

	self.enemy = enemy;
	if(enemy != null):
		Utility.ConnectSignal(self.enemy, "onDead", Callable(self, "clearEnemy"));
		Utility.ConnectSignal(self.enemy, "onReachEndPoint", Callable(self, "clearEnemy"));

func clearEnemy(_enemy = null, _cause = null, _reward = null):
	# Default args so this can serve both the 3-arg enemy signals (onDead /
	# onReachEndPoint) and the 0-arg EnemyDetector.onRemoveTarget — the latter
	# previously errored ("expected 3 arguments, called with 0") and silently
	# no-op'd. Net targeting is unchanged: _onEnemyDetected re-sets enemy.
	enemy = null;
	attacking = false;

func play_animation(name: String, speed: float = 1):
	if(anim != null):
		return anim.play(name, speed);
	return false;

func play_animation_default():
	if(anim != null):
		anim.playDefault();

func animation_finished(name: String):
	match name:
		_:
			pass;
			# play_animation_default();

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
				var b := BuffInstance.new(
					str(synergy_id) + extraKey + "_atk_flat",
					BuffInstance.StatType.ATTACK_FLAT,
					float(value),
					BuffInstance.Category.BUFF,
				)
				data.buffs.add(b)
			"attack_bonus_percent":
				var b := BuffInstance.new(
					str(synergy_id) + extraKey + "_atk_mult",
					BuffInstance.StatType.ATTACK_MULT,
					float(value),
					BuffInstance.Category.BUFF,
				)
				data.buffs.add(b)
			"rangeBuff":
				data.addAttackRangeBuff(value, str(synergy_id) + extraKey)
			"mana_regen":
				data.addManaRegenBuff(value, str(synergy_id) + extraKey)
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
				"attack_bonus":
					data.buffs.remove(str(synergy_id) + "_atk_flat")
				"attack_bonus_percent":
					data.buffs.remove(str(synergy_id) + "_atk_mult")
				"rangeBuff":
					data.removeAttackRangeBuff(synergy_id)
				"phys_atk_bonus_percent":
					data.removePhysicDamagePercentBuff(synergy_id)
				"magic_atk_bonus_percent":
					data.removeMagicDamagePercentBuff(synergy_id)
				"mana_regen":
					data.removeManaRegenBuff(synergy_id)
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

func resetForWave():
	attacking = false
	attackCooldownRemaining = 0.0
	usingSkill = false
	# Invalidate any in-flight skill-lock timers (e.g. SkillActionProjectile lifetime
	# await) so a stale callback can't re-toggle enableRegenMana mid-next-cast.
	skill_lock_generation += 1
	enableRegenMana = true
	clearEnemy(null, null, null)

	if skillController != null:
		skillController.cancel()
		var initMana: float = data.getStat().intialMana
		skillController.currentMana = initMana
		skillController.on_mana_updated.emit(initMana)

	# Free any persistent projectiles this tower spawned (e.g. Gura storm waves)
	# so they don't keep orbiting into the next wave.
	for node in get_tree().get_nodes_in_group("projectile"):
		if node is Projectile and node.shooter == self:
			node.queue_free()

	data.buffs.clear_skill_buffs()

	for child in get_children():
		if child is CircleEffectArea:
			child.queue_free()

	play_animation_default()

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

func setTowerStar(tier: int):
	if(towerStar != null):
		towerStar.setStar(tier);

func addDecreaseAtkSpeed(value: float, key: String = ""):
	# ATTACK_SPEED is decimal scale (0.5 = +50%) — caller passes decimal directly.
	var buff := BuffInstance.new(
		key,
		BuffInstance.StatType.ATTACK_SPEED,
		-value,
		BuffInstance.Category.DEBUFF,
	)
	buff.sourceSkill = key
	data.buffs.add(buff)

func removeDecreaseAtkSpeed(key: String):
	data.buffs.remove(key)

func addDecreaseDmgAllPercent(value: float, key: String = ""):
	# value is decimal (0.10 = 10%), BuffInstance ATTACK_MULT expects percent (-10)
	var buff := BuffInstance.new(
		key,
		BuffInstance.StatType.ATTACK_MULT,
		-value * 100.0,
		BuffInstance.Category.DEBUFF,
	)
	buff.sourceSkill = key
	data.buffs.add(buff)

func removeDecreaseDmgAllPercent(key: String):
	data.buffs.remove(key)

signal onReceiveMission(mission: MissionDetail);
signal on_animation_finished(name: String);
