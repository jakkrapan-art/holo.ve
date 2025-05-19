extends Node
class_name AttackController

@onready var attackDelayTimer = $AttackDelayTimer

var attackCooldown: float = 0;
var isReady: bool = true;

var target: Enemy = null;

func setup(cooldown: float):
	attackCooldown = cooldown;

func canAttack(target: Enemy):
	return target != null && isReady

func attack(target: Enemy):
	isReady = false;
	self.target = target;

func dealDamage(damage: int) -> int:
	if(target == null):
		return 0;

	var dmgResult = 0
	if (target && target.has_method("recvDamage")):
		dmgResult = target.recvDamage(damage);
	target = null;
	
	startAttackTimer();
	return 0

func startAttackTimer():
	attackDelayTimer.wait_time = attackCooldown
	attackDelayTimer.start();

func _onAttackDelayTimerTimeout():
	isReady = true;
