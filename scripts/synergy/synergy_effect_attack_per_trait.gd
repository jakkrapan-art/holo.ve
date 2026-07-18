class_name SynergyEffectAttackPerTrait
extends SynergyEffect

# Hero - the first META synergy: the bonus scales with how many OTHER traits are
# active on the board, not with its own unit count. Every active trait (including
# Hero itself, and including declared-but-unwired placeholder traits) grants the
# Hero units +atk_per_trait% Physical Attack. Magic Attack is deliberately NOT
# granted (Director 2026-07-18) - do not "fix" it to match Tempus.
#
# The total is recomputed and re-applied under ONE source_id: attack_mult_up is a
# REFRESH effect, so re-applying overwrites the value (EffectContainer.apply).
# A per-trait source_id would SUM instead and double-count.

const _SOURCE := "synergy_hero"

func activate() -> void:
	_recompute()

# Defensive only: every trait activation happens inside a placement that ends in
# on_tower_added, so that hook alone is complete. Kept because _recompute is cheap
# and idempotent - not load-bearing.
func on_tier_changed(_new_tier: int) -> void:
	_recompute()

func on_tower_added(_tower) -> void:
	# Fires for EVERY placement, not just Hero units: someone else's placement is
	# what activates a new trait and raises the bonus. Traits are counted before
	# this hook runs (TowerFactory.getTower), so the recompute sees the new state.
	_recompute()

# Apply the current total to every Hero unit. Lifetime and duration are set
# explicitly: the registry def is WAVE with a non-zero duration, both wrong for a
# permanent synergy buff (same trap as synergy_effect_quest_tempus.gd).
func _recompute() -> void:
	var per_trait = data.get_parameter("atk_per_trait", 0)
	if per_trait == null:
		return
	var total := float(per_trait) * controller.active_synergy_count()
	if total <= 0.0:
		return
	for tower in controller.towers_with(data.synergy_id):
		if not is_instance_valid(tower):
			continue
		var inst := EffectUtility.make_instance("attack_mult_up", _SOURCE, total, 0.0)
		if inst == null:
			continue
		inst.lifetime = EffectTypes.Lifetime.BOARD
		tower.apply_effect(inst)
