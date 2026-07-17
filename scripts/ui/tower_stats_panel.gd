class_name TowerStatsPanel
extends Control

# Placeholder tower stats panel (bottom-left HUD). Artist design pass pending.
# The skeleton (portrait / name+level header / trait row / stat grid / energy
# bar / right-edge skill icon column) is the shared layout convention for the
# future enemy stats panel (ui.md).

@onready var _portrait: TextureRect = $Portrait
@onready var _name_label: Label = $NameLabel
@onready var _level_label: Label = $LevelLabel
@onready var _class_icon: TextureRect = $TraitRow/ClassIcon
@onready var _class_label: Label = $TraitRow/ClassLabel
@onready var _gen_icon: TextureRect = $TraitRow/GenIcon
@onready var _gen_label: Label = $TraitRow/GenLabel
@onready var _atk_value: Label = $StatsGrid/AtkValue
@onready var _type_value: Label = $StatsGrid/TypeValue
@onready var _as_value: Label = $StatsGrid/AsValue
@onready var _crit_value: Label = $StatsGrid/CritValue
@onready var _crit_dmg_value: Label = $StatsGrid/CritDmgValue
@onready var _range_value: Label = $StatsGrid/RangeValue
@onready var _energy_row: Control = $EnergyRow
@onready var _energy_bar: ProgressBar = $EnergyRow/EnergyBar
@onready var _energy_text: Label = $EnergyRow/EnergyBar/EnergyText
# Right-edge column: the hover popup opens toward the open playfield instead of
# over the panel's own stat text (Director feedback 2026-07-16).
@onready var _skill_column: VBoxContainer = $SkillColumn
# Buff/debuff strip floating above the panel's top border (rich hover).
@onready var _effect_row: EffectIconRow = $EffectRow

const OUTLINE_SHADER := preload("res://resources/ui_component/inspect_outline.gdshader")

var _tower: Tower = null
# Rebuild key for the skill-icon row ("level_isEvolved"): icons/tooltips only
# change on level-up or evolve, so the per-frame poll skips the rebuild.
var _skills_key: String = ""
# Inspect-highlight outline on the selected tower's sprite (ui.md). One material
# is enough: only one unit is ever selected (panels mutually clear).
var _outline_mat: ShaderMaterial
var _hl_sprite: AnimatedSprite2D = null

func _ready():
	visible = false
	_outline_mat = ShaderMaterial.new()
	_outline_mat.shader = OUTLINE_SHADER

func show_tower(tower: Tower) -> void:
	_tower = tower
	_skills_key = ""
	visible = true
	# Container lives on TowerData, which evolve() mutates in place and which
	# outlives the node - bind once per selection is safe.
	_effect_row.setup(tower.data.effects if tower.data != null else null)
	_apply_highlight(tower.spr)
	_refresh()

func clear() -> void:
	_tower = null
	visible = false
	_effect_row.setup(null)
	_remove_highlight()

# The shader needs the CURRENT frame's rect inside the sheet (its cell clamp +
# grow contraction). Feeding it live from the sprite - instead of hardcoding any
# frame/sheet size - keeps the highlight correct through future asset resizes
# or repacks (Director requirement 2026-07-17).
func _apply_highlight(spr: AnimatedSprite2D) -> void:
	_remove_highlight()
	if spr == null:
		return
	_hl_sprite = spr
	# A centered sprite's quad center in local vertex space is its offset; the
	# shader grows vertices away from it (flip-proof, unlike UV-derived growth).
	_outline_mat.set_shader_parameter("quad_center_px", spr.offset)
	_update_highlight_region()
	spr.material = _outline_mat
	spr.frame_changed.connect(_update_highlight_region)
	spr.animation_changed.connect(_update_highlight_region)

func _remove_highlight() -> void:
	if _hl_sprite != null and is_instance_valid(_hl_sprite):
		_hl_sprite.material = null
		if _hl_sprite.frame_changed.is_connected(_update_highlight_region):
			_hl_sprite.frame_changed.disconnect(_update_highlight_region)
		if _hl_sprite.animation_changed.is_connected(_update_highlight_region):
			_hl_sprite.animation_changed.disconnect(_update_highlight_region)
	_hl_sprite = null

func _update_highlight_region() -> void:
	if _hl_sprite == null or not is_instance_valid(_hl_sprite):
		return
	# Default = whole texture (non-atlas frames need no cell clamp).
	var region := Vector4(0.0, 0.0, 1.0, 1.0)
	var frames := _hl_sprite.sprite_frames
	if frames != null and frames.has_animation(_hl_sprite.animation) \
			and _hl_sprite.frame < frames.get_frame_count(_hl_sprite.animation):
		var atlas := frames.get_frame_texture(_hl_sprite.animation, _hl_sprite.frame) as AtlasTexture
		if atlas != null and atlas.atlas != null:
			var sheet: Vector2 = atlas.atlas.get_size()
			region = Vector4(atlas.region.position.x / sheet.x, atlas.region.position.y / sheet.y,
					atlas.region.size.x / sheet.x, atlas.region.size.y / sheet.y)
	_outline_mat.set_shader_parameter("region_uv", region)

