class_name SkillActionAddBuff
extends SkillAction

@export var buff: StatusEffect

func execute(context: SkillContext):
	if context.target != null && buff != null:
		for t in context.target:
			if t.has_method("addStatusEffect"):
				t.addStatusEffect(buff.duplicate(true))
