extends PathFollow2D
class_name Enemy

@onready var sprite: Sprite2D = $Sprite2D;
@onready var area: Area2D = $Enemy;
@onready var healthBar: HealthBar = $HealthBar;

@export var stats: EnemyStat;
var originalModulate: Color

var enemyType: EnemyType = EnemyType.Normal;

# Unified buff/debuff store (created in setup; icon row binds there too -
# _ready runs a frame BEFORE setup in the factory flow, so never bind at
# _ready).
var effects: EffectContainer = null;
var skillController: EnemySkillController;
var enableMove: bool = true;
# Cast telegraph lock: the enemy stands still while casting. Kept separate from
# enableMove so StunBehavior's restore can't free a casting enemy mid-cast (and
# a cast ending can't free a stunned one).
var castLocked: bool = false;
var usingSkill: bool = false;
# In-combat gate, single pacing timer (Director 2026-07-08): a hit wakes the
# enemy AND arms the castWait timer; the timer ticks only while awake, and a
# cast is allowed when it reaches 0 - hit = wait -> cast, never instant and
# never back-to-back (it re-arms on wake and after each completed cast).
# inCombatWindow seconds without damage puts the enemy back to sleep, looping.
# A sleeping boss (out of coverage / towers busy elsewhere) is intended, not a
# bug. Do NOT restore instant-cast-on-wake: with skills ready at spawn it
# chain-casts the whole kit on first engagement (enemy_skill.md).
@export var inCombatWindow: float = 4.0
@export var castWait: float = 4.0
var inCombatRemaining: float = 0.0
var castWaitRemaining: float = 0.0

var initialized: bool = false;
# Mutex flag: ensures exactly ONE removal signal fires per enemy (onDead OR
# onReachEndPoint, not both). Without this, lethal damage on the same frame
# an enemy reaches the end double-decrements wave_controller.enemyAliveCount,
# causing wave to end prematurely while monsters are still alive.
var _removed: bool = false;

enum EnemyType {Normal, Elite, Boss}
const FACING_X_EPSILON: float = 0.01

func setup(p_enemyType: EnemyType, hp: int, armor: int, mArmor: int, moveSpeed: int, texture: Texture2D, skills: Array[Skill] = [], damageReduction: float = 0.0):
	self.enemyType = p_enemyType;
	setTexture(texture);
	stats = EnemyStat.new(hp, armor, mArmor, moveSpeed, damageReduction);
	effects = EffectContainer.new();
	effects.set_host(self);
	stats.effects = effects;
	var iconRow := get_node_or_null("EffectIconRow") as EffectIconRow
	if iconRow != null:
		iconRow.setup(effects)
	originalModulate = sprite.modulate
	skillController = EnemySkillController.new(self, skills);
	skillController.applyPassives();
	initialized = true;

	if healthBar:
		healthBar.setup(hp, false);
		healthBar.visible = false;

func _process(_delta):
	if(!initialized):
		return;

	if effects:
		effects.tick(_delta)

	if inCombatRemaining > 0.0:
		castWaitRemaining = maxf(0.0, castWaitRemaining - _delta)
		inCombatRemaining = maxf(0.0, inCombatRemaining - _delta)
		if inCombatRemaining <= 0.0 and EnemySkillController.DEBUG_LOG:
			print("[EnemySkill] asleep: ", self)

	if skillController:
		skillController.process(_delta)
		skillController.useSkill();

	if(progress_ratio >= 1.0):
		if _removed:
			return
		_removed = true
		onReachEndPoint.emit();
		queue_free()

func _physics_process(delta):
	if(!initialized):
		return

	if enableMove and not castLocked:
		var parent: Path2D = get_parent() as Path2D
		var moveRatio = stats.getMoveSpeed(parent) * delta;
		var previousProgressRatio := progress_ratio
		progress_ratio += moveRatio;
		var direction := getPathDirection(parent, previousProgressRatio, progress_ratio)
		updateFacingFromDirection(direction)

func getPathDirection(parent: Path2D, fromProgressRatio: float, toProgressRatio: float) -> Vector2:
	if parent == null or parent.curve == null:
		return Vector2.ZERO

	var bakedLength := parent.curve.get_baked_length()
	if bakedLength <= 0.0:
		return Vector2.ZERO

	var fromDistance := clampf(fromProgressRatio * bakedLength, 0.0, bakedLength)
	var toDistance := clampf(toProgressRatio * bakedLength, 0.0, bakedLength)
	return parent.curve.sample_baked(toDistance) - parent.curve.sample_baked(fromDistance)

func updateFacingFromDirection(direction: Vector2):
	if sprite == null:
		return

	# Enemy source art is authored facing left; flip only when moving right.
	if abs(direction.x) <= FACING_X_EPSILON:
		return

	sprite.flip_h = direction.x > 0.0;

func setTexture(image: Texture2D):
	if(sprite != null && image != null):
		sprite.texture = image;
		sprite.flip_h = false;

