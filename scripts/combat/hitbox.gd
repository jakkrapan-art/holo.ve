extends Area2D
class_name Hitbox

var _callback: Callable
var _size: Vector2 = Vector2.ZERO
var _local_offset: Vector2 = Vector2.ZERO
var _visual_color: Color = Color(1, 0, 0, 0.25)
var hide_delay: float = 0.2

static func create(width: float, height: float, callback: Callable, spawn_pos: Vector2 = Vector2.ZERO, parent: Node = null, spawn_rotation: float = 0.0, local_offset: Vector2 = Vector2.ZERO, visual_color: Color = Color(1, 0, 0, 0.25), visual_delay: float = 0.2) -> Hitbox:
	var hitbox := Hitbox.new()

	# Set callback and visual state
	hitbox._callback = callback
	hitbox._size = Vector2(width, height)
	hitbox._local_offset = local_offset
	hitbox._visual_color = visual_color
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
	hitbox._detect()

	return hitbox

func _draw():
	if _size == Vector2.ZERO:
		return

	var rect = Rect2(-_size * 0.5 + _local_offset, _size)
	draw_rect(rect, _visual_color, true)
	draw_rect(rect, Color(_visual_color.r, _visual_color.g, _visual_color.b, 1.0), false, 2)

func _detect():
	var enemies: Array = []
	var discovered = {}

	# Check areas and bodies so we cover both area-based and body-based enemies
	for node in get_overlapping_areas() + get_overlapping_bodies():
		print("overlapping node:", node)
		if not node or not node is Node:
			continue

		# enemy_base.tscn: PathFollow2D has group enemy, and sub-node Enemy Area2D also has group enemy.
		# Prefer returning the top-level Enemy instance when possible.
		var enemy_node: Node = node
		if node is PathFollow2D and node.is_in_group("enemy"):
			enemy_node = node
		elif node.has_node("..") and node.get_parent() and node.get_parent().is_in_group("enemy"):
			enemy_node = node.get_parent()
		elif node.is_in_group("enemy"):
			enemy_node = node

		if not enemy_node or not enemy_node.is_in_group("enemy"):
			continue
		if enemy_node in discovered:
			continue

		discovered[enemy_node] = true
		enemies.append(enemy_node)

	# If physics overlap gave nothing, fallback to group check via enemy nodes + local rectangle test
	if enemies.is_empty():
		for enemy_candidate in get_tree().get_nodes_in_group("enemy"):
			if not enemy_candidate or not enemy_candidate is Node2D:
				continue

			var point = to_local(enemy_candidate.global_position) - _local_offset
			if abs(point.x) <= _size.x * 0.5 and abs(point.y) <= _size.y * 0.5:
				if enemy_candidate not in discovered:
					discovered[enemy_candidate] = true
					enemies.append(enemy_candidate)

	# Debug logging
	print("Hitbox: global", global_position, "size", _size, "overlap_areas", get_overlapping_areas().size(), "overlap_bodies", get_overlapping_bodies().size(), "final", enemies.size())

	# Call callback
	if _callback:
		_callback.call(enemies)

	# Wait so player can see the hitbox
	if hide_delay > 0:
		await get_tree().create_timer(hide_delay).timeout

	# Cleanup
	queue_free()
