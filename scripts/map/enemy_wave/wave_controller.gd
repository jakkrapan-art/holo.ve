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

var enemyAliveCount: int = 0;
var isSpawnAllEnemy: bool = false;

var onEnemyReachEndPoint: Callable;

func _ready():
	spawnParent = map.path

func setup(waveDatas: Array[WaveData], onEnemyReachEndpoint: Callable):
	self.waveDatas = waveDatas;
	self.onEnemyReachEndPoint = onEnemyReachEndpoint;
	enemyTextures = SpriteLoader.getSpriteGroup("enemy");

func start():
	nextWaveTimer.wait_time = 0.001
	nextWaveTimer.start()
	
	onWaveStart.emit();
	
func startNextWave():
	if(currWave >= waveDatas.size()):
		return
	spawnedCount = 0
	currWave += 1
	currentGroupIndex = 0;
	groupSpawnCount = 0;
	isSpawnAllEnemy;
	
	var data: WaveData = waveDatas[currWave - 1] as WaveData
	timer.wait_time = 0.5;
	timer.start()
	waveData = data
	active = true

func endWave():
	nextWaveTimer.wait_time = 5
	nextWaveTimer.start()

func spawnEnemy():
	if(currentGroupIndex >= waveData.groupList.size()):
		return;
	var enemy: Enemy = createEnemyObject(Enemy.EnemyType.Normal)
	var waveGroup = waveData.groupList[currentGroupIndex];
	var texture: Texture2D = null; 
	if(enemyTextures.has(waveGroup.texture)):
		texture = enemyTextures[waveGroup.texture]
	enemy.setup(waveGroup.health, waveGroup.def, waveGroup.mDef, waveGroup.moveSpeed, texture)
	groupSpawnCount += 1;
	spawnedCount += 1;
	enemyAliveCount += 1;
	
	if(groupSpawnCount >= waveGroup.count):
		currentGroupIndex += 1;
		groupSpawnCount = 0;
	
	if(currentGroupIndex >= waveData.groupList.size()):
		isSpawnAllEnemy = true
	
	Utility.ConnectSignal(enemy, "onReachEndPoint", Callable(self, "reduceEnemyCount"));
	Utility.ConnectSignal(enemy, "onReachEndPoint", Callable(self, "enemyReachEndPoint").bind(enemy));
	Utility.ConnectSignal(enemy, "onDead", Callable(self, "enemyDead"));	

func createEnemyObject(type: Enemy.EnemyType):
	if(enemyFactory == null):
		return;

	var instance = enemyFactory.getEnemy(type);
	spawnParent.add_child(instance)
	return instance

func enemyReachEndPoint(enemy: Enemy):
	onEnemyReachEndPoint.call(5);
	pass

func checkEndWave():
	if(!isSpawnAllEnemy || enemyAliveCount > 0):
		return;
	
	endWave();

func enemyDead(cause: Damage):
	reduceEnemyCount();
	onEnemyDead.emit(cause);

func reduceEnemyCount():
	enemyAliveCount -= 1;
	checkEndWave();

func _on_next_wave_delay_timer_timeout():
	startNextWave()

func _on_spawn_timer_timeout():
	if (waveData == null):
		return
	if (!active):
		timer.stop()
		return
	spawnEnemy()

signal onWaveStart();
signal onEnemyDead(cause: Damage);
