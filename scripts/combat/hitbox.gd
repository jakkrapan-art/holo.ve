extends Area2D
class_name Hitbox

enum VisualKind {
	DEBUG_ONLY,
	GAMEPLAY_TELEGRAPH,
}

const DEV_AREA_META: StringName = &"_dev_show_skill_areas"
const DEV_VISUAL_GROUP: StringName = &"_dev_skill_area_visual"
const DEV_MIN_VISIBLE_SECONDS := 0.35
const DEV_FILL := Color(1.0, 0.0, 0.0, 0.15)
const DEV_BORDER := Color(1.0, 0.0, 0.0, 1.0)
const DEV_BORDER_WIDTH := 3.0

var _callback: Callable
var _size: Vector2 = Vector2.ZERO
var _local_offset: Vector2 = Vector2.ZERO
var _visual_color: Color = Color(1, 0, 0, 0.25)
var _visual_kind: VisualKind = VisualKind.DEBUG_ONLY
var _last_dev_visible: bool = false
var _dev_visual_suppressed: bool = false
var hide_delay: float = 0

static func create(width: float, height: float, callback: Callable, spawn_pos: Vector2 = Vector2.ZERO, parent: Node = null, spawn_rotation: float = 0.0, local_offset: Vector2 = Vector2.ZERO, visual_color: Color = Color(1, 0, 0, 0.25), visual_delay: float = 0, visual_kind: VisualKind = VisualKind.DEBUG_ONLY) -> Hitbox:
	var hitbox := Hitbox.new()

	# Set callback and visual state
	hitbox._callback = callback
	hitbox._size = Vector2(width, height)
	hitbox._local_offset = local_offset
	hitbox._visual_color = visual_color
	hitbox._visual_kind = visual_kind
	hitbox.hide_delay = visual_delay

	# Collision shape
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = hitbox._size
	collision.shape = shape
	collision.position = local_offset

	hitbox.add_child(collision)

	# Set position + rotation
	hitbox.global_position = spawn_pos
	hitbox.global_rotation = spawn_rotation

	# Monitoring settings
	hitbox.monitoring = true
	hitbox.monitorable = true

	# Collision layers/masks (make sure it can detect enemies)
	hitbox.collision_layer = 0xFFFFFFFF
	hitbox.collision_mask = 0xFFFFFFFF

	# Add to scene
	if parent:
		parent.add_child(hitbox)

	# Force redraw and physics frame update
	hitbox.queue_redraw()
	await hitbox.get_tree().process_frame
	# process_frame keeps emitting while the tree is paused (same trap the dash
	# action guards) - hold the strike until unpause so a pause landing on this
	# exact frame can't let damage through mid-pause.
	while is_instance_valid(hitbox) and hitbox.get_tree().paused:
		await hitbox.get_tree().process_frame
	if not is_instance_valid(hitbox):
		return null
	hitbox._detect()

	return hitbox

func _draw():
	if _size == Vector2.ZERO:
		return
	var dev_visible := _dev_area_visible()
	if dev_visible and _dev_visual_suppressed:
		return
	if not dev_visible and (
		_visual_kind != VisualKind.GAMEPLAY_TELEGRAPH or _visual_color.a <= 0.0
	):
		return

	var rect = Rect2(-_size * 0.5 + _local_offset, _size)
	var fill := DEV_FILL if dev_visible else _visual_color
	var border := DEV_BORDER if dev_visible else Color(
		_visual_color.r, _visual_color.g, _visual_color.b, 1.0
	)
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, DEV_BORDER_WIDTH if dev_visible else 2.0)

func _ready() -> void:
	add_to_group(DEV_VISUAL_GROUP)
	_last_dev_visible = _dev_area_visible()
	if _last_dev_visible:
		_claim_matching_dev_visual()

