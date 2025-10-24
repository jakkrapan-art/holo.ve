class_name WaveEnemyGroup
extends RefCounted

var texture: String
var health: int
var def: float
var mDef: float
var moveSpeed: float
var count: int
var spawnInterval: float = 0.2
var skill: Array[Skill] = []

func setup(texture: String, health: int,def: float, mDef: float, moveSpeed: float, count: int, spawnInterval: float = 0.2, skillData: Array[Skill] = []):
	self.texture = texture;
	self.health = health;
	self.moveSpeed = moveSpeed;
	self.def = def;
	self.mDef = mDef;
	self.count = count;
	self.spawnInterval = spawnInterval;
	self.skill = skillData;