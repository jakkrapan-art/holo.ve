extends SkillAction
class_name SkillActionFindMultipleInRange

@export var width: int = 1 # Width in cells
@export var height: int = 2 # Height in cells

var target_group: String = "enemy" # Group name for potential targets
var max_attempt := 1
var attempt := 0

func execute(context: SkillContext):
	attempt = 0
	context.target = [] # Assuming context has a targets array property

	while context.target.is_empty() && attempt < max_attempt:
		find_targets_in_rotated_range(context)

		if context.target.is_empty():
			attempt += 1
			await context.user.get_tree().process_frame

	if attempt >= max_attempt && context.target.is_empty():
		context.cancel = true

func find_targets_in_rotated_range(context: SkillContext):
	if not context.user:
		return

	var user_position = context.user.global_position
	var user_rotation = 0;
	if context.user is Tower:
		var tower := context.user as Tower
		if tower.enemy == null:
			return;

		user_rotation = get_user_rotation(tower, tower.enemy)

	# Calculate actual dimensions from cell counts
	var actual_width = width * GridHelper.CELL_SIZE
	var actual_height = height * GridHelper.CELL_SIZE

	# Get all nodes in the target group
	var all_targets = context.user.get_tree().get_nodes_in_group(target_group);
	var valid_targets = []

	for target in all_targets:
		if not target or not target is Node2D:
			continue

		if is_target_in_rotated_rectangle(user_position, user_rotation, target.global_position, actual_width, actual_height):
			var distance = user_position.distance_to(target.global_position)
			valid_targets.append({
				"target": target,
				"distance": distance
			})

	# Sort by distance (closest first)
	valid_targets.sort_custom(func(a, b): return a.distance < b.distance)

	# Add all targets (no limit)
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
	if(tower.enemy == null):
		return;

	var user_rotation = get_user_rotation(tower, tower.enemy);
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
