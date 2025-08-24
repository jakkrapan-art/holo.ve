class_name BossDBData

var name: String
var texture: Texture2D
var scale: float
var stats: Dictionary

func _init(boss_name: String, boss_texture: Texture2D, boss_scale: float, boss_stats: Dictionary):
	self.name = boss_name
	self.texture = boss_texture
	self.scale = boss_scale
	self.stats = boss_stats
