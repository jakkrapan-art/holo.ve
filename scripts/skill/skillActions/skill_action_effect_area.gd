class_name SkillActionEffectArea
extends SkillAction

# Aura zone: spawns a CircleEffectArea on each context target and applies one
# registry effect to matching hosts while they are inside. Replaces the legacy
# decrease_atk_spd_area / decrease_dmg_all_area / increase_def_area /
# increase_move_spd_area actions.
#
# Aura lifetime rule (plan F6): the applied instance has NO self-expiry
# (duration 0) - it is removed on exit or when the area dies; `duration` in
# data is the AREA's lifetime only. Wave clear catches any orphan.
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

func execute(context: SkillContext) -> void:
	if context.target.is_empty():
		context.cancel = true
		return
	user = context.user
	for target in context.target:
		var area := CircleEffectArea.new()
		area.setup(radius, duration, EffectAreaCallback.new(Callable(self, "_on_enter"), Callable(self, "_on_exit")))
		target.add_child(area)

func _on_enter(node: Area2D) -> void:
	if not is_instance_valid(user) or not _matches(node):
		return
	if node.has_method("apply_effect"):
		var inst := EffectUtility.make_instance(effectId, _source_id(), value, 0.0, user)
		if inst != null:
			node.apply_effect(inst)

func _on_exit(node: Area2D) -> void:
	if not _matches(node):
		return
	if is_instance_valid(node) and node.has_method("remove_effect_source"):
		node.remove_effect_source(_source_id())

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
