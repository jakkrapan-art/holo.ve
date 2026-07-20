extends Area2D
class_name EnemyDetector

var radius: float = 3
@export var collision: CollisionShape2D;

# Attack-range ring, drawn for both the placement preview and an inspected tower.
# Publisher-CI blue family: bright cyan edge over a faint blue wash.
# Static by design - the inspect outline already owns the pulsing beat, and a
# second pulse on a shape this large reads as noise (Director 2026-07-20).
const RING_FILL := Color(0.40, 0.85, 1.00, 0.12)
const RING_STROKE := Color("#6cecfd", 0.95)
# Blocked variant, placement only: the cell tint alone was easy to miss once the
# ring drew in a friendly colour, so the ring itself answers "can I drop here"
# (Director 2026-07-20).
const RING_FILL_BLOCKED := Color(1.00, 0.35, 0.35, 0.12)
const RING_STROKE_BLOCKED := Color(0.80, 0.16, 0.20, 0.95)
# Cell-relative, not a pixel literal: world-space _draw() must survive camera
# zoom and map-extent changes. CELL_SIZE comes from an
# autoload, so this stays a fraction and is resolved at draw time, not a const.
const RING_STROKE_CELL_FRAC := 0.046

var target: Enemy = null
var enemyInRange: Array[Enemy] = []
var enableDrawRange: bool = false
var rangeBlocked: bool = false

signal onEnemyDetected(enemy: Enemy)
signal onRemoveTarget()

func setup(p_radius: float):
	# 🔥 Make shape unique so it won't affect other towers
	if collision and collision.shape:
		collision.shape = collision.shape.duplicate()

	syncRange(p_radius)

	# Ring sits below every tower (z 0) and enemy (z 1) but above the TileMap
	# (also -1, but earlier in tree order), so an inspected tower's ring never
	# washes over its neighbours' art.
	z_index = -1

	connect("area_entered", Callable(self, "onCollisionHit"))
	connect("area_exited", Callable(self, "onCollisionExit"))

# The only place the detection radius is written. Call it whenever the tower's
# range can have changed (level-up, evolve) - the value is a snapshot, not a
# live read, so a missed call silently desyncs the real hitbox from the range
# the stats panel displays.
func syncRange(p_range: float) -> void:
	self.radius = p_range + 0.5

	if collision != null:
		var circle = collision.shape as CircleShape2D
		if circle:
			circle.radius = self.radius * GridHelper.CELL_SIZE

	queue_redraw()

func setEnabledDrawRange(value: bool):
	if not value:
		# Placement is the only writer of the blocked state, so clearing it on
		# hide guarantees an inspected tower can never inherit a stale red ring.
		rangeBlocked = false
	enableDrawRange = value
	queue_redraw()

# Called every frame while a tower is being dragged, so it must stay a no-op
# until the answer actually flips - otherwise the ring is back to redrawing
# every frame.
func setRangeBlocked(value: bool) -> void:
	if rangeBlocked == value:
		return
	rangeBlocked = value
	queue_redraw()

func _draw():
	if not enableDrawRange:
		return

	var fill = RING_FILL_BLOCKED if rangeBlocked else RING_FILL
	var stroke = RING_STROKE_BLOCKED if rangeBlocked else RING_STROKE

	var draw_radius = radius * GridHelper.CELL_SIZE
	draw_circle(position, draw_radius, fill)
	draw_arc(position, draw_radius, 0.0, TAU, 64, stroke,
			GridHelper.CELL_SIZE * RING_STROKE_CELL_FRAC, true)

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
			# Untargetable (invincible) enemies are skipped BEFORE the sticky
			# check, so a locked target that turns invincible is dropped too.
			# InvincibleBehavior re-runs updateTarget on apply/expire.
			if enemy.isInvincible():
				continue

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
