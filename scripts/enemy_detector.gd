extends Area2D
class_name EnemyDetector

@export var radius: float = 3
@export var collision: CollisionShape2D;

var target: Enemy = null
var enemyInRange: Array[Enemy] = []

func _ready():
	collision.scale = Vector2.ONE * (radius * 2)
	connect("area_entered", Callable(self, "onCollisionHit"))
	connect("area_exited", Callable(self, "onCollisionExit"))

func _draw():
	if(target != null):
		var targetLocalPos = to_local(target.global_position);
		draw_line(position, targetLocalPos, Color.RED, 2.0)

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
	if(enemyInRange.size() == 0 || target != null):
		return;
	var currentDistance: Vector2 = Vector2.ZERO;
	
	for i in range(enemyInRange.size()):
		var enemy = enemyInRange[i];
		if !enemy:
			continue;

		var distance = position.direction_to(enemy.position);
		
		if target == null || currentDistance < distance:
			setTarget(enemy)
			currentDistance = distance;
	onEnemyDetected.emit(target)

func setTarget(enemy: Enemy):
	removeTarget();
	
	enemy.connect("onDead", Callable(self, "updateTarget"));
	target = enemy;

func removeTarget():
	if target == null:
		return;
	
	target.disconnect("onDead", Callable(self, "updateTarget"))
	target = null;

func isHasEnemy() -> bool:
	return target != null

signal onEnemyDetected(enemy: Entity)
