class_name AnimationController

var list: Array[String];
var default: String;
var current: String;
var anim: AnimatedSprite2D;

func _init(animSprite: AnimatedSprite2D, defaultAnimation: String, animationList: Array[String]):
	list = animationList;
	anim = animSprite;
	default = defaultAnimation;
	
	#anim.connect("animation_finished", Callable(self, "anim_finish"))
	Utility.ConnectSignal(anim,"frame_changed", Callable(self, "anim_finish"))
	play(defaultAnimation);

func playDefault():
	play(default);

func play(animationName: String, speed: float = 1):
	if(!list.has(animationName)):
		return false;

	if(animationName == current):
		anim.play(default);
	anim.speed_scale = speed;
	current = animationName;
	anim.play(current);
	
	return true;

func anim_finish():
	var currFrame: float = anim.frame;
	var maxFrame: float = anim.sprite_frames.get_frame_count(current) - 1;
	if (currFrame / maxFrame > 0.8):
		on_animation_finished.emit(anim.animation);	

signal on_animation_finished(name: String)
