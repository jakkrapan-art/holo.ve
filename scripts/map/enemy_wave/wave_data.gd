class_name WaveData
extends Resource

@export var waveTime: float = 60
@export var groupList: Array[WaveEnemyGroup]

func addGroup(group: WaveEnemyGroup):
	self.groupList.append(group);
