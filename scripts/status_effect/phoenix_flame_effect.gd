class_name PhoenixFlameEffect
extends StatusEffect

# Phoenix Flame DOT — Kiara debuff. First DOT in the project.
#
# Per-tick damage formula (magic type, routed through enemy magic resist):
#     dmg = (attackPercent × snapshotAttack) + (maxHpPercent × target.maxHp)
#
# Design decisions (locked):
# - Snapshot caster attack at apply time — DOT magnitude is predictable and
#   doesn't react to buffs applied after the cast (Dota Liquid Fire convention).
# - refresh_on_apply = true — container replaces existing phoenix_flame entry
#   so re-cast refreshes duration cleanly and array stays size 1 (also
#   side-steps the per-frame sort cost in _getStrongestEffect).
# - Damage.new(null, ...) — no live Tower needed by the receiver-side magic
#   resist pipeline; matches PoisonEffect pattern.
# - applier_ref is released to null after snapshot so the Resource is safe
#   to outlive the casting Tower (Resources can persist across scene churn).

@export var interval: float = 1.0
@export var attackPercent: float = 0.10
@export var maxHpPercent: float = 0.01

var snapshotAttack: float = 0.0
var applier_ref: Tower = null
var localElapsed: float = 0.0
var lastTriggered: float = 0.0

func _init(duration_: float = 5.0,
		interval_: float = 1.0,
		atkPct: float = 0.10,
		hpPct: float = 0.01) -> void:
	super._init(duration_, 1, "phoenix_flame")
	refresh_on_apply = true
	interval = interval_
	attackPercent = atkPct
	maxHpPercent = hpPct

# Called by the cast site (SkillActionAttack or Projectile.hitTarget) AFTER
# the effect is duplicated for this target and BEFORE addStatusEffect runs.
# Lets us snapshot caster-side state during _on_apply.
func set_applier(applier: Node) -> void:
	if applier is Tower:
		applier_ref = applier as Tower

func _on_apply(target: Node) -> void:
	super._on_apply(target)
	if is_instance_valid(applier_ref):
		snapshotAttack = float(applier_ref.data.getTotalAttack())
	# Release Tower ref — Resource may outlive caster, and we only needed
	# the snapshot. Per-tick damage no longer depends on applier liveness.
	applier_ref = null

func _process_effect(delta: float, target: Node) -> void:
	super._process_effect(delta, target)
	localElapsed += delta
	if localElapsed - lastTriggered < interval:
		return
	lastTriggered = localElapsed
	if not (target is Enemy):
		return
	var enemy: Enemy = target as Enemy
	# maxHp lives on EnemyStat (Resource on enemy.stats), NOT directly on Enemy.
	# Guard against null stats just in case (e.g., despawn race during tick).
	if enemy.stats == null:
		return
	var dmg: int = int(attackPercent * snapshotAttack + maxHpPercent * float(enemy.stats.maxHp))
	enemy.recvDamage(Damage.new(null, dmg, Damage.DamageType.MAGIC))
