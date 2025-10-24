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
var bossWaveInterval: int = 2;
var bossList: Array[BossDBData] = [];
var waveData: WaveData = null

var isBossWave:bool = false;
var bossRandomIndex: int = -1;

var spawnedCount: int = 0

var groupSpawnCount: int = 0
var currentGroupIndex: int = 0

var enemyAliveCount: int = 0;
var isSpawnAllEnemy: bool = false;

var onEnemyReachEndPoint: Callable;

func _ready():
	spawnParent = map.path

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			testSpawnBoss(0);
		elif event.keycode == KEY_2:
			testSpawnBoss(1);
		elif event.keycode == KEY_3:
			testSpawnBoss(2);

func setup(waveDatas: Array[WaveData], onEnemyReachEndpoint: Callable):
	self.waveDatas = waveDatas;
	self.onEnemyReachEndPoint = onEnemyReachEndpoint;
	enemyTextures = SpriteLoader.getSpriteGroup("enemy");

func setBossList(list: Array[BossDBData]):
	bossList = list;

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
	isSpawnAllEnemy = false;

	var data: WaveData = waveDatas[currWave - 1] as WaveData
	waveData = data
	active = true
	isBossWave = currWave % bossWaveInterval == 0;
	if isBossWave:
		bossRandomIndex = randi_range(0, bossList.size() - 1);

	spawnEnemy();

func endWave():
	nextWaveTimer.wait_time = 5
	nextWaveTimer.start()

func spawnEnemy():
	if(currentGroupIndex >= waveData.groupList.size()):
		return;

	var enemyType := Enemy.EnemyType.Boss if isBossWave else Enemy.EnemyType.Normal
	var waveGroup = waveData.groupList[currentGroupIndex];

	var health := 0;
	var def := 0;
	var mDef := 0;
	var moveSpeed := 0;
	var texture: Texture2D = null;
	var skills: Array[Skill] = [];

	if (enemyType == Enemy.EnemyType.Boss):
		var boss = bossList[bossRandomIndex];

		texture = boss.texture;
		health = boss.stats.hp
		def = boss.stats.def
		mDef = boss.stats.mDef
		moveSpeed = boss.stats.moveSpeed
		isSpawnAllEnemy = true;
		skills = boss.skills;
		timer.stop()

	else:
		health = waveGroup.health
		def = waveGroup.def
		mDef = waveGroup.mDef
		moveSpeed = waveGroup.moveSpeed
		texture = enemyTextures.get(waveGroup.texture, null)
		skills = []
		for skill in waveGroup.skill:
			skills.append(Utility.deep_duplicate_resource(skill))

		groupSpawnCount += 1;

		if(groupSpawnCount >= waveGroup.count):
			currentGroupIndex += 1;
			groupSpawnCount = 0;

		if(currentGroupIndex >= waveData.groupList.size()):
			isSpawnAllEnemy = true

		countdownSpawnNextEnemy(waveGroup.spawnInterval);

	var enemy: Enemy = await createEnemyObject(enemyType, health, def, mDef, moveSpeed, texture, skills);
	spawnedCount += 1;
	enemyAliveCount += 1;

	connectSignalToEnemy(enemy);

func testSpawnBoss(index: int = -1):
	if(bossList.size() == 0):
		print("No boss available to spawn.");
		return;

	if(index < 0):
		index = randi_range(0, bossList.size() - 1);

	var boss = bossList[index]; # For testing, spawn the first boss in the list.

	var texture = boss.texture;
	var health = boss.stats.hp
	var def = boss.stats.def
	var mDef = boss.stats.mDef
	var moveSpeed = boss.stats.moveSpeed

	var enemy: Enemy = await createEnemyObject(Enemy.EnemyType.Boss, health, def, mDef, moveSpeed, texture);
	enemyAliveCount += 1;
	connectSignalToEnemy(enemy);

func connectSignalToEnemy(enemy: Enemy):
	Utility.ConnectSignal(enemy, "onReachEndPoint", Callable(self, "reduceEnemyCount"));
	Utility.ConnectSignal(enemy, "onReachEndPoint", Callable(self, "enemyReachEndPoint").bind(enemy));
	Utility.ConnectSignal(enemy, "onDead", Callable(self, "enemyDead"));

func createEnemyObject(type: Enemy.EnemyType, health: int, def: int, mDef: int, moveSpeed: int, texture: Texture2D = null, skills: Array[Skill] = []):

	if(enemyFactory == null):
		return;

	var instance = await enemyFactory.createEnemy(type, spawnParent, health, def, mDef, moveSpeed, texture, skills);
	return instance

func enemyReachEndPoint(enemy: Enemy):
	onEnemyReachEndPoint.call(5);
	pass

func checkEndWave():
	if(!isSpawnAllEnemy || enemyAliveCount > 0):
		return;

	endWave();

func enemyDead(cause: Damage, reward: EnemyReward):
	reduceEnemyCount();
	onEnemyDead.emit(cause, reward);

func reduceEnemyCount():
	enemyAliveCount -= 1;
	checkEndWave();

func countdownSpawnNextEnemy(waitTime: float):
	# timer.one_shot = true;
	timer.wait_time = waitTime;
	timer.start()

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
