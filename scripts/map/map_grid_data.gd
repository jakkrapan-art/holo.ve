extends Resource
class_name MapGridData

var cell: Vector2;
var placable: bool;

func _init(x: int, y: int, p_placable: bool = true):
	cell = Vector2(x, y);
	self.placable = p_placable;
