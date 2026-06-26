class_name StaffWidget
extends Control

# Bottom-right HUD widget for the Staff: portrait + HP gauge + skill button.
# Layered TextureRects (bg → portrait → border → hp_gauge + hp_text) + skill (border + icon button).
# Dynamic textures (portrait, skill_icon) are populated from StaffData at setup() — static ones (bg,
# border, hp_border, hp_gauge, skill_border) sit in the scene as-is.

signal skill_pressed  # forwarded by GameScene → Staff.requestCastSkill (Phase 2 enters casting state)

@onready var _portrait: TextureRect = $PortraitBG/Portrait
@onready var _hp_gauge: TextureProgressBar = $HpGauge
@onready var _hp_label: Label = $HpLabel
@onready var _skill_mask: TextureRect = $SkillMask
@onready var _skill_icon: StaffSkillTooltip = $SkillMask/SkillButton
@onready var _skill_border: TextureRect = $SkillBorder

# Hover effect — subtle scale tween on the skill area when mouse enters / leaves the button.
# Reusable pattern for future skill widgets across the project (see ui.md §8 Artist-friendly principles).
const HOVER_SCALE := Vector2(1.05, 1.05)
const HOVER_TWEEN_DURATION := 0.12
var _hover_tween: Tween = null

# Used / disabled state — alpha 0.4 + button disabled when skill has 0 uses remaining.
const USED_ALPHA := 0.4

var _staff: Staff = null

func setup(staff: Staff) -> void:
	if staff == null:
		push_error("StaffWidget.setup: staff is null")
		return
	_staff = staff
	_apply_staff_textures(staff.data)
	_apply_skill_hover(staff.data)
	_apply_hp(staff.getCurrentHp(), staff.getMaxHp())
	if not staff.is_connected("hp_changed", Callable(self, "_on_hp_changed")):
		staff.hp_changed.connect(_on_hp_changed)
	if not staff.is_connected("skill_used", Callable(self, "_on_skill_used")):
		staff.skill_used.connect(_on_skill_used)
	# Hover effect — connect once at setup. mouse_filter ignored for skill mask/border (visual only);
	# the underlying SkillButton handles input so we route hover events from THE BUTTON.
	if _skill_icon != null:
		if not _skill_icon.mouse_entered.is_connected(_on_skill_hover_entered):
			_skill_icon.mouse_entered.connect(_on_skill_hover_entered)
		if not _skill_icon.mouse_exited.is_connected(_on_skill_hover_exited):
			_skill_icon.mouse_exited.connect(_on_skill_hover_exited)

func _apply_staff_textures(data: StaffData) -> void:
	if data == null:
		return
	# Per-staff portrait + skill icon are loaded from string paths in YAML.
	if data.hud_portrait != "":
		_portrait.texture = load("res://resources/" + data.hud_portrait)
	if data.hud_skill_icon != "":
		_skill_icon.texture_normal = load("res://resources/" + data.hud_skill_icon)

func _apply_skill_hover(data: StaffData) -> void:
	# Placeholder skill-info hover (name + desc) on the skill button. The rich tooltip
	# is built by StaffSkillTooltip._make_custom_tooltip; tooltip_text just needs to be
	# non-empty so the tooltip triggers (delay lowered globally in project.godot).
	if _skill_icon == null or data == null or data.skill == null:
		return
	_skill_icon.skill = data.skill
	_skill_icon.max_charges = data.skill_max_charges
	_skill_icon.tooltip_text = data.skill.get_display_name(1)

func _apply_hp(current: int, max_hp: int) -> void:
	_hp_gauge.max_value = float(max_hp)
	_hp_gauge.value = float(current)
	_hp_label.text = "%d/%d" % [current, max_hp]

func _on_hp_changed(current: int, max_hp: int) -> void:
	_apply_hp(current, max_hp)

func _on_skill_button_pressed() -> void:
	skill_pressed.emit()

# True when the cursor is over the skill button — GameScene uses this so a click on the
# button during skill targeting cancels (via the button) instead of committing a cast.
func is_skill_button_hovered() -> bool:
	return _skill_icon != null and _skill_icon.is_hovered()

func _on_skill_used() -> void:
	# A charge was consumed. Grey out only when all charges depleted (charges == 0).
	# -1 = unlimited (never greys); > 0 = still has charges; 0 = depleted.
	# TODO (VFX pass): replace instant grey with cooldown sweep / charge-counter HUD.
	if _staff == null:
		return
	if _staff.skill_charges_remaining == 0:
		if _skill_icon != null:
			_skill_icon.disabled = true
			_skill_icon.modulate.a = USED_ALPHA
		if _skill_border != null:
			_skill_border.modulate.a = USED_ALPHA
		if _skill_mask != null:
			_skill_mask.modulate.a = USED_ALPHA

func _on_skill_hover_entered() -> void:
	_tween_skill_scale(HOVER_SCALE)

func _on_skill_hover_exited() -> void:
	_tween_skill_scale(Vector2.ONE)

func _tween_skill_scale(target: Vector2) -> void:
	# Tween scale on the parent SkillMask so both icon + border move together.
	# Control.pivot_offset = size/2 → scale happens around CENTER (default is top-left
	# which makes the widget jump down-right on hover). Refresh pivot each call in
	# case size changed since last hover (Game Director may tune via editor).
	if _skill_mask == null:
		return
	_skill_mask.pivot_offset = _skill_mask.size * 0.5
	if _skill_border != null:
		_skill_border.pivot_offset = _skill_border.size * 0.5
	if _hover_tween != null and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(_skill_mask, "scale", target, HOVER_TWEEN_DURATION)
	if _skill_border != null:
		_hover_tween.parallel().tween_property(_skill_border, "scale", target, HOVER_TWEEN_DURATION)
