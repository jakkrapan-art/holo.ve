extends Button

const DEFAULT_SPEED := 1.0
const FAST_SPEED := 2.0

var _enabled := false
var _active_style: StyleBoxFlat
var _inactive_style: StyleBoxFlat

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_on_pressed)
	_active_style = _make_style(Color(0.12, 0.12, 0.12, 0.7), Color(1.0, 0.84, 0.2, 1.0), 3)
	_inactive_style = _make_style(Color(0.12, 0.12, 0.12, 0.45), Color(0.0, 0.0, 0.0, 0.0), 0)
	_set_speed(false)

func _exit_tree():
	Engine.time_scale = DEFAULT_SPEED

func _on_pressed():
	_set_speed(!_enabled)
	release_focus()

func _set_speed(enabled: bool):
	_enabled = enabled
	Engine.time_scale = FAST_SPEED if _enabled else DEFAULT_SPEED
	_update_active_style()

func _update_active_style():
	var style := _active_style if _enabled else _inactive_style
	for style_name in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		add_theme_stylebox_override(style_name, style)

func _make_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style
