extends Node
class_name WaveController

@export var datas: Array[WaveData] = []
@onready var timer: Timer = $SpawnTimer
@onready var nextWaveTimer: Timer = $NextWaveDelayTimer

var active: bool = false
var currWave: int = 0
var waveData: WaveData = null
var spawnedCount: int = 0

func _ready():
	startNextWave()

func startNextWave():
	if(currWave >= datas.size()):
		return
	spawnedCount = 0
	currWave += 1
	var data: WaveData = datas[currWave - 1]
	timer.wait_time = data.waveTime / data.enemyCount
	timer.start()
	waveData = data
	active = true
	if(nextWaveTimer != null):
		nextWaveTimer.wait_time = waveData.waveTime + 5
		nextWaveTimer.start();

func spawnEnemy():
	spawnedCount += 1
	if(spawnedCount == waveData.enemyCount):
		active = false

func _on_next_wave_delay_timer_timeout():
	startNextWave()

func _on_spawn_timer_timeout():
	if (waveData == null):
		return
	if (!active):
		timer.stop()
		return
	spawnEnemy()
