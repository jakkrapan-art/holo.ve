class_name StaffSkillTooltip
extends TextureButton

# Placeholder skill-info hover for the Staff skill button (StaffWidget).
# Shows skill name + description as a rich tooltip, mirroring the synergy hover
# pattern (ui_synergy_content.gd _make_custom_tooltip). Guideline only — the final
# skill UI surface is tracked in coding log "Tower UI surface" / staff hover task.
#
# StaffWidget.setup() assigns `skill` and a non-empty tooltip_text so the custom
# tooltip triggers (tooltip delay is lowered globally in project.godot).

var skill: Skill = null

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
	lines.append("[b]" + skill.get_display_name(1) + "[/b]")
	var desc := skill.get_display_desc(1)
	if desc != "":
		lines.append(desc)
	return "\n".join(lines)
