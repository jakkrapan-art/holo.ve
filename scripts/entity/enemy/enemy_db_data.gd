class_name EnemyDBData

# One enemy definition from the map's enemy roster
# (resources/database/enemy/<map>/<tier>/<id>.yaml). Mirrors BossDBData:
# stats is a plain Dictionary { hp, def, mDef, moveSpeed }.
var id: String
var tier: String                 # "normal" / "elite" / "boss" - drives sprite path + leak damage
var stats: Dictionary
var skills: Array[Skill] = []

func _init(p_id: String, p_tier: String, p_stats: Dictionary, p_skills: Array[Skill] = []):
	self.id = p_id
	self.tier = p_tier
	self.stats = p_stats
	self.skills = p_skills
