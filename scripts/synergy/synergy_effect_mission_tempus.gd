class_name SynergyEffectMissionTempus
extends SynergyEffect

# Tempus - the first mission-type synergy. Reaching a unit threshold (2/4/6) opens a
# Guild Mission (cumulative kill goal 100/200/400); completing it unlocks a reward
# that STACKS on the lower tiers (each tier = its own effect source_id, so they
# SUM rather than replace). Kill count starts when Tempus first activates (2 units)
# and lives here in the effect; SynergyController is run-level, so it persists
# across waves (never reset per wave). Rewards are BOARD-lifetime (survive wave
# reset by construction).
#
#   Tier 0 (2 units, 100 kills): Tempus units +atk_bonus% Physical & Magic Attack
#   Tier 1 (4 units, 200 kills): Tempus units +as_bonus Attack Speed
#   Tier 2 (6 units, 400 kills): ALL field units regain energy_percent of max
#                                Energy every energy_interval seconds (in tick)

const _SOURCE_PREFIX := "synergy_tempus_t"

var _kills: int = 0
var _rewarded := [false, false, false]
var _energy_timer: float = 0.0

func activate() -> void:
	# Guild formed (2 Tempus units): start the tracker at 0.
	controller.report_mission_progress(data.synergy_id, _kills)

func on_enemy_killed(_enemy, _cause, _reward) -> void:
	_kills += 1
	controller.report_mission_progress(data.synergy_id, _kills)
	_check_rewards()

func on_tier_changed(_new_tier: int) -> void:
	# A newly reached unit threshold can retro-unlock a reward whose kill goal is
	# already met (two-gate: needs both enough kills AND enough units).
	_check_rewards()

func on_tower_added(tower) -> void:
	if tower == null or tower.data == null:
		return
	if tower.data.towerClass != data.synergy_id and tower.data.generation != data.synergy_id:
		return
	# Give the newcomer the Tempus rewards already earned (idempotent per source).
	if _rewarded[0]:
		_apply_tier_stat(0, [tower])
	if _rewarded[1]:
		_apply_tier_stat(1, [tower])

func tick(delta: float) -> void:
	if not _rewarded[2]:
		return
	var interval := float(data.get_parameter("energy_interval", 2))
	if interval <= 0.0:
		return
	_energy_timer += delta
	while _energy_timer >= interval:
		_energy_timer -= interval
		_grant_energy_pulse()

# Grant every tier whose kill goal is met AND whose unit threshold is active.
func _check_rewards() -> void:
	var tier: int = controller.active_tier(data.synergy_id)
	for t in range(3):
		if _rewarded[t]:
			continue
		var goal = data.get_parameter("mission_kills", t)
		if goal == null:
			continue
		if _kills >= int(goal) and tier >= t:
			_grant(t)
			_rewarded[t] = true

func _grant(t: int) -> void:
	match t:
		0, 1:
			_apply_tier_stat(t, controller.towers_with(data.synergy_id))
		2:
			# T3 is the recurring energy pulse (handled in tick). Reset the timer so
			# the first pulse lands one full interval after unlock.
			_energy_timer = 0.0

# Apply tier t's BOARD stat buff(s) to the given towers. Each tier uses its own
# source_id so tiers SUM (stack) instead of refresh-overwriting each other.
# lifetime + duration are set explicitly: the registry defs are WAVE with a
# non-zero default duration, both wrong for a permanent synergy reward.
func _apply_tier_stat(t: int, towers: Array) -> void:
	var source := _SOURCE_PREFIX + str(t + 1)
	var specs: Array = []
	match t:
		0:
			var atk = data.get_parameter("atk_bonus", 0)
			specs = [["attack_mult_up", atk], ["magic_mult_up", atk]]
		1:
			specs = [["attack_speed_up", data.get_parameter("as_bonus", 1)]]
	for tower in towers:
		if not is_instance_valid(tower):
			continue
		for spec in specs:
			var inst := EffectUtility.make_instance(spec[0], source, float(spec[1]), 0.0)
			if inst == null:
				continue
			inst.lifetime = EffectTypes.Lifetime.BOARD
			tower.apply_effect(inst)

func _grant_energy_pulse() -> void:
	var pct := float(data.get_parameter("energy_percent", 2))
	for tower in controller.all_towers():
		if not is_instance_valid(tower):
			continue
		if tower.skillController == null:
			continue
		var amount := int(tower.skillController.maxMana * pct)
		if amount > 0:
			tower.regenMana(amount)
