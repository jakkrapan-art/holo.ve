extends Node
class_name AttackController

@onready var attackDelayTimer = $AttackDelayTimer
@export var projectile: PackedScene #for test projectile

var getAttackCooldown: Callable;

var tower: Tower;
var target: Enemy = null;
var damage: Damage = null;

var modifier: Dictionary = {}

func setup(tower: Tower, getCooldown: Callable):
	getAttackCooldown = getCooldown;
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
	return is_instance_valid(target)

func attack(target: Enemy, damage: Damage = Damage.new(null, 0, Damage.DamageType.PHYSIC)):
	self.target = target;
	self.damage = damage;

func attackAnimFinish():
	if(target == null):
		return;

	dealDamage(target);
	# shootProjectile(Callable(self, "dealDamage"));

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
			p.setupTarget(tower, target, damage, -1, ProjectileCallback.new(onHit, Callable(), Callable()));
		3:
			p.setupTargetPosition(tower, target.global_position, damage, -1, ProjectileCallback.new(onHit, Callable(), Callable()));
		2:
			p.setup_direction(tower, target.global_position - tower.global_position, damage, -1, ProjectileCallback.new(onHit, Callable(), Callable()));
		1:
			p.setup_circle(tower, damage, 1 * GridHelper.CELL_SIZE, 180.0, 0, 5, ProjectileCallback.new(onHit, Callable(), Callable()));
		_:
			print(rand, " type: ", typeof(rand));

func dealDamage(enemy: Enemy = null):
	if(!enemy):
		return;

	if (enemy && enemy.has_method("recvDamage")):
		enemy.recvDamage(damage);
		executeModifier();

	if (target && target == enemy):
		target = null;
