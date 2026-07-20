class_name EnemyStatsPanel
extends Control

# Placeholder enemy stats panel (bottom-left HUD; artist design pass pending).
# Sibling of TowerStatsPanel - both share the bottom-left slot, one selection
# at a time (Director 2026-07-17). Skeleton cloned from tower_stats_panel.gd,
# the shared layout convention.

@onready var _portrait: TextureRect = $Portrait
@onready var _name_label: Label = $NameLabel
@onready var _tier_label: Label = $TierLabel
@onready var _ms_value: Label = $StatsGrid/MsValue
@onready var _armor_value: Label = $StatsGrid/ArmorValue
@onready var _mr_value: Label = $StatsGrid/MrValue
@onready var _hp_bar: ProgressBar = $HpRow/HpBar
@onready var _hp_text: Label = $HpRow/HpBar/HpText
# Right-edge column: hover popups open toward the open playfield.
@onready var _skill_column: VBoxContainer = $SkillColumn
# Buff/debuff strip floating above the panel's top border (rich hover).
@onready var _effect_row: EffectIconRow = $EffectRow

const TIER_NAMES := {
	Enemy.EnemyType.Normal: "Normal",
	Enemy.EnemyType.Elite: "Elite",
	Enemy.EnemyType.Boss: "Boss",
}

const OUTLINE_SHADER := preload("res://resources/ui_component/inspect_outline.gdshader")

var _enemy: Enemy = null
# Inspect-highlight outline on the selected enemy's sprite. Enemies are
# single full textures, so no frame-region feed is needed (unlike the tower
# panel): the shader reads texture dimensions itself and region stays the
# default whole-texture rect.
var _outline_mat: ShaderMaterial
var _hl_sprite: Sprite2D = null

func _ready():
	visible = false
	_outline_mat = ShaderMaterial.new()
	_outline_mat.shader = OUTLINE_SHADER

func show_enemy(enemy: Enemy) -> void:
	_enemy = enemy
	visible = true
	_effect_row.setup(enemy.effects)
	# Enemy skills never change on a live enemy - build the column once per
	# selection (unlike the tower panel's level/evolve rebuild key).
	_rebuild_skill_column(enemy)
	_apply_highlight(enemy.sprite)
	_refresh()

func clear() -> void:
	_enemy = null
	visible = false
	_effect_row.setup(null)
	_remove_highlight()

func _apply_highlight(spr: Sprite2D) -> void:
	_remove_highlight()
	if spr == null:
		return
	_hl_sprite = spr
	# Quad center in local vertex space = the sprite's offset (flip-proof grow
	# direction; see the shader header).
	_outline_mat.set_shader_parameter("quad_center_px", spr.offset)
	spr.material = _outline_mat

func _remove_highlight() -> void:
	if _hl_sprite != null and is_instance_valid(_hl_sprite):
		_hl_sprite.material = null
	_hl_sprite = null

func _process(_delta):
	if not visible:
		return
	# Enemies die/leak constantly - deselect the moment the instance frees.
	if _enemy == null or not is_instance_valid(_enemy):
		clear()
		return
	_refresh()

func _refresh() -> void:
	var stats: EnemyStat = _enemy.stats
	if stats == null:
		clear()
		return

	_set_text(_name_label, _enemy.display_name)
	_set_text(_tier_label, TIER_NAMES.get(_enemy.enemyType, "Normal"))
	# No enemy portrait art exists - the walk sprite stands in (Director OK).
	if _portrait.texture != _enemy.sprite.texture:
		_portrait.texture = _enemy.sprite.texture

	# Live getters, so buffs/debuffs show (same rule as the tower panel).
	_set_text(_ms_value, _format_number(stats.getEffectiveMoveSpeed()))
	_set_text(_armor_value, str(stats.getTotalArmor()))
	_set_text(_mr_value, str(stats.getTotalMArmor()))

	_hp_bar.max_value = stats.maxHp
	_hp_bar.value = stats.currentHp
	_set_text(_hp_text, "%d / %d" % [stats.currentHp, stats.maxHp])

func _rebuild_skill_column(enemy: Enemy) -> void:
	for child in _skill_column.get_children():
		child.queue_free()
	if enemy.skillController == null:
		return
	for skill in enemy.skillController.skills:
		var es := skill as EnemySkill
		if es == null:
			continue
		var kind := "Active"
		if es.passive:
			kind = "Passive"
		elif es.triggered:
			kind = "Triggered"
		_skill_column.add_child(_make_skill_icon(es, kind))

func _make_skill_icon(skill: Skill, kind: String) -> TowerSkillIcon:
	var icon := TowerSkillIcon.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Enemy skills are single-level; the hover card renders desc at level 1.
	icon.setup(skill, kind, 1)

	# Same placeholder ladder as the tower panel (no skill icon art yet).
	var texture: Texture2D = null
	if skill.icon != "":
		texture = ResourceManager.loadImage("skill_icon", skill.icon, skill.icon)
	if texture == null:
		texture = ResourceManager.getSprite("synergy", "default")
	icon.texture = texture
	return icon

# Skip no-op text writes so per-frame polling doesn't churn label layout (PR #20 rule).
func _set_text(label: Label, value: String) -> void:
	if label.text != value:
		label.text = value

func _format_number(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return "%.1f" % value
