class_name EffectHoverIcon
extends TextureRect

# One buff/debuff icon, built by EffectIconRow for both surfaces: overhead
# rows (display-only, hover disabled) and the stats-panel strip, where hover
# opens the shared opaque tooltip card (same pattern as TowerSkillIcon).

const CATEGORY_LINES := {
	EffectTypes.Category.BUFF: "[color=#45C759]BUFF[/color]",
	EffectTypes.Category.DEBUFF: "[color=#DB4545]DEBUFF[/color]",
	EffectTypes.Category.MARK: "[color=#AB59DB]MARK[/color]",
}

var inst: EffectInstance = null
# Ref into the open card so stack/value ticks refresh it live (same pattern
# as the synergy hover - ui_synergy_content.gd). Invalid once the card closes.
var _tooltip_label: RichTextLabel = null

func _make_custom_tooltip(_for_text: String) -> Object:
	var panel := UISynergyContent.make_tooltip_card(_build_hover_bbcode(), 320.0, self)
	_tooltip_label = panel.get_child(0) as RichTextLabel
	return panel

# Called by the row on effect_updated while this icon exists.
func refresh_tooltip() -> void:
	if _tooltip_label != null and is_instance_valid(_tooltip_label):
		_tooltip_label.text = _build_hover_bbcode()

func _build_hover_bbcode() -> String:
	if inst == null:
		return ""
	var lines: PackedStringArray = []
	lines.append("[b]" + inst.display_title() + "[/b]")
	var category_line: String = CATEGORY_LINES.get(inst.def.category, "")
	if category_line != "":
		lines.append(category_line)
	var desc := inst.display_desc()
	if desc != "":
		lines.append(desc)
	return "\n".join(lines)
