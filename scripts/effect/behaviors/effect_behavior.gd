class_name EffectBehavior
extends RefCounted

# Strategy object for non-stat effect kinds (stun, DOT, ...). Attached to an
# EffectInstance at build time; the container calls the hooks. Behaviors must
# guard the host (is_instance_valid) - the container may outlive the node.
#
# Generic tint support: a def with params.tint_modulate ("r,g,b") tints the
# host sprite on apply and restores it on expire, keeping originalModulate in
# sync so damage flashes restore to the tinted color (legacy
# dmg_reduction_buff behavior).

func on_apply(host: Node, inst: EffectInstance) -> void:
	_apply_tint(host, inst)

func on_expire(host: Node, inst: EffectInstance) -> void:
	_restore_tint(host, inst)

func process(_delta: float, _host: Node, _inst: EffectInstance) -> void:
	pass

# Snapshot caster-dependent data into inst.snapshot; never keep the ref.
func capture(_applier: Node, _inst: EffectInstance) -> void:
	pass

func _apply_tint(host: Node, inst: EffectInstance) -> void:
	var tint := str(inst.def.params.get("tint_modulate", ""))
	if tint == "" or host == null or not is_instance_valid(host):
		return
	var parts := tint.split(",")
	if parts.size() < 3:
		return
	var color := Color(float(parts[0]), float(parts[1]), float(parts[2]))
	if "sprite" in host and host.sprite != null:
		host.sprite.modulate = color
		if "originalModulate" in host:
			inst.snapshot["prev_modulate"] = host.originalModulate
			host.originalModulate = color

func _restore_tint(host: Node, inst: EffectInstance) -> void:
	if not inst.snapshot.has("prev_modulate") or host == null or not is_instance_valid(host):
		return
	var prev: Color = inst.snapshot["prev_modulate"]
	if "originalModulate" in host:
		host.originalModulate = prev
	if "sprite" in host and host.sprite != null:
		host.sprite.modulate = prev