func _process(_delta: float) -> void:
	var dev_visible := _dev_area_visible()
	if dev_visible != _last_dev_visible:
		_last_dev_visible = dev_visible
		if dev_visible:
			_claim_matching_dev_visual()
		else:
			_dev_visual_suppressed = false
		queue_redraw()

func _claim_matching_dev_visual() -> void:
	# Rapid/channel hits keep independent detection nodes, but exact repeated
	# geometry gets one visual owner so translucent fills cannot accumulate.
	_dev_visual_suppressed = false
	for node in get_tree().get_nodes_in_group(DEV_VISUAL_GROUP):
		var other := node as Hitbox
		if other == null or other == self or not _matches_dev_geometry(other):
			continue
		if other.get_instance_id() > get_instance_id():
			_dev_visual_suppressed = true
		else:
			other._dev_visual_suppressed = true
			other.queue_redraw()

func _matches_dev_geometry(other: Hitbox) -> bool:
	return _size.is_equal_approx(other._size) \
		and _local_offset.is_equal_approx(other._local_offset) \
		and global_position.is_equal_approx(other.global_position) \
		and is_equal_approx(global_rotation, other.global_rotation)

func _restore_previous_dev_visual() -> void:
	var replacement: Hitbox = null
	for node in get_tree().get_nodes_in_group(DEV_VISUAL_GROUP):
		var candidate := node as Hitbox
		if candidate == null or candidate == self \
			or not _matches_dev_geometry(candidate):
			continue
		if replacement == null \
			or candidate.get_instance_id() > replacement.get_instance_id():
			replacement = candidate
	if replacement != null:
		replacement._dev_visual_suppressed = false
		replacement.queue_redraw()

func _dev_area_visible() -> bool:
	return is_inside_tree() and bool(get_tree().get_meta(DEV_AREA_META, false))

func _exit_tree() -> void:
	if _last_dev_visible and not _dev_visual_suppressed:
		_restore_previous_dev_visual()

# Normalize an overlap / group-scan result to its owning Enemy (PathFollow2D).
# enemy_base.tscn places the "enemy" group on BOTH the PathFollow2D Enemy and its child Area2D (EnemyArea),
# so overlap queries / group scans may return either node. Resolve once here so callbacks always receive Enemy.
# Returns null if the node is not an enemy-shaped node.
static func _resolve_enemy(node: Node) -> Enemy:
	if node is Enemy:
		return node
	if node is Area2D and node.get_parent() is Enemy:
		return node.get_parent()
	return null

func _detect():
	var enemies: Array = []
	var discovered := {}

	if _callback.is_valid():
		# Check areas and bodies so we cover both area-based and body-based enemies
		for node in get_overlapping_areas() + get_overlapping_bodies():
			var enemy_node := _resolve_enemy(node)
			if enemy_node == null:
				continue
			if enemy_node in discovered:
				continue
			discovered[enemy_node] = true
			enemies.append(enemy_node)

		# If physics overlap gave nothing, fallback to group check via enemy nodes + local rectangle test
		if enemies.is_empty():
			for candidate in get_tree().get_nodes_in_group("enemy"):
				var enemy_node := _resolve_enemy(candidate)
				if enemy_node == null:
					continue
				if enemy_node in discovered:
					continue

				# Rect test uses the canonical Enemy position (EnemyArea may have local offset).
				var point = to_local(enemy_node.global_position) - _local_offset
				if abs(point.x) <= _size.x * 0.5 and abs(point.y) <= _size.y * 0.5:
					discovered[enemy_node] = true
					enemies.append(enemy_node)

		_callback.call(enemies)

	# Debug visibility is cosmetic and begins after detection, so it cannot delay damage.
	var visible_seconds := (
		maxf(hide_delay, DEV_MIN_VISIBLE_SECONDS)
		if _dev_area_visible()
		else hide_delay
	)
	if visible_seconds > 0:
		await get_tree().create_timer(visible_seconds, false).timeout

	# Cleanup
	queue_free()
