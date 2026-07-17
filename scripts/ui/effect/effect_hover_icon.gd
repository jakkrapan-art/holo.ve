class_name EffectHoverIcon
extends TextureRect

# One buff/debuff icon, built by EffectIconRow for both surfaces: overhead
# rows (display-only, hover disabled) and the stats-panel strip, where hover
# opens the shared opaque tooltip card (same pattern as TowerSkillIcon).
# The card is built lazily at hover-open, so it reads the live instance
# (stacks mutate in place); an already-open card does not refresh - re-hover.

const CATEGORY_LINES := {
	EffectTypes.Category.BUFF: "[color=#45C759]BUFF[/color]",
	EffectTypes.Category.DEBUFF: "[color=#DB4545]DEBUFF[/color]",
	EffectTypes.Category.MARK: "[color=#AB59DB]MARK[/color]",
}

var inst: EffectInstance = null

func _make_custom_tooltip(_for_text: String) -> Object:
	return UISynergyContent.make_tooltip_card(_build_hover_bbcode(), 320.0, self)

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
		lines.append("")
		lines.append(desc)
	return "\n".join(lines)
