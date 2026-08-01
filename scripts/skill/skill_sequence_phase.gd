extends Resource
class_name SkillSequencePhase

# One phase of a sequence Active Skill: the actions cast when this phase is up,
# plus per-phase display metadata. Parsed once per character and SHARED across
# casts - runtime phase progress lives on the caster's controller
# (BaseSkillController.sequence_index), never here.

@export var label: String = ""
@export var icon: String = ""
# Placeholder tint ("#RRGGBB") applied to the fallback icon while no per-phase
# icon art exists; "" = no tint. Real icon art fills `icon` and blanks this.
@export var icon_tint: String = ""
@export var actions: Array[SkillAction] = []
