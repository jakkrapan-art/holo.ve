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

# Guaranteed crit — true forces every hit to crit regardless of crit chance
# (e.g. Regis Altare beat-2 gun shot). Still applies the normal crit multiplier.
@export var forcedCrit: bool = false

# Damage type — defaults to tower.data.attackType (set damageTypeOverride=true to use this)
@export var damageType: Damage.DamageType = Damage.DamageType.PHYSIC
@export var damageTypeOverride: bool = false

# Registry effects applied to each target after all hits land (e.g., Kiara's
# Phoenix Flame DOT). A fresh EffectInstance is built per target so per-target
# state never bleeds between enemies.
@export var statusEffects: Array[EffectSpec] = []

# Stack-scaling bonus: adds (caster's stacks of an effect id) x per-stack value
# to the Skill Multiplier, read at execute time so the count is always live
# (e.g. Calliope Souls). Generic - a stack-scaling tower authors YAML only.
@export var stackBonusEffectId: String = ""
@export var stackBonusPerStack: float = 0.0

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

	# Stack-scaling bonus (live count at execute time - see export note above)
	if stackBonusEffectId != "" and stackBonusPerStack != 0.0:
		mult += float(tower.data.effects.stacks_of(stackBonusEffectId)) * stackBonusPerStack

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
	# The authored canCrit gate can be opened from outside by the SpellCaster
	# synergy marker. It unlocks the roll only - the synergy
	# grants no crit chance, so a 0-chance holder still never crits.
	var critAllowed: bool = canCrit or tower.data.effects.stacks_of("spellcaster_crit") > 0
	var critChance: float = tower.data.getCritChance() if critAllowed else 0.0
	var sigmaCD: float = stat.critMultiplier + tower.data.effects.aggregate(EffectTypes.Kind.CRIT_DAMAGE_BONUS)

	# Apply damage: per (hit, target) — each crit roll independent
	for hitRatio in hits:
		var hitBase: float = baseValue * hitRatio
		for target in context.target:
			if not is_instance_valid(target) or not target.has_method("recvDamage"):
				continue
			# randi_range(1, 100) → 100 values for exact critChance/100 probability (§6.2 #1 fix)
			# forcedCrit overrides the roll (guaranteed crit, e.g. Altare beat 2).
			var isCrit: bool = forcedCrit or (critAllowed and critChance > 0 and randi_range(1, 100) <= critChance)
			var hitDamage: float = hitBase
			if isCrit:
				# §5: Critical Damage = 1 + (1 × (ΣCD − 1)) = ΣCD
				hitDamage *= sigmaCD
			var dmg := Damage.new(tower, int(hitDamage), dmgType, isCrit)
			dmg.isSkillDamage = true
			# Each target is damaged through its own Damage, so each gets the amp
			# for its own distance (the shared-value rule is a projectile concern).
			dmg.sourceAmp = tower.data.getDistanceAmp(tower, target as Enemy)
			target.recvDamage(dmg)

	# Apply registry effects once per target after all hits land. instantiate()
	# builds a fresh isolated instance and snapshots caster-side stats (e.g.
	# the Phoenix Flame DOT's attack snapshot) from the casting tower.
	if statusEffects.size() > 0:
		for target in context.target:
			if not is_instance_valid(target) or not target.has_method("apply_effect"):
				continue
			for spec: EffectSpec in statusEffects:
				if spec == null:
					continue
				var inst := spec.instantiate(tower)
				if inst != null:
					target.apply_effect(inst)
