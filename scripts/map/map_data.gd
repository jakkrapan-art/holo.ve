extends RefCounted
class_name MapData

var mapName: String = "forest01"
var width: int = 0
var height: int = 0
var waves: Array[WaveData] = []
# Stage modifiers applied to EVERY enemy in this stage (all waves). Primary
# tuning tool. Each entry: { stat, op, value } - validated by EnemyModifier.
var stageModifiers: Array = []

func setWave(waves: Array[WaveData]):
	self.waves = waves;
