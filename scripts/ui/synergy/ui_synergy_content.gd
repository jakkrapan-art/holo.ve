extends PanelContainer
class_name UISynergyContent

# Placeholder template colours (artist refines later). Stepped per tier so the
# player reads tier order at a glance; the scaling value gets its own accent.
const INACTIVE_COLOR := "#4D4D4D"
const TIER_COLORS := ["#CD7F32", "#C0C0C0", "#FFD15A"]   # bronze / silver / gold = tier 1 / 2 / 3
const SCALING_COLOR := "#5AC8FA"                          # the per-tier value that scales
const DIM_COLOR := "#7A7A7A"                              # not-yet-reached tier rows in the hover
const ACTIVE_HIGHLIGHT := "#FFD15A"                       # active tier row in the hover (single gold)

@onready var bg = $"."
@onready var synergyName = $HBoxContainer/VBoxContainer/SynergyName
@onready var synergyValue = $HBoxContainer/VBoxContainer/SynergyValue

var _name: String = ""
var _data: SynergyData = null
var _tier: int = -1
var _count: int = 0                   # live unit count (sort key; drops when units removed)
var _quest_progress: int = -1         # quest cumulative progress (-1 = not a quest / unset)
var _order: int = -1                  # creation order, frozen by UISynergy (stable-sort tie-break)
var _stylebox: StyleBoxFlat = null   # this row's own panel StyleBox (see setup)

# tier: current active tier (-1 = not yet proc'd). data: SynergyData or null.
func setup(p_name: String, current: int, tier: int, data) -> void:
	_name = p_name
	_data = data
	_tier = tier
	_count = current

	if bg != null:
		# The scene's panel StyleBox is one shared sub-resource across every row
		# instance (even with the .tscn's own theme override). Duplicate it once per
		# instance so colouring one synergy row never recolours the others.
		if _stylebox == null:
			var base = bg.get_theme_stylebox("panel")
			if base is StyleBoxFlat:
				_stylebox = (base as StyleBoxFlat).duplicate()
				bg.add_theme_stylebox_override("panel", _stylebox)
		if _stylebox != null:
			_stylebox.bg_color = Color(_tier_color(tier))

	if synergyName != null:
		synergyName.text = p_name

	if synergyValue != null:
		# current count - proc breakpoints, active one bracketed (e.g. "4 - 3 [4] 5").
		synergyValue.text = "%d - %s" % [current, _breakpoints_text(tier)]

	# Rich tooltip is built in _make_custom_tooltip; tooltip_text just needs to be
	# non-empty so the tooltip triggers (delay lowered globally in project.godot).
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = name

# Sort keys read by UISynergy._reflow - kept on the row so its sort state has a
# single source of truth (mirrors how _tier is already threaded via setup).
func getTier() -> int: return _tier
func getCount() -> int: return _count
func getOrder() -> int: return _order
func setOrder(value: int) -> void: _order = value

# A quest synergy's cumulative progress; shown at the bottom of this row's hover.
func setQuestProgress(current: int) -> void: _quest_progress = current

func _tier_color(tier: int) -> String:
	if tier < 0:
		return INACTIVE_COLOR
	return TIER_COLORS[clampi(tier, 0, TIER_COLORS.size() - 1)]

# "3 4 5" with the active tier's threshold bracketed.
func _breakpoints_text(tier: int) -> String:
	if _data == null or _data.thresholds.is_empty():
		return ""
	var parts: PackedStringArray = []
	for i in _data.thresholds.size():
		var t := str(int(_data.thresholds[i]))
		parts.append("[" + t + "]" if i == tier else t)
	return " ".join(parts)

# Rich hover: flavour (scaling value highlighted) + a per-tier table with the
# active tier marked + tier-coloured and the rest dimmed.
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
	if _data == null:
		return _name

	var lines: PackedStringArray = []
	lines.append("[b]" + _data.display_name + "[/b]")

	# Flavour preview the lowest tier's value when not yet proc'd (maxi(tier,0)).
	var flavor := _data.flavor(maxi(_tier, 0), SCALING_COLOR)
	if flavor != "":
		lines.append(flavor)

	# Per-tier table (only when the synergy defines effect lines).
	if not _data.tier_effects.is_empty():
		lines.append("")
		for i in _data.tier_count():
			var row := "(" + str(_data.threshold_at(i)) + ")  " + _data.tier_effect(i)
			if i == _tier:
				row = "[color=" + ACTIVE_HIGHLIGHT + "]> " + row + "[/color]"   # active tier (single gold)
			else:
				row = "[color=" + DIM_COLOR + "]" + row + "[/color]"
			lines.append(row)

	if _quest_progress >= 0:
		lines.append("")
		lines.append("[b]Current Progress: " + str(_quest_progress) + "[/b]")
	return "\n".join(lines)
