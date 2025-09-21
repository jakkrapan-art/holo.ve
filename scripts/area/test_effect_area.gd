extends CollisionShape2D

func _on_circle_effect_area_area_entered(area: Area2D) -> void:
	print(area, " entered in area entered");

func _on_circle_effect_area_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	print(area, " entered in area shape entered");
