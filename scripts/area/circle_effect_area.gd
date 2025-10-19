class_name CircleEffectArea
# extends Area2D
extends EffectArea

@export var radius: float = 2.0  # Default radius of the circle

func _ready():
	# Ensure the area is set up with the default radius
	setup(radius)

func setup(radius: float = 2.0, callback: EffectAreaCallback = null):
	# Set the shape of the area to a circle
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	#(transform.children[0] as CollisionShape2D).shape = circle_shape
	# _base_setup(callback)

func _draw():
	var circleColor = Color.BLUE
	circleColor.a = 0.15

	var draw_radius = radius * GridHelper.CELL_SIZE
	draw_circle(position, draw_radius, circleColor)
