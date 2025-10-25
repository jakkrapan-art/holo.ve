extends Resource
class_name Skill

enum TARGET_TYPE {ENEMY, FRIENDLY}

@export var name:String = "Skill"
@export var desc:String = "Just a skill"
@export var oneTimeUse: bool = false
@export var actions: Array[SkillAction] = []
@export var parameters: Dictionary = {}
var using = false;

func _init(name:String="Skill", desc:String="Just a skill", actions:Array[SkillAction]=[], parameters:Dictionary={}, oneTimeUse: bool = false):
	self.name = name;
	self.desc = desc;
	self.actions = actions;
	self.parameters = parameters;
	self.oneTimeUse = oneTimeUse;

func isReady():
	return !using;
