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

# Passive runtime (e.g. PassiveCritPierce). null = tower has no passive.
var passive = null

var onPlace: Callable;
var onRemove: Callable;

var enemy: Enemy = null;

var IDLE_ANIMATION = "idle";
var ATTACK_ANIMATION = "n_attack";


func getAttackAnimationSpeed():
	return data.getAttackAnimationSpeed(spr, ATTACK_ANIMATION);

func _ready():
	add_to_group("tower")
	if data != null:
		data.effects.set_host(self)
	anim = AnimationController.new(spr, IDLE_ANIMATION);
	Utility.ConnectSignal(anim,"on_animation_finished", Callable(self, "animation_finished"));

	var stat = data.getStat();

	var maxMana = stat.mana;
	var initMana = stat.initialMana;

	if _hasActiveSkill():
		if(manaBar != null):
			manaBar.setup(maxMana, false);
			manaBar.updateValue(initMana);

		skillController = SkillController.new(self,maxMana, initMana, data.skill);
		Utility.ConnectSignal(skillController, "on_mana_updated", Callable(self, "update_mana_bar"));
		Utility.ConnectSignal(skillController, "cast_succeeded", Callable(self, "_on_cast_succeeded"));
	elif manaBar != null:
		# No active skill (e.g. passive-only tower) -> no Energy bar.
		manaBar.visible = false;

	_setupPassive();

	if(attackController != null):
		attackController.setup(self, Callable(stat, "getAttackDelay"));

	if(enemyDetector != null):
		enemyDetector.setup(stat.attackRange);
		Utility.ConnectSignal(enemyDetector, "onRemoveTarget", Callable(self, "clearEnemy"))
		if inPlaceMode:
			showAttackRange(true);

	if(towerStar != null):
		towerStar.setStar(data.level);

	# Overhead status icons. Bound after the data-null guard above; setup()
	# also draws any effects already on the shared container (re-placed tower).
	var iconRow := get_node_or_null("EffectIconRow") as EffectIconRow
	if iconRow != null and data != null:
		iconRow.setup(data.effects)

	isReady = true;

func _hasActiveSkill() -> bool:
	return data.skill != null and not data.skill.actions.is_empty();

# (Re)create the passive runtime from the current form's passive params.
# Called on _ready and after evolve (evolutionPassive overrides passive).
func _setupPassive() -> void:
	if passive != null:
		passive.reset();
		# Detach external listeners (e.g. PassiveSoulHarvest's kill signal)
		# before the rebuild - the connection keeps the old RefCounted alive,
		# and a leaked listener would double its effect after evolve.
		if passive.has_method("dispose"):
			passive.dispose();
		passive = null;

	var params: Dictionary = data.evolutionPassive if data.isEvolved and not data.evolutionPassive.is_empty() else data.passive;
	if params == null or params.is_empty():
		return;

	match str(params.get("behavior", "")):
		"crit_pierce":
			passive = PassiveCritPierce.new(self, params);
		"soul_harvest":
			passive = PassiveSoulHarvest.new(self, params);
		_:
			push_warning("Tower '" + towerName + "': unknown passive behavior '" + str(params.get("behavior", "")) + "'");

func _process(delta):
	# Effect expiry clock: the container owns all durations (no scene-tree
	# timers - R2/R3 root fix). Freezes with pause, scales with x2 speed.
	if data != null:
		data.effects.tick(delta)

	if attackCooldownRemaining > 0.0:
		attackCooldownRemaining = maxf(0.0, attackCooldownRemaining - delta)
		if attackCooldownRemaining <= 0.0:
			attacking = false

	if isMoving:
		position = GridHelper.snapToGrid(get_viewport().size, get_global_mouse_position());
		updateTowerState();

	# Energy-full skill takes priority over auto-attack: while skillReady, the attack
	# below is suppressed so a swing can't kill the target before the skill fires. Cast
	# only with a locked target; a fizzle (target outside the skill box) keeps Energy
	# full by design and the attack stays suppressed until find lands a target.
	var skillReady := skillController != null && skillController.currentMana == skillController.maxMana

	if skillReady && !usingSkill && !attacking && is_instance_valid(enemy):
		await useSkill();
		if not is_instance_valid(self):
			return

	if enableAttack && !attacking && !usingSkill && !skillReady:
		attackEnemy();

