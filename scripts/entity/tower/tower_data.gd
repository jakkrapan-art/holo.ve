class_name TowerData
extends Resource

const TowerClass = preload("res://scripts/entity/tower/tower_trait.gd").TowerClass
const TowerGeneration = preload("res://scripts/entity/tower/tower_trait.gd").TowerGeneration

var level: int = 1;

var damageBuff: int = 0;
var damagePercentBuff: float = 0;
var rangeBuff: float = 0;
var attackSpeedBuff: float = 0;
var manaRegenBuff: float = 0.0
var critChanceBuff: float = 0.0
var meteorProcChanceBuff: float = 0.0
var meteorDamageBuff: float = 0.0

var attackModifierBuff: Array[Callable] = []
var modifiers := {}

@export var maxLevel: int = 3;
@export var towerClass: TowerClass;
@export var generation: TowerGeneration;
@export var stats: Array[TowerStat];

func getStat():
	var index = level - 1 if level > 0 and level <= (stats.size()) else stats.size() - 1
	return stats[index]

func getDamage(enemy: Enemy) -> Damage:
	if(enemy == null):
		return getStat().damage + damageBuff

	var finalDamage = calculateFinalDamage(getStat().damage + damageBuff, enemy);
	return finalDamage;

func addPhysicDamageBuff(amount: int, key):
	if(key):
		if(modifiers.has(key)):
			removePhysicDamageBuff(key)

	damageBuff += amount;
	applyBuff(key, amount);

func removePhysicDamageBuff(key):
	var amount := 0;
	if(modifiers.has(key)):
		amount = modifiers.get(key, 0)
		removeBuff(key, amount);

	damageBuff -= amount;

func addAttackBonusPercentBuff(amount: int, key):
	if key && modifiers.has(key):
		removeAttackBonusPercentBuff(key);

	damagePercentBuff += amount;
	applyBuff(key, amount);

func removeAttackBonusPercentBuff(key):
	var amount = 0;
	if(modifiers.has(key)):
		amount = modifiers[key]
		removeBuff(key, amount);
	damagePercentBuff -= amount

func calculateFinalDamage(baseDamage: float, enemy: Enemy) -> Damage:
	var finalDamage = baseDamage

	# Apply each modifier in the array
	for modifier in attackModifierBuff:
		finalDamage = modifier.call(finalDamage, enemy)

	#Apply percent buff
	finalDamage += finalDamage * damagePercentBuff / 100

	var critChance = getCritChance();
	var isCrit = false;
	if(critChance > 0):
		if(randi_range(0, 100) <= critChance):
			finalDamage *= getStat().critMultiplier
			isCrit = true

	return Damage.new(null, int(finalDamage), Damage.DamageType.PHYSIC, isCrit)

func getAttackRange():
	return getStat().attackRange + rangeBuff;

func addAttackRangeBuff(amount: int, key):
	if(key):
		if(modifiers.has(key)):
			removeAttackRangeBuff(key)
		applyBuff(key, amount);
	rangeBuff += amount;

func removeAttackRangeBuff(key):
	var amount = 0;
	if(modifiers.has(key)):
		amount = modifiers[key]
		removeBuff(key, amount);
	rangeBuff -= amount

func getAttackSpeed():
	return getStat().attackSpeed + attackSpeedBuff;

func getAttackDelay():
	return getStat().getAttackDelay(attackSpeedBuff);

func getManaRegen():
	return getStat().manaRegen + manaRegenBuff;

func addAttackSpeedBuff(amount: int, key):
	if(key):
		if(modifiers.has(key)):
			removeAttackSpeedBuff(key)
		applyBuff(key, amount);
	attackSpeedBuff += amount;

func removeAttackSpeedBuff(key):
	var amount = 0;
	if(modifiers.has(key)):
		amount = modifiers[key]
		removeBuff(key, amount);
	attackSpeedBuff -= amount

func getAttackAnimationSpeed(anim: AnimatedSprite2D, name: String):
	var stat = getStat();
	return stat.getAttackAnimationSpeed(anim, name);

func addmanaRegenBuff(amount: float, key):
	if(key):
		if(modifiers.has(key)):
			removemanaRegenBuff(key)
		applyBuff(key, amount);
	manaRegenBuff += amount

func removemanaRegenBuff(key):
	var amount := 0;
	if(modifiers.has(key)):
		amount = modifiers.get(key, 0)
		removeBuff(key, amount);
	manaRegenBuff -= amount

func getCritChance():
	return critChanceBuff + getStat().critChance

func addCritChanceBuff(amount: float, key):
	if(key):
		if(modifiers.has(key)):
			removeCritChanceBuff(key)
		applyBuff(key, amount);
	critChanceBuff += amount

func removeCritChanceBuff(key):
	var amount := 0;
	if(modifiers.has(key)):
		amount = modifiers.get(key, 0)
		removeBuff(key, amount);
	critChanceBuff -= amount

func levelUp():
	if level >= stats.size() - 1:
		return false;

	level = mini(level + 1, maxLevel);
	return true;

func applyBuff(key: String, value):
	modifiers[key] = value

func removeBuff(key: String, value):
	modifiers.erase(key);

signal onAttack(target);
