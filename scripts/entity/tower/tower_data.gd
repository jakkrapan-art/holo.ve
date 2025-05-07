class_name TowerData
extends Resource

const TowerClass = preload("res://scripts/entity/tower/tower_trait.gd").TowerClass
const TowerGeneration = preload("res://scripts/entity/tower/tower_trait.gd").TowerGeneration

var level: int = 1;

var pDamageBuff: int = 0;
var mDamageBuff: int = 0;
var rangeBuff: float = 0;
var attackSpeedBuff: float = 0;

@export var maxLevel: int = 3;
@export var towerClass: TowerClass;
@export var generation: TowerGeneration;
@export var stats: Array[TowerStat];

func getStat():
	var index = level - 1 if level > 0 and level <= (stats.size()) else stats.size() - 1
	return stats[index]
	
func getPhysicDamage():
	return getStat().pDamage + pDamageBuff;

func addPhysicDamageBuff(amount: int):
	pDamageBuff += amount;

func removePhysicDamageBuff(amount: int):
	pDamageBuff -= amount

func getMagicDamage():
	return getStat().mDamage + mDamageBuff;
	
func addMagicDamageBuff(amount: int):
	mDamageBuff += amount;

func removeMagicDamageBuff(amount: int):
	mDamageBuff -= amount

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

func addAttackSpeedBuff(amount: int):
	attackSpeedBuff += amount;

func removeAttackSpeedBuff(amount: int):
	attackSpeedBuff -= amount

func getAttackAnimationSpeed(anim: AnimatedSprite2D, name: String):
	var stat = getStat();
	return stat.getAttackAnimationSpeed(anim, name);

func levelUp():
	level = mini(level + 1, maxLevel);
