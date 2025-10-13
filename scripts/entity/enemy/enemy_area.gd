extends Area2D
class_name  EnemyArea

@onready var enemy: Enemy = $"..";

func addIncreaseMoveSpeed(value: float, key: String):
	enemy.addIncreaseMoveSpeed(value, key);

func removeIncreaseMoveSpeed(key: String):
	enemy.removeIncreaseMoveSpeed(key);

func addBlockDamageCount(value: int):
	enemy.addBlockDamageCount(value);

func addIncreaseDef(value: float, key: String):
	enemy.addArmorPercent(value, key);

func removeIncreaseDef(key: String):
	enemy.removeArmorPercent(key);