extends Node2D
class_name Metheor

var spawn_position: Vector2
var delay_explode: float
var max_radius: float = GridHelper.CELL_SIZE / 2
var elapsed_time: float = 0.0
var damage: float;

func _init(damage: float, position: Vector2, delay_explode: float) -> void:
	spawn_position = position
	self.delay_explode = delay_explode;

	self.position = position;
	self.damage = damage;
	
func _process(delta: float) -> void:
	elapsed_time += delta
	if elapsed_time > self.delay_explode:
		elapsed_time = self.delay_explode

	if elapsed_time >= self.delay_explode:
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
				if eArea.enemy.has_method("recvDamage"):
					eArea.enemy.recvDamage(damage);

func _draw() -> void:
	#draw_circle(Vector2.ZERO, max_radius, Color.WHITE)
	var t := elapsed_time / self.delay_explode
	var current_radius = lerp(0.0, max_radius, t)
	draw_circle(Vector2.ZERO, current_radius, Color(1, 0, 0, 0.7))
