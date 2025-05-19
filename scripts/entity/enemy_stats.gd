class_name EnemyStat
extends Resource

@export var maxHp: int = 0;
@export var currentHp: int = 0;
@export var armor: int = 0;
@export var mArmor: int = 0;
@export var moveSpeed: float = 0;

func _init(hp: int, armor: int, mArmor: int, moveSpeed: float):
	maxHp = hp;
	currentHp = hp;
	self.armor = armor;
	self.mArmor = mArmor;
	self.moveSpeed = moveSpeed;
	
func updateHealth(amount: int):
	currentHp = clamp(currentHp + amount, 0, maxHp);
	return currentHp;

func getMoveSpeed(path: Path2D):
	return calculatePathfollowSpeed(path);
	
func calculatePathfollowSpeed(path: Path2D) -> float:
	var curve = path.curve
	if not curve:
		return 0.0
	var totalSegments = curve.point_count - 3
	if totalSegments <= 0:
		return 0.0
	var totalTime = (100.0 / moveSpeed) * totalSegments
	return 1.0 / totalTime  # how much progress_ratio to move per second
