class_name Manager
extends AnimatedSprite2D

@export var animationName = "";
var animationController: AnimationController;

func _ready() -> void:
	animationController = AnimationController.new(self, animationName, ["a_chan"]);