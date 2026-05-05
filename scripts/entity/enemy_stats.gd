class_name EnemyStat
extends Resource

@export var maxHp: int = 0;
@export var currentHp: int = 0;
@export var armor: int = 0;
var extraArmorFlat: int = 0; # Additional armor (flat) from buffs/debuffs — ΣFlat in §4.1
var extraArmorPercent: float = 0; # Additional armor (%) from buffs/debuffs — ΣMult in §4.1
@export var mArmor: int = 0;
var extraMArmorFlat: int = 0; # Additional magic armor (flat) from buffs/debuffs
var extraMArmorPercent: float = 0; # Additional magic armor (%) from buffs/debuffs
@export var moveSpeed: float = 0;
var moveSpeedMultiplier: float = 1;
@export var damageReduction: float = 0.0; # Σ Damage Reduction (additive 0.0–0.9) — §6 final pipeline

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

const MS_MIN := 1.0
const MS_MAX := 500.0

# Effective Move Speed = Base × (1 + ΣM) clamp [1, 500]
# Logic: 100 = monster เดินผ่าน 1 ช่อง / วินาที, 200 = 2 ช่อง / วินาที
# Floor 1 ตั้งใจแยก slow ออกจาก stun/freeze (slow ติด floor=1 ไม่หยุด)
func getEffectiveMoveSpeed() -> float:
	return clampf(moveSpeed * moveSpeedMultiplier, MS_MIN, MS_MAX)

func getMoveSpeed(path: Path2D):
	return calculatePathfollowSpeed(path);

func calculatePathfollowSpeed(path: Path2D) -> float:
	var curve = path.curve
	if not curve:
		return 0.0
	var totalSegments = curve.point_count - 3
	if totalSegments <= 0:
		return 0.0
	var totalTime = (100.0 / getEffectiveMoveSpeed()) * totalSegments
	return 1.0 / totalTime  # how much progress_ratio to move per second

func getDamageReduction() -> float:
	if(blockCount > 0):
		blockCount -= 1
		print("block remain:", blockCount);
		return 1

	return clamp(damageReduction, 0.0, 0.9);

func addMoveSpeedMultiplier(value: float, key: String):
	if buffs.has(key):
		removeMoveSpeedMultiplier(key);
	moveSpeedMultiplier += value;
	buffs[key] = value;

func removeMoveSpeedMultiplier(key: String):
	if(!buffs.has(key)):
		return;
	moveSpeedMultiplier -= buffs[key];
	buffs.erase(key);

func addDefPercent(value: float, key: String):
	if buffs.has(key):
		removeDefPercent(key);

	extraArmorPercent += value;
	buffs[key] = value;

func removeDefPercent(key: String):
	if(!buffs.has(key)):
		return;

	extraArmorPercent -= buffs[key];
	buffs.erase(key);

func addMArmorPercent(value: float, key: String):
	if buffs.has(key):
		removeMArmorPercent(key);

	extraMArmorPercent += value;
	buffs[key] = value;

func removeMArmorPercent(key: String):
	if(!buffs.has(key)):
		return;

	extraMArmorPercent -= buffs[key];
	buffs.erase(key);

func addArmorFlat(value: int, key: String):
	if buffs.has(key):
		removeArmorFlat(key);

	extraArmorFlat += value;
	buffs[key] = value;

func removeArmorFlat(key: String):
	if(!buffs.has(key)):
		return;

	extraArmorFlat -= int(buffs[key]);
	buffs.erase(key);

func addMArmorFlat(value: int, key: String):
	if buffs.has(key):
		removeMArmorFlat(key);

	extraMArmorFlat += value;
	buffs[key] = value;

func removeMArmorFlat(key: String):
	if(!buffs.has(key)):
		return;

	extraMArmorFlat -= int(buffs[key]);
	buffs.erase(key);

func addDamageReduction(value: float, key: String):
	if buffs.has(key):
		removeDamageReduction(key);

	damageReduction += value;
	buffs[key] = value;

func removeDamageReduction(key: String):
	if(!buffs.has(key)):
		return;

	damageReduction -= float(buffs[key]);
	buffs.erase(key);

const ARMOR_MAX := 95

# §4.1 / §4.2: Total = (Base + ΣFlat) × (1 + ΣMult), clamp 0–95
func getTotalArmor() -> int:
	var withFlat: int = armor + extraArmorFlat
	return clampi(int(withFlat * (1.0 + extraArmorPercent)), 0, ARMOR_MAX);

func getTotalMArmor() -> int:
	var withFlat: int = mArmor + extraMArmorFlat
	return clampi(int(withFlat * (1.0 + extraMArmorPercent)), 0, ARMOR_MAX);

func getArmorFactor() -> float:
	return 1.0 - float(getTotalArmor()) / 100.0

func getMagicResistFactor() -> float:
	return 1.0 - float(getTotalMArmor()) / 100.0
