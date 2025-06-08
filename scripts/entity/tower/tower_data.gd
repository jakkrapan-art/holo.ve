class_name TowerData
extends Resource

const TowerClass = preload("res://scripts/entity/tower/tower_trait.gd").TowerClass
const TowerGeneration = preload("res://scripts/entity/tower/tower_trait.gd").TowerGeneration

var level: int = 1;

var damageBuff: int = 0;
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
	
func getDamage(enemy: Enemy):
	var finalDamage = calculateFinalDamage(getStat().damage + damageBuff, enemy);
	return finalDamage;

func addPhysicDamageBuff(amount: int):
	damageBuff += amount;

func removePhysicDamageBuff(amount: int):
	damageBuff -= amount

func calculateFinalDamage(baseDamage: float, enemy: Enemy) -> float:
	var finalDamage = baseDamage
	
	# Apply each modifier in the array
	for modifier in attackModifierBuff:
		finalDamage = modifier.call(finalDamage, enemy)
	
	return finalDamage

func getAttackRange():
	return getStat().attackRange + rangeBuff;

func addAttackRangeBuff(amount: int):
	rangeBuff += amount;

func removeAttackRangeBuff(amount: int):
	rangeBuff -= amount

func getAttackSpeed():
	return getStat().attackSpeed + attackSpeedBuff;

func getAttackDelay():
	return getStat().getAttackDelay(attackSpeedBuff);

func getManaRegen():
	return getStat().manaRegen + manaRegenBuff;

func addAttackSpeedBuff(amount: int):
	attackSpeedBuff += amount;

func removeAttackSpeedBuff(amount: int):
	attackSpeedBuff -= amount

func getAttackAnimationSpeed(anim: AnimatedSprite2D, name: String):
	var stat = getStat();
	return stat.getAttackAnimationSpeed(anim, name);

func addAttackModifierBuff(modifier: Callable):
	attackModifierBuff.append(modifier);

func removeAttackModifierBuff(modifier: Callable):
	attackModifierBuff.erase(modifier);
	
func addmanaRegenBuff(amount: float):
	manaRegenBuff += amount
	applyBuff("manaRegenBuff", amount)

func removemanaRegenBuff(amount: float):
	manaRegenBuff -= amount
	removeBuff("manaRegenBuff", amount)

func addCritChanceBuff(amount: float):
	critChanceBuff += amount
	applyBuff("critChanceBuff", amount)

func removeCritChanceBuff(amount: float):
	critChanceBuff -= amount
	removeBuff("critChanceBuff", amount)

func addMeteorProcChanceBuff(amount: float):
	meteorProcChanceBuff += amount
	applyBuff("meteorProcChanceBuff", amount)

func removeMeteorProcChanceBuff(amount: float):
	meteorProcChanceBuff -= amount
	removeBuff("meteorProcChanceBuff", amount)

func addMeteorDamageBuff(amount: float):
	meteorDamageBuff += amount
	applyBuff("meteorDamageBuff", amount)

func removeMeteorDamageBuff(amount: float):
	meteorDamageBuff -= amount
	removeBuff("meteorDamageBuff", amount)

func levelUp():
	if level >= stats.size() - 1:
		return false;
	
	level = mini(level + 1, maxLevel);
	return true;

func applyBuff(key: String, value):
	modifiers[key] = (modifiers.get(key, 0) + value)

func removeBuff(key: String, value):
	modifiers[key] = max(0, modifiers.get(key, 0) - value)

signal onAttack(target);
