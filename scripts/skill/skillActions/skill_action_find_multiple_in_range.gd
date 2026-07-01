extends SkillAction
class_name SkillActionFindMultipleInRange

@export var width: int = 1 # Width in cells
@export var height: int = 2 # Height in cells
var cancel_when_empty: bool = true

var target_group: String = "enemy" # Group name for potential targets
var max_attempt := 1
var attempt := 0

func execute(context: SkillContext):
	attempt = 0
	context.target = [] # Assuming context has a targets array property

	while context.target.is_empty() && attempt < max_attempt:
		await find_targets_in_rotated_range(context)

		if context.target.is_empty():
			attempt += 1
			await context.user.get_tree().process_frame

	if attempt >= max_attempt && context.target.is_empty() && cancel_when_empty:
		context.cancel = true

func find_targets_in_rotated_range(context: SkillContext):
	if not context.user:
		return

	# Default: tower-aimed AOE — anchor at user position, rotate toward target, extend forward.
	var user_position = context.user.global_position
	var user_rotation = 0.0
	var center_on_anchor: bool = false

	# Player-aimed override: if context.extra carries a target_position (Vector2), use it as the
	# hitbox CENTER instead of context.user.global_position. Skip rotation (axis-aligned grid AOE)
	# and skip the forward-extend offset (rect centered on click, not extending past it).
	# Caller responsibility: snap target_position to grid cell before passing it in.
	var override_position = context.extra.get("target_position", null)
	if override_position != null and override_position is Vector2:
		user_position = override_position
		user_rotation = 0.0
		center_on_anchor = true
	elif context.user is Tower:
		var tower := context.user as Tower
		if tower.enemy != null:
			user_rotation = get_user_rotation(tower, tower.enemy)
			# Snapshot aim direction while tower.enemy is valid — survives the skill's
			# animation await even if the enemy dies before play_effect/projectile run.
			var aim := tower.enemy.global_position - tower.global_position
			if aim.length() > 0.001:
				context.extra["aim_dir"] = aim.normalized()
		else:
			# Combo beat fallback: the locked enemy died (e.g. an earlier beat killed it),
			# so reuse the snapshotted aim direction. The box still fires along the cast
			# direction and hits live enemies in it, instead of no-op'ing on an empty target.
			# aim_dir is the first-beat snapshot UNLESS an earlier beat re-locked a live
			# enemy via the detector and refreshed it — both are correct.
			# aim_dir.angle() - PI/2 matches get_user_rotation's angle_to_point(target) - PI/2 (Godot 4.x).
			var aim_dir = context.extra.get("aim_dir", null)
			if aim_dir is Vector2:
				user_rotation = aim_dir.angle() - PI / 2
			else:
				return

	# Calculate actual dimensions from cell counts
	var cellSize = GridHelper.CELL_SIZE
	var actual_width = width * cellSize + (cellSize * 0.5) # Add half cell size for better coverage
	var actual_height = height * cellSize + (cellSize * 0.5) # Add half cell size for better coverage

	# Offset: tower mode extends forward from anchor; player-aim mode centers on click.
	var local_offset = Vector2(0, 0) if center_on_anchor else Vector2(0, actual_height * 0.5)

	# Place the hitbox at the resolved anchor
	var hitbox_position = user_position

	# Parent the hitbox to ensure it's in the scene tree for physics checks
	var parent_node = context.user.get_parent() if context.user.get_parent() else context.user.get_tree().current_scene

	var callback = Callable(self, "_on_hitbox_detected").bind(context, user_position)
	await Hitbox.create(actual_width, actual_height, callback, hitbox_position, parent_node, user_rotation, local_offset)

