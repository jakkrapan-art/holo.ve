class_name WaveData
extends RefCounted

var waveTime: float = 60
var groupList: Array[WaveEnemyGroup]
var isBossWave: bool = false

func addGroup(group: WaveEnemyGroup):
	self.groupList.append(group);
