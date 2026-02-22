class_name SkillActionIncreaseDefArea
extends SkillAction

@export var increaseValue := 0.5
@export var duration := 3.0
@export var radius := 1
var user: Node2D;
var effectedTargets := [];

func execute(context: SkillContext):
	if (context.target.is_empty()):
		context.cancel = true
		return
	user = context.user
	for target in context.target:
		var area = CircleEffectArea.new();
		area.setup(radius, duration, EffectAreaCallback.new(Callable(self, "enemyEntered"), Callable(self, "enemyExited")), Color(0.1, 0, 0.1, 0.2));
		target.add_child(area);

func enemyEntered(area: Area2D):
	if(isEnemy(user, area)):
		return;

	if(area.has_method("addIncreaseDef")):
		area.addIncreaseDef(increaseValue, getDebuffKey());
	effectedTargets.append(area);

func enemyExited(area: Area2D):
	if(!effectedTargets.has(area)):
		return;

	if(area.has_method("removeIncreaseDef")):
		area.removeIncreaseDef(getDebuffKey());

	effectedTargets.erase(area);

func isEnemy(user: Node, target: Node):
	return (user is Enemy and target is Tower) || (user is Tower and (target is Enemy or target is EnemyArea))

func getDebuffKey():
	return "skill_buff_move_spd";
