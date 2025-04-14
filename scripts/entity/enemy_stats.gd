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
