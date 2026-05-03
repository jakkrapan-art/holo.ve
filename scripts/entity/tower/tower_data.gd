class_name TowerData
extends Resource

const TowerClass = preload("res://scripts/entity/tower/tower_trait.gd").TowerClass
const TowerGeneration = preload("res://scripts/entity/tower/tower_trait.gd").TowerGeneration

const AS_MIN := 1.0
const AS_MAX := 500.0

var _level: int = 1;
var _evolutionCost: int = 1;
var _isEvolved: bool = false;

var _rangeBuff: float = 0;
var _manaRegenBuff: float = 0.0
var _critChanceBuff: float = 0.0

var _attackModifierBuff: Array[Callable] = []
var _modifiers := {}

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

	var critChance = getCritChance();
	var isCrit = false;
	if(critChance > 0):
		if(randi_range(0, 100) <= critChance):
			finalDamage *= getStat().critMultiplier
			isCrit = true

	return Damage.new(null, int(finalDamage), attackType, isCrit)

func getAttackRange():
	return getStat().attackRange + _rangeBuff;

func addAttackRangeBuff(amount: int, key):
	if(key):
		if(_modifiers.has(key)):
			removeAttackRangeBuff(key)
		applyBuff(key, amount);
	_rangeBuff += amount;

func removeAttackRangeBuff(key):
	var amount = 0;
	if(_modifiers.has(key)):
		amount = _modifiers[key]
		removeBuff(key, amount);
	_rangeBuff -= amount

func getAttackSpeed() -> float:
	var sigma := 1.0 + (buffs.aggregate(BuffInstance.StatType.ATTACK_SPEED) / 100.0)
	return clampf(getStat().attackSpeed * sigma, AS_MIN, AS_MAX)

func getAttackDelay() -> float:
	return 100.0 / getAttackSpeed()

func getManaRegen():
	return getStat().manaRegen + _manaRegenBuff;

func getAttackAnimationSpeed(anim: AnimatedSprite2D, name: String) -> float:
	return getStat().getAttackAnimationSpeed(anim, name, getAttackDelay())

func addManaRegenBuff(amount: float, key):
	if(key):
		if(_modifiers.has(key)):
			removeManaRegenBuff(key)
		applyBuff(key, amount);
	_manaRegenBuff += amount

func removeManaRegenBuff(key):
	var amount := 0;
	if(_modifiers.has(key)):
		amount = _modifiers.get(key, 0)
		removeBuff(key, amount);
	_manaRegenBuff -= amount

func getCritChance():
	return _critChanceBuff + getStat().critChance

func addCritChanceBuff(amount: float, key):
	if(key):
		if(_modifiers.has(key)):
			removeCritChanceBuff(key)
		applyBuff(key, amount);
	_critChanceBuff += amount

func removeCritChanceBuff(key):
	var amount := 0;
	if(_modifiers.has(key)):
		amount = _modifiers.get(key, 0)
		removeBuff(key, amount);
	_critChanceBuff -= amount

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

func applyBuff(key: String, value):
	_modifiers[key] = value

func removeBuff(key: String, value):
	_modifiers.erase(key);

signal onAttack(target);
