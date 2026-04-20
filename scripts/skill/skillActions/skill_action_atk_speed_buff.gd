class_name SkillActionAtkSpeedBuff
extends SkillAction

@export var duration: float = 4.0
@export var paramName: String = "attackSpeedPercent"

const BUFF_KEY = "atk_speed_buff_skill"

func execute(context: SkillContext) -> void:
	var tower := context.user as Tower
	if tower == null:
		return

	var percent: float = context.getParameter(paramName, tower.data.level - 1)
	tower.data.addAttackSpeedPercentBuff(percent, BUFF_KEY)
	context.user.get_tree().create_timer(duration).timeout.connect(
		func(): tower.data.removeAttackSpeedPercentBuff(BUFF_KEY),
		CONNECT_ONE_SHOT
	)
