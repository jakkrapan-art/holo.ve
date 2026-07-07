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

# Show the applied box with the same red Hitbox visual Kiara/Altare skills use
# (Lead's component). Detection is done by _resolve_targets; the empty Callable
# skips the Hitbox callback - this instance is visual-only.
func _spawn_area_flash(user: Node) -> void:
	var caster := user as Node2D
	if caster == null or not caster.is_inside_tree():
		return
	var side := float(range_cells * 2 + 1) * GridHelper.CELL_SIZE   # range 1 = 3x3
	Hitbox.create(side, side, Callable(), caster.global_position, caster.get_parent(), 0.0, Vector2.ZERO, Color(1, 0, 0, 0.25), AREA_FLASH_SECONDS)

func _resolve_targets(context: SkillContext, user: Node) -> Array:
	match targetMode:
		"allies_in_range", "towers_in_range":
			# Body-centered box, NOT cell-snapped: a mid-cell caster (a walking
			# boss) hits exactly the box the red flash shows. For tower casters
			# this is equivalent to the old cell-index check (towers sit on cell
			# centers); range 1 = a 3x3-cell box around the caster's body.
			var towers: Array = []
			var half := (float(range_cells) + 0.5) * GridHelper.CELL_SIZE
			var source_pos: Vector2 = (user as Node2D).global_position
			for node in user.get_tree().get_nodes_in_group("tower"):
				var tower := node as Tower
				if tower == null:
					continue
				var d: Vector2 = tower.global_position - source_pos
				if abs(d.x) <= half and abs(d.y) <= half:
					towers.append(tower)
			return towers
		"targets":
			return context.target
		_:
			return [user]
