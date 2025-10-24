class_name WaveData
extends RefCounted

var waveTime: float = 60
var groupList: Array[WaveEnemyGroup]

func addGroup(group: WaveEnemyGroup):
	self.groupList.append(group);
