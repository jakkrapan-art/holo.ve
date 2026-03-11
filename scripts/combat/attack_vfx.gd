extends Node

var vfx_dict: Dictionary = {}

func _init() -> void:
	register_vfx("atk", preload("res://resources/tower/attack_vfx/atk_vfx1.tscn"))

func register_vfx(id: String, scene: PackedScene) -> void:
	vfx_dict[id] = scene

func play_vfx(id: String, position: Vector2, direction: Global.DIRECTION, parent: Node = get_tree().current_scene) -> void:
	if !vfx_dict.has(id):
		push_warning("VFX not found: " + id)
		return

	var vfx_scene: PackedScene = vfx_dict[id]
	var vfx = vfx_scene.instantiate()

	parent.add_child(vfx);
	vfx.play_animation(direction);
	vfx.global_position = position