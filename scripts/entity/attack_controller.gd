extends Node
class_name AttackController

@onready var attackDelayTimer = $AttackDelayTimer

var attackDamage: int = 0;
var attackCooldown: float = 0;
var isReady: bool = true;

var target: Enemy = null;

func setup(damage: int, cooldown: float):
	attackCooldown = cooldown;
	updateAttackDamage(damage);

func canAttack(target: Enemy):
	return target != null && isReady

func updateAttackDamage(damage: int):
	attackDamage = damage;

func attack(target: Enemy):
	isReady = false;
	self.target = target;

func dealDamage() -> int:
	if(target == null):
		return 0;

	var dmgResult = 0
	if (target && target.has_method("recvDamage")):
		dmgResult = target.recvDamage(attackDamage);
	target = null;
	
	startAttackTimer();
	return 0

func startAttackTimer():
	attackDelayTimer.wait_time = attackCooldown
	attackDelayTimer.start();

func _onAttackDelayTimerTimeout():
	isReady = true;
