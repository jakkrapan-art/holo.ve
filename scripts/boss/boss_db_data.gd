class_name BossDBData

var name: String
var texture: Texture2D
var scale: float
var stats: Dictionary
var skills: Array[Skill] = []

func _init(boss_name: String, boss_texture: Texture2D, boss_scale: float, boss_stats: Dictionary, boss_skills: Array[Skill] = []):
	self.name = boss_name
	self.texture = boss_texture
	self.scale = boss_scale
	self.stats = boss_stats
	self.skills = boss_skills
