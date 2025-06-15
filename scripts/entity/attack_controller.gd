extends Node
class_name AttackController

@onready var attackDelayTimer = $AttackDelayTimer

var attackCooldown: float = 0;
var isReady: bool = true;

var tower: Tower;
var target: Enemy = null;

var modifier: Dictionary = {}

func setup(tower: Tower,cooldown: float):
	attackCooldown = cooldown;
	self.tower = tower;

func addModifier(key: int, mod: Callable):
	modifier[key] = mod

func removeModifier(key: int):
	if(!modifier.has(key)):
		pass
	
	modifier.erase(key);

func executeModifier():
	for mod in modifier.values():
		mod.call(tower);

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
	executeModifier();
	target = null;
	
	startAttackTimer();
	return 0

func startAttackTimer():
	attackDelayTimer.wait_time = attackCooldown
	attackDelayTimer.start();

func _onAttackDelayTimerTimeout():
	isReady = true;
