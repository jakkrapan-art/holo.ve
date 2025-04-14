class_name TowerStat
extends Resource

@export var pDamage: int = 4
@export var mDamage: int = 4
@export var attackSpeed: float = 0.5
@export var mana: int = 100
@export var intialMana: int = 10


func getAttackAnimationSpeed(anim: AnimatedSprite2D, name: String):
	var total_frames: int = anim.sprite_frames.get_frame_count(name)
	var base_fps: float = anim.sprite_frames.get_animation_speed(name)
	var animation_duration: float = total_frames / base_fps

	# Default speed scale is 1.0 (normal speed)
	var speed_scale := 1.0
	var attack_delay = getAttackDelay();
	# Only adjust speed if animation would take longer than attack delay
	if animation_duration > attack_delay:
		speed_scale = animation_duration / attack_delay
		
	return speed_scale

func getAttackDelay():
	return (100 + (100 - attackSpeed)) / 100;
