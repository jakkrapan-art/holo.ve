extends Area2D
class_name Projectile

@export var speed: float = 300.0
# When true, hitTarget gates each Enemy by instance_id so the same enemy
# can only be hit once per projectile lifetime. Used by directional pierce
# projectiles (Kiara Hinotori) to prevent re-hit when an enemy moves through
# the Area2D and re-triggers area_entered. Default false preserves Gura
# circle projectile behavior (orbital may legitimately hit same enemy across
# revolutions if designer wants — kept as opt-in).
@export var prevent_rehit: bool = false

var damage: Damage;
var shooter: Tower = null
var target: Enemy = null

func _ready() -> void:
	# Lets towers locate their own in-flight projectiles for wave-end cleanup.
	add_to_group("projectile")

var target_position: Vector2 = Vector2.ZERO
var move_direction: Vector2 = Vector2.ZERO
var moveType: ProjectileMoveType = ProjectileMoveType.Direction
var lifetime: float = 5.0
var statusEffects: Array[StatusEffect] = []
var _hit_ids: Dictionary = {}  # enemy.instance_id → true; used when prevent_rehit

# for circle movement
var spawn_position: Vector2 = Vector2.ZERO
var circle_radius: float = 100.0
var circle_angle: float = 0.0
var circle_angular_speed: float = 180.0  # Degrees per second

enum ProjectileMoveType
{
	Target, Position, Direction, Circle
}

# New Modifier Callable
var callback: ProjectileCallback = null

func _base_setup(p_shooter: Tower, p_damage: Damage, p_lifetime: float = 5.0, p_callback: ProjectileCallback = null):
	self.shooter = p_shooter
	self.damage = p_damage
	self.lifetime = p_lifetime
	self.callback = p_callback if p_callback else ProjectileCallback.new(Callable(), Callable(), Callable())

func setupTarget(p_shooter: Tower, p_target: Enemy, p_damage: Damage, p_lifetime: float = 5.0, p_callback: ProjectileCallback = null):
	_base_setup(p_shooter, p_damage, p_lifetime, p_callback)
	self.target = p_target
	moveType = ProjectileMoveType.Target
	rotation = Utility.get_angle_to_target(global_position, p_target.global_position)
	connect("area_entered", Callable(self, "onAreaEntered"))

func setupTargetPosition(p_shooter: Tower, p_target_position: Vector2, p_damage: Damage, p_lifetime: float = 5.0, p_callback: ProjectileCallback = null):
	_base_setup(p_shooter, p_damage, p_lifetime, p_callback)
	self.target_position = p_target_position
	moveType = ProjectileMoveType.Position
	rotation = Utility.get_angle_to_target(global_position, p_target_position)

func setup_direction(p_shooter: Tower, direction: Vector2, p_damage: Damage, p_lifetime: float = 5.0, p_callback: ProjectileCallback = null):
	_base_setup(p_shooter, p_damage, p_lifetime, p_callback)
	self.move_direction = direction.normalized()
	moveType = ProjectileMoveType.Direction
	rotation = Utility.get_angle_to_target(global_position, global_position + direction)
	connect("area_entered", Callable(self, "onAreaEntered"))

func setup_circle(p_shooter: Tower, p_damage: Damage, p_circle_radius: float = 100.0, angular_speed: float = 180.0, initial_angle: float = 0.0, p_lifetime: float = 5.0, p_callback: ProjectileCallback = null):
	_base_setup(p_shooter, p_damage, p_lifetime, p_callback)
	spawn_position = global_position
	self.circle_radius = p_circle_radius * GridHelper.CELL_SIZE
	self.circle_angle = initial_angle
	self.circle_angular_speed = angular_speed
	moveType = ProjectileMoveType.Circle
	connect("area_entered", Callable(self, "onAreaEntered"))

func setupStatusEffects(p_statusEffects: Array[StatusEffect]):
	if p_statusEffects:
		self.statusEffects = p_statusEffects

func _process(delta: float) -> void:
	match moveType:
		ProjectileMoveType.Target:
			processMoveToTarget(delta)
		ProjectileMoveType.Position:
			processMoveToPosition(delta)
		ProjectileMoveType.Direction:
			processMoveByDirection(delta)
		ProjectileMoveType.Circle:
			processCircleMovement(delta)
		_:
			queue_free();

	if callback and callback.onMove.is_valid():
		callback.onMove.call(self)
	processLifetime(delta);

func processMoveToTarget(delta: float):
	if not is_instance_valid(target):
		queue_free()
		return

	var direction = (target.global_position - global_position).normalized()
	rotation = Utility.get_angle_to_target(global_position, target.global_position)
	global_position += direction * speed * delta

func processMoveToPosition(delta: float):
	if target_position == Vector2.ZERO:
		queue_free()
		return

	var direction = (target_position - global_position).normalized()
	global_position += direction * speed * delta

	if global_position.distance_to(target_position) < 5.0:
		# hitTarget(target.area)
		if callback and callback.onHit.is_valid():
			callback.onHit.call(target)
		queue_free()

func processMoveByDirection(delta: float):
	global_position += move_direction.normalized() * speed * delta

func processCircleMovement(delta: float):
	circle_angle += circle_angular_speed * delta
	if circle_angle >= 360.0:
		circle_angle -= 360.0

	var rad = deg_to_rad(circle_angle)
	global_position = spawn_position + Vector2(cos(rad), sin(rad)) * circle_radius
	rotation = rad + PI / 2  # Optional: rotate to face tangent of the circle

func processLifetime(delta: float):
	if lifetime < 0:
		return  # Infinite lifetime, do nothing

	lifetime -= delta
	if lifetime <= 0:
		if callback and callback.onExpire.is_valid():
			callback.onExpire.call()
		queue_free()

func hitTarget(hit_area: EnemyArea):
	var enemy = hit_area.enemy
	if enemy and is_instance_valid(enemy):
		# Pierce re-hit guard: skip if this enemy has already been hit by
		# this projectile and prevent_rehit is on.
		if prevent_rehit:
			var key: int = enemy.get_instance_id()
			if _hit_ids.has(key):
				return
			_hit_ids[key] = true

		if statusEffects:
			for effect in statusEffects:
				if effect and is_instance_valid(effect):
					var dup_effect = effect.duplicate(true)
					# Snapshot caster-side state for effects that need it
					# (e.g., PhoenixFlame reads applier.totalAttack at apply).
					if shooter and is_instance_valid(shooter):
						dup_effect.set_applier(shooter)
					enemy.addStatusEffect(dup_effect)

	if moveType == ProjectileMoveType.Target:
		if target and is_instance_valid(target) and hit_area == target.area:
			if callback and callback.onHit.is_valid():
				callback.onHit.call(self, target)
			queue_free()
	else:
		if hit_area:
			if callback and callback.onHit.is_valid():
				callback.onHit.call(self, enemy)

func onAreaEntered(area: Area2D):
	if not is_instance_valid(area) || area == self || area == shooter || not area is EnemyArea:
		return

	if moveType == ProjectileMoveType.Target:
		if is_instance_valid(target) and area == target.area:
			hitTarget(area as EnemyArea)
			queue_free()
	else:
		hitTarget(area as EnemyArea)
		if(lifetime < 0):
			queue_free()
