class_name EnemySkill
extends Skill

@export var cooldown: float = 3
var lastUsedTime: float = 0;

func isReady():
	return Time.get_ticks_msec() / 1000.0 - lastUsedTime >= cooldown

func executeSkill():
	lastUsedTime = Time.get_ticks_msec() / 1000.0