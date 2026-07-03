class_name EnemyStat
extends Resource

# Enemy stat block. Buff/debuff modifiers live in the unified EffectContainer
# (injected by Enemy.setup) and are read through aggregate() - the legacy
# per-key extra*/multiplier fields are gone.

@export var maxHp: int = 0;
@export var currentHp: int = 0;
@export var armor: int = 0;
@export var mArmor: int = 0;
@export var moveSpeed: float = 0;
@export var damageReduction: float = 0.0; # base Damage Reduction - Master Formula final pipeline

var blockCount: int = 0; # Number of damage blocks available

# Injected by Enemy.setup(); shared with the icon row and skill actions.
var effects: EffectContainer = null

func _init(hp: int, p_armor: int, p_mArmor: int, p_moveSpeed: float, p_damageReduction: float = 0.0):
	maxHp = hp;
	currentHp = hp;
	self.armor = p_armor;
	self.mArmor = p_mArmor;
	self.moveSpeed = p_moveSpeed;
	self.damageReduction = p_damageReduction;

func _agg(kind: int) -> float:
	return effects.aggregate(kind) if effects != null else 0.0

func updateHealth(amount: int):
	currentHp = clamp(currentHp + amount, 0, maxHp);
	return currentHp;

const MS_MIN := 1.0
const MS_MAX := 500.0

# Effective Move Speed = (Base + SigmaFlat) * (1 + SigmaMult) clamp [1, 500]
# Logic: 100 = 1 tile/second, 200 = 2 tiles/second.
# Floor 1 is intentional: slow stays distinct from stun/freeze (never stops).
func getEffectiveMoveSpeed() -> float:
	var base: float = moveSpeed + _agg(EffectTypes.Kind.MOVE_SPEED_FLAT)
	return clampf(base * (1.0 + _agg(EffectTypes.Kind.MOVE_SPEED_MULT)), MS_MIN, MS_MAX)

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
		return 1

	return clamp(damageReduction + _agg(EffectTypes.Kind.DAMAGE_REDUCTION), 0.0, 0.9);

const ARMOR_MAX := 95

# Master Formula armor: Total = (Base + SigmaFlat) * (1 + SigmaMult), clamp 0-95
func getTotalArmor() -> int:
	var withFlat: float = armor + _agg(EffectTypes.Kind.ARMOR_FLAT)
	return clampi(int(withFlat * (1.0 + _agg(EffectTypes.Kind.ARMOR_MULT))), 0, ARMOR_MAX);

func getTotalMArmor() -> int:
	var withFlat: float = mArmor + _agg(EffectTypes.Kind.MARMOR_FLAT)
	return clampi(int(withFlat * (1.0 + _agg(EffectTypes.Kind.MARMOR_MULT))), 0, ARMOR_MAX);

func getArmorFactor() -> float:
	return 1.0 - float(getTotalArmor()) / 100.0

func getMagicResistFactor() -> float:
	return 1.0 - float(getTotalMArmor()) / 100.0
