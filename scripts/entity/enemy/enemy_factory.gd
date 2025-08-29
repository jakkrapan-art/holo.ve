extends Node
class_name EnemyFactory

@export var enemyTemplate: PackedScene;

func createEnemy(type: Enemy.EnemyType, parent: Node2D, health: int, def: int, mDef: int, moveSpeed: int, texture: Texture2D, skillPool: Array[Skill] = []):
	if(enemyTemplate == null):
		return;

	var enemy = enemyTemplate.instantiate() as Enemy;
	match type:
		Enemy.EnemyType.Elite:
			enemy.scale *= 1.25;
		Enemy.EnemyType.Boss:
			enemy.scale *= 1.7;

	if(parent != null):
		parent.add_child(enemy);
		await get_tree().process_frame
		enemy.setup(health, def, mDef, moveSpeed, texture, skillPool);

	return enemy

func addBuff(count: int):
	pass

func addSkill(count: int):
	pass
