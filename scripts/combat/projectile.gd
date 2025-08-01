extends Area2D
class_name Projectile

@export var speed: float = 300.0

var damage: Damage;
var shooter: Tower = null
var target: Enemy = null
var target_position: Vector2 = Vector2.ZERO
var move_direction: Vector2 = Vector2.ZERO
var moveType: ProjectileMoveType = ProjectileMoveType.Direction
var lifetime: float = 5.0
var statusEffects: Array[StatusEffect] = []

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

func _base_setup(shooter: Tower, damage: Damage, lifetime: float = 5.0, callback: ProjectileCallback = null):
	self.shooter = shooter
	self.damage = damage
	self.lifetime = lifetime
	self.callback = callback if callback else ProjectileCallback.new(Callable(), Callable(), Callable())

func setupTarget(shooter: Tower, target: Enemy, damage: Damage, lifetime: float = 5.0, callback: ProjectileCallback = null):
	_base_setup(shooter, damage, lifetime, callback)
	self.target = target
	moveType = ProjectileMoveType.Target
	rotation = Utility.get_angle_to_target(global_position, target.global_position)
	connect("area_entered", Callable(self, "onAreaEntered"))

func setupTargetPosition(shooter: Tower, target_position: Vector2, damage: Damage, lifetime: float = 5.0, callback: ProjectileCallback = null):
	_base_setup(shooter, damage, lifetime, callback)
	self.target_position = target_position
	moveType = ProjectileMoveType.Position
	rotation = Utility.get_angle_to_target(global_position, target_position)

func setup_direction(shooter: Tower, direction: Vector2, damage: Damage, lifetime: float = 5.0, callback: ProjectileCallback = null):
	_base_setup(shooter, damage, lifetime, callback)
	self.move_direction = direction.normalized()
	moveType = ProjectileMoveType.Direction
	rotation = Utility.get_angle_to_target(global_position, global_position + direction)
	connect("area_entered", Callable(self, "onAreaEntered"))

func setup_circle(shooter: Tower, damage: Damage, circle_radius: float = 100.0, angular_speed: float = 180.0, initial_angle: float = 0.0, lifetime: float = 5.0, callback: ProjectileCallback = null):
	_base_setup(shooter, damage, lifetime, callback)
	spawn_position = global_position
	self.circle_radius = circle_radius * GridHelper.CELL_SIZE
	self.circle_angle = initial_angle
	self.circle_angular_speed = angular_speed
	moveType = ProjectileMoveType.Circle
	connect("area_entered", Callable(self, "onAreaEntered"))

func setupStatusEffects(statusEffects: Array[StatusEffect]):
	if statusEffects:
		self.statusEffects = statusEffects

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
		if statusEffects:
			for effect in statusEffects:
				if effect and is_instance_valid(effect):
					enemy.statusEffects.addEffect(effect.duplicate(true))

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
