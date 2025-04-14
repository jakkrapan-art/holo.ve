extends PathFollow2D
class_name Enemy

@onready var sprite: Sprite2D = $Sprite2D;
@onready var area: Area2D = $Enemy;

@export var stats: EnemyStat;

enum EnemyType {Normal, Elite, Boss}

func setup(hp: int, armor: int, mArmor: int, moveSpeed: int, texture: Texture2D):
	setTexture(texture);
	var calMoveSpeed = calculate_pathfollow_speed(get_parent() as Path2D, moveSpeed);
	stats = EnemyStat.new(hp, armor, mArmor, calMoveSpeed);

func _process(_delta):
	if(progress_ratio == 1):
		onReachEndPoint.emit();
		queue_free()

func _physics_process(delta):
	progress_ratio += stats.moveSpeed * delta;

func setTexture(image: Texture2D):
	if(sprite != null && image != null):
		sprite.texture = image;
		
func recvDamage(damage: int) -> int:
	var currentHp = stats.updateHealth(-damage);
	if(currentHp <= 0):
		dead();
	return damage;
	
func dead():
	onDead.emit();
	queue_free();
	
func calculate_pathfollow_speed(path: Path2D, moveSpeed: float) -> float:
	var curve = path.curve
	if curve.point_count < 2:
		return 0.0  # Not enough points to move
	
	var pointCount = curve.point_count - 2; # remove start and end node
	var totalSegments = pointCount - 1
	return 1.0 / (totalSegments * moveSpeed)


signal onReachEndPoint();
signal onDead();
