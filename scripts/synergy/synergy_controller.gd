class_name SynergyController
extends RefCounted

# Owns active-synergy runtime state and routes events to SynergyEffect objects.
# Replaces the old SYNERGY_BUFFS apply logic. Tier is run-level state (NOT
# per-wave): it is ratcheted up and never cleared on wave reset, matching the
# "synergy is not deactivated mid-run" design rule.

var _factory                       # TowerFactory (tower lists)
var _active_tier: Dictionary = {}  # synergy_id -> int (highest tier, -1 none)
var _effects: Dictionary = {}      # synergy_id -> SynergyEffect

func setup(factory) -> void:
	_factory = factory

# From TowerTrait.synergy_updated. tier is the absolute current tier (-1 = none).
# Ratchets up only; a lower tier (e.g. a future tower removal) does not downgrade.
func on_synergy_updated(synergy_id: int, _count: int, tier: int) -> void:
	var prev: int = _active_tier.get(synergy_id, -1)
	if tier <= prev:
		return
	_active_tier[synergy_id] = tier

	var effect: SynergyEffect = _effects.get(synergy_id, null)
	if effect == null:
		effect = _create_effect(synergy_id)
		if effect == null:
			return   # placeholder synergy: declared in YAML, no effect handler yet
		_effects[synergy_id] = effect
		effect.activate()
	effect.on_tier_changed(tier)

func _create_effect(synergy_id: int) -> SynergyEffect:
	var data: SynergyData = ResourceManager.getSynergyData(synergy_id)
	if data == null:
		return null
	var effect := SynergyEffect.create(data.effect)
	if effect == null:
		return null
	effect.setup(data, self)
	return effect

# From TowerFactory when a new tower is placed: let active effects apply to it.
func on_tower_added(tower) -> void:
	for effect in _effects.values():
		effect.on_tower_added(tower)

# From each tower's skill_cast_succeeded.
func on_tower_cast(tower) -> void:
	for effect in _effects.values():
		effect.on_tower_cast(tower)

func active_tier(synergy_id: int) -> int:
	return _active_tier.get(synergy_id, -1)

# Towers currently holding a given synergy trait (factory's keyed list).
func towers_with(synergy_id: int) -> Array:
	if _factory == null:
		return []
	return _factory.towers.get(synergy_id, [])
