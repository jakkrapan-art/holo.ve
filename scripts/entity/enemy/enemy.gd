extends PathFollow2D
class_name Enemy

@onready var sprite: Sprite2D = $Sprite2D;
@onready var area: Area2D = $Enemy;

enum EnemyType {Normal, Elite, Boss}

var maxHp: int = 0;
var currentHp: int = 0;
var armor: int = 0;
var mArmor: int = 0;
var moveSpeed: int = 0;

func setup(hp: int, armor: int, mArmor: int, moveSpeed: int, texture: Texture2D):
	setTexture(texture);
	maxHp = hp;
	currentHp = hp;
	self.armor = armor;
	self.mArmor = mArmor;
	self.moveSpeed = moveSpeed;

func _process(_delta):
	if(progress_ratio == 1):
		onReachEndPoint.emit();
		queue_free()

func _physics_process(delta):
	progress_ratio += 0.1 * delta

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

signal onReachEndPoint();
signal onDead();
