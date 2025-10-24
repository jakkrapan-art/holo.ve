extends RefCounted
class_name MapData

var mapName: String = "forest01"
var width: int = 0
var height: int = 0
var waves: Array[WaveData] = []

func setWave(waves: Array[WaveData]):
	self.waves = waves;
