class_name DecreaseDamageAllArea
extends SkillAction

@export var duration: int = 3
@export var radius: float = 1.0
@export var decreaseValue: float = 0.0
var user: Node2D;
var effectedTargets := [];

func execute(context: SkillContext):
	if(context.user == null):
		return;

	user = context.user
	for target in context.target:
		var area = CircleEffectArea.new();
		area.setup(radius, duration, EffectAreaCallback.new(Callable(self, "enemyEntered"), Callable(self, "enemyExited")));
		target.add_child(area);

func enemyEntered(area: Area2D):
	if(!isEnemy(user, area)):
		return;

	if(area.has_method("addDecreaseDmgAllPercent")):
		area.addDecreaseDmgAllPercent(decreaseValue, getDebuffKey());
	effectedTargets.append(area);

func enemyExited(area: Area2D):
	if(!effectedTargets.has(area)):
		return;

	if(area.has_method("removeDecreaseDmgAllPercent")):
		area.removeDecreaseDmgAllPercent(getDebuffKey());

	effectedTargets.erase(area);

func isEnemy(user: Node, target: Node):
	return (user is Enemy and target is Tower) || (user is Tower and (target is Enemy or target is EnemyArea))

func getDebuffKey():
	return "skill_" + str(get_instance_id());