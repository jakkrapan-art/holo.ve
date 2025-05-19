extends PathFollow2D
class_name Enemy

@onready var sprite: Sprite2D = $Sprite2D;
@onready var area: Area2D = $Enemy;

@export var stats: EnemyStat;
var original_modulate: Color

enum EnemyType {Normal, Elite, Boss}

func setup(hp: int, armor: int, mArmor: int, moveSpeed: int, texture: Texture2D):
	setTexture(texture);
	stats = EnemyStat.new(hp, armor, mArmor, moveSpeed);
	
	original_modulate = sprite.modulate

func _process(_delta):
	if(progress_ratio == 1):
		onReachEndPoint.emit();
		queue_free()

func _physics_process(delta):
	progress_ratio += stats.getMoveSpeed(get_parent() as Path2D) * delta;

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

signal onReachEndPoint();
signal onDead();
