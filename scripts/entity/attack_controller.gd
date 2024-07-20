extends Node
class_name AttackController

@onready var attackDelayTimer = $AttackDelayTimer
var weapon = null;

func setup(weapon):
	self.weapon = weapon

func setDelayTime(delay: float):
	if attackDelayTimer == null:
		return
	attackDelayTimer.wait_time = delay

func attack(target: Entity, damageAmount: int) -> int:
	if(weapon == null || target == null || !isReady()):
		return 0
	weapon.attack(target);
	attackDelayTimer.start()
	return 0
	#if (target.has_method("recvDamage")):
		#return target.recvDamage(damageAmount)
	#else:
		#return 0

func isReady() -> bool:
	return attackDelayTimer != null && attackDelayTimer.time_left <= 0