func setup(p_id: String, p_onPlace: Callable, p_onRemove: Callable):
	self.id = p_id;
	self.name = p_id;
	towerName = p_id;
	self.onPlace = p_onPlace;
	self.onRemove = p_onRemove;

	var towerData = TowerCenter._towers_data.get(p_id.to_lower(), null);

	if towerData == null:
		push_error("tower data not found: " + p_id + ", exists: " + str(TowerCenter._towers_data.keys()));
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
			skillController = SkillController.new(self, stat.mana, stat.initialMana, data.evolutionSkill)
			Utility.ConnectSignal(skillController, "on_mana_updated", Callable(self, "update_mana_bar"))
			Utility.ConnectSignal(skillController, "cast_succeeded", Callable(self, "_on_cast_succeeded"))
			# Refresh manaBar visual to match the new evolved stat:
			# - setup() re-applies the new max so the bar's full-bar fills at the
			#   evolved cap (e.g., Kiara 50 -> 80) instead of the base cap.
			# - updateValue() shows the new initial mana (e.g., Kiara 10 -> 40)
			#   immediately; no on_mana_updated signal fires from the constructor.
			if manaBar != null:
				manaBar.setup(stat.mana, false)
				manaBar.updateValue(stat.initialMana)

		_setupPassive()
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

		# Roll the attack once. Crit is decided here (TowerData.getDamage), and the
		# crit chance already includes any passive Bull Eyes stacks.
		var dmg: Damage = data.getDamage(enemy, self)

		# attack() deals damage synchronously. If this is the killing blow on the
		# wave's last enemy, the onDead cascade runs endWave -> resetForWave INSIDE
		# this call (bumping skill_lock_generation). If so, skip the post-attack
		# state writes so mana/cooldown/attacking don't leak into the next wave.
		var gen := skill_lock_generation
		if passive != null and dmg.isCritical and passive.replaces_attack_on_crit():
			# Crit -> the passive fires its pierce arrow INSTEAD of the normal hit.
			passive.on_crit_attack(enemy)
			if data.attack_sound != "":
				AudioManager.playSfx(Utility.parse_string_to_enum(SoundDatabase.SFX_NAME, data.attack_sound))
		else:
			if data.attack_config != null and data.attack_config.is_projectile():
				# Projectile mode: spawn homing bullet(s); damage lands on hit (async).
				# Sound at fire; no generic AttackVfx (the bullet IS the vfx).
				attackController.attackProjectile(enemy, dmg, data.attack_config)
				if data.attack_sound != "":
					AudioManager.playSfx(Utility.parse_string_to_enum(SoundDatabase.SFX_NAME, data.attack_sound))
			else:
				attackController.attack(enemy, attackDir, dmg, data.attack_sound, data.attack_vfx);
			if skill_lock_generation != gen:
				return
			if passive != null:
				passive.on_normal_attack()
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

func _onEnemyDetected(p_enemy: Enemy):
	if self.enemy != null:
		clearEnemy(null, null, null);

	self.enemy = p_enemy;
	if(p_enemy != null):
		Utility.ConnectSignal(self.enemy, "onDead", Callable(self, "clearEnemy"));
		Utility.ConnectSignal(self.enemy, "onReachEndPoint", Callable(self, "clearEnemy"));

func clearEnemy(_enemy = null, _cause = null, _reward = null):
	# Default args so this serves both the 3-arg enemy signals (onDead /
	# onReachEndPoint) and the 0-arg EnemyDetector.onRemoveTarget.
	# Symmetric teardown: drop this enemy's hooks before clearing, so switching
	# or re-detecting a target never double-connects clearEnemy ("already
	# connected") nor leaks a stale onDead hook that would clear a later target.
	if enemy != null and is_instance_valid(enemy):
		var cb := Callable(self, "clearEnemy")
		if enemy.is_connected("onDead", cb):
			enemy.disconnect("onDead", cb)
		if enemy.is_connected("onReachEndPoint", cb):
			enemy.disconnect("onReachEndPoint", cb)
	enemy = null;
	attacking = false;

func play_animation(p_name: String, speed: float = 1):
	if(anim != null):
		return anim.play(p_name, speed);
	return false;

func get_animation_duration(p_name: String) -> float:
	if(anim != null):
		return anim.get_native_duration(p_name);
	return 0.0;

func has_animation(p_name: String) -> bool:
	if(anim != null):
		return anim.has_animation(p_name);
	return false;

func play_animation_default():
	if(anim != null):
		anim.playDefault();

func animation_finished(p_name: String):
	match p_name:
		_:
			pass;
			# play_animation_default();

	on_animation_finished.emit(p_name);

func update_mana_bar(current: float):
	if(manaBar == null):
		return;

	manaBar.updateValue(current)

func _on_cast_succeeded(_skill):
	# A fully successful skill cast -> notify the synergy system (e.g. Myth team battery).
	skill_cast_succeeded.emit(self)

func resetForWave():
	attacking = false
	attackCooldownRemaining = 0.0
	usingSkill = false
	# Invalidate any in-flight skill-lock timers (e.g. SkillActionProjectile lifetime
	# await) so a stale callback can't re-toggle enableRegenMana mid-next-cast.
	skill_lock_generation += 1
	enableRegenMana = true
	clearEnemy(null, null, null)

	if passive != null:
		passive.reset()

	if skillController != null:
		skillController.cancel()
		var initMana: float = data.getStat().initialMana
		skillController.currentMana = initMana
		skillController.on_mana_updated.emit(initMana)

	# Free any persistent projectiles this tower spawned (e.g. Gura storm waves)
	# so they don't keep orbiting into the next wave.
	for node in get_tree().get_nodes_in_group("projectile"):
		if node is Projectile and node.shooter == self:
			node.queue_free()

	data.effects.clear_wave_scoped()

	for child in get_children():
		if child is CircleEffectArea:
			child.queue_free()

	play_animation_default()

func showAttackRange(p_show: bool):
	if enemyDetector != null:
		enemyDetector.setEnabledDrawRange(p_show);

func setTowerStar(tier: int):
	if(towerStar != null):
		towerStar.setStar(tier);

# Uniform effect surface (same shape as Enemy) so actions/areas/projectiles
# never care about the host type.
func apply_effect(inst: EffectInstance) -> void:
	if data != null:
		data.effects.apply(inst)

func remove_effect_source(source_id: String) -> void:
	if data != null:
		data.effects.remove_source(source_id)

# TowerData (and its EffectContainer) is shared per-character and outlives
# this node: clear wave-scoped effects when the tower leaves the board so a
# re-placed tower never resumes a frozen buff (plan F3).
func _exit_tree():
	if passive != null and passive.has_method("dispose"):
		passive.dispose()
	if data != null:
		data.effects.clear_wave_scoped()
		if data.effects.get_host() == self:
			data.effects.set_host(null)

signal on_animation_finished(name: String);
# Emitted after this tower completes a skill cast (drives synergy effects).
signal skill_cast_succeeded(tower);
