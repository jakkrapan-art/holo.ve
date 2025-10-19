class_name EnemyReward
extends RefCounted

var gold: int = 0
var evoToken: int = 0

func _init(gold: int, evoToken: int):
	self.gold = gold
	self.evoToken = evoToken