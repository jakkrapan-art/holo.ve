extends Resource
class_name MapData

@export var width: int = 0
@export var height: int = 0
@export var waves: Array[WaveData] = []

func setWave(waves: Array[WaveData]):
	self.waves = waves;
