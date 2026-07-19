class_name SkillCreateCircleProjectile
extends SkillActionProjectile

@export var circle_radius: float = 1.0;
@export var angular_speed: float = 180.0;
@export var initial_angle: float = 0.0;
@export var angle_offset: float = 0.0;
# Scale multipliers applied to the projectile root (visual + collision).
# 1.0 = template default size; 2.5 ≈ covers diagonal tile centers when orbit radius is 1 tile.
@export var projectile_size_w: float = 1.0;
@export var projectile_size_h: float = 1.0;

func setupProjectile(projectile: Projectile, i: int, context: SkillContext):
	var tower: Tower = context.user as Tower;
	var multi = getDamageMultiplier(context)
	projectile.scale = Vector2(projectile_size_w, projectile_size_h)
	var damage := Damage.new(tower, int(multi * tower.data.getDamage(null, null).damage), damageType)
	damage.isSkillDamage = true
	# No sourceAmp: getDamage(null, null) has no target to measure against, so
	# skill projectiles carry no distance bonus (gap noted in tower_synergy.md).
	projectile.setup_circle(tower, damage, circle_radius, angular_speed, initial_angle + (angle_offset * i), lifetime, ProjectileCallback.new(Callable(self, "onHit"), Callable(), Callable()))
	super.setupProjectile(projectile, i, context)
