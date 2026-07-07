class_name SkillActionApplyEffect
extends SkillAction

# Applies one registry effect (resources/database/effect/effects.yaml) to the
# caster, nearby allied towers, or the context targets. Replaces the legacy
# atk_speed_buff / atk_speed_buff_aoe / crit_chance_buff / apply_status_effect
# actions. No timers here: EffectContainer owns expiry (R2/R3 root fix).
#
# YAML:
#   - type: apply_effect
#     data:
#       effect: attack_speed_up      # registry id
#       target: self                 # self | allies_in_range | towers_in_range | targets
#       value: 0.5                   # literal, or:
#       value_param: "attackSpeedBuff"   # per-level parameters binding
#       duration: 4.0                # literal, or duration_param
#       range: 1                     # allies_in_range / towers_in_range (cells)
#
# towers_in_range = same tower box as allies_in_range, named for enemy casters
# (a boss debuffing towers around itself, e.g. Slime Fluid's 3x3 = range 1).

@export var effectId: String = ""
@export var targetMode: String = "self"
@export var value: float = 0.0
@export var valueParam: String = ""
@export var duration: float = 0.0
@export var durationParam: String = ""
@export var range_cells: int = 1
@export var authoredTitle: String = ""

func execute(context: SkillContext) -> void:
	var user := context.user
	if user == null or not is_instance_valid(user):
		return

	var level_index := 0
	if user is Tower:
		level_index = (user as Tower).data.level - 1
	var resolved_value: float = float(context.getParameter(valueParam, level_index)) if valueParam != "" else value
	var resolved_duration: float = float(context.getParameter(durationParam, level_index)) if durationParam != "" else duration
	# Identity = source skill + effect (Decision 2): recasts refresh, different
	# skills stack. Fallback keeps the key non-empty for unnamed skills.
	var source_id := context.skillName if context.skillName != "" else "skill_" + str(get_instance_id())

	# Enemy-cast area debuff: flash the affected box in red so the player (and
	# playtests) can see the real footprint - reuses the staff SkillCastIndicator.
	if targetMode == "towers_in_range":
		_spawn_area_flash(user)

	for target in _resolve_targets(context, user):
		if not is_instance_valid(target) or not target.has_method("apply_effect"):
			continue
		var inst := EffectUtility.make_instance(effectId, source_id, resolved_value, resolved_duration, user, authoredTitle)
		if inst == null:
			return
		target.apply_effect(inst)

const AREA_FLASH_SECONDS := 0.6

func _spawn_area_flash(user: Node) -> void:
	var caster := user as Node2D
	if caster == null or not caster.is_inside_tree():
		return
	var flash := SkillCastIndicator.new()
	var cells := range_cells * 2 + 1   # range 1 = 3x3 box around the caster
	flash.set_aoe_size(cells, cells)
	flash.fill_color = Color(1.0, 0.15, 0.1, 0.22)
	flash.outline_color = Color(1.0, 0.35, 0.2, 1.0)
	caster.get_parent().add_child(flash)
	flash.update_position_from_world(caster.global_position)
	flash.visible = true
	caster.get_tree().create_timer(AREA_FLASH_SECONDS).timeout.connect(flash.queue_free)

func _resolve_targets(context: SkillContext, user: Node) -> Array:
	match targetMode:
		"allies_in_range", "towers_in_range":
			var towers: Array = []
			var source_cell: Vector2 = GridHelper.WorldToCell((user as Node2D).global_position)
			for node in user.get_tree().get_nodes_in_group("tower"):
				var tower := node as Tower
				if tower == null:
					continue
				var cell: Vector2 = GridHelper.WorldToCell(tower.global_position)
				if abs(cell.x - source_cell.x) <= range_cells and abs(cell.y - source_cell.y) <= range_cells:
					towers.append(tower)
			return towers
		"targets":
			return context.target
		_:
			return [user]
