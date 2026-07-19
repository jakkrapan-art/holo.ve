extends PanelContainer
class_name UISynergyContent

# Placeholder template colours (artist refines later). Stepped per tier so the
# player reads tier order at a glance; the scaling value gets its own accent.
const INACTIVE_COLOR := "#4D4D4D"
const TIER_COLORS := ["#CD7F32", "#C0C0C0", "#FFD15A"]   # bronze / silver / gold = tier 1 / 2 / 3
# Unique synergies skip the tier ladder entirely - one holder in the whole game
# means they are maxed the moment they activate, so a rank colour says nothing.
# Vivid red-orange, deliberately far from the muted bronze above.
const UNIQUE_COLOR := "#FF5A36"
const SCALING_COLOR := "#5AC8FA"                          # the per-tier value that scales
const DIM_COLOR := "#7A7A7A"                              # not-yet-reached tier rows in the hover
const ACTIVE_HIGHLIGHT := "#FFD15A"                       # reward-running tier rows in the hover (gold)
const QUEST_PENDING_HIGHLIGHT := "#8C7431"                # ACTIVE_HIGHLIGHT darkened ~45%: mission open, reward not yet earned

@onready var bg = $"."
@onready var synergyName = $HBoxContainer/VBoxContainer/SynergyName
@onready var synergyValue = $HBoxContainer/VBoxContainer/SynergyValue
@onready var synergyIcon = $HBoxContainer/SynergyIcon

var _name: String = ""
var _data: SynergyData = null
var _tier: int = -1
var _count: int = 0                   # live unit count (sort key; drops when units removed)
var _quest_progress: int = -1         # quest cumulative progress (-1 = not a quest / unset)
var _order: int = -1                  # creation order, frozen by UISynergy (stable-sort tie-break)
var _stylebox: StyleBoxFlat = null   # this row's own panel StyleBox (see setup)
var _tooltip_label: RichTextLabel = null  # open hover's rich label, for live quest-progress refresh

# tier: current active tier (-1 = not yet proc'd). data: SynergyData or null.
func setup(p_name: String, current: int, tier: int, icon: Texture2D, data) -> void:
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

	if synergyIcon != null:
		synergyIcon.texture = icon

	# Rich tooltip is built in _make_custom_tooltip; tooltip_text just needs to be
	# non-empty so the tooltip triggers (delay lowered globally in project.godot).
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = name

# Sort keys read by UISynergy._reflow - kept on the row so its sort state has a
# single source of truth (mirrors how _tier is already threaded via setup).
func getTier() -> int: return _tier
func getTierRank() -> float: return _rank_for(_tier)
func isUnique() -> bool: return _data != null and _data.is_unique()
func getCount() -> int: return _count
func getOrder() -> int: return _order
func setOrder(value: int) -> void: _order = value

# A quest synergy's cumulative progress; shown at the bottom of this row's hover.
# Refreshes the open tooltip live (TFT-style); Godot builds it once per hover, so
# without this the number would freeze until the player re-hovers.
func setQuestProgress(current: int) -> void:
	_quest_progress = current
	if _tooltip_label != null and is_instance_valid(_tooltip_label):
		_tooltip_label.text = _build_hover_bbcode()

# Colour by tier RANK, not absolute index: a synergy's highest tier always reads
# gold, whatever its tier count. Hero defines a single tier, so an absolute index
# left it permanently bronze - the lowest rank while fully maxed.
# 3 tiers -> bronze/silver/gold (unchanged); 2 -> bronze/gold; 1 -> gold.
# The colour is only a 3-step quantization of the rank UISynergy sorts on, so
# order and colour cannot contradict each other. Do not re-derive it here.
func _tier_color(tier: int) -> String:
	var rank := _rank_for(tier)
	if rank < 0.0:
		return INACTIVE_COLOR
	if isUnique():
		return UNIQUE_COLOR
	var last := TIER_COLORS.size() - 1
	return TIER_COLORS[clampi(int(round(rank * float(last))), 0, last)]

# SynergyData.tier_rank for this row, tolerating a row whose data failed to
# resolve: treat it as maxed, which is what the colour already did before rank
# became shared - so a broken row still colours and sorts one consistent way.
func _rank_for(tier: int) -> float:
	if tier < 0:
		return -1.0
	if _data == null:
		return 1.0
	return _data.tier_rank(tier)

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
	var panel := make_tooltip_card(_build_hover_bbcode(), 320.0, self)
	# Keep a ref so live kills can refresh the open tooltip (see setQuestProgress).
	_tooltip_label = panel.get_child(0) as RichTextLabel
	return panel

