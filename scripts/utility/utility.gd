class_name Utility

static func ConnectSignal(target, signalName: String, callable: Callable):
	if(target.has_signal(signalName)):
		target.connect(signalName, callable)
		return true;

	return false;

static func DisconnectSignal(target, signalName: String, callable: Callable):
	if(target.has_signal(signalName)):
		target.disconnect(signalName, callable)

static func get_angle_to_target(from_position: Vector2, target_position: Vector2) -> float:
	var direction = target_position - from_position
	return direction.angle()

static func show_damage_text(position: Vector2, parent: Node2D, damage: int, color: Color = Color(1, 0, 0)):
	var atkNumber = load("res://resources/ui_component/damage_number.tscn").instantiate() as DamageNumber;
	atkNumber.setup(damage, color);
	atkNumber.global_position = position;
	parent.add_child(atkNumber);