func _on_hitbox_detected(enemies: Array, context: SkillContext, user_position: Vector2):
	if not context:
		return

	var valid_targets = []
	for enemy in enemies:
		if not enemy or not enemy is Node2D:
			continue

		# Normalize to the Enemy (PathFollow2D) for progress lookup.
		# Hitbox._detect() may return either Enemy or EnemyArea (Area2D child of Enemy), since both share the "enemy" group.
		var enemy_node: Enemy = null
		if enemy is Enemy:
			enemy_node = enemy
		elif enemy is Area2D and enemy.get_parent() is Enemy:
			enemy_node = enemy.get_parent()
		if enemy_node == null:
			continue

		var distance = user_position.distance_to(enemy.global_position)
		valid_targets.append({
			"target": enemy,
			"enemy_node": enemy_node,
			"distance": distance
		})

	# Sort by path progress (closest to end first) — match normal-attack priority.
	valid_targets.sort_custom(func(a, b): return a.enemy_node.progress_ratio > b.enemy_node.progress_ratio)

	for target_data in valid_targets:
		context.target.append(target_data.target)

func get_user_rotation(user: Node2D, target: Node2D) -> float:
	var angle = user.global_position.angle_to_point(target.global_position)
	angle -= PI / 2  # Adjust by 90 degrees (in radians)
	return angle

func is_target_in_rotated_rectangle(origin: Vector2, rotation: float, target_pos: Vector2, rect_width: float, rect_height: float) -> bool:
	# Transform target position to local space (relative to origin and rotation)
	var relative_pos = target_pos - origin

	# Rotate the relative position by negative rotation to "unrotate" it
	var cos_rot = cos(-rotation)
	var sin_rot = sin(-rotation)
	var local_x = relative_pos.x * cos_rot - relative_pos.y * sin_rot
	var local_y = relative_pos.x * sin_rot + relative_pos.y * cos_rot

	# The rectangle extends from origin forward (positive Y) and to both sides
	# Rectangle bounds: -width/2 to width/2 (X), 0 to height (Y)
	var half_width = rect_width / 2.0

	return (local_x >= -half_width && local_x <= half_width &&
			local_y >= 0 && local_y <= rect_height)

# Optional: Get rectangle corners for debug visualization
func get_rectangle_corners(origin: Vector2, rotation: float, rect_width: float, rect_height: float) -> Array[Vector2]:
	var half_width = rect_width / 2.0

	# Local corners (before rotation)
	var local_corners = [
		Vector2(-half_width, 0), # Bottom-left
		Vector2(half_width, 0), # Bottom-right
		Vector2(half_width, rect_height), # Top-right
		Vector2(-half_width, rect_height) # Top-left
	]

	# Rotate and translate corners
	var cos_rot = cos(rotation)
	var sin_rot = sin(rotation)
	var corners: Array[Vector2] = []

	for local_corner in local_corners:
		var world_x = local_corner.x * cos_rot - local_corner.y * sin_rot + origin.x
		var world_y = local_corner.x * sin_rot + local_corner.y * cos_rot + origin.y
		corners.append(Vector2(world_x, world_y))

	return corners

# Optional: Debug draw function (call this in _draw() method of a CanvasItem)
func debug_draw(canvas_item: CanvasItem, context: SkillContext, color: Color = Color.YELLOW):
	if not context.user or not canvas_item or not context.user is Tower:
		return

	var tower := context.user as Tower
	var user_position = GridHelper.WorldToCell(context.user.global_position)
	if tower.enemy == null:
		return

	var user_rotation = get_user_rotation(tower, tower.enemy)
	var actual_width = width * GridHelper.CELL_SIZE;
	var actual_height = height * GridHelper.CELL_SIZE;

	# Get rectangle corners
	var corners = get_rectangle_corners(user_position, user_rotation, actual_width, actual_height)
	for i in range(corners.size()):
		var next_i = (i + 1) % corners.size()
		canvas_item.draw_line(corners[i], corners[next_i], color, GridHelper.CELL_SIZE * 0.25)

	# Draw grid lines for cells
	var grid_color = Color(color.r, color.g, color.b, 0.3)

	# Horizontal grid lines (width divisions)
	for i in range(1, width):
		var t = float(i) / float(width)
		var start = corners[0].lerp(corners[1], t)
		var end = corners[3].lerp(corners[2], t)
		canvas_item.draw_line(start, end, grid_color, 1.0)

	# Vertical grid lines (height divisions)
	for i in range(1, height):
		var t = float(i) / float(height)
		var start = corners[0].lerp(corners[3], t)
		var end = corners[1].lerp(corners[2], t)
		canvas_item.draw_line(start, end, grid_color, 1.0)
