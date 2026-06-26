extends Area2D
class_name EnemyDetector

var radius: float = 3
@export var collision: CollisionShape2D;

var target: Enemy = null
var enemyInRange: Array[Enemy] = []
var enableDrawRange: bool = false

signal onEnemyDetected(enemy: Enemy)
signal onRemoveTarget()

func setup(radius: float):
	self.radius = radius + 0.5

	# 🔥 Make shape unique so it won't affect other towers
	if collision and collision.shape:
		collision.shape = collision.shape.duplicate()

	var circle = collision.shape as CircleShape2D
	if circle:
		circle.radius = self.radius * GridHelper.CELL_SIZE

	connect("area_entered", Callable(self, "onCollisionHit"))
	connect("area_exited", Callable(self, "onCollisionExit"))

func setEnabledDrawRange(value: bool):
	enableDrawRange = value

func _draw():
	if not enableDrawRange:
		return

	var circleColor = Color.SPRING_GREEN
	circleColor.a = 0.25

	var draw_radius = radius * GridHelper.CELL_SIZE
	draw_circle(position, draw_radius, circleColor)

	if target != null:
		var targetLocalPos = to_local(target.global_position)
		draw_line(position, targetLocalPos, Color.RED, 2.0)

func _process(_delta):
	queue_redraw();

func onCollisionHit(area: Area2D):
	if area.is_in_group("enemy"):
		var eArea = area as EnemyArea
		if eArea and eArea.enemy and not enemyInRange.has(eArea.enemy):
			enemyInRange.append(eArea.enemy)
			updateTarget(null, null, null)

func onCollisionExit(area: Area2D):
	if area.is_in_group("enemy"):
		var eArea = area as EnemyArea
		if eArea:
			var enemy = eArea.enemy
			enemyInRange.erase(enemy)

			if enemy == target:
				removeTarget()

			updateTarget(null, null, null)

func updateTarget(_enemy, _cause, _reward):
	if enemyInRange.size() == 0:
		setTarget(null)
		onEnemyDetected.emit(null)
		return

	# Priority: enemy closest to its path end point (highest progress_ratio).
	# Sticky: current target stays locked until it leaves range / dies.
	var best: Enemy = null
	var bestProgress: float = -1.0

	for enemy in enemyInRange:
		if enemy:
			if (enemy == target):
				best = enemy
				break;

			var p: float = enemy.progress_ratio
			if p > bestProgress:
				bestProgress = p
				best = enemy

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
