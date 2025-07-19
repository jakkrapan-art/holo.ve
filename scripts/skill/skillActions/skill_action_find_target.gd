extends SkillAction
class_name SkillActionFindTarget

var maxAttemp:= 20;
var attemp:= 0;

func execute(context: SkillContext):
	attemp = 0;
	while context.target == null && attemp < maxAttemp:
		if context.user is Tower:
			var tower := context.user as Tower
			context.target = [tower.enemy]
		else:
			break
			
		if(context.target == null):
			attemp += 1;
			await context.user.get_tree().process_frame;
	
	if(attemp >= maxAttemp && context.target == null):
		context.cancel = true;
