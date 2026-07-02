class_name SkillActionEffectArea
extends SkillAction

# Aura zone: spawns a CircleEffectArea on each context target and applies one
# registry effect to matching hosts while they are inside. Replaces the legacy
# decrease_atk_spd_area / decrease_dmg_all_area / increase_def_area /
# increase_move_spd_area actions.
#
# Aura lifetime rules (Director 2026-07-02):
#   - leaving the zone while it lives  -> effect removed immediately
#   - zone expires naturally           -> effect expires via its own timer
#   - the CASTER DIES (zone freed)     -> effect stays and runs out its timer
# Implemented by giving each applied instance duration = zone lifetime and
# skipping the exit-removal when no living zone remains (zone teardown fires
# the same exited callbacks as a genuine exit). Side effect: a host entering
# late keeps the effect up to `duration` after zone death - accepted.
#
# YAML:
#   - type: effect_area
#     data:
#       effect: attack_speed_down   # registry id ("_down" ids: enter positive value)
#       value: 0.1
#       duration: 5                 # area lifetime (seconds)
#       radius: 5                   # cells
#       affects: towers             # towers | enemies (who receives the effect)

@export var effectId: String = ""
@export var value: float = 0.0
@export var duration: float = 3.0
@export var radius: float = 1.0
@export var affects: String = "enemies"

var user: Node2D
var _zones: Array = []

func execute(context: SkillContext) -> void:
	if context.target.is_empty():
		context.cancel = true
		return
	user = context.user
	for target in context.target:
		var area := CircleEffectArea.new()
		area.setup(radius, duration, EffectAreaCallback.new(Callable(self, "_on_enter"), Callable(self, "_on_exit")))
		target.add_child(area)
		_zones.append(area)

func _on_enter(node: Area2D) -> void:
	if not is_instance_valid(user) or not _matches(node):
		return
	if node.has_method("apply_effect"):
		var inst := EffectUtility.make_instance(effectId, _source_id(), value, duration, user)
		if inst != null:
			node.apply_effect(inst)

func _on_exit(node: Area2D) -> void:
	if not _matches(node):
		return
	# Zone teardown (caster death / natural end) also fires exits - keep the
	# effect in that case; only a genuine walk-out removes it early.
	if not _any_zone_alive():
		return
	if is_instance_valid(node) and node.has_method("remove_effect_source"):
		node.remove_effect_source(_source_id())

func _any_zone_alive() -> bool:
	for z in _zones:
		if is_instance_valid(z) and not z.is_queued_for_deletion() and z.is_inside_tree():
			return true
	return false

func _matches(node: Node) -> bool:
	match affects:
		"towers":
			return node is Tower
		_:
			return node is Enemy or node is EnemyArea

# Per-action-instance source: two different casters' auras never collide
# (fixes the legacy shared-BUFF_KEY cross-tower removal bug).
func _source_id() -> String:
	return "area_" + str(get_instance_id())
