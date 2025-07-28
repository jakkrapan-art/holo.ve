extends Node
class_name AttackController

@onready var attackDelayTimer = $AttackDelayTimer
@export var projectile: PackedScene #for test projectile

var attackCooldown: float = 0;
var isReady: bool = true;

var tower: Tower;
var target: Enemy = null;
var damage: Damage = null;

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
	return is_instance_valid(target) && isReady

func attack(target: Enemy, damage: int = 0):
	isReady = false;
	self.target = target;
	self.damage = Damage.new(tower, damage, Damage.DamageType.physical);

func attackAnimFinish(damage: int) -> int:
	if(target == null):
		return 0;

	# dealDamage(Damage.new(tower, damage, Damage.DamageType.physical));
	shootProjectile(Callable(self, "dealDamage"));
	startAttackTimer();
	return 0

func shootProjectile(onHit: Callable = Callable()):
	if(target == null):
		return;

	var p: Projectile = projectile.instantiate() as Projectile;
	p.global_position = tower.global_position;
	get_tree().root.add_child(p);

	var rand: int = randi_range(0, 2)
	# print("rand result:", rand);
	match rand:
		0:
			print("shoot projectile to target");
			p.setupTarget(tower, target, damage, -1, ProjectileCallback.new(onHit, Callable(), Callable()));
		3:
			print("shoot projectile to target position");
			p.setupTargetPosition(tower, target.global_position, damage, -1, ProjectileCallback.new(onHit, Callable(), Callable()));
		2:
			print("shoot projectile by direction");
			p.setup_direction(tower, target.global_position - tower.global_position, damage, -1, ProjectileCallback.new(onHit, Callable(), Callable()));
		1:
			print("shoot projectile in circle");
			p.setup_circle(tower, damage, 1 * GridHelper.CELL_SIZE, 180.0, 5, ProjectileCallback.new(onHit, Callable(), Callable()));
		_:
			print(rand, " type: ", typeof(rand));

func dealDamage(projectile: Projectile, enemy: Enemy = null):
	if(!enemy):
		return;

	if (enemy && enemy.has_method("recvDamage")):
		enemy.recvDamage(damage);
		executeModifier();

	if (target && target == enemy):
		target = null;

func startAttackTimer():
	attackDelayTimer.wait_time = attackCooldown
	attackDelayTimer.start();

func _onAttackDelayTimerTimeout():
	isReady = true;
