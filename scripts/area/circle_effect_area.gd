class_name CircleEffectArea
# extends Area2D
extends EffectArea

@export var radius: float = 2.0  # Default radius of the circle
@export var duration: float = 5.0  # Default duration of the effect
@export var drawColor: Color = Color(0, 0, 1, 0.2);

var elapsedTime: float = 0.0;

func setup(p_radius: float = 2.0, p_duration: float = 5.0, callback: EffectAreaCallback = null, p_drawColor: Color = Color(0, 0, 1, 0.2)):
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = p_radius
	_base_setup(circle_shape, callback);
	collisionShape.scale = Vector2.ONE * p_radius;
	elapsedTime = 0.0
	self.drawColor = p_drawColor
	self.radius = p_radius
	self.duration = p_duration

func _process(delta: float) -> void:
	elapsedTime += delta
	if elapsedTime >= duration:
		queue_free();

	super._process(delta);

func _draw():
	var circleColor = drawColor;
	if(collisionShape == null):
		var children = get_children()
		for child in children:
			if child is CollisionShape2D:
				collisionShape = child
				break;
	var draw_radius = collisionShape.scale.x * GridHelper.CELL_SIZE
	draw_circle(position, draw_radius, circleColor)
