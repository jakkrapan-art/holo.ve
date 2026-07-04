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
	initialized = true;

	if healthBar:
		healthBar.setup(hp, false);
		healthBar.visible = false;

func _process(_delta):
	if(!initialized):
		return;

	if effects:
		effects.tick(_delta)

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

	if enableMove:
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

		var sigmaRed: float = stats.getDamageReduction()  # already clamped + handles blockCount
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
	if healthBar:
		healthBar.visible = true
		healthBar.updateValue(value)

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

signal onReachEndPoint();
signal onDead(enemy: Enemy,cause: Damage, reward: EnemyReward);
