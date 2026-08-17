class_name CircleEffectArea
# extends Area2D
extends EffectArea

@export var radius: float = 2.0  # Default radius of the circle
@export var duration: float = 5.0  # Default duration of the effect
@export var drawColor: Color = Color(0, 0, 1, 0.2);

const DEV_AREA_META: StringName = &"_dev_show_skill_areas"

var elapsedTime: float = 0.0;
var _radius_pixels: float = 0.0
var _dev_visible: bool = false

func _ready() -> void:
	_dev_visible = bool(get_tree().get_meta(DEV_AREA_META, false))
	queue_redraw()

func setup(p_radius: float = 2.0, p_duration: float = 5.0, callback: EffectAreaCallback = null, p_drawColor: Color = Color(0, 0, 1, 0.2)):
	_radius_pixels = maxf(p_radius, 0.0) * GridHelper.CELL_SIZE
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = _radius_pixels
	_base_setup(circle_shape, callback);
	collisionShape.scale = Vector2.ONE;
	elapsedTime = 0.0
	self.drawColor = p_drawColor
	self.radius = p_radius
	self.duration = p_duration

func _process(delta: float) -> void:
	var dev_visible := bool(get_tree().get_meta(DEV_AREA_META, false))
	if dev_visible != _dev_visible:
		_dev_visible = dev_visible
		queue_redraw()
	elapsedTime += delta
	if elapsedTime >= duration:
		queue_free();

	super._process(delta);

func _draw():
	if _radius_pixels <= 0.0:
		return
	if _dev_visible:
		draw_circle(Vector2.ZERO, _radius_pixels, Hitbox.DEV_FILL)
		draw_arc(
			Vector2.ZERO,
			_radius_pixels,
			0.0,
			TAU,
			64,
			Hitbox.DEV_BORDER,
			Hitbox.DEV_BORDER_WIDTH,
			true
		)
	else:
		draw_circle(Vector2.ZERO, _radius_pixels, drawColor)
