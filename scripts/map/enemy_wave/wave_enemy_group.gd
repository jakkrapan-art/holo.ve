class_name WaveEnemyGroup
extends Resource

@export var texture: String
@export var health: int
@export var def: float
@export var mDef: float
@export var moveSpeed: float
@export var count: int

func setup(texture: String, health: int,def: float, mDef: float, moveSpeed: float, count: int):
	self.texture = texture;
	self.health = health;
	self.moveSpeed = moveSpeed;
	self.def = def;
	self.mDef = mDef;
	self.count = count;
