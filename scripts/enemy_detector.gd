extends Area2D
class_name EnemyDetector

@export var radius: float = 3
@export var collision: CollisionShape2D;

var target: Enemy = null
var enemyInRange: Array[Enemy] = []

func _ready():
	collision.scale = Vector2.ONE * (radius)
	connect("area_entered", Callable(self, "onCollisionHit"))
	connect("area_exited", Callable(self, "onCollisionExit"))

func _draw():
	if(target != null):
		var targetLocalPos = to_local(target.global_position);
		draw_line(position, targetLocalPos, Color.RED, 2.0)
	
	var circleColor = Color.SPRING_GREEN;
	circleColor.a = 0.2;
	draw_circle(position, 12.5 * radius, circleColor);

func _process(delta):
	queue_redraw();

func onCollisionHit(area: Area2D):
	if area.is_in_group("enemy"):
		var eArea = area as EnemyArea
		if(eArea):
			enemyInRange.append(eArea.enemy)
			pass
	
	updateTarget();

func onCollisionExit(area: Area2D):
	if(area.is_in_group("enemy")):
		var eArea = area as EnemyArea
		if(eArea):
			var enemy = eArea.enemy;
			if(enemy == target):
				target = null

			if(enemyInRange.has(enemy)):
				for i in range(enemyInRange.size()):
					if(enemyInRange[i] == enemy):
						enemyInRange.remove_at(i);
						break

			updateTarget();

func updateTarget():
	if(enemyInRange.size() == 0):
		setTarget(null);
		onEnemyDetected.emit(null);
		return;

	var currentDistance: float = 0;
	
	for i in range(enemyInRange.size()):
		var enemy = enemyInRange[i];
		if !enemy:
			continue;

		var distance = enemy.progress_ratio;
		
		if distance > currentDistance:
			setTarget(enemy)
			currentDistance = distance;
	onEnemyDetected.emit(target)

func setTarget(enemy: Enemy):
	removeTarget();
	if(enemy != null):
		enemy.connect("onDead", Callable(self, "updateTarget"));
		target = enemy;

func removeTarget():
	if target == null:
		return;
	
	target.disconnect("onDead", Callable(self, "updateTarget"))
	target = null;
	onRemoveTarget.emit();

func isHasEnemy() -> bool:
	return target != null

signal onEnemyDetected(enemy: Entity);
signal onRemoveTarget();
