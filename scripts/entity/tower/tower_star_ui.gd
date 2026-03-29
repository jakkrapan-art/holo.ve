extends Node
class_name TowerStarUI

func setStar(star: int):
	var childCount = get_child_count();
	for i in range(childCount):
		get_child(i).visible = i == star - 1;