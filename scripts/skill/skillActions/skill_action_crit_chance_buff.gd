class_name SkillActionCritChanceBuff
extends SkillAction

@export var duration: float = 4.0
@export var percent: float = 100.0
@export var paramName: String = ""

const BUFF_KEY = "crit_chance_buff_skill"

func execute(context: SkillContext) -> void:
	var tower := context.user as Tower
	if tower == null:
		return

	var resolved_percent: float = context.getParameter(paramName, tower.data.level - 1) if paramName != "" else percent
	tower.data.addCritChanceBuff(resolved_percent, BUFF_KEY)

	tower.get_tree().create_timer(duration).timeout.connect(
		func():
			if is_instance_valid(tower):
				tower.data.removeCritChanceBuff(BUFF_KEY),
		CONNECT_ONE_SHOT
	)