func _process(_delta):
	if not visible:
		return
	if _tower == null or not is_instance_valid(_tower):
		clear()
		return
	_refresh()

func _refresh() -> void:
	var data: TowerData = _tower.data
	if data == null:
		clear()
		return

	# Identity: tower.id is the data key; display name + portrait come from the
	# TowerCenter registry (same access pattern as Tower.setup).
	var entry = TowerCenter._towers_data.get(_tower.id.to_lower(), null)
	_set_text(_name_label, entry.name if entry != null else _tower.id)
	_portrait.texture = TowerCenter._tower_portrait.get(entry.data_name, null) if entry != null else null

	_set_text(_level_label, "Evolved" if data.isEvolved else "Level %d" % data.level)

	# Traits: display names + synergy icons (default.png fallback, PR #95 pattern).
	var class_display: String = TowerTrait.TOWER_CLASS_NAMES.get(data.towerClass, "default")
	var gen_display: String = TowerTrait.TOWER_GENERATION_NAMES.get(data.generation, "default")
	_set_text(_class_label, class_display)
	_set_text(_gen_label, gen_display)
	_class_icon.texture = _trait_sprite(class_display)
	_gen_icon.texture = _trait_sprite(gen_display)

	# Stats: live getters, so buffs/debuffs show (player-facing terms per
	# game_copy.md). 3x2 grid: attack block left, crit block + range right.
	_set_text(_atk_value, str(data.getTotalAttack()))
	_set_text(_type_value, "Magic" if data.attackType == Damage.DamageType.MAGIC else "Physical")
	_set_text(_as_value, _format_number(data.getAttackSpeed()))
	_set_text(_range_value, _format_number(data.getAttackRange()))
	_set_text(_crit_value, _format_number(data.getCritChance()) + "%")
	# Display-only percent form (1.5 -> "150%"); the damage formula still uses
	# the raw multiplier.
	_set_text(_crit_dmg_value, _format_number(data.getCritDamage() * 100.0) + "%")

	# Energy: evolve swaps the SkillController (tower.gd evolve) - re-read every
	# frame, never cache. Passive-only towers have none -> hide the row.
	var sc = _tower.skillController
	_energy_row.visible = sc != null
	if sc != null:
		_energy_bar.max_value = sc.maxMana
		_energy_bar.value = sc.currentMana
		_set_text(_energy_text, "%d / %d" % [int(sc.currentMana), int(sc.maxMana)])

	var skills_key := "%d_%s" % [data.level, data.isEvolved]
	if skills_key != _skills_key:
		_skills_key = skills_key
		_rebuild_skill_row(data)

func _rebuild_skill_row(data: TowerData) -> void:
	for child in _skill_column.get_children():
		child.queue_free()

	var level: int = data.level
	var active: Skill = data.evolutionSkill if data.isEvolved and data.evolutionSkill != null else data.skill
	if active != null and not active.actions.is_empty():
		_skill_column.add_child(_make_skill_icon(active, "Active", level))

	var passive_params: Dictionary = data.evolutionPassive if data.isEvolved and not data.evolutionPassive.is_empty() else data.passive
	var passive_skill: Skill = TowerDataLoader.build_passive_display_skill(passive_params)
	if passive_skill != null:
		_skill_column.add_child(_make_skill_icon(passive_skill, "Passive", level))

func _make_skill_icon(skill: Skill, kind: String, level: int) -> TowerSkillIcon:
	var icon := TowerSkillIcon.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.setup(skill, kind, level)

	# No tower skill icon art exists yet; the shared synergy default placeholder
	# stands in (a dedicated skills/default asset needs a Godot-generated .import,
	# so reuse beats hand-adding a binary - see tower_skill.md icon note).
	var texture: Texture2D = null
	if skill.icon != "":
		texture = ResourceManager.loadImage("skill_icon", skill.icon, skill.icon)
	if texture == null:
		texture = ResourceManager.getSprite("synergy", "default")
	icon.texture = texture
	return icon

func _trait_sprite(trait_display: String) -> Texture2D:
	var sprite = ResourceManager.getSprite("synergy", trait_display.to_lower())
	if sprite == null:
		sprite = ResourceManager.getSprite("synergy", "default")
	return sprite

# Skip no-op text writes so per-frame polling doesn't churn label layout (PR #20 rule).
func _set_text(label: Label, value: String) -> void:
	if label.text != value:
		label.text = value

func _format_number(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return "%.1f" % value
