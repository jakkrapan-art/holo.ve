extends Node
class_name AttackController

@onready var attackDelayTimer = $AttackDelayTimer
var attackDamage: int = 0;
var isReady: bool = true;

func setup(damage: int, delay: float):
	updateDelayTime(delay);
	updateAttackDamage(damage);

func updateAttackDamage(damage: int):
	attackDamage = damage;

func updateDelayTime(delay: float):
	if attackDelayTimer == null:
		return
	attackDelayTimer.wait_time = delay

func attack(target: Enemy) -> int:
	if(target == null || !isReady):
		return 0
	isReady = false;
	attackDelayTimer.start()
	if (target.has_method("recvDamage")):
		return target.recvDamage(attackDamage);
	else:
		return 0


func _onAttackDelayTimerTimeout():
	isReady = true;
