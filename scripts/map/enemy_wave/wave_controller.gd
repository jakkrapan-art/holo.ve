extends Node
class_name WaveController

var waveDatas: Array[WaveData] = []
@onready var timer: Timer = $SpawnTimer
@onready var nextWaveTimer: Timer = $NextWaveDelayTimer

@export var map: Map = null;
var spawnParent: Node2D = null;

var enemyTextures: Dictionary = {};
@onready var enemyFactory: EnemyFactory = $"../EnemyFactory";

var active: bool = false
var currWave: int = 0
var waveData: WaveData = null
var spawnedCount: int = 0

var groupSpawnCount: int = 0
var currentGroupIndex: int = 0

func _ready():
	spawnParent = map.enemyParent

func setup(waveDatas: Array[WaveData]):
	self.waveDatas = waveDatas;
	enemyTextures = SpriteLoader.getSpriteGroup("enemy");

func start():
	nextWaveTimer.wait_time = 0
	nextWaveTimer.start()
	
func startNextWave():
	if(currWave >= waveDatas.size()):
		return
	spawnedCount = 0
	currWave += 1
	currentGroupIndex = 0;
	groupSpawnCount = 0;
	
	var data: WaveData = waveDatas[currWave - 1] as WaveData
	timer.wait_time = 0.5;
	timer.start()
	waveData = data
	active = true
	#if(nextWaveTimer != null):
		#nextWaveTimer.wait_time = waveData.waveTime + 5
		#nextWaveTimer.start();

func spawnEnemy():
	var enemy: Enemy = createEnemyObject(Enemy.EnemyType.Normal)
	var waveGroup = waveData.groupList[currentGroupIndex];
	var texture: Texture2D = null; 
	if(enemyTextures.has(waveGroup.texture)):
		texture = enemyTextures[waveGroup.texture]
	enemy.setup(waveGroup.health, waveGroup.def, waveGroup.mDef, waveGroup.moveSpeed, texture)
	groupSpawnCount += 1
	spawnedCount += 1
	
	if(groupSpawnCount >= waveGroup.count):
		currentGroupIndex += 1;
		groupSpawnCount = 0;
	
	if(currentGroupIndex >= waveData.groupList.size()):
		active = false
		for child in enemy.get_children():
			if(child.has_signal("onReachEndPoint")):
				child.connect("onReachEndPoint", Callable(self, "endWave"))
				break;

func createEnemyObject(type: Enemy.EnemyType):
	if(enemyFactory == null):
		return;

	var instance = enemyFactory.getEnemy(type);
	spawnParent.add_child(instance)
	return instance

func _on_next_wave_delay_timer_timeout():
	startNextWave()

func _on_spawn_timer_timeout():
	if (waveData == null):
		return
	if (!active):
		timer.stop()
		return
	spawnEnemy()

func endWave():
	nextWaveTimer.wait_time = 5
	nextWaveTimer.start()
