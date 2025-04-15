extends Area2D
class_name EnemyDetector

@export var radius: float = 3
@export var collision: CollisionShape2D;

var target: Enemy = null
var enemyInRange: Array[Enemy] = []

signal onEnemyDetected(enemy: Enemy)
signal onRemoveTarget()

func _ready():
	var circle = collision.shape as CircleShape2D
	if circle:
		circle.radius = radius * GridHelper.CELL_SIZE

	connect("area_entered", Callable(self, "onCollisionHit"))
	connect("area_exited", Callable(self, "onCollisionExit"))

#func _draw():
	#var circleColor = Color.SPRING_GREEN
	#circleColor.a = 0.2
#
	#var draw_radius = radius * GridHelper.CELL_SIZE
	#draw_circle(position, draw_radius, circleColor)
#
	#if target != null:
		#var targetLocalPos = to_local(target.global_position)
		#draw_line(position, targetLocalPos, Color.RED, 2.0)

func _process(delta):
	queue_redraw()

func onCollisionHit(area: Area2D):
	if area.is_in_group("enemy"):
		var eArea = area as EnemyArea
		if eArea and eArea.enemy and not enemyInRange.has(eArea.enemy):
			enemyInRange.append(eArea.enemy)
			updateTarget()

func onCollisionExit(area: Area2D):
	if area.is_in_group("enemy"):
		var eArea = area as EnemyArea
		if eArea:
			var enemy = eArea.enemy
			if enemy == target:
				removeTarget()

			enemyInRange.erase(enemy)
			updateTarget()

func updateTarget():
	if enemyInRange.size() == 0:
		setTarget(null)
		onEnemyDetected.emit(null)
		return

	var best: Enemy = null
	var currentDistance: float = -1

	for enemy in enemyInRange:
		if enemy:
			var distance = enemy.progress_ratio
			if distance > currentDistance:
				currentDistance = distance
				best = enemy
	
	if(best == target):
		return;
	setTarget(best)
	onEnemyDetected.emit(best)

func setTarget(enemy: Enemy):
	removeTarget()
	if enemy != null:
		if not enemy.is_connected("onDead", Callable(self, "updateTarget")):
			enemy.connect("onDead", Callable(self, "updateTarget"))
		target = enemy

func removeTarget():
	if target != null:
		if target.is_connected("onDead", Callable(self, "updateTarget")):
			target.disconnect("onDead", Callable(self, "updateTarget"))
		target = null
		onRemoveTarget.emit()

func isHasEnemy() -> bool:
	return target != null
