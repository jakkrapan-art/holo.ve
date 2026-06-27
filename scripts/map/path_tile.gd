class_name PathTile

var index: int;
var position: Vector2i;

func _init(p_index: int, x: int, y: int):
	self.index = p_index;
	self.position = Vector2i(x, y);
