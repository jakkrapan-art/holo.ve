class_name SkillActionAtkSpeedBuffAOE
extends SkillAction

@export var duration: float = 4.0
@export var percent: float = 50.0
@export var range: int = 1

const BUFF_KEY = "atk_speed_buff_aoe_skill"

func execute(context: SkillContext) -> void:
	var source := context.user as Tower
	if source == null:
		return

	var source_cell: Vector2 = GridHelper.WorldToCell(source.global_position)
	var buffed: Array[Tower] = []

	for node in source.get_tree().get_nodes_in_group("tower"):
		var tower := node as Tower
		if tower == null:
			continue
		var cell: Vector2 = GridHelper.WorldToCell(tower.global_position)
		if abs(cell.x - source_cell.x) <= range and abs(cell.y - source_cell.y) <= range:
			tower.data.addAttackSpeedPercentBuff(percent, BUFF_KEY)
			buffed.append(tower)

	source.get_tree().create_timer(duration).timeout.connect(
		func():
			for t in buffed:
				if is_instance_valid(t):
					t.data.removeAttackSpeedPercentBuff(BUFF_KEY),
		CONNECT_ONE_SHOT
	)
