class_name TowerSkillIcon
extends TextureRect

# Skill-icon hover for the tower stats panel: Dota2-style rich tooltip built
# from Skill display metadata at the tower's current level - name, kind line,
# affects/tags lines, then the desc with per-level scaling values highlighted.
# Palette + layout mirror the synergy hover (ui_synergy_content.gd).

const SCALING_COLOR := "#5AC8FA"   # per-level scaling value (synergy hover palette)
const DIM_COLOR := "#7A7A7A"       # metadata lines (affects / tags)
const KIND_COLOR := "#FFD15A"      # kind line (single gold)

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
	# Opaque dark card (stats-panel palette): the default tooltip theme let the
	# panel text underneath bleed through and the two texts collided.
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
	rich.custom_minimum_size = Vector2(340, 0)
	rich.text = _build_hover_bbcode()
	panel.add_child(rich)
	return panel

func _build_hover_bbcode() -> String:
	if skill == null:
		return ""
	var lines: PackedStringArray = []
	lines.append("[b]" + skill.get_display_name(level) + "[/b]")

	if kind_label != "":
		lines.append("[color=" + KIND_COLOR + "]" + kind_label.to_upper() + "[/color]")

	var affects := _affects_line()
	if affects != "":
		lines.append("[color=" + DIM_COLOR + "]" + affects + "[/color]")

	# Bare tag list, no "TAGS:" prefix (long lists eat the line - Director).
	if not skill.tags.is_empty():
		var tag_names: PackedStringArray = []
		for tag in skill.tags:
			tag_names.append(str(tag).capitalize().to_upper())
		lines.append("[color=" + DIM_COLOR + "]" + ", ".join(tag_names) + "[/color]")

	var desc := skill.get_display_desc(level, SCALING_COLOR)
	if desc != "":
		lines.append("")
		lines.append(desc)
	return "\n".join(lines)

# "AFFECTS: ENEMY - AREA" from the skill's target_summary (team + shape).
func _affects_line() -> String:
	if skill.target_summary.is_empty():
		return ""
	var parts: PackedStringArray = []
	var team := str(skill.target_summary.get("target_team", ""))
	var shape := str(skill.target_summary.get("target_shape", ""))
	if team != "":
		parts.append(team.to_upper())
	if shape != "":
		parts.append(shape.to_upper())
	if parts.is_empty():
		return ""
	return "AFFECTS: " + " - ".join(parts)
