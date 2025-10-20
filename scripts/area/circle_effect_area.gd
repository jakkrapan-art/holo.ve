class_name CircleEffectArea
# extends Area2D
extends EffectArea

@export var radius: float = 2.0  # Default radius of the circle
@export var duration: float = 5.0  # Default duration of the effect
@export var drawColor: Color = Color(0, 0, 1, 0.2);

var endTime = 0;

func setup(radius: float = 2.0, duration: float = 5.0, callback: EffectAreaCallback = null, drawColor: Color = Color(0, 0, 1, 0.2)):
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	_base_setup(circle_shape, callback);
	collisionShape.scale = Vector2.ONE * radius;
	endTime = Time.get_ticks_msec() + (duration * 1000)
	print("shape:", collisionShape, " shape scale:", collisionShape.scale, " radius:", radius, "cell size:", GridHelper.CELL_SIZE)
	self.drawColor = drawColor
	self.radius = radius
	self.duration = duration

func _process(delta: float) -> void:
	if endTime < Time.get_ticks_msec():
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
