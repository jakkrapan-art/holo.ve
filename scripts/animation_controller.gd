class_name AnimationController

var default: String;
var current: String;
var anim: AnimatedSprite2D;

func _init(animSprite: AnimatedSprite2D, defaultAnimation: String):
	anim = animSprite;
	default = defaultAnimation if defaultAnimation != "" else "idle";

	# frame_changed drives the ~80% early finish; animation_finished is a backstop so a
	# 1-frame clip (which never emits frame_changed) still resolves and can't hang a skill.
	Utility.ConnectSignal(anim,"frame_changed", Callable(self, "anim_finish"))
	Utility.ConnectSignal(anim,"animation_finished", Callable(self, "anim_finish"))
	play(defaultAnimation);

func playDefault():
	play(default);

func play(animationName: String, speed: float = 1):
	if(animationName == current):
		anim.play(default);
	anim.speed_scale = speed;
	current = animationName;
	anim.play(current);

	return true;

func anim_finish():
	var maxFrame: float = anim.sprite_frames.get_frame_count(current) - 1;
	if maxFrame <= 0:
		# 1-frame clip (maxFrame == 0 -> 0/0 = NaN) or missing clip (count 0 -> -1):
		# treat as instantly finished so a skill await never hangs.
		on_animation_finished.emit(anim.animation);
		return;
	var currFrame: float = anim.frame;
	if (currFrame / maxFrame > 0.8):
		on_animation_finished.emit(anim.animation);

func get_native_duration(name: String) -> float:
	if not anim.sprite_frames.has_animation(name):
		return 0.0;
	var frames: int = anim.sprite_frames.get_frame_count(name);
	var fps: float = anim.sprite_frames.get_animation_speed(name);
	if frames <= 0 or fps <= 0.0:
		return 0.0;
	return frames / fps;

func has_animation(name: String) -> bool:
	return anim.sprite_frames.has_animation(name);

signal on_animation_finished(name: String)
