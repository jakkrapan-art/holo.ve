class_name SynergyChipIcon
extends TextureRect

# Synergy-trait hover for tower-select cards: same text and opaque card as the
# synergy panel hover via the shared helpers (ui_synergy_content.gd), rendered
# definitionally (tier -1: no active-tier highlight or mission progress - live
# state stays on the panel).

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
	var data = ResourceManager.getSynergyData(synergy_id)
	return UISynergyContent.make_tooltip_card(
		UISynergyContent.build_hover_bbcode(data, display_name, -1, -1), 320.0, self)
