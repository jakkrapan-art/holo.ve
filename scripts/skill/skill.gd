extends Resource
class_name Skill

enum TARGET_TYPE {ENEMY, FRIENDLY}

@export var name:String = "Skill"
@export var desc:String = "Just a skill"
@export var actions: Array[SkillAction] = []
@export var parameters: Dictionary = {}
