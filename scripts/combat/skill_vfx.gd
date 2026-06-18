class_name SkillVfx

# Shared helpers for lane-static skill-VFX controllers (composition, NOT a base class -
# each controller keeps its own lifecycle/geometry/tweens). Pairs with the shader-side
# helpers in resources/tower/shared/lane_fx.gdshaderinc. See docs/shader.md "Skill-VFX
# families + checklist".

# Resolve the RAW aim vector for a lane effect, caster-agnostic (no `as Tower`, so a future
# non-Tower caster like a Staff works once SkillActionPlayEffect stops gating on Tower).
# Ladder: live locked target on the caster -> snapshotted aim_dir (survives the target
# dying mid-cast) -> ZERO. Un-normalized on purpose: each caller checks length() and applies
# its own "no aim" fallback (Kiara normal skips orienting; Kiara evo keeps facing RIGHT).
static func resolve_aim(caster, context) -> Vector2:
	if caster != null:
		var e = caster.get("enemy")
		if e != null and is_instance_valid(e):
			return e.global_position - caster.global_position
	if context != null and context.extra.has("aim_dir"):
		return context.extra["aim_dir"]
	return Vector2.ZERO

# Create a centred, click-through ColorRect running `shader_path`, parented to `parent`.
# Returns the rect; the caller sets effect-specific uniforms on `rect.material` and drives
# the tweens. (Uniforms set after add_child are fine - it is just material state.)
static func make_lane_rect(parent: Node, size: Vector2, shader_path: String) -> ColorRect:
	var rect := ColorRect.new()
	rect.size = size
	rect.position = -size * 0.5
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load(shader_path)
	rect.material = mat
	parent.add_child(rect)
	return rect
