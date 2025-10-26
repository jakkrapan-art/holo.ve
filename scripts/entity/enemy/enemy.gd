extends PathFollow2D
class_name Enemy

@onready var sprite: Sprite2D = $Sprite2D;
@onready var area: Area2D = $Enemy;

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

func _process(_delta):
	if(!initialized):
		return;

	if skillController:
		skillController.useSkill();

	if statusEffects:
		statusEffects.processEffects(_delta, self)

	if(progress_ratio == 1):
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

	var reduction = stats.getDamageReduction();
	var damageVal = damage.damage;
	if reduction > 0:
		damageVal = int(damage.damage * (1 - reduction))
	var currentHp = stats.updateHealth(-damageVal)
	if currentHp <= 0:
		dead(damage)

	var dmgColor = Color(1, 1, 1) if not damage.isCritical else Color(1, 0.15, 0)

	Utility.show_damage_text(global_position, get_parent(), damageVal, dmgColor)
	return damageVal

func _on_damage_flash_timeout():
	if sprite:
		sprite.modulate = originalModulate

func dead(cause: Damage):
	var reward = calcurateReward();
	onDead.emit(cause, reward);
	queue_free();

func addStatusEffect(effect: StatusEffect):
	if statusEffects == null:
		statusEffects = StatusEffectContainer.new(self)
	statusEffects.addEffect(effect)

func calcurateReward() -> EnemyReward:
	# var evoTokenRand = randi_range(0, 100)
	var reward = EnemyReward.new(100, 0)
	if enemyType == EnemyType.Boss:
		reward.evoToken = 1;
	return reward

func addIncreaseMoveSpeed(value: float, key: String):
	stats.addMoveSpeedMultiplier(value, key);

func removeIncreaseMoveSpeed(key: String):
	stats.removeMoveSpeedMultiplier(key);

func addIncreaseDef(value: float, key: String):
	stats.addArmorPercent(value, key);

func removeIncreaseDef(key: String):
	stats.removeArmorPercent(key);

func addBlockDamageCount(value: int):
	stats.blockCount += value;

func setSpeed(value: float):
	stats.moveSpeed = value;

signal onReachEndPoint();
signal onDead(cause: Damage, reward: EnemyReward);