# Shared Theme that blanks the engine's native TooltipPanel stylebox; assigned
# to tooltip owners in make_tooltip_card (see the p_owner param there).
static var _tooltip_owner_theme: Theme = null

# Opaque tooltip card shared by every rich hover: the panel rows, the card
# chips (synergy_chip_icon.gd), the stats-panel skill hover
# (tower_skill_icon.gd), and the staff hover (staff_skill_tooltip.gd), so
# every rich tooltip reads as one family.
# Child 0 is the RichTextLabel (callers may keep it for live refresh).
# p_owner != null: strip the engine's native tooltip panel on that owner so only
# our card renders (kills the ghost rect behind custom tooltips). Godot wraps
# a custom tooltip in a popup styled by the TooltipPanel theme item and adds
# it as a child of the owner, so an owner Theme reaches it (a per-control
# stylebox override would not propagate to the child Window).
static func make_tooltip_card(bbcode: String, width: float = 320.0, p_owner: Control = null) -> PanelContainer:
	if p_owner != null:
		if _tooltip_owner_theme == null:
			_tooltip_owner_theme = Theme.new()
			_tooltip_owner_theme.set_stylebox("panel", "TooltipPanel", StyleBoxEmpty.new())
		p_owner.theme = _tooltip_owner_theme
	var panel := PanelContainer.new()
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
	rich.custom_minimum_size = Vector2(width, 0)
	rich.text = bbcode
	panel.add_child(rich)
	return panel

func _build_hover_bbcode() -> String:
	return build_hover_bbcode(_data, _name, _tier, _quest_progress)

# Shared with the tower-select card chips (synergy_chip_icon.gd) so both hovers
# render identical text from one builder; hover colors stay single-source here.
# tier -1 = definitional view (no active row); quest_progress -1 = no progress line.
static func build_hover_bbcode(data: SynergyData, fallback_name: String, tier: int, quest_progress: int) -> String:
	if data == null:
		return fallback_name

	var lines: PackedStringArray = []
	lines.append("[b]" + data.display_name + "[/b]")
	# Category subtitle under the name, dimmed so it never competes with the name
	# or the desc, then a blank line to set the desc apart as its own block.
	lines.append("[i][color=" + DIM_COLOR + "]" + data.type_label() + "[/color][/i]")
	lines.append("")

	# Flavour preview the lowest tier's value when not yet proc'd (maxi(tier,0)).
	var flavor := data.flavor(maxi(tier, 0), SCALING_COLOR)
	if flavor != "":
		lines.append(flavor)

	# Per-tier table (only when the synergy defines effect lines).
	if not data.tier_effects.is_empty():
		lines.append("")
		for i in data.tier_count():
			var row := "(" + str(data.threshold_at(i)) + ")  " + data.tier_effect(i)
			match _tier_row_state(data, i, tier, quest_progress):
				TierRowState.EARNED:
					# Reward running (normal lane: the single active tier; quest
					# lane: every earned mission, so 2+ gold arrow rows can show).
					row = "[color=" + ACTIVE_HIGHLIGHT + "]> " + row + "[/color]"
				TierRowState.PENDING:
					row = "[color=" + QUEST_PENDING_HIGHLIGHT + "]" + row + "[/color]"   # mission open, unfinished
				TierRowState.LOCKED:
					row = "[color=" + DIM_COLOR + "]" + row + "[/color]"
			lines.append(row)

	if quest_progress >= 0:
		lines.append("")
		lines.append("[b]Current Progress: " + str(quest_progress) + "[/b]")
	return "\n".join(lines)

enum TierRowState { LOCKED, PENDING, EARNED }

# Truthful per-tier row state for the hover table.
# Standard synergies keep today's single-active-row read (highest tier REPLACES).
# Mission synergies stack: unit gate uses the row's tier,
# kill gate uses quest_progress vs mission_kills[i] - mirroring
# SynergyEffectQuestTempus._check_rewards (same get_parameter clamp, so display
# and effect cannot diverge). Assumes tier is monotonic within a run - holds
# permanently: no tower-removal path exists by Director decision
# (tower_synergy.md Notes). If a tower-destroying mechanic ever ships, the
# effect's _rewarded[] is sticky while this recomputes live - re-derive then.
static func _tier_row_state(data: SynergyData, i: int, tier: int, quest_progress: int) -> TierRowState:
	if i > tier:
		return TierRowState.LOCKED
	if data.type != SynergyData.TYPE_MISSION:
		return TierRowState.EARNED if i == tier else TierRowState.LOCKED
	var goal = data.get_parameter("mission_kills", i)
	if goal != null and quest_progress >= int(goal):
		return TierRowState.EARNED
	return TierRowState.PENDING   # incl. null goal: reward can never fire, matches effect
