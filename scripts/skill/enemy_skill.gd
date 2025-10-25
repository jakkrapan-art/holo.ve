class_name EnemySkill
extends Skill

@export var cooldown: float = 3
var lastUsedTime: float = 0;

func _init(name:String="EnemySkill", desc:String="Just an enemy skill", actions:Array[SkillAction]=[], parameters:Dictionary={}, oneTimeUse: bool = false, cooldown:float=3.0):
	super(name, desc, actions, parameters, oneTimeUse);
	self.cooldown = cooldown;

func isReady():
	return super.isReady() and Time.get_ticks_msec() / 1000.0 - lastUsedTime >= cooldown

func initCooldown():
	lastUsedTime = (Time.get_ticks_msec() / (1000.0)) - (cooldown / 2)

func startCooldown():
	lastUsedTime = Time.get_ticks_msec() / 1000.0