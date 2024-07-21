extends Node
class_name WaveController

@export var dataList: Array[WaveData] = []
@onready var timer: Timer = $SpawnTimer
@onready var nextWaveTimer: Timer = $NextWaveDelayTimer

@export var spawnParent: Node2D = null;

var active: bool = false
var currWave: int = 0
var waveData: WaveData = null
var spawnedCount: int = 0

func setup(spawnParent: Node2D):
	self.spawnParent = spawnParent

func startNextWave():
	if(currWave >= dataList.size()):
		return
	spawnedCount = 0
	currWave += 1
	var data: WaveData = dataList[currWave - 1]
	timer.wait_time = data.waveTime / data.enemyCount
	timer.start()
	waveData = data
	active = true
	setEnemySpawnedCountText(0);
	if(nextWaveTimer != null):
		nextWaveTimer.wait_time = waveData.waveTime + 5
		nextWaveTimer.start();

func spawnEnemy():
	createEnemyObject(waveData.enemyTemplate)
	spawnedCount += 1
	if(spawnedCount == waveData.enemyCount):
		active = false

func createEnemyObject(template: PackedScene):
	if(template == null || spawnParent == null):
		return
	var instance = template.instantiate()
	spawnParent.add_child(instance)

func _on_next_wave_delay_timer_timeout():
	startNextWave()

func _on_spawn_timer_timeout():
	if (waveData == null):
		return
	if (!active):
		timer.stop()
		return
	spawnEnemy()