func recvDamage(damage: Damage) -> int:
	# Refresh the awake window before ANY early-return so blocked hits
	# (e.g. while invincible or shield-blocked) still count as engagement.
	if inCombatRemaining <= 0.0:
		# Waking from sleep: arm the pacing timer - hit = wait -> cast.
		castWaitRemaining = castWait
		if EnemySkillController.DEBUG_LOG:
			print("[EnemySkill] engaged: ", self)
	inCombatRemaining = inCombatWindow

	# Invincible: no damage, no flash, no floating text. Single choke point -
	# every damage source (attacks, projectiles, DoT ticks, TRUE) funnels here.
	if isInvincible():
		return 0

	# Shield Block: one charge eats the WHOLE hit regardless of damage type
	# (TRUE included). Unlike invincible the enemy STAYS targetable - that is
	# the block vs untargetable line (enemy_skill.md). Charges live on
	# stats.blockCount, outside the effect system (buff_debuff.md).
	if stats.blockCount > 0:
		stats.blockCount -= 1
		Utility.show_float_text(global_position, get_parent(), "Block", Color(0.7, 0.85, 1.0))
		return 0

	sprite.modulate = Color.RED

	# Create a one-shot timer to reset the color
	var timer := get_tree().create_timer(0.3)
	timer.timeout.connect(_on_damage_flash_timeout)

	# TRUE damage bypasses armor/MR + ΣAmp + ΣRed — raw value applied straight to HP.
	# First caller: Staff skill `damage_percent_maxhp` (see damage_formula.md §4).
	var damageVal: int
	if damage.type == Damage.DamageType.TRUE:
		damageVal = damage.damage
	else:
		var defense_factor: float
		match damage.type:
			Damage.DamageType.MAGIC:
				defense_factor = stats.getMagicResistFactor()
			_:
				defense_factor = stats.getArmorFactor()

		# Master Formula §2 final pipeline: × armor_factor × (1 + ΣAmp) × (1 − ΣRed)
		var sigmaAmp: float = 0.0
		if damage.source != null and damage.source is Tower:
			var towerData: TowerData = (damage.source as Tower).data
			if towerData != null:
				sigmaAmp = towerData.effects.aggregate(EffectTypes.Kind.DAMAGE_AMPLIFIER)

		var sigmaRed: float = stats.getDamageReduction()  # already clamped; blocks consumed above
		damageVal = int(damage.damage * defense_factor * (1.0 + sigmaAmp) * (1.0 - sigmaRed))

	var currentHp = stats.updateHealth(-damageVal)

	updateHealthBar(currentHp);

	if currentHp <= 0:
		dead(damage)

	var dmgColor: Color
	match damage.type:
		Damage.DamageType.MAGIC:
			# vivid purple (normal) → pink-magenta (crit, rare event)
			dmgColor = Color(1.0, 0.3, 0.85) if damage.isCritical else Color(0.85, 0.45, 1.0)
		Damage.DamageType.TRUE:
			# bright gold — distinct from PHYSIC red and MAGIC purple
			dmgColor = Color(1.0, 0.85, 0.2)
		_:
			dmgColor = Color(1, 0.15, 0) if damage.isCritical else Color(1, 1, 1)

	Utility.show_damage_text(global_position, get_parent(), damageVal, dmgColor)
	return damageVal

func _on_damage_flash_timeout():
	if sprite:
		sprite.modulate = originalModulate

func updateHealthBar(value: float):
	# Bosses never show the small overhead bar - the top-center BossHealthBar
	# is their one HP surface (Director 2026-07-07).
	if healthBar and enemyType != EnemyType.Boss:
		healthBar.visible = true
		healthBar.updateValue(value)
	# recvDamage is the only HP mutation path, so this is the one emit site
	# (data source for the top-center boss HP bar).
	onHpChanged.emit(value, float(stats.maxHp))

func dead(cause: Damage):
	# Mutex guard (see _removed comment near top). If the reach-end branch
	# already fired, suppress onDead so the enemy doesn't double-decrement.
	# Note: ordering inside _process matters — effects.tick (DOT damage)
	# runs BEFORE the reach-end check, so a DOT-lethal tick at
	# progress_ratio >= 1.0 will set _removed here first, suppressing
	# the reach-end emit later in the same frame.
	if _removed:
		return
	_removed = true
	var reward = calcurateReward();
	onDead.emit(self, cause, reward);
	queue_free();

# Uniform effect surface (same shape as Tower).
func apply_effect(inst: EffectInstance) -> void:
	if effects != null:
		effects.apply(inst)

func remove_effect_source(source_id: String) -> void:
	if effects != null:
		effects.remove_source(source_id)

func calcurateReward() -> EnemyReward:
	# var evoTokenRand = randi_range(0, 100)
	var reward = EnemyReward.new(0, 0)
	if enemyType == EnemyType.Boss:
		reward.evoToken = 1;
	return reward

func addBlockDamageCount(value: int):
	stats.blockCount += value;

func setSpeed(value: float):
	stats.moveSpeed = value;

func isInCombat() -> bool:
	return inCombatRemaining > 0.0

# Pacing gate for EnemySkillController.useSkill: awake AND the castWait timer
# has elapsed (enemy_skill.md cast rules).
func canCastNow() -> bool:
	return isInCombat() and castWaitRemaining <= 0.0

# Container state is the single source of truth (no bool flag to desync);
# InvincibleBehavior pushes tower re-target on apply/expire.
func isInvincible() -> bool:
	return effects != null and effects.has_kind(EffectTypes.Kind.INVINCIBLE)

signal onReachEndPoint();
signal onDead(enemy: Enemy,cause: Damage, reward: EnemyReward);
signal onHpChanged(current: float, maxHp: float);
