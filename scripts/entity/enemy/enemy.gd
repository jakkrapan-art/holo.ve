extends PathFollow2D
class_name Enemy

@onready var sprite: Sprite2D = $Sprite2D;
@onready var area: Area2D = $Enemy;

@export var stats: EnemyStat;
var original_modulate: Color

enum EnemyType {Normal, Elite, Boss}

func setup(hp: int, armor: int, mArmor: int, moveSpeed: int, texture: Texture2D):
	setTexture(texture);
	var calMoveSpeed = calculate_pathfollow_speed(get_parent() as Path2D, moveSpeed);
	stats = EnemyStat.new(hp, armor, mArmor, calMoveSpeed);
	
	original_modulate = sprite.modulate

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
	sprite.modulate = Color.RED

	# Create a one-shot timer to reset the color
	var timer := get_tree().create_timer(0.3)
	timer.timeout.connect(_on_damage_flash_timeout)

	var currentHp = stats.updateHealth(-damage)
	if currentHp <= 0:
		dead()

	return damage

func _on_damage_flash_timeout():
	if sprite:
		sprite.modulate = original_modulate
	
func dead():
	onDead.emit();
	queue_free();
	
func calculate_pathfollow_speed(path: Path2D, moveSpeed: float) -> float:
	var curve = path.curve
	if not curve:
		return 0.0
	var totalSegments = curve.point_count - 3
	if totalSegments <= 0:
		return 0.0
	var totalTime = (100.0 / moveSpeed) * totalSegments
	return 1.0 / totalTime  # how much progress_ratio to move per second

signal onReachEndPoint();
signal onDead();
