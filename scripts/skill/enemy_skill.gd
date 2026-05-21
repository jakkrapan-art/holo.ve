class_name EnemySkill
extends Skill

@export var cooldown: float = 3
var cooldownRemaining: float = 0.0;

func _init(name:String="EnemySkill", desc:String="Just an enemy skill", actions:Array[SkillAction]=[], parameters:Dictionary={}, oneTimeUse: bool = false, cooldown:float=3.0):
	super(name, desc, actions, parameters, oneTimeUse);
	self.cooldown = cooldown;

func isReady():
	return super.isReady() and cooldownRemaining <= 0.0

func tick(delta: float):
	cooldownRemaining = maxf(0.0, cooldownRemaining - delta)

func initCooldown():
	cooldownRemaining = cooldown / 2.0

func startCooldown():
	cooldownRemaining = cooldown
