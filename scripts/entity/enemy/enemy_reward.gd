class_name EnemyReward
extends RefCounted

var gold: int = 0
var evoToken: int = 0

func _init(p_gold: int, p_evoToken: int):
	self.gold = p_gold
	self.evoToken = p_evoToken