class_name SkillActionCritChanceBuff
extends SkillAction

@export var duration: float = 4.0
@export var percent: float = 100.0

const BUFF_KEY = "crit_chance_buff_skill"

func execute(context: SkillContext) -> void:
	var tower := context.user as Tower
	if tower == null:
		return

	tower.data.addCritChanceBuff(percent, BUFF_KEY)

	tower.get_tree().create_timer(duration).timeout.connect(
		func():
			if is_instance_valid(tower):
				tower.data.removeCritChanceBuff(BUFF_KEY),
		CONNECT_ONE_SHOT
	)
