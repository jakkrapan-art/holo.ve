extends Resource
class_name Skill

@export var name:String = "Skill"
@export var desc:String = "Just a skill"
@export var cooldown:float = 5
@export var successChance:float = 1 #0-1
@export var actions: Array[Resource] = []
