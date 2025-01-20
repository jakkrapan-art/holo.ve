extends Node
class_name EnemyFactory

@export var enemyTemplate: PackedScene;

func getEnemy(type: Enemy.EnemyType):
	if(enemyTemplate == null):
		return;
	
	var enemy = enemyTemplate.instantiate() as Enemy;
	match type:
		Enemy.EnemyType.Normal:
			pass;
		Enemy.EnemyType.Elite:
			pass;
		Enemy.EnemyType.Boss:
			pass;
	
	return enemy
