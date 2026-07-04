class_name TowerData
extends Resource

const TowerClass = preload("res://scripts/entity/tower/tower_trait.gd").TowerClass
const TowerGeneration = preload("res://scripts/entity/tower/tower_trait.gd").TowerGeneration

const AS_MIN := 1.0
const AS_MAX := 500.0

# Energy gained per normal attack. Design intent: a fixed base, buff/debuff adjustable.
const BASE_MANA_REGEN := 10

var _level: int = 1;
var _evolutionCost: int = 1;
var _isEvolved: bool = false;

var _attackModifierBuff: Array[Callable] = []

# Unified buff/debuff store. NOTE: TowerData is shared per-character and
# outlives the tower node (sell/re-place) - the Tower clears wave-scoped
# effects on exit and rebinds the host on ready.
var effects: EffectContainer = EffectContainer.new()

@export var maxLevel: int = 3;
@export var towerClass: TowerClass = TowerClass.Assassin;
@export var generation: TowerGeneration = TowerGeneration.Myth;
@export var attackType: Damage.DamageType = Damage.DamageType.PHYSIC;

@export var stats: Array[TowerStat];
@export var evolutionStat: TowerStat;

@export var skill: Skill;
var evolutionSkill: Skill = null;
# Passive slot params (designer-tunable values; behavior lives in code keyed by
# `behavior`). Empty = no passive. evolutionPassive overrides when evolved.
var passive: Dictionary = {};
var evolutionPassive: Dictionary = {};
var attack_sound: String = "hit";
var attack_vfx: String = "atk";
var open_sound: String = "open";
var evolve_sound: String = "";
# Optional normal-attack config (YAML `attack:` block). null = hitscan (back-compat).
var attack_config: TowerAttackConfig = null;

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
			flat = effects.aggregate(EffectTypes.Kind.MAGIC_FLAT)
			mult = effects.aggregate(EffectTypes.Kind.MAGIC_MULT)
		_:
			flat = effects.aggregate(EffectTypes.Kind.ATTACK_FLAT)
			mult = effects.aggregate(EffectTypes.Kind.ATTACK_MULT)
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
	# randi_range(1, 100) → 100 values for exact critChance/100 probability (§6.2 #1 fix)
	var isCrit: bool = critChance > 0 and randi_range(1, 100) <= critChance
	var sigmaCD: float = getStat().critMultiplier + effects.aggregate(EffectTypes.Kind.CRIT_DAMAGE_BONUS)
	var critCheck: float = 1.0 if isCrit else 0.0
	finalDamage *= 1.0 + (critCheck * (sigmaCD - 1.0))

	return Damage.new(null, int(finalDamage), attackType, isCrit)

func getAttackRange():
	return getStat().attackRange + effects.aggregate(EffectTypes.Kind.RANGE)

func getAttackSpeed() -> float:
	# ATTACK_SPEED is decimal scale (0.5 = +50%) — matches MOVE_SPEED post-PR #9.
	var sigma := 1.0 + effects.aggregate(EffectTypes.Kind.ATTACK_SPEED)
	return clampf(getStat().attackSpeed * sigma, AS_MIN, AS_MAX)

func getAttackDelay() -> float:
	return 100.0 / getAttackSpeed()

func getManaRegen():
	return BASE_MANA_REGEN + effects.aggregate(EffectTypes.Kind.MANA_REGEN)

func getAttackAnimationSpeed(anim: AnimatedSprite2D, name: String) -> float:
	return getStat().getAttackAnimationSpeed(anim, name, getAttackDelay())

func getCritChance():
	return getStat().critChance + effects.aggregate(EffectTypes.Kind.CRIT_CHANCE)

# Current critical-damage multiplier (base + additive CRIT_DAMAGE_BONUS).
# Mirrors the `sigmaCD` term in calculateFinalDamage so callers (e.g. the
# crit_pierce passive arrow) reuse the same additive crit-damage rule.
func getCritDamage() -> float:
	return getStat().critMultiplier + effects.aggregate(EffectTypes.Kind.CRIT_DAMAGE_BONUS)

func levelUp():
	if _level >= stats.size():
		return false;

	_level = mini(_level + 1, maxLevel);
	return true;

func evolve():
	if _isEvolved:
		return false;

	_isEvolved = true;
	return true;
