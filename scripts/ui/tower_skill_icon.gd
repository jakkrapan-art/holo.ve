class_name TowerSkillIcon
extends TextureRect

# Skill-icon hover for the tower stats panel: rich tooltip built from Skill
# display metadata (get_display_name / get_display_desc) at the tower's current
# level - the template desc path, never raw legacy desc. Mirrors the
# StaffSkillTooltip pattern (staff_skill_tooltip.gd).

var skill: Skill = null
var kind_label: String = ""
var level: int = 1

func setup(p_skill: Skill, p_kind: String, p_level: int) -> void:
	skill = p_skill
	kind_label = p_kind
	level = p_level
	# tooltip_text must carry REAL text: the viewport strips whitespace and
	# shows nothing for a blank tooltip, custom tooltip included.
	tooltip_text = p_skill.get_display_name(p_level) if p_skill != null else ""
	mouse_filter = Control.MOUSE_FILTER_STOP

func _make_custom_tooltip(_for_text: String) -> Object:
	var panel := PanelContainer.new()
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.custom_minimum_size = Vector2(320, 0)
	rich.text = _build_hover_bbcode()
	panel.add_child(rich)
	return panel

func _build_hover_bbcode() -> String:
	if skill == null:
		return ""
	var lines: PackedStringArray = []
	var title := "[b]" + skill.get_display_name(level) + "[/b]"
	if kind_label != "":
		title += " (" + kind_label + ")"
	lines.append(title)
	var desc := skill.get_display_desc(level)
	if desc != "":
		lines.append("")
		lines.append(desc)
	return "\n".join(lines)
