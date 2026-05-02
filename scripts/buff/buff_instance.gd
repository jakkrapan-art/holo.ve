class_name BuffInstance
extends Resource

enum StatType {
	ATTACK_SPEED,
	DAMAGE,
	CRIT,
	RANGE,
	MANA_REGEN,
	ATTACK_FLAT,
	ATTACK_MULT,
}

enum Category {
	BUFF,
	DEBUFF,
	OTHER,
}

enum StackPolicy {
	IGNORE_IF_PRESENT,
	REFRESH,
	STACK,
}

@export var id: String = ""
@export var statType: StatType = StatType.ATTACK_SPEED
@export var value: float = 0.0
@export var category: Category = Category.BUFF
@export var displayName: String = ""
@export var iconPath: String = ""
@export var sourceSkill: String = ""
@export var duration: float = 0.0
@export var stackPolicy: StackPolicy = StackPolicy.IGNORE_IF_PRESENT

var appliedAt: float = 0.0

func _init(
	p_id: String = "",
	p_statType: StatType = StatType.ATTACK_SPEED,
	p_value: float = 0.0,
	p_category: Category = Category.BUFF,
	p_duration: float = 0.0,
	p_stackPolicy: StackPolicy = StackPolicy.IGNORE_IF_PRESENT,
) -> void:
	id = p_id
	statType = p_statType
	value = p_value
	category = p_category
	duration = p_duration
	stackPolicy = p_stackPolicy
