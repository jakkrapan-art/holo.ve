extends PathFollow2D
class_name Enemy

@onready var sprite: Sprite2D = $Sprite2D;
@onready var area: Area2D = $Enemy;

enum EnemyType {Normal, Elite, Boss}

var maxHp: int = 0;
var currentHp: int = 0;
var armor: int = 0;
var mArmor: int = 0;
var moveSpeed: float = 0;

var spawnTime = 0

func setup(hp: int, armor: int, mArmor: int, moveSpeed: int, texture: Texture2D):
	setTexture(texture);
	maxHp = hp;
	currentHp = hp;
	self.armor = armor;
	self.mArmor = mArmor;
	self.moveSpeed = calculate_pathfollow_speed(get_parent() as Path2D, moveSpeed);
	spawnTime = Time.get_ticks_msec();
	
	connect("onReachEndPoint", Callable(self, "showLifeTime"));

func showLifeTime():
	print("lifetime: ", (Time.get_ticks_msec() - spawnTime)/1000);

func _process(_delta):
	if(progress_ratio == 1):
		onReachEndPoint.emit();
		queue_free()

func _physics_process(delta):
	progress_ratio += moveSpeed * delta;

func setTexture(image: Texture2D):
	if(sprite != null && image != null):
		sprite.texture = image;
		
func recvDamage(damage: int) -> int:
	currentHp -= damage;
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
