class_name TowerData
extends Resource

const TowerClass = preload("res://scripts/entity/tower/tower_trait.gd").TowerClass
const TowerGeneration = preload("res://scripts/entity/tower/tower_trait.gd").TowerGeneration

const AS_MIN := 1.0
const AS_MAX := 500.0

var _level: int = 1;
var _evolutionCost: int = 1;
var _isEvolved: bool = false;

var _attackModifierBuff: Array[Callable] = []

var buffs: TowerBuffContainer = TowerBuffContainer.new()

@export var maxLevel: int = 3;
@export var towerClass: TowerClass;
@export var generation: TowerGeneration;
@export var attackType: Damage.DamageType = Damage.DamageType.PHYSIC;

@export var stats: Array[TowerStat];
@export var evolutionStat: TowerStat;

@export var skill: Skill;
var evolutionSkill: Skill = null;
var attack_sound: String = "hit";
var attack_vfx: String = "atk";
var open_sound: String = "open";

func getStat():
	if(!_isEvolved):
		var index = _level - 1 if _level > 0 and _level <= (stats.size()) else stats.size() - 1
		return stats[index]

	return evolutionStat if evolutionStat != null else stats[stats.size() - 1];

@export var level: int:
	get:
		return _level;

@export var isEvolved: bool:
	get:
		return _isEvolved;

@export var evolutionCost: int:
	get:
		return _evolutionCost;

func getTotalAttack() -> int:
	var base: float = float(getStat().damage)
	var flat: float
	var mult: float
	match attackType:
		Damage.DamageType.MAGIC:
			flat = buffs.aggregate(BuffInstance.StatType.MAGIC_FLAT)
			mult = buffs.aggregate(BuffInstance.StatType.MAGIC_MULT)
		_:
			flat = buffs.aggregate(BuffInstance.StatType.ATTACK_FLAT)
			mult = buffs.aggregate(BuffInstance.StatType.ATTACK_MULT)
	var total: float = (base + flat) * (1.0 + mult / 100.0)
	return int(clampf(total, 1.0, INF))

func getDamage(enemy: Enemy, source: Node2D) -> Damage:
	if(enemy == null):
		return Damage.new(source, getTotalAttack(), attackType);

	var finalDamage = calculateFinalDamage(getTotalAttack(), enemy);
	return finalDamage;

func calculateFinalDamage(baseDamage: float, enemy: Enemy) -> Damage:
	var finalDamage = baseDamage

	# Apply each modifier in the array
	for modifier in _attackModifierBuff:
		finalDamage = modifier.call(finalDamage, enemy)

	var critChance: float = getCritChance()
	var isCrit: bool = critChance > 0 and randi_range(0, 100) <= critChance
	var sigmaCD: float = getStat().critMultiplier + buffs.aggregate(BuffInstance.StatType.CRIT_DAMAGE_BONUS)
	var critCheck: float = 1.0 if isCrit else 0.0
	finalDamage *= 1.0 + (critCheck * (sigmaCD - 1.0))

	return Damage.new(null, int(finalDamage), attackType, isCrit)

func getAttackRange():
	return getStat().attackRange + buffs.aggregate(BuffInstance.StatType.RANGE)

func addAttackRangeBuff(amount, key):
	_addBuffByStat(BuffInstance.StatType.RANGE, float(amount), key)

func removeAttackRangeBuff(key):
	if key:
		buffs.remove(str(key))

func getAttackSpeed() -> float:
	var sigma := 1.0 + (buffs.aggregate(BuffInstance.StatType.ATTACK_SPEED) / 100.0)
	return clampf(getStat().attackSpeed * sigma, AS_MIN, AS_MAX)

func getAttackDelay() -> float:
	return 100.0 / getAttackSpeed()

func getManaRegen():
	return getStat().manaRegen + buffs.aggregate(BuffInstance.StatType.MANA_REGEN)

func getAttackAnimationSpeed(anim: AnimatedSprite2D, name: String) -> float:
	return getStat().getAttackAnimationSpeed(anim, name, getAttackDelay())

func addManaRegenBuff(amount: float, key):
	_addBuffByStat(BuffInstance.StatType.MANA_REGEN, amount, key)

func removeManaRegenBuff(key):
	if key:
		buffs.remove(str(key))

func getCritChance():
	return getStat().critChance + buffs.aggregate(BuffInstance.StatType.CRIT_CHANCE)

func addCritChanceBuff(amount: float, key):
	_addBuffByStat(BuffInstance.StatType.CRIT_CHANCE, amount, key)

func removeCritChanceBuff(key):
	if key:
		buffs.remove(str(key))

# Internal helper — REFRESH-on-key semantics (matches legacy behavior).
# Inserts BuffInstance into `buffs`; if `key` already exists it's replaced.
func _addBuffByStat(statType: int, value: float, key) -> void:
	if not key:
		return
	var keyStr := str(key)
	buffs.remove(keyStr)
	var category: int = BuffInstance.Category.BUFF if value >= 0 else BuffInstance.Category.DEBUFF
	buffs.add(BuffInstance.new(keyStr, statType, value, category))

func levelUp():
	print("level up, current level ", _level, " max level ", maxLevel);
	if _level >= stats.size():
		return false;

	_level = mini(_level + 1, maxLevel);
	print("level up to ", _level);
	return true;

func evolve():
	if _isEvolved:
		return false;

	_isEvolved = true;
	print("evolve success");
	return true;

signal onAttack(target);
