extends Resource
class_name Skill

enum TARGET_TYPE {ENEMY, FRIENDLY}

@export var name:String = "Skill"
@export var desc:String = "Just a skill"
@export var actions: Array[SkillAction] = []
@export var parameters: Dictionary = {}

func _init(name:String="Skill", desc:String="Just a skill", actions:Array[SkillAction]=[], parameters:Dictionary={}):
	self.name = name;
	self.desc = desc;
	self.actions = actions;
	self.parameters = parameters;

var using = false;

func isReady():
	return !using;
