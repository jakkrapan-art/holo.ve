class_name FrameArea
extends EffectArea

@export var radius: float = 2.0
@export var damage: int = 1;
@export var interval: float = 1.0;

var enemyList: Array[Enemy] = [];
var lastTick: float = 0.0;

func _ready():
	setup(radius, EffectAreaCallback.new(Callable(self, "enemyEntered"), Callable(self, "enemyExited")))

func setup(radius: float = 2.0, callback: EffectAreaCallback = EffectAreaCallback.new(Callable(), Callable())):
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius * GridHelper.CELL_SIZE

	_base_setup(circle_shape, callback)

func _process(delta: float):
	damageInArea(delta);

func damageInArea(delta: float):
	var currTick: float = Time.get_ticks_msec() / 1000.0;

	if lastTick + interval > currTick:
		return;

	lastTick = currTick;
	for enemy in enemyList:
		if is_instance_valid(enemy):
			enemy.recvDamage(Damage.new(null, damage, Damage.DamageType.MAGIC));
		else:
			enemyList.erase(enemy);

func enemyEntered(area: Area2D):
	if area is EnemyArea:
		var enemy_area: EnemyArea = area
		if enemy_area.enemy:
			enemyList.append(enemy_area.enemy)

func enemyExited(area: Area2D):
	if area is EnemyArea:
		var enemy_area: EnemyArea = area
		if enemy_area.enemy && enemyList.has(enemy_area.enemy):
			enemyList.erase(enemy_area.enemy)

func _draw():
	var circleColor = Color.INDIAN_RED
	circleColor.a = 0.15

	var draw_radius = radius * GridHelper.CELL_SIZE
	draw_circle(position, draw_radius, circleColor)
