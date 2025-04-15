extends Node
class_name AttackController

@onready var attackDelayTimer = $AttackDelayTimer


enum STATE {DELAY_ATTACK, COOLDOWN}

var attackDamage: int = 0;
var attackCooldown: float = 0;
var attackDelay: float = 0;
var isReady: bool = true;
var state: STATE; 
var target: Enemy = null;

func setup(damage: int, delay: float, cooldown: float):
	attackDelay = delay;
	attackCooldown = cooldown;
	
	print("attack delay:", attackDelay);
	print("attack cd:", attackCooldown);
	updateAttackDamage(damage);

func canAttack(target: Enemy):
	return target != null && isReady

func updateAttackDamage(damage: int):
	attackDamage = damage;

func attack(target: Enemy):
	isReady = false;
	self.target = target;
	startAttackTimer(attackDelay, STATE.DELAY_ATTACK);
	print("attack:", Time.get_ticks_msec());

func dealDamage() -> int:
	var dmgResult = 0
	if (target && target.has_method("recvDamage")):
		dmgResult = target.recvDamage(attackDamage);
	target = null;
	startAttackTimer(attackCooldown, STATE.COOLDOWN);
	print("deal dmg:", Time.get_ticks_msec());	
	return 0

func startAttackTimer(time: float, state: STATE):
	self.state = state
	attackDelayTimer.wait_time = time
	
	if(attackDelayTimer != null):
		attackDelayTimer.start();

func _onAttackDelayTimerTimeout():
	match(state):
		STATE.DELAY_ATTACK:
			dealDamage();
		STATE.COOLDOWN:
			isReady = true
	if(state == STATE.DELAY_ATTACK):
		isReady = true;
	
