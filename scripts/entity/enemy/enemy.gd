extends PathFollow2D
class_name Enemy

@onready var sprite: Sprite2D = $Sprite2D;
@onready var area: Area2D = $Enemy;
@onready var healthBar: HealthBar = $HealthBar;

@export var stats: EnemyStat;
var originalModulate: Color

var enemyType: EnemyType = EnemyType.Normal;

var statusEffects: StatusEffectContainer;
var skillController: EnemySkillController;
var enableMove: bool = true;

var initialized: bool = false;

enum EnemyType {Normal, Elite, Boss}

func setup(enemyType: EnemyType, hp: int, armor: int, mArmor: int, moveSpeed: int, texture: Texture2D, skills: Array[Skill] = []):
	self.enemyType = enemyType;
	setTexture(texture);
	stats = EnemyStat.new(hp, armor, mArmor, moveSpeed);
	originalModulate = sprite.modulate
	skillController = EnemySkillController.new(self, skills);
	initialized = true;

	if healthBar:
		healthBar.setup(hp, false);
		healthBar.visible = false;

func _process(_delta):
	if(!initialized):
		return;

	if statusEffects:
		statusEffects.processEffects(_delta, self)

	if skillController:
		skillController.process(_delta)
		skillController.useSkill();

	if(progress_ratio >= 1.0):
		onReachEndPoint.emit();
		queue_free()

func _physics_process(delta):
	if(!initialized):
		return

	if enableMove:
		var parent: Path2D = get_parent() as Path2D
		var moveRatio = stats.getMoveSpeed(parent) * delta;
		# var curve := (parent).curve
		var oldPos := global_position
		progress_ratio += moveRatio;
		var pos := global_position # sample a little ahead
		var direction = pos - oldPos;
		if abs(direction.x) > (GridHelper.CELL_SIZE * 0.01):
			sprite.flip_h = direction.x > 0;

func setTexture(image: Texture2D):
	if(sprite != null && image != null):
		sprite.texture = image;

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
				sigmaAmp = towerData.buffs.aggregate(BuffInstance.StatType.DAMAGE_AMPLIFIER)

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
	var reward = calcurateReward();
	onDead.emit(self, cause, reward);
	queue_free();

func addStatusEffect(effect: StatusEffect):
	if statusEffects == null:
		statusEffects = StatusEffectContainer.new(self)
	statusEffects.addEffect(effect)

func calcurateReward() -> EnemyReward:
	# var evoTokenRand = randi_range(0, 100)
	var reward = EnemyReward.new(0, 0)
	if enemyType == EnemyType.Boss:
		reward.evoToken = 1;
	return reward

func addIncreaseMoveSpeed(value: float, key: String):
	stats.addMoveSpeedMultiplier(value, key);

func removeIncreaseMoveSpeed(key: String):
	stats.removeMoveSpeedMultiplier(key);

func addIncreaseDefPercent(value: float, key: String):
	stats.addDefPercent(value, key);

func removeIncreaseDefPercent(key: String):
	stats.removeDefPercent(key);

func addIncreaseMArmorPercent(value: float, key: String):
	stats.addMArmorPercent(value, key);

func removeIncreaseMArmorPercent(key: String):
	stats.removeMArmorPercent(key);

func addIncreaseArmorFlat(value: int, key: String):
	stats.addArmorFlat(value, key);

func removeIncreaseArmorFlat(key: String):
	stats.removeArmorFlat(key);

func addIncreaseMArmorFlat(value: int, key: String):
	stats.addMArmorFlat(value, key);

func removeIncreaseMArmorFlat(key: String):
	stats.removeMArmorFlat(key);

func addBlockDamageCount(value: int):
	stats.blockCount += value;

func setSpeed(value: float):
	stats.moveSpeed = value;

signal onReachEndPoint();
signal onDead(enemy: Enemy,cause: Damage, reward: EnemyReward);
