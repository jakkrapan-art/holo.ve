class_name SkillActionField
extends SkillActionChannel

# "field" execution pattern (tower_skill.md): a NON-BLOCKING, self-centered,
# persistent damaging + debuffing zone. Unlike "channel" (which BLOCKS the
# caster for the whole duration), the field is planted and execute() returns
# immediately - the tower resumes auto-attack while the zone ticks on its own,
# exactly like "aftershock". It reuses channel's ChannelTicker verbatim (the
# generation / in_flight defer-free / re-entrancy guard cluster stays in ONE
# place); the only deltas are: no await (non-blocking), no self-played cast
# clip, and an optional Energy refund to the caster on natural expiry.
# First user: Banzoin Hakka "Exocirst Field".
#
# castTime (inherited from SkillActionChannel) is reused as the field LIFETIME
# (the tick-sequence duration). tick_interval / width / height / find_action /
# attack_action are inherited and set by the parser (skill_utility.gd).
#
# YAML: width, height, duration/duration_param_name (-> castTime),
#   tick_interval/tick_interval_param_name, energy_refund_percent/
#   energy_refund_percent_param_name, plus the full "attack" key set
#   (damage_multiplier_param_name, damage_type, can_crit, effects) reused each
#   tick. Reference: resources/database/towers/banzoin_hakka.yaml.

@export var energyRefundPercent: float = 0.0

func execute(context: SkillContext):
	var tower: Tower = context.user as Tower
	if tower == null or find_action == null or attack_action == null:
		return
	var gen: int = tower.skill_lock_generation
	var ticker := SkillActionChannel.ChannelTicker.new()
	# Self-centered zone: the ticker re-queries an axis-aligned box centered on
	# this point each tick (its target_position override), so a stationary tower
	# keeps the field on itself with no aim snapshot.
	ticker.setup(self, tower, gen, tower.global_position,
			context.extra.get("parameter", {}), context.skillName)
	tower.add_child(ticker)
	Utility.ConnectSignal(ticker, "finished",
			Callable(self, "_on_field_finished").bind(ticker, tower, gen))
	# No await: the cast finishes normally while the field ticks (aftershock model).

# The ticker emits "finished" exactly once (channel's `done` once-guard) on
# EVERY exit path - natural end, wave-end generation bump, and external free.
# Refund only on natural expiry: all ticks fired AND the tower still alive on
# the same generation (a cancel path fails one of these checks, so no refund
# ever leaks into the next wave). updateMana clamps at maxMana, so a refund
# arriving after a re-cast already refilled Energy is a harmless no-op.
func _on_field_finished(ticker: SkillActionChannel.ChannelTicker, tower: Tower, gen: int) -> void:
	if energyRefundPercent <= 0.0:
		return
	if not is_instance_valid(ticker) or ticker.ticks_fired < ticker.total_ticks:
		return
	if not is_instance_valid(tower) or tower.skill_lock_generation != gen:
		return
	if tower.skillController == null:
		return
	var refund: int = int(round(tower.skillController.maxMana * energyRefundPercent))
	if refund > 0:
		tower.skillController.updateMana(refund)
