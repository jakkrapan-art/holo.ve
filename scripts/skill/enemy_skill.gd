class_name EnemySkill
extends Skill

@export var cooldown: float = 3
var cooldownRemaining: float = 0.0;

func _init(p_name:String="EnemySkill", p_desc:String="Just an enemy skill", p_actions:Array[SkillAction]=[], p_parameters:Dictionary={}, p_oneTimeUse: bool = false, p_cooldown:float=3.0, p_castTime: float = 0.0):
	super(p_name, p_desc, p_actions, p_parameters, p_oneTimeUse, p_castTime);
	self.cooldown = p_cooldown;

func isReady():
	return super.isReady() and cooldownRemaining <= 0.0

func tick(delta: float):
	cooldownRemaining = maxf(0.0, cooldownRemaining - delta)

func initCooldown():
	cooldownRemaining = cooldown / 2.0

func startCooldown():
	cooldownRemaining = cooldown
