extends Node
class_name AttackController

@onready var attackDelayTimer = $AttackDelayTimer
@export var projectile: PackedScene #for test projectile

var getAttackCooldown: Callable;

var tower: Tower;

var modifier: Dictionary = {}

func setup(tower: Tower, getCooldown: Callable):
	getAttackCooldown = getCooldown;
	self.tower = tower;

func addModifier(key: int, mod: Callable):
	modifier[key] = mod

func removeModifier(key: int):
	modifier.erase(key);

func executeModifier():
	for mod in modifier.values():
		mod.call(tower);

func canAttack(target: Enemy):
	return is_instance_valid(target)

func attack(target: Enemy, direction: Global.DIRECTION, damage: Damage = Damage.new(null, 0, Damage.DamageType.PHYSIC), sound: String = "", vfx: String = ""):
	if(target == null):
		return;

	dealDamage(target, damage);

	if(sound != ""):
		AudioManager.playSfx(Utility.parse_string_to_enum(SoundDatabase.SFX_NAME, sound));

	AttackVfx.play_vfx(Utility.parse_string_to_enum(AttackVfx.AttackVFXName, vfx), self.tower.global_position, direction, get_tree().current_scene);

# func shootProjectile(onHit: Callable = Callable()):
# 	if(target == null):
# 		return;

# 	var p: Projectile = projectile.instantiate() as Projectile;
# 	p.global_position = tower.global_position;
# 	get_tree().root.add_child(p);

# 	var rand: int = randi_range(0, 2)
# 	# print("rand result:", rand);
# 	match rand:
# 		0:
# 			p.setupTarget(tower, target, damage, -1, ProjectileCallback.new(onHit, Callable(), Callable()));
# 		3:
# 			p.setupTargetPosition(tower, target.global_position, damage, -1, ProjectileCallback.new(onHit, Callable(), Callable()));
# 		2:
# 			p.setup_direction(tower, target.global_position - tower.global_position, damage, -1, ProjectileCallback.new(onHit, Callable(), Callable()));
# 		1:
# 			p.setup_circle(tower, damage, 1 * GridHelper.CELL_SIZE, 180.0, 0, 5, ProjectileCallback.new(onHit, Callable(), Callable()));
# 		_:
# 			print(rand, " type: ", typeof(rand));

func dealDamage(enemy: Enemy = null, damage: Damage = null):
	if(!enemy):
		return;

	if (enemy && enemy.has_method("recvDamage")):
		enemy.recvDamage(damage);
		executeModifier();

# Normal-attack PROJECTILE path (design A: fire `burst` homing bullets, but only
# the first carries damage so DPS == one hitscan hit). Fire-and-forget: the attack
# commits (cooldown/energy) in Tower.attackEnemy at fire time; damage lands on hit.
func attackProjectile(target: Enemy, dmg: Damage, cfg: TowerAttackConfig) -> void:
	if target == null or cfg == null or cfg.projectile_scene == null:
		return
	if not is_instance_valid(tower):
		return

	# Captured at fire; if a wave reset bumps it, in-flight callbacks/spawns abort
	# so a stale bullet can't damage a recycled enemy next wave (see resetForWave).
	var saved_gen: int = tower.skill_lock_generation

	_spawnBullet(target, cfg, dmg, saved_gen, true)   # damage carrier
	if cfg.burst > 1:
		_spawnBurstRemainder(target, cfg, saved_gen)   # cosmetic, staggered

func _spawnBullet(target: Enemy, cfg: TowerAttackConfig, dmg: Damage, saved_gen: int, carries_damage: bool) -> void:
	if not is_instance_valid(tower) or not is_instance_valid(target):
		return
	var proj := cfg.projectile_scene.instantiate() as Projectile
	if proj == null:
		return
	tower.get_tree().root.add_child(proj)
	var aim_dir := (target.global_position - tower.global_position).normalized()
	proj.global_position = Utility.muzzle_origin(tower.global_position, aim_dir)
	proj.speed = cfg.speed * GridHelper.CELL_SIZE
	_applyBulletVisual(proj, cfg)

	var cb: ProjectileCallback
	if carries_damage:
		# bound saved_gen arrives as the 3rd arg of _onProjectileHit(proj, target, gen)
		cb = ProjectileCallback.new(Callable(self, "_onProjectileHit").bind(saved_gen), Callable(), Callable())
	else:
		cb = ProjectileCallback.new()   # empty -> no damage; fizzles on hit / target death
	proj.setupTarget(tower, target, dmg, 5.0, cb)

func _spawnBurstRemainder(target: Enemy, cfg: TowerAttackConfig, saved_gen: int) -> void:
	for i in range(1, cfg.burst):
		await tower.get_tree().create_timer(0.07).timeout
		if not is_instance_valid(tower) or tower.skill_lock_generation != saved_gen:
			return   # wave reset mid-burst (tower survives waves; only gen bumps)
		if not is_instance_valid(target):
			return
		_spawnBullet(target, cfg, null, saved_gen, false)

func _onProjectileHit(proj: Projectile, target, saved_gen: int) -> void:
	if not is_instance_valid(tower) or tower.skill_lock_generation != saved_gen:
		return   # stale: a wave reset happened since fire — don't hit a recycled enemy
	if target is Enemy and is_instance_valid(target):
		(target as Enemy).recvDamage(proj.damage)
		executeModifier()

# Scales sprite + collision to cfg.size and pushes ONLY the shader-uniform overrides the
# YAML actually set (cfg.visual_overrides); anything omitted keeps the shader's own default.
# Duplicates the shared ShaderMaterial / CircleShape2D so per-bullet (and per-tower) tuning
# never mutates the scene's shared resources.
func _applyBulletVisual(proj: Projectile, cfg: TowerAttackConfig) -> void:
	for child in proj.get_children():
		if child is Sprite2D:
			var spr := child as Sprite2D
			var tex_h: float = float(spr.texture.get_height()) if spr.texture else 64.0
			spr.scale = Vector2.ONE * (cfg.size / max(tex_h, 1.0))
			if spr.material is ShaderMaterial:
				var mat := (spr.material as ShaderMaterial).duplicate() as ShaderMaterial
				spr.material = mat
				for uniform_name in cfg.visual_overrides:
					mat.set_shader_parameter(uniform_name, cfg.visual_overrides[uniform_name])
		elif child is CollisionShape2D:
			var cs := child as CollisionShape2D
			if cs.shape is CircleShape2D:
				var shape := (cs.shape as CircleShape2D).duplicate() as CircleShape2D
				shape.radius = cfg.size * 0.5
				cs.shape = shape
