extends Node
class_name EnemyFactory

@export var enemyTemplate: PackedScene;

# spawnScale: data-driven visual size from the enemy/boss YAML `scale:` key
# (root-node scale, so hitbox and overhead bar grow with the sprite).
# pathProgress: spawn mid-path (summons) - set BEFORE the process_frame await
# or the enemy renders one frame at the path start.
func createEnemy(type: Enemy.EnemyType, parent: Node2D, health: int, def: int, mDef: int, moveSpeed: int, texture: Texture2D, skillPool: Array[Skill] = [], damageReduction: float = 0.0, pathProgress: float = 0.0, spawnScale: float = 1.0):
	if(enemyTemplate == null):
		return;

	var enemy = enemyTemplate.instantiate() as Enemy;
	if spawnScale != 1.0:
		enemy.scale *= spawnScale;
	if(parent != null):
		parent.add_child(enemy);
		parent.move_child(enemy, 0);
		if pathProgress > 0.0:
			enemy.progress_ratio = clampf(pathProgress, 0.0, 0.999);

		await get_tree().process_frame
		enemy.setup(type, health, def, mDef, moveSpeed, texture, skillPool, damageReduction);

	return enemy

func addBuff(_count: int):
	pass

func addSkill(_count: int):
	pass
