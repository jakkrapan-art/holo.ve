extends Node
class_name AttackController

@onready var attackDelayTimer = $AttackDelayTimer
@export var projectile: PackedScene #for test projectile

## Bullet lifetime in seconds. Also the clock the bullet shader's `life` uniform is
## derived from (BULLET_LIFETIME - proj.lifetime), so it must stay the value passed to
## setupTarget below.
const BULLET_LIFETIME := 5.0
const IMPACT_QUAD_PX := 64.0   # carrier quad for the impact beat; scaled to cfg.get_impact_size()

var getAttackCooldown: Callable;

var tower: Tower;

var modifier: Dictionary = {}

func setup(p_tower: Tower, getCooldown: Callable):
	getAttackCooldown = getCooldown;
	self.tower = p_tower;

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
	var mat := _applyBulletVisual(proj, cfg)

	# onMove ticks the bullet shader's `life` every frame (Projectile calls it before
	# processLifetime, so frame one reads 0.0). Rides the same _process delta as the
	# bullet, so it is pause-frozen and x2-correct for free. A bullet shader without a
	# `life` uniform just ignores the push.
	var move_cb := Callable()
	if mat != null:
		move_cb = Callable(self, "_onBulletMove").bind(mat)

	var cb: ProjectileCallback
	if carries_damage:
		# Projectile emits onHit.call(self, target) and bind() appends, so the bound args
		# land as _onProjectileHit(proj, target, saved_gen, cfg) - order matters.
		cb = ProjectileCallback.new(Callable(self, "_onProjectileHit").bind(saved_gen, cfg), Callable(), move_cb)
	else:
		cb = ProjectileCallback.new(Callable(), Callable(), move_cb)   # no damage; visual only
	proj.setupTarget(tower, target, dmg, BULLET_LIFETIME, cb)

func _spawnBurstRemainder(target: Enemy, cfg: TowerAttackConfig, saved_gen: int) -> void:
	for i in range(1, cfg.burst):
		await tower.get_tree().create_timer(0.07, false).timeout
		if not is_instance_valid(tower) or tower.skill_lock_generation != saved_gen:
			return   # wave reset mid-burst (tower survives waves; only gen bumps)
		if not is_instance_valid(target):
			return
		_spawnBullet(target, cfg, null, saved_gen, false)

func _onProjectileHit(proj: Projectile, target, saved_gen: int, cfg: TowerAttackConfig) -> void:
	if not is_instance_valid(tower) or tower.skill_lock_generation != saved_gen:
		return   # stale: a wave reset happened since fire — don't hit a recycled enemy
	if target is Enemy and is_instance_valid(target):
		# Impact BEFORE the damage: a killing blow can run endWave -> resetForWave
		# synchronously inside recvDamage (see Tower.attackEnemy), and this beat belongs
		# to the moment of contact. Centred on the ENEMY, not on the bullet: the bullet
		# stops a collision-radius short of it.
		_spawnImpact(cfg, (target as Enemy).global_position)
		(target as Enemy).recvDamage(proj.damage)
		executeModifier()

# Pushes seconds-in-flight to the bullet shader (see BULLET_LIFETIME).
func _onBulletMove(proj: Projectile, mat: ShaderMaterial) -> void:
	if not is_instance_valid(proj) or mat == null:
		return
	mat.set_shader_parameter("life", BULLET_LIFETIME - proj.lifetime)

# On-hit beat for bullets whose shader draws a phase-1 impact (opt-in via `impact: true`).
# Square quad and rotation 0 on purpose: the impact fragment is radial, and its droplet
# gravity only reads as "down" while the quad is unrotated.
func _spawnImpact(cfg: TowerAttackConfig, at: Vector2) -> void:
	if cfg == null or not cfg.has_impact or cfg.vfx_shader == "":
		return
	if not is_instance_valid(tower):
		return
	var shader = load(cfg.vfx_shader)
	if shader == null:
		return

	var spr := Sprite2D.new()
	spr.texture = _whiteQuad()
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("phase", 1.0)
	mat.set_shader_parameter("progress", 0.0)
	spr.material = mat
	spr.scale = Vector2.ONE * (cfg.get_impact_size() / IMPACT_QUAD_PX)
	tower.get_tree().root.add_child(spr)
	spr.global_position = at

	# Tween lives on the sprite: it freezes with the tree on pause and dies with the node.
	var t := spr.create_tween()
	t.tween_method(
		func(p: float): mat.set_shader_parameter("progress", p),
		0.0, 1.0, cfg.impact_time
	)
	t.tween_callback(spr.queue_free)

# Plain white carrier quad - the impact shader draws everything from UV, sampling nothing.
func _whiteQuad() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color.WHITE, Color.WHITE])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = int(IMPACT_QUAD_PX)
	tex.height = int(IMPACT_QUAD_PX)
	return tex

# Scales sprite + collision to cfg.size and pushes ONLY the shader-uniform overrides the
# YAML actually set (cfg.visual_overrides); anything omitted keeps the shader's own default.
# Duplicates the shared ShaderMaterial / CircleShape2D so per-bullet (and per-tower) tuning
# never mutates the scene's shared resources. Returns the per-bullet ShaderMaterial (null if
# the bullet has none) so the caller can drive per-frame uniforms on it.
func _applyBulletVisual(proj: Projectile, cfg: TowerAttackConfig) -> ShaderMaterial:
	var bullet_mat: ShaderMaterial = null
	for child in proj.get_children():
		if child is Sprite2D:
			var spr := child as Sprite2D
			var tex_h: float = float(spr.texture.get_height()) if spr.texture else 64.0
			spr.scale = Vector2.ONE * (cfg.size / max(tex_h, 1.0))
			if spr.material is ShaderMaterial:
				var mat := (spr.material as ShaderMaterial).duplicate() as ShaderMaterial
				spr.material = mat
				bullet_mat = mat
				for uniform_name in cfg.visual_overrides:
					mat.set_shader_parameter(uniform_name, cfg.visual_overrides[uniform_name])
		elif child is CollisionShape2D:
			var cs := child as CollisionShape2D
			if cs.shape is CircleShape2D:
				var shape := (cs.shape as CircleShape2D).duplicate() as CircleShape2D
				shape.radius = cfg.size * 0.5
				cs.shape = shape
	return bullet_mat
