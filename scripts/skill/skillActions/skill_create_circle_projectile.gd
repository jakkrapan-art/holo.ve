class_name SkillCreateCircleProjectile
extends SkillActionProjectile

@export var circle_radius: float = 1.0;
@export var angular_speed: float = 180.0;
@export var initial_angle: float = 0.0;
@export var angle_offset: float = 0.0;

func setupProjectile(projectile: Projectile, i: int, context: SkillContext):
	var tower: Tower = context.user as Tower;
	var multi = getDamageMultiplier(context)
	projectile.setup_circle(tower, Damage.new(tower, multi * tower.data.getDamage(null), damageType), circle_radius, angular_speed, initial_angle + (angle_offset * i), lifetime, ProjectileCallback.new(Callable(self, "onHit"), Callable(), Callable()))
	super.setupProjectile(projectile, i, context)