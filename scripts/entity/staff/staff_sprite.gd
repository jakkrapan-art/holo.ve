class_name StaffSprite
extends AnimatedSprite2D

# Animated sprite that visualizes the Staff at the path endpoint.
# Different staffs swap this scene via StaffData.end_sprite_scene; the script
# itself only handles default-animation playback.

@export var animationName = "";
var animationController: AnimationController;

func _ready() -> void:
	animationController = AnimationController.new(self, animationName);
