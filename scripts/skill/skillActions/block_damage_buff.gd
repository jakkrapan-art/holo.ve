class_name SkillActionBlockDamage
extends SkillAction

var blockCount: int = 1
func execute(context: SkillContext):
	for target in context.target:
		if target.has_method("addBlockDamageCount"):
			target.addBlockDamageCount(blockCount);