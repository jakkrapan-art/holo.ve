class_name SkillActionAtkSpeedBuff
extends SkillAction

@export var duration: float = 4.0
@export var paramName: String = "attackSpeedPercent"
@export var displayName: String = "Attack Speed Up"
@export var iconPath: String = ""

const BUFF_KEY = "atk_speed_buff_skill"

func execute(context: SkillContext) -> void:
	var tower := context.user as Tower
	if tower == null:
		return

	var percent: float = context.getParameter(paramName, tower.data.level - 1)
	var buff := BuffInstance.new(
		BUFF_KEY,
		BuffInstance.StatType.ATTACK_SPEED,
		percent,
		BuffInstance.Category.BUFF,
		duration,
		BuffInstance.StackPolicy.IGNORE_IF_PRESENT,
	)
	buff.displayName = displayName
	buff.iconPath = iconPath
	buff.sourceSkill = BUFF_KEY

	var added := tower.data.buffs.add(buff)
	if not added:
		return

	var on_expire := func():
		if not is_instance_valid(tower):
			return
		tower.data.buffs.remove(BUFF_KEY)
	context.user.get_tree().create_timer(duration).timeout.connect(
		on_expire,
		CONNECT_ONE_SHOT
	)
