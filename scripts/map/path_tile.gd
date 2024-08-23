class_name PathTile

var index: int;
var position: Vector2i;

func _init(index: int, x: int, y: int):
	self.index = index;
	self.position = Vector2i(x, y);
