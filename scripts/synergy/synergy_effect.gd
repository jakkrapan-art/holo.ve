class_name SynergyEffect
extends RefCounted

# Behaviour of one active synergy. Constructed by `effect` key (see create),
# mirroring SkillUtility.ParseAction (SkillAction subclasses) and Tower._setupPassive.
# Adding a synergy that reuses an existing effect needs only a YAML file; a new
# effect kind adds one subclass + one match arm here.

var data: SynergyData
var controller   # SynergyController (tower lists + active tier)

func setup(d: SynergyData, c) -> void:
	data = d
	controller = c

# Synergy first reached tier 0 (effect created).
func activate() -> void:
	pass

# Active tier increased to new_tier (0-based). Tier never decreases mid-run
# (no synergy deactivation by design - see tower_synergy.md).
func on_tier_changed(_new_tier: int) -> void:
	pass

# A tower joined while this synergy is already active. For stat-style effects,
# apply the current-tier buff to the newcomer. Live-read effects (e.g. Myth)
# need nothing here.
func on_tower_added(_tower) -> void:
	pass

# A tower cast a skill successfully (routed for every tower; the effect filters).
func on_tower_cast(_tower) -> void:
	pass

# An enemy was killed (routed for every kill; the effect counts/filters).
func on_enemy_killed(_enemy, _cause, _reward) -> void:
	pass

# Per-frame tick from TowerFactory._process (time-based effects, e.g. periodic grants).
func tick(_delta: float) -> void:
	pass

# effect key -> concrete SynergyEffect. "" / unknown -> null (placeholder, not wired).
static func create(effect_key: String) -> SynergyEffect:
	match effect_key:
		"energy_on_skill_cast":
			return SynergyEffectEnergyOnCast.new()
		"quest_kill_tempus":
			return SynergyEffectQuestTempus.new()
		"attack_per_active_trait":
			return SynergyEffectAttackPerTrait.new()
		"magic_up_skill_crit":
			return SynergyEffectSpellcaster.new()
		"damage_per_range":
			return SynergyEffectMarksman.new()
		"", "none":
			return null   # placeholder synergy: declared but no effect handler yet
		_:
			push_warning("Unknown synergy effect: " + effect_key)
			return null
