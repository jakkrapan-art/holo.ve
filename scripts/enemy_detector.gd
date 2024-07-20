extends Node
class_name EnemyDetector

@export var radius: float = 3
@onready var collision: CollisionShape2D = $CollisionShape2D

var target: Entity = null

func _ready():
	collision.scale = Vector2.ONE * (radius * 2)
	connect("area_entered", Callable(self, "onCollisionHit"))
	connect("area_exited", Callable(self, "onCollisionExit"))

func onCollisionHit(area: Area2D):
	if area.is_in_group("enemy"):
		target = area as Entity
		onEnemyDetected.emit(target)

func onCollisionExit(area: Area2D):
	if(area.is_in_group("enemy") && target != null):
		target = null
	
func isHasEnemy() -> bool:
	return target != null

signal onEnemyDetected(enemy: Entity)
