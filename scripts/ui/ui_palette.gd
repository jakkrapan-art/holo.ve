class_name UIPalette

# Attack-type display colors, single source: the tower-select card stat block
# reads these now; the stats panel type cell can adopt them later. Placeholder
# hexes - Director tunes here. Do not reuse #5AC8FA (scaling-value cyan) or
# #FFD15A (kind gold): both already carry a meaning in skill/synergy text.
const ATTACK_WEAPON := Color("#FF9C40")
const ATTACK_MAGIC := Color("#B06CFF")
const ATTACK_TRUE := Color.WHITE

static func attack_type_color(type: Damage.DamageType) -> Color:
	match type:
		Damage.DamageType.MAGIC:
			return ATTACK_MAGIC
		Damage.DamageType.TRUE:
			return ATTACK_TRUE
		_:
			return ATTACK_WEAPON
