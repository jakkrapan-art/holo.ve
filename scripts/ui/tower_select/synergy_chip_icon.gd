class_name SynergyChipIcon
extends TextureRect

# Synergy-trait hover for tower-select cards: same text as the synergy panel
# hover via the shared builder (ui_synergy_content.gd), rendered definitionally
# (tier -1: no active-tier highlight or quest progress - live state stays on
# the panel). Opaque card style mirrors tower_skill_icon.gd (ui.md lesson).

var synergy_id: int = 0
var display_name: String = ""

func set_synergy(p_id: int, p_display_name: String) -> void:
	synergy_id = p_id
	display_name = p_display_name
	# tooltip_text must carry REAL text: the viewport strips whitespace and
	# shows nothing for a blank tooltip, custom tooltip included.
	tooltip_text = p_display_name
	# PASS (not the TextureRect default STOP): hover tooltip still fires while
	# clicks fall through to the card Button (effect_icon_row.gd pattern).
	mouse_filter = Control.MOUSE_FILTER_PASS

func _make_custom_tooltip(_for_text: String) -> Object:
	var panel := PanelContainer.new()
	# Opaque dark card: the default tooltip theme lets text underneath bleed
	# through (same fix as tower_skill_icon.gd).
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.05, 0.12, 0.97)
	style.border_color = Color(0.85, 0.7, 0.45, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.custom_minimum_size = Vector2(320, 0)
	var data = ResourceManager.getSynergyData(synergy_id)
	rich.text = UISynergyContent.build_hover_bbcode(data, display_name, -1, -1)
	panel.add_child(rich)
	return panel
