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

# Put this in a global autoload or utility script
static func deep_duplicate_resource(resource: Resource) -> Resource:
	if resource == null:
		return null

	var copy = resource.duplicate(true)

	# Get all properties of the resource
	for property in resource.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var prop_name = property.name
			var value = resource.get(prop_name)

			# Deep copy arrays of resources
			if value is Array:
				var new_array = []
				for item in value:
					if item is Resource:
						new_array.append(deep_duplicate_resource(item))
					else:
						new_array.append(item)
				copy.set(prop_name, new_array)

			# Deep copy dictionaries
			elif value is Dictionary:
				var new_dict = {}
				for key in value:
					if value[key] is Resource:
						new_dict[key] = deep_duplicate_resource(value[key])
					else:
						new_dict[key] = value[key]
				copy.set(prop_name, new_dict)

	return copy

static func parse_tower_trait_enum(enum_dict: Dictionary, value: String):
	if typeof(value) != TYPE_STRING:
		push_error("Invalid enum value type: " + str(value))
		return 0

	var target := value.to_lower()

	for key in enum_dict.keys():
		if key.to_lower() == target:
			return enum_dict[key]

	push_error("Enum value not found: " + value)
	return 0
