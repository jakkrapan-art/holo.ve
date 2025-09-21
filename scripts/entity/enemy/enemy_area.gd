extends Area2D
class_name  EnemyArea

@onready var enemy: Enemy = $"..";

func addIncreaseMoveSpeed(value: float, key: String):
	enemy.addIncreaseMoveSpeed(value, key);

func removeIncreaseMoveSpeed(key: String):
	enemy.removeIncreaseMoveSpeed(key);