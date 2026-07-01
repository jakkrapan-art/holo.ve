class_name SkillActionPlayEffect
extends SkillAction

@export var effectScriptPath: String = ""

func execute(context: SkillContext) -> void:
	var tower := context.user as Tower
	if tower == null || effectScriptPath == "":
		return

	var script = load(effectScriptPath)
	if script == null:
		push_error("SkillActionPlayEffect: script not found at ", effectScriptPath)
		return

	var effect := Node2D.new()
	effect.set_script(script)
	effect.global_position = tower.global_position
	tower.get_parent().add_child(effect)

	# Optional aim hook: directional effects (e.g. Kiara Flame Slash) implement
	# setup(tower) to rotate/offset themselves toward tower.enemy. Self-centered
	# effects (e.g. Amelia) omit it and stay put — backward compatible.
	if effect.has_method("setup"):
		effect.setup(tower, context)
