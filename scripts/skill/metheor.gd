extends Node2D
class_name Metheor

var spawn_position: Vector2
var spawn_delay: float
var max_radius: float = GridHelper.CELL_SIZE / 2
var elapsed_time: float = 0.0
var callback: Callable;
var tower: Tower;
var damagePercent: float;

func _init(tower: Tower, damagePercent: float, position: Vector2, delay: float, callback: Callable) -> void:
	spawn_position = position
	spawn_delay = delay;

	self.tower = tower;
	self.position = position;
	self.callback = callback;
	self.damagePercent = damagePercent;
	
func _process(delta: float) -> void:
	elapsed_time += delta
	if elapsed_time > spawn_delay:
		elapsed_time = spawn_delay

	if elapsed_time >= spawn_delay:
		detect_collision()
		queue_free();

	queue_redraw();

func detect_collision() -> void:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = max_radius
	query.shape = circle
	query.transform = Transform2D(0, global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [self]  # prevent detecting self

	# Optional: define specific collision layer
	query.collision_mask = 0xFFFFFFFF  # all layers

	var result = space_state.intersect_shape(query)
	for hit in result:
		if(hit.get("collider") is Area2D):
			var area = hit.get("collider") as Area2D;
			if(area.is_in_group("enemy")):
				var eArea = area as EnemyArea;
				callback.call(tower, damagePercent, eArea.enemy as Enemy);

func _draw() -> void:
	#draw_circle(Vector2.ZERO, max_radius, Color.WHITE)
	var t := elapsed_time / spawn_delay
	var current_radius = lerp(0.0, max_radius, t)
	draw_circle(Vector2.ZERO, current_radius, Color(1, 0, 0, 0.7))
