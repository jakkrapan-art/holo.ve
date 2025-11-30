extends RefCounted
class_name GetTowerResult

enum State {
	New,
	Upgrade,
	Evolve
}

var tower: Tower;
var state: State = State.New;

func _init():
	self.tower = null;
	self.state = State.New;
