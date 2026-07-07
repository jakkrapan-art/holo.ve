class_name SkillActionSummonEnemy
extends SkillAction

# Summons roster enemies from the caster's current path position (King Salam's
# "King's Command"). Spawning is delegated to WaveController.summon so the
# summons join enemyAliveCount and the wave-end signals exactly like scheduled
# spawns. Fire-and-forget: the caster resumes acting while the batch trickles.
#
# YAML:
#   - type: summon_enemy
#     data:
#       enemy: armored_salam   # roster enemy id (the map's enemy DB)
#       count: 10
#       interval: 0.2          # seconds between spawns

@export var enemyId: String = ""
@export var count: int = 1
@export var interval: float = 0.2

func execute(context: SkillContext) -> void:
	var user := context.user
	if user == null or not is_instance_valid(user) or not (user is Enemy):
		return
	var caster := user as Enemy
	if not caster.is_inside_tree():
		return

	var controller := caster.get_tree().get_first_node_in_group("wave_controller") as WaveController
	if controller == null:
		push_error("SkillActionSummonEnemy: no WaveController found in group 'wave_controller'")
		return

	controller.summon(enemyId, count, interval, caster.progress_ratio)
