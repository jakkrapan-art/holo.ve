class_name SkillActionDash
extends SkillAction

# Path dash (first user: Giant Boar Super Charge): slides the casting enemy
# forward ALONG ITS PATH by `cells` path-cells over `duration` seconds. Runs
# inside the cast while castLocked blocks normal walking - the action drives
# progress_ratio directly. One curve segment = one cell, the same convention
# as EnemyStat.calculatePathfollowSpeed. Reaching the endpoint mid-dash leaks
# normally: Enemy._process runs its endpoint check outside the movement gate,
# and the path curve does not loop, so overshoot clamps (design: a dash into
# the base IS a leak). A stunned caster still completes the slide - cast rule
# "a started skill always completes".

@export var cells: float = 1.0
@export var duration: float = 0.3

func execute(context: SkillContext):
	var enemy := context.user as Enemy
	if enemy == null or not is_instance_valid(enemy):
		return
	var parent := enemy.get_parent() as Path2D
	if parent == null or parent.curve == null:
		return
	var totalSegments: int = parent.curve.point_count - 3
	if totalSegments <= 0:
		return
	var totalRatio: float = cells / float(totalSegments)
	if duration <= 0.0:
		enemy.progress_ratio += totalRatio
		return
	var remaining := duration
	while remaining > 0.0:
		await enemy.get_tree().process_frame
		if not is_instance_valid(enemy):
			context.cancel = true
			return
		if enemy.get_tree().paused:
			continue
		var delta: float = enemy.get_process_delta_time()
		var step: float = minf(delta, remaining)
		var previousRatio := enemy.progress_ratio
		enemy.progress_ratio += totalRatio * (step / duration)
		enemy.updateFacingFromDirection(enemy.getPathDirection(parent, previousRatio, enemy.progress_ratio))
		remaining -= step
		if enemy.progress_ratio >= 1.0:
			return  # endpoint (leak) flow takes over in Enemy._process
