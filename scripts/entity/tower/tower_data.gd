class_name TowerData
extends Resource

const TowerClass = preload("res://scripts/entity/tower/tower_trait.gd").TowerClass
const TowerGeneration = preload("res://scripts/entity/tower/tower_trait.gd").TowerGeneration

var _level: int = 1;
var _evolutionCost: int = 1;
var _isEvolved: bool = false;

var _damageBuff: int = 0;
var _damagePercentBuff: float = 0;
var _damagePercentDebuff: float = 0;
var _rangeBuff: float = 0;
var _attackSpeedBuff: float = 1;
var _attackSpeedDebuff: float = 0;
var _manaRegenBuff: float = 0.0
var _critChanceBuff: float = 0.0

var _attackModifierBuff: Array[Callable] = []
var _modifiers := {}

@export var maxLevel: int = 3;
@export var towerClass: TowerClass;
@export var generation: TowerGeneration;

@export var stats: Array[TowerStat];
@export var evolutionStat: TowerStat;

@export var skill: Skill;

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

func getDamage(enemy: Enemy, source: Node2D) -> Damage:
	if(enemy == null):
		return Damage.new(source, getStat().damage + _damageBuff, Damage.DamageType.MAGIC);

	var finalDamage = calculateFinalDamage(getStat().damage + _damageBuff, enemy);
	return finalDamage;

func addPhysicDamageBuff(amount: int, key):
	if(key):
		if(_modifiers.has(key)):
			removePhysicDamageBuff(key)

	_damageBuff += amount;
	applyBuff(key, amount);

func removePhysicDamageBuff(key):
	var amount := 0;
	if(_modifiers.has(key)):
		amount = _modifiers.get(key, 0)
		removeBuff(key, amount);

	_damageBuff -= amount;

func addAttackBonusPercentBuff(amount: int, key):
	if key && _modifiers.has(key):
		removeAttackBonusPercentBuff(key);

	_damagePercentBuff += amount;
	applyBuff(key, amount);

func removeAttackBonusPercentBuff(key):
	var amount = 0;
	if(_modifiers.has(key)):
		amount = _modifiers[key]
		removeBuff(key, amount);
	_damagePercentBuff -= amount

func addAttackBonusPercentDebuff(amount: int, key):
	if key && _modifiers.has(key):
		removeAttackBonusPercentDebuff(key);

	_damagePercentDebuff += amount;
	applyBuff(key, amount);

func removeAttackBonusPercentDebuff(key):
	var amount = 0;
	if(_modifiers.has(key)):
		amount = _modifiers[key]
		removeBuff(key, amount);
	_damagePercentDebuff -= amount

func calculateFinalDamage(baseDamage: float, enemy: Enemy) -> Damage:
	var finalDamage = baseDamage

	# Apply each modifier in the array
	for modifier in _attackModifierBuff:
		finalDamage = modifier.call(finalDamage, enemy)

	#Apply percent buff
	finalDamage += (finalDamage * _damagePercentBuff / 100) * (1 - _damagePercentDebuff)

	var critChance = getCritChance();
	var isCrit = false;
	if(critChance > 0):
		if(randi_range(0, 100) <= critChance):
			finalDamage *= getStat().critMultiplier
			isCrit = true

	return Damage.new(null, int(finalDamage), Damage.DamageType.PHYSIC, isCrit)

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

func getAttackSpeed():
	return getStat().attackSpeed + _attackSpeedBuff;

func getAttackDelay():
	return getStat().getAttackDelay(_attackSpeedBuff) * (1 + _attackSpeedDebuff);

func getManaRegen():
	return getStat().manaRegen + _manaRegenBuff;

func addAttackSpeedBuff(amount: int, key):
	if(key):
		if(_modifiers.has(key)):
			removeAttackSpeedBuff(key)
		applyBuff(key, amount);
	_attackSpeedBuff += amount;

func removeAttackSpeedBuff(key):
	var amount = 0;
	if(_modifiers.has(key)):
		amount = _modifiers[key]
		removeBuff(key, amount);
	_attackSpeedBuff -= amount

func addAttackSpeedDebuff(amount: float, key):
	if(key):
		if(_modifiers.has(key)):
			removeAttackSpeedDebuff(key)
		applyBuff(key, amount);
	_attackSpeedDebuff += amount;

func removeAttackSpeedDebuff(key):
	var amount = 0;
	if(_modifiers.has(key)):
		amount = _modifiers[key]
		removeBuff(key, amount);
	_attackSpeedDebuff -= amount

func getAttackAnimationSpeed(anim: AnimatedSprite2D, name: String):
	var stat = getStat();
	return stat.getAttackAnimationSpeed(anim, name) * _attackSpeedBuff * (1 - _attackSpeedDebuff);

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
