class_name TowerSkillIcon
extends TextureRect

# Skill-icon hover for the tower stats panel: Dota2-style rich tooltip built
# from Skill display metadata at the tower's current level - name, kind line,
# affects/tags lines, then the desc with per-level scaling values highlighted.
# Palette + layout mirror the synergy hover (ui_synergy_content.gd).

const SCALING_COLOR := "#5AC8FA"   # per-level scaling value (synergy hover palette)
const FIXED_COLOR := "#9EB7C6"     # fixed (single-value) number - softer sibling of SCALING_COLOR
const DIM_COLOR := "#7A7A7A"       # metadata lines (affects / tags)
const KIND_COLOR := "#FFD15A"      # kind line (single gold)
const NOTE_FONT_SIZE := 13         # hover-card "Note:" line size (body default ~16)

var skill: Skill = null
var kind_label: String = ""
var level: int = 1
# Live effect container of the inspected tower - lets stack-bonus desc tokens
# show the computed current value. Null on template surfaces (select cards).
var effects: EffectContainer = null
# Label of the currently open hover card; effect-change signals rewrite it so
# stack-bonus values tick live while the tooltip is held (Director 2026-08-02).
var _tooltip_rich: RichTextLabel = null

# "\nNote:" desc tail -> blank-line separated + dimmed (+ optionally smaller).
# Styling lives renderer-side so YAML keeps plain "\nNote:" (game_copy.md rule).
# Pass note_font_size 0 on surfaces whose font-fit steps THEME sizes (an
# absolute BBCode font_size tag would not shrink with them - tower-select card).
static func style_note_desc(text: String, note_font_size: int = 0) -> String:
	var idx := text.find("\nNote:")
	if idx == -1:
		return text
	var styled := "[color=" + DIM_COLOR + "]" + text.substr(idx + 1) + "[/color]"
	if note_font_size > 0:
		styled = "[font_size=" + str(note_font_size) + "]" + styled + "[/font_size]"
	return text.substr(0, idx) + "\n\n" + styled

# Shared icon fallback: authored icon path, else the synergy default placeholder
# (no tower skill icon art exists yet). Used by the tower-select card too.
static func resolve_icon_texture(p_skill: Skill) -> Texture2D:
	var icon_texture: Texture2D = null
	if p_skill.icon != "":
		icon_texture = ResourceManager.loadImage("skill_icon", p_skill.icon, p_skill.icon)
	if icon_texture == null:
		icon_texture = ResourceManager.getSprite("synergy", "default")
	return icon_texture

func setup(p_skill: Skill, p_kind: String, p_level: int, p_effects: EffectContainer = null) -> void:
	skill = p_skill
	kind_label = p_kind
	level = p_level
	effects = p_effects
	# Freed icons auto-disconnect, and the handler no-ops with no open tooltip.
	if effects != null:
		Utility.ConnectSignal(effects, "effect_added", _on_effects_changed)
		Utility.ConnectSignal(effects, "effect_updated", _on_effects_changed)
		Utility.ConnectSignal(effects, "effect_removed", _on_effects_changed)
	# tooltip_text must carry REAL text: the viewport strips whitespace and
	# shows nothing for a blank tooltip, custom tooltip included.
	tooltip_text = p_skill.get_display_name(p_level) if p_skill != null else ""
	mouse_filter = Control.MOUSE_FILTER_STOP

func _make_custom_tooltip(_for_text: String) -> Object:
	# Shared opaque card; 340 (not the 320 default) is the tested fit for the
	# longer skill descs.
	var card := UISynergyContent.make_tooltip_card(_build_hover_bbcode(), 340.0, self)
	_tooltip_rich = card.get_child(0) as RichTextLabel
	return card

func _on_effects_changed(_inst) -> void:
	if _tooltip_rich != null and is_instance_valid(_tooltip_rich):
		_tooltip_rich.text = _build_hover_bbcode()
	else:
		_tooltip_rich = null

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

	var desc := style_note_desc(skill.get_display_desc(level, SCALING_COLOR, FIXED_COLOR, effects), NOTE_FONT_SIZE)
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
