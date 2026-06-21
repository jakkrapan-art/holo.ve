extends RefCounted
class_name WaveControllerData

var waveDatas: Array[WaveData]
var onEnemyReachEndpoint: Callable
var onWaveEnd: Callable
# Stage-wide enemy stat modifiers (from MapData.stageModifiers).
var stageModifiers: Array = []