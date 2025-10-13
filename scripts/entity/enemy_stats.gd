class_name EnemyStat
extends Resource

@export var maxHp: int = 0;
@export var currentHp: int = 0;
@export var armor: int = 0;
var extraArmorPercent: float = 0; # Additional armor from buffs/debuffs
@export var mArmor: int = 0;
var extraMArmorPercent: float = 0; # Additional magic armor from buffs/debuffs
@export var moveSpeed: float = 0;
var moveSpeedMultiplier: float = 1;
@export var damageReduction: float = 0.0; # Percentage (0.0 to 1.0)

var blockCount: int = 0; # Number of damage blocks available

var buffs: Dictionary = {};

func _init(hp: int, armor: int, mArmor: int, moveSpeed: float, damageReduction: float = 0.0):
	maxHp = hp;
	currentHp = hp;
	self.armor = armor;
	self.mArmor = mArmor;
	self.moveSpeed = moveSpeed;
	self.damageReduction = damageReduction;

func updateHealth(amount: int):
	currentHp = clamp(currentHp + amount, 0, maxHp);
	return currentHp;

func getMoveSpeed(path: Path2D):
	return calculatePathfollowSpeed(path) * moveSpeedMultiplier;

func calculatePathfollowSpeed(path: Path2D) -> float:
	var curve = path.curve
	if not curve:
		return 0.0
	var totalSegments = curve.point_count - 3
	if totalSegments <= 0:
		return 0.0
	var totalTime = (100.0 / moveSpeed) * totalSegments
	return 1.0 / totalTime  # how much progress_ratio to move per second

func getDamageReduction() -> float:
	if(blockCount > 0):
		blockCount -= 1
		return 1

	return clamp(damageReduction, 0.0, 0.9);

func addMoveSpeedMultiplier(value: float, key: String):
	moveSpeedMultiplier += value;
	buffs[key] = value;

func removeMoveSpeedMultiplier(key: String):
	moveSpeedMultiplier -= buffs[key];
	buffs.erase(key);

func addArmorPercent(value: float, key: String):
	if buffs.has(key):
		removeArmorPercent(key);

	extraArmorPercent += value;
	buffs[key] = value;

func removeArmorPercent(key: String):
	extraArmorPercent -= buffs[key];
	buffs.erase(key);

func addMArmorPercent(value: float, key: String):
	if buffs.has(key):
		removeMArmorPercent(key);

	extraMArmorPercent += value;
	buffs[key] = value;

func removeMArmorPercent(key: String):
	extraMArmorPercent -= buffs[key];
	buffs.erase(key);

func getTotalArmor() -> int:
	return armor + int(armor * extraArmorPercent);

func getTotalMArmor() -> int:
	return mArmor + int(mArmor * extraMArmorPercent);
