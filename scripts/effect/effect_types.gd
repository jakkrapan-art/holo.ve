class_name EffectTypes

# Shared enums for the unified buff/debuff system (tower + enemy).
# Stat kinds feed EffectContainer.aggregate(); behavior kinds attach an
# EffectBehavior object; MARK_ONLY is a pure marker (no intrinsic effect).
#
# Unit conventions per kind (MUST match legacy math exactly):
#   ATTACK_SPEED / MOVE_SPEED_MULT      decimal (0.5 = +50%)
#   ATTACK_MULT / MAGIC_MULT            percent (10 = +10%)
#   ARMOR_MULT / MARMOR_MULT            decimal (0.05 = +5%)
#   CRIT_CHANCE                         percent points
#   DAMAGE_AMPLIFIER / DAMAGE_REDUCTION decimal
#   *_FLAT / RANGE / MANA_REGEN / MOVE_SPEED_FLAT  flat additive
enum Kind {
	ATTACK_SPEED,
	ATTACK_FLAT,
	ATTACK_MULT,
	MAGIC_FLAT,
	MAGIC_MULT,
	CRIT_CHANCE,
	CRIT_DAMAGE_BONUS,
	RANGE,
	MANA_REGEN,
	DAMAGE_AMPLIFIER,
	ARMOR_FLAT,
	ARMOR_MULT,
	MARMOR_FLAT,
	MARMOR_MULT,
	MOVE_SPEED_FLAT,
	MOVE_SPEED_MULT,
	DAMAGE_REDUCTION,
	STUN,
	DOT,
	MARK_ONLY,
}

enum Category { BUFF, DEBUFF, MARK }

# WAVE effects are removed by clear_wave_scoped() at wave end (and when the
# owning tower leaves the board); BOARD effects (synergy) survive until
# clear_all(). Replaces the legacy "empty sourceSkill survives" convention.
enum Lifetime { WAVE, BOARD }

# Same identity (source_id + effect id) re-applied:
#   REFRESH  reset the timer, take the new value (player-favorable; P3-L verdict).
#   STACK    +1 stack (up to max_stacks; 0 = unlimited) and refresh the shared
#            timer; effective value = value * stacks (Batrider-style).
enum StackRule { REFRESH, STACK }

const KIND_FROM_STRING := {
	"attack_speed": Kind.ATTACK_SPEED,
	"attack_flat": Kind.ATTACK_FLAT,
	"attack_mult": Kind.ATTACK_MULT,
	"magic_flat": Kind.MAGIC_FLAT,
	"magic_mult": Kind.MAGIC_MULT,
	"crit_chance": Kind.CRIT_CHANCE,
	"crit_damage": Kind.CRIT_DAMAGE_BONUS,
	"range": Kind.RANGE,
	"mana_regen": Kind.MANA_REGEN,
	"damage_amp": Kind.DAMAGE_AMPLIFIER,
	"armor_flat": Kind.ARMOR_FLAT,
	"armor_mult": Kind.ARMOR_MULT,
	"marmor_flat": Kind.MARMOR_FLAT,
	"marmor_mult": Kind.MARMOR_MULT,
	"move_speed_flat": Kind.MOVE_SPEED_FLAT,
	"move_speed": Kind.MOVE_SPEED_MULT,
	"damage_reduction": Kind.DAMAGE_REDUCTION,
	"stun": Kind.STUN,
	"dot": Kind.DOT,
	"mark": Kind.MARK_ONLY,
}

const CATEGORY_FROM_STRING := {
	"buff": Category.BUFF,
	"debuff": Category.DEBUFF,
	"mark": Category.MARK,
}

const STACK_FROM_STRING := {
	"refresh": StackRule.REFRESH,
	"stack": StackRule.STACK,
}

const LIFETIME_FROM_STRING := {
	"wave": Lifetime.WAVE,
	"board": Lifetime.BOARD,
}

static func is_stat_kind(kind: int) -> bool:
	return kind < Kind.STUN
