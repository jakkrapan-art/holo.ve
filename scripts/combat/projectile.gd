extends RigidBody2D
class_name Projectile

@export var lifetime: float = 5
@onready var lifetimeTimer: Timer = $LifetimeTimer

@export var target: Node2D
var targetPosInMem: Vector2
var onHit: Callable

# Called when the node enters the scene tree for the first time.
func _ready():
	setLifeTime(lifetime)

func _process(delta):
	checkHitTarget();

func _physics_process(delta):
	moveToTarget(delta);

func setLifeTime(time: float):
	if (lifetimeTimer != null && lifetime > 0):
		lifetimeTimer.wait_time = time
		lifetimeTimer.start()

func setTarget(target: Node2D):
	self.target = target
	targetPosInMem = target.position

func subscribeOnHitAction(action: Callable):
	onHit = action

func checkHitTarget():
	if(position.distance_to(targetPosInMem) < 1):
		onTargetHitFunc()

func moveToTarget(delta):
	#rotate to target
	look_at(targetPosInMem)
	
	#move towards target
	var SPEED = 3000
	var dir = Vector2.RIGHT.rotated(rotation)
	linear_velocity = dir * SPEED * delta
	if (target != null):
		targetPosInMem = target.position

func onExpired():
	queue_free()

func onTargetHitFunc():
	queue_free()
	onTargetHit.emit(target)

signal onTargetHit(target: Entity)
