class_name TowerStat
extends Resource

@export var damage: int = 4
@export var attackRange: float = 1.0
@export var attackSpeed: float = 100.0
@export var critChance: float = 15.0
@export var critMultiplier: float = 1.5
@export var mana: int = 100
@export var initialMana: int = 10

func getAttackAnimationSpeed(anim: AnimatedSprite2D, name: String, attack_delay: float) -> float:
	# Weighted frames (per-frame duration multipliers count), matching what the
	# sprite actually plays - frame_count alone ignores artist frame holds.
	var total_frames: int = anim.sprite_frames.get_frame_count(name)
	var base_fps: float = anim.sprite_frames.get_animation_speed(name)
	if total_frames <= 0 or base_fps <= 0.0:
		return 1.0
	var weighted_frames: float = 0.0
	for i in total_frames:
		weighted_frames += anim.sprite_frames.get_frame_duration(name, i)
	var animation_duration: float = weighted_frames / base_fps

	var speed_scale := 1.0
	if animation_duration > attack_delay:
		speed_scale = (animation_duration * 1.01) / attack_delay

	return speed_scale
