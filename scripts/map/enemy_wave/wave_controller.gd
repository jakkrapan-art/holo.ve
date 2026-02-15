extends Node
class_name WaveController

var data: WaveControllerData = null;

@onready var nextWaveTimer: Timer = $NextWaveDelayTimer

@export var map: Map = null;
var spawnParent: Node2D = null;

var enemyTextures: Dictionary = {};
@onready var enemyFactory: EnemyFactory = $"../EnemyFactory";

@onready var waveCounterText: Label = $"../GameUI/WaveCounter/Text"

var active: bool = false
var currWave: int = 0
var endWaveCalled: bool = false
var bossList: Array[BossDBData] = [];
var waveData: WaveData = null

var isBossWave:bool = false;
var bossRandomIndex: int = -1;

var groupSpawnRemain: Dictionary = {}

var enemyAliveCount: int = 0;
var isSpawnAllEnemy: bool = false;
var deadList: Array[Enemy] = [];

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

func setup(data: WaveControllerData):
	self.data = data;
	enemyTextures = SpriteLoader.getSpriteGroup("enemy");

func setBossList(list: Array[BossDBData]):
	bossList = list;

func start():
	nextWaveTimer.wait_time = 0.001
	nextWaveTimer.start()

	onWaveStart.emit();

func startNextWave():
	if(currWave >= data.waveDatas.size()):
		return
	currWave += 1
	isSpawnAllEnemy = false;
	endWaveCalled = false;

	var wData: WaveData = data.waveDatas[currWave - 1] as WaveData
	waveData = wData
	active = true
	isBossWave = wData.isBossWave;
	if isBossWave:
		bossRandomIndex = randi_range(0, bossList.size() - 1);

	if isBossWave:
		spawnBoss();
	else:
		setupSpawnTask()

	updateUI();

func endWave():
	print("End Wave ", currWave);
	if endWaveCalled:
		return;

	endWaveCalled = true;
	deadList.clear();
	data.onWaveEnd.call();

func setupSpawnTask():
	print("wave data: ", waveData, " wave index:", currWave);
	for group in range(0, waveData.groupList.size()):
		spawnEnemyTask(group);

func spawnEnemyTask(groupIndex: int):
	var groupData = waveData.groupList[groupIndex]
	var interval = groupData.spawnInterval;
	var remain = groupData.count;

	groupSpawnRemain[groupIndex] = remain
	while remain > 0:
		spawnEnemy(groupIndex);
		remain -= 1;
		groupSpawnRemain[groupIndex] = remain

		if remain == 0:
			groupSpawnRemain.erase(groupIndex)
			isSpawnAllEnemy = groupSpawnRemain.size() == 0

		await get_tree().create_timer(interval).timeout

func spawnEnemy(groupIndex: int):
	var waveGroup = waveData.groupList[groupIndex];

	var health = waveGroup.health
	var def = waveGroup.def
	var mDef = waveGroup.mDef
	var moveSpeed = waveGroup.moveSpeed
	var texture = enemyTextures.get(waveGroup.texture, null)
	var skills: Array[Skill] = []
	for skill in waveGroup.skill:
		skills.append(Utility.deep_duplicate_resource(skill))

	var enemy: Enemy = await createEnemyObject(Enemy.EnemyType.Normal, health, def, mDef, moveSpeed, texture, skills);
	enemyAliveCount += 1;

	connectSignalToEnemy(enemy);

func spawnBoss():
	var bossData = bossList[bossRandomIndex];
	var texture = bossData.texture;
	var health = bossData.stats.hp
	var def = bossData.stats.def
	var mDef = bossData.stats.mDef
	var moveSpeed = bossData.stats.moveSpeed
	var skills = bossData.skills;

	isSpawnAllEnemy = true;
	var boss: Enemy = await createEnemyObject(Enemy.EnemyType.Boss, health, def, mDef, moveSpeed, texture, skills);
	enemyAliveCount += 1;

	connectSignalToEnemy(boss);

func updateUI():
	if waveCounterText != null:
		waveCounterText.text = "wave " + str(currWave)

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
	data.onEnemyReachEndpoint.call(5);

func checkEndWave():
	print("check end wave called alive: " + str(enemyAliveCount) + " is spawn all: " + str(isSpawnAllEnemy));
	if(isSpawnAllEnemy && enemyAliveCount <= 0):
		print("end wave: " + str(isSpawnAllEnemy) + " alive: " + str(enemyAliveCount))
		endWave();

func enemyDead(enemy: Enemy, cause: Damage, reward: EnemyReward):
	if(deadList.has(enemy)):
		return

	deadList.append(enemy);
	reduceEnemyCount();
	onEnemyDead.emit(cause, reward);

func reduceEnemyCount():
	enemyAliveCount -= 1;
	checkEndWave();

func _on_next_wave_delay_timer_timeout():
	startNextWave()

signal onWaveStart();
signal onEnemyDead(cause: Damage);
