extends Node

enum AttackVFXName {
	DEFAULT,
	BLUE
}

var vfx_dict: Dictionary = {}

func _init() -> void:
	register_vfx(AttackVFXName.DEFAULT, preload("res://resources/tower/attack_vfx/atk_vfx1.tscn"))
	register_vfx(AttackVFXName.BLUE, preload("res://resources/tower/attack_vfx/atk_vfx_blue.tscn"))

func register_vfx(id: AttackVFXName, scene: PackedScene) -> void:
	vfx_dict[id] = scene

func play_vfx(id: AttackVFXName, position: Vector2, direction: Global.DIRECTION, parent: Node = get_tree().current_scene) -> void:
	if !vfx_dict.has(id):
		push_warning("VFX not found: " + str(id))
		return

	var vfx_scene: PackedScene = vfx_dict[id]
	var vfx = vfx_scene.instantiate()

	parent.add_child(vfx);
	vfx.play_animation(direction);
	vfx.global_position = position