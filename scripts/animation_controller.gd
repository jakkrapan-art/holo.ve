class_name AnimationController

var default: String;
var current: String;
var anim: AnimatedSprite2D;

func _init(animSprite: AnimatedSprite2D, defaultAnimation: String):
	anim = animSprite;
	default = defaultAnimation if defaultAnimation != "" else "idle";
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

# Weighted clip length in seconds: per-frame duration multipliers count (a frame
# with duration 2.0 lasts two frame units), so this matches what the sprite
# actually plays - never frame_count / fps, which ignores artist frame holds.
func get_native_duration(name: String) -> float:
	var fps: float = anim.sprite_frames.get_animation_speed(name) if anim.sprite_frames.has_animation(name) else 0.0;
	if fps <= 0.0:
		return 0.0;
	return get_weighted_frames(name) / fps;

# Sum of per-frame duration weights for a clip.
func get_weighted_frames(name: String) -> float:
	if not anim.sprite_frames.has_animation(name):
		return 0.0;
	var total: float = 0.0;
	for i in anim.sprite_frames.get_frame_count(name):
		total += anim.sprite_frames.get_frame_duration(name, i);
	return total;

# Impact frame for a skill beat, 0-based. An authored 1-based impact_frame wins
# (clamped into range); unset (<= 0) falls back to the first frame whose
# cumulative weight reaches 80% of the clip's weighted length - the legacy
# impact point, now duration-aware.
func resolve_impact_frame(name: String, impact_frame: int) -> int:
	if not anim.sprite_frames.has_animation(name):
		return 0;
	var count: int = anim.sprite_frames.get_frame_count(name);
	if count <= 0:
		return 0;
	if impact_frame > 0:
		if impact_frame > count:
			push_warning("impact_frame " + str(impact_frame) + " > frame count " + str(count) + " on '" + name + "' - clamped to the last frame");
		return clampi(impact_frame - 1, 0, count - 1);
	var target: float = get_weighted_frames(name) * 0.8;
	var cum: float = 0.0;
	for i in count:
		cum += anim.sprite_frames.get_frame_duration(name, i);
		if cum >= target:
			return i;
	return count - 1;

func is_looping(name: String) -> bool:
	return anim.sprite_frames.has_animation(name) and anim.sprite_frames.get_animation_loop(name);

# Waits until the playing clip `name` reaches frame index `frame_idx` (or has
# already stopped). Returns false when the clip was switched away or the sprite
# died mid-wait - the caller cancels its beat. State-poll on process_frame, so
# it can never hang: tree pause freezes the sprite (the poll just keeps
# re-checking) and x2 speed advances it faster, both for free.
func wait_frame(name: String, frame_idx: int) -> bool:
	while true:
		if not is_instance_valid(anim):
			return false;
		if anim.animation != name:
			return false;
		if anim.frame >= frame_idx:
			return true;
		if not anim.is_playing():
			return true;
		var tree = anim.get_tree();
		if tree == null:
			return false;
		await tree.process_frame;
	return false;

# Waits until the non-looping clip `name` finishes (or was switched away).
# Same no-hang state-poll as wait_frame; a looping clip returns immediately -
# it would never finish, and loop+cast_time is already warned as an authoring
# error at the beat level.
func wait_clip_end(name: String) -> void:
	if is_looping(name):
		return;
	while true:
		if not is_instance_valid(anim):
			return;
		if anim.animation != name:
			return;
		if not anim.is_playing():
			return;
		var tree = anim.get_tree();
		if tree == null:
			return;
		await tree.process_frame;

func has_animation(name: String) -> bool:
	return anim.sprite_frames.has_animation(name);
