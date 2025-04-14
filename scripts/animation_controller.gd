class_name AnimationController

var list: Array[String];
var default: String;
var current: String;
var anim: AnimatedSprite2D;

func _init(animSprite: AnimatedSprite2D, defaultAnimation: String, animationList: Array[String]):
	list = animationList;
	anim = animSprite;
	default = defaultAnimation;
	
	play(defaultAnimation);

func playDefault():
	play(default);

func play(animationName: String, speed: float = 1):
	if(!list.has(animationName)):
		return;

	if(animationName == current):
		anim.play(default);

	anim.speed_scale = speed;
	current = animationName;
	anim.play(current);
