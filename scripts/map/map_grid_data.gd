extends Resource
class_name MapGridData

var cell: Vector2;
var placable: bool;

func _init(x: int, y: int, placable: bool = true):
	cell = Vector2(x, y);
	self.placable = placable;
