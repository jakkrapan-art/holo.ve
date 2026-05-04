extends SkillAction
class_name SkillActionAttack

# Phase 3 Block C — Skill Multiplier (per Master Formula §3.5)
# baseDamage = Total Attack × Skill Multiplier × hit_ratio
# Each hit goes through full pipeline (crit + armor + ΣAmp + ΣRed) independently.

# Legacy fallback (kept for backward compat with old YAML using `damage: N`)
@export var damage: int = 0

# Skill Multiplier — scalar OR per-level array (array overrides scalar)
@export var damageMultiplier: float = 1.0
@export var damageMultiplierPerLevel: Array[float] = []

# Multi-hit distribution — empty = single hit @ 1.0
# Sum should = 1.0 (warns if not). Each ratio applies to baseDamage before pipeline.
@export var hitDistribution: Array[float] = []

# Crit toggle — false disables crit roll for this skill (e.g. Kiara fire blade)
@export var canCrit: bool = true

# Damage type — defaults to tower.data.attackType (set damageTypeOverride=true to use this)
@export var damageType: Damage.DamageType = Damage.DamageType.PHYSIC
@export var damageTypeOverride: bool = false

func execute(context: SkillContext):
	var tower: Tower = context.user as Tower

	# Pure legacy: no tower available → flat damage as-is
	if tower == null:
		for target in context.target:
			if is_instance_valid(target) && target.has_method("recvDamage"):
				target.recvDamage(Damage.new(null, damage, damageType))
		return

	# Resolve multiplier: per-level array > scalar
	var mult: float = damageMultiplier
	if damageMultiplierPerLevel.size() > 0:
		var idx: int = clampi(tower.data.level - 1, 0, damageMultiplierPerLevel.size() - 1)
		mult = damageMultiplierPerLevel[idx]

	# Resolve hits — empty distribution = single hit
	var hits: Array[float] = hitDistribution if hitDistribution.size() > 0 else ([1.0] as Array[float])
	if hitDistribution.size() > 0:
		var hitSum: float = 0.0
		for r in hits:
			hitSum += r
		if abs(hitSum - 1.0) > 0.001:
			push_warning("hit_distribution sum %.4f != 1.0 — sum should equal 1.0 (skill=%s)" % [hitSum, context.skillName])

	# Resolve damage type
	var dmgType: Damage.DamageType = damageType if damageTypeOverride else tower.data.attackType

	# Resolve base value: legacy flat (if no multiplier configured) OR Total Attack × multiplier
	var useLegacyFlat: bool = damageMultiplierPerLevel.is_empty() and damageMultiplier == 1.0 and damage > 0
	var baseValue: float
	if useLegacyFlat:
		baseValue = float(damage)
	else:
		baseValue = float(tower.data.getTotalAttack()) * mult

	# Cache crit context (avoid recomputing per-target)
	var stat = tower.data.getStat()
	var critChance: float = tower.data.getCritChance() if canCrit else 0.0
	var sigmaCD: float = stat.critMultiplier + tower.data.buffs.aggregate(BuffInstance.StatType.CRIT_DAMAGE_BONUS)

	# Apply damage: per (hit, target) — each crit roll independent
	for hitRatio in hits:
		var hitBase: float = baseValue * hitRatio
		for target in context.target:
			if not is_instance_valid(target) or not target.has_method("recvDamage"):
				continue
			var isCrit: bool = canCrit and critChance > 0 and randi_range(0, 100) <= critChance
			var hitDamage: float = hitBase
			if isCrit:
				# §5: Critical Damage = 1 + (1 × (ΣCD − 1)) = ΣCD
				hitDamage *= sigmaCD
			target.recvDamage(Damage.new(tower, int(hitDamage), dmgType, isCrit))
