extends Node
class_name WaveController

var data: WaveControllerData = null;

@onready var nextWaveTimer: Timer = $NextWaveDelayTimer

@export var map: Map = null;

# Breathing beat between the player starting a wave (managing-phase popup closed)
# and the first enemy spawning - a short "wave incoming" telegraph. Applies to every
# wave incl. the first and boss waves. Symmetric to game_scene.wave_end_popup_delay.
# Inspector-editable feel knob; scales with game-speed time_scale like spawns.
@export var pre_wave_start_delay: float = 0.8
var spawnParent: Node2D = null;

var enemyTextures: Dictionary = {};
@onready var enemyFactory: EnemyFactory = $"../EnemyFactory";

@onready var waveCounterText: Label = $"../GameUI/WaveCounter/Text"

# Top-center wave-time countdown. Shows wave-timeline progression during a normal
# wave's spawn window; hides at zero (enemies may remain - wave end is field-clear,
# not the timer) and during the Managing Phase / on boss waves.
@onready var waveTimer: Control = $"../GameUI/WaveTimer"
@onready var waveTimerText: Label = $"../GameUI/WaveTimer/Text"

# Top-center boss HP bar; occupies the WaveTimer slot (the countdown hides on
# boss waves, so the two never show together).
@onready var bossHpBar: BossHealthBar = $"../GameUI/BossHealthBar"
var _wave_elapsed: float = 0.0
var _countdown_active: bool = false

var active: bool = false
var currWave: int = 0
var endWaveCalled: bool = false
var bossList: Array[BossDBData] = [];
var waveData: WaveData = null

var isBossWave:bool = false;

var groupSpawnRemain: Dictionary = {}

var enemyAliveCount: int = 0;
var isSpawnAllEnemy: bool = false;
var deadList: Array[Enemy] = [];

func _ready():
	# Skill actions (summon_enemy) locate the controller through this group -
	# WaveController is not an autoload and actions only receive a SkillContext.
	add_to_group("wave_controller")
	spawnParent = map.path
	if waveTimer != null:
		waveTimer.visible = false

# Drives the top-center wave countdown. Counts down the wave's authored duration;
# at zero the spawn timeline is done so the timer hides (the wave continues until
# the field is clear). delta scales with the game-speed time_scale, matching spawns.
func _process(delta):
	if not _countdown_active:
		return
	_wave_elapsed += delta
	var remaining: float = waveData.duration - _wave_elapsed
	if remaining <= 0.0:
		_stopCountdown()
		return
	if waveTimerText != null:
		waveTimerText.text = _format_time(remaining)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			testSpawnBoss(0);
		elif event.keycode == KEY_2:
			testSpawnBoss(1);
		elif event.keycode == KEY_3:
			testSpawnBoss(2);

func setup(p_data: WaveControllerData):
	self.data = p_data;
	enemyTextures = ResourceManager.getSpriteGroup("enemy");

func setBossList(list: Array[BossDBData]):
	bossList = list;

func start():
	nextWaveTimer.wait_time = max(pre_wave_start_delay, 0.001)
	nextWaveTimer.start()

	onWaveStart.emit();

func startNextWave():
	if(currWave >= data.waveDatas.size()):
		return
	currWave += 1
	isSpawnAllEnemy = false;
	endWaveCalled = false;
	groupSpawnRemain.clear()
	# Reset alive count as defense vs any stale count carryover from the
	# previous wave's tracking. With Enemy._removed mutex preventing
	# double-decrement at source, count should already be 0 here; this is
	# unguarded cheap insurance, not the primary fix.
	enemyAliveCount = 0

	var wData: WaveData = data.waveDatas[currWave - 1] as WaveData
	waveData = wData
	active = true
	isBossWave = wData.isBossWave;

	if isBossWave:
		_stopCountdown()
		spawnBoss();
	else:
		_startCountdown()
		setupSpawnTask()

	updateUI();

func endWave():
	if endWaveCalled:
		return;

	endWaveCalled = true;
	_stopCountdown();
	deadList.clear();

	if(currWave >= data.waveDatas.size()):
		var ui = UIEndDemo.create();
		if(ui):
			get_tree().current_scene.add_child(ui);
	else:
		data.onWaveEnd.call();

func setupSpawnTask():
	# Initialize remaining counts early so end-wave checks don't trigger before all groups have been registered.
	for group in range(0, waveData.groupList.size()):
		var groupData = waveData.groupList[group]
		groupSpawnRemain[group] = groupData.count

	for group in range(0, waveData.groupList.size()):
		spawnEnemyTask(group);

func spawnEnemyTask(groupIndex: int):
	var groupData = waveData.groupList[groupIndex]

	# Per-group start delay on the wave timeline. The await sits HERE (after
	# setupSpawnTask has already registered groupSpawnRemain for every group), so a
	# delayed group keeps remain > 0 and _allGroupsSpawned() can't end the wave early.
	if groupData.startAt > 0:
		var gen := currWave
		await get_tree().create_timer(groupData.startAt).timeout
		# Wave may have ended / advanced during the delay - bail if so (await guard).
		if not is_instance_valid(self) or currWave != gen or endWaveCalled:
			return

	var interval = groupData.spawnInterval;
	var remain = groupData.count;
	var spawned := 0;

	groupSpawnRemain[groupIndex] = remain
	while remain > 0:
		# Hard cap: do NOT spawn an enemy scheduled past the wave timer (duration).
		# Safety net for a too-long interval / bad startAt (the load-time warning in
		# MapParser flags it; this enforces it). The k-th enemy (0-indexed) is
		# scheduled at startAt + k*interval. When we cut off, mark the group spawned
		# so the wave can still end (else _allGroupsSpawned stays false -> softlock),
		# and re-check end since the field may already be clear at the cutoff moment.
		if groupData.startAt + float(spawned) * interval > waveData.duration:
			groupSpawnRemain[groupIndex] = 0
			isSpawnAllEnemy = _allGroupsSpawned()
			checkEndWave()
			return
		spawnEnemy(groupIndex);
		spawned += 1;
		remain -= 1;
		groupSpawnRemain[groupIndex] = remain

		if remain == 0:
			isSpawnAllEnemy = _allGroupsSpawned()
		else:
			await get_tree().create_timer(interval).timeout

func spawnEnemy(groupIndex: int):
	if(groupIndex >= waveData.groupList.size()):
		return;

	var waveGroup = waveData.groupList[groupIndex];

	# Look up the enemy definition (stats + skills + tier) from the per-map enemy DB.
	# Fail loud on a bad id instead of silently spawning a default-tier enemy (R7).
	var db: EnemyDBData = ResourceManager.getEnemyData(waveGroup.enemy)
	if db == null:
		push_error("WaveController: unknown enemy id '" + str(waveGroup.enemy) + "' (not in the map's enemy DB)")
		return

	# Resolve final base stats: enemy DB stats + stage modifiers + this wave's
	# modifiers, stacked additively (EnemyModifier). Applied BEFORE the enemy is
	# built so Enemy.setup() seeds maxHp/currentHp/healthbar from the final numbers.
	var final_stats = EnemyModifier.resolve(db.stats, [data.stageModifiers, waveData.waveModifiers])
	var health = int(final_stats.hp)
	var def = int(final_stats.def)
	var mDef = int(final_stats.mDef)
	var moveSpeed = final_stats.moveSpeed
	var damageReduction = final_stats.damageReduction

	var texture = enemyTextures.get(waveGroup.enemy, null)
	var skills: Array[Skill] = []
	for skill in db.skills:
		skills.append(Utility.deep_duplicate_resource(skill))

	# Reserve count BEFORE the async spawn so the in-flight createEnemyObject
	# await window can't cause a premature wave-end. Otherwise, the while loop
	# in spawnEnemyTask flips isSpawnAllEnemy = true while the final enemy is
	# still being instantiated; if previously-spawned enemies have already
	# died / reached the end, checkEndWave would see alive=0 + spawnedAll=true
	# and call endWave() before the uncounted enemy is even on the map.
	enemyAliveCount += 1;

	# Resolve enemy tier from the id (registered by ResourceManager.preloadEnemy
	# from the enemy DB). Elite enemies deal Elite-tier damage (10) on reach-end
	# and are correctly tagged for downstream type-aware logic. Default to Normal.
	var enemy_type := _tierToEnemyType(ResourceManager.getEnemyTier(waveGroup.enemy))

	var enemy: Enemy = await createEnemyObject(enemy_type, health, def, mDef, moveSpeed, texture, skills, damageReduction);

	if enemy == null:
		# Spawn failed — undo the reservation so the count stays accurate.
		enemyAliveCount -= 1;
		return;

	enemy.display_name = db.display_name;
	connectSignalToEnemy(enemy);

func _tierToEnemyType(tier: String) -> Enemy.EnemyType:
	match tier:
		"boss":
			return Enemy.EnemyType.Boss
		"elite":
			return Enemy.EnemyType.Elite
		_:
			return Enemy.EnemyType.Normal

func spawnBoss():
	var result = bossList.filter(func(b):
		return b.wave.has(currWave);
	)

	if result.is_empty():
		push_error("No boss found for current wave ", currWave)
		return

	var bossData: BossDBData;

	if(result.size() > 1):
		bossData = result[randi_range(0, result.size() - 1)]
	else:
		bossData = result[0]

	var texture = bossData.texture;
	var health = bossData.stats.hp
	var def = bossData.stats.def
	var mDef = bossData.stats.mDef
	var moveSpeed = bossData.stats.moveSpeed
	# Deep-duplicate per spawn: BossDBData holds one parsed skill template per boss,
	# so each spawn must get its own copy or per-instance state
	# (cooldownRemaining/using/disable) would collide across boss spawns. Mirrors spawnEnemy.
	var skills: Array[Skill] = []
	for skill in bossData.skills:
		skills.append(Utility.deep_duplicate_resource(skill))

	# Reserve count BEFORE the async spawn (same race-condition guard as
	# spawnEnemy — checkEndWave can fire while boss creation is still in flight).
	isSpawnAllEnemy = true;
	enemyAliveCount += 1;

	var boss: Enemy = await createEnemyObject(Enemy.EnemyType.Boss, health, def, mDef, moveSpeed, texture, skills, 0.0, 0.0, bossData.scale);

	if boss == null:
		enemyAliveCount -= 1;
		return;

	boss.display_name = bossData.name;
	connectSignalToEnemy(boss);
	if bossHpBar != null:
		bossHpBar.track(boss, bossData.name);

# Skill-driven mid-wave reinforcements (King's Command): spawn `count` copies of a
# roster enemy at a path position, `interval` seconds apart. Runs through the same
# accounting as scheduled spawns (modifiers, tier, signals). The WHOLE batch is
# reserved into enemyAliveCount before the first await (game_stage invariant), so
# the wave can never end while summons are still trickling out.
func summon(enemyId: String, count: int, interval: float, pathProgress: float):
	if count <= 0 or data == null or waveData == null:
		return

	var db: EnemyDBData = ResourceManager.getEnemyData(enemyId)
	if db == null:
		push_error("WaveController.summon: unknown enemy id '" + str(enemyId) + "' (not in the map's enemy DB)")
		return

	var final_stats = EnemyModifier.resolve(db.stats, [data.stageModifiers, waveData.waveModifiers])
	var texture = enemyTextures.get(enemyId, null)
	var enemy_type := _tierToEnemyType(ResourceManager.getEnemyTier(enemyId))
	var gen := currWave

	enemyAliveCount += count

	for i in range(count):
		var skills: Array[Skill] = []
		for skill in db.skills:
			skills.append(Utility.deep_duplicate_resource(skill))

		var enemy: Enemy = await createEnemyObject(enemy_type, int(final_stats.hp), int(final_stats.def), int(final_stats.mDef), final_stats.moveSpeed, texture, skills, final_stats.damageReduction, pathProgress)
		if enemy == null:
			enemyAliveCount -= 1
		else:
			# Summons render above everything on the path - the (scaled) boss
			# sprite must not hide them (Director 2026-07-07).
			enemy.z_index = 1
			enemy.display_name = db.display_name
			connectSignalToEnemy(enemy)

		if i < count - 1:
			await get_tree().create_timer(interval).timeout
			# Wave advanced during the trickle: its counters were already reset by
			# startNextWave, so the remaining reservations are void - do NOT
			# decrement (that would corrupt the new wave's count). Just stop.
			if not is_instance_valid(self) or currWave != gen:
				return

func updateUI():
	if waveCounterText != null:
		waveCounterText.text = "wave " + str(currWave)

func _startCountdown():
	_wave_elapsed = 0.0
	_countdown_active = true
	if waveTimerText != null:
		waveTimerText.text = _format_time(waveData.duration)
	if waveTimer != null:
		waveTimer.visible = true

func _stopCountdown():
	_countdown_active = false
	if waveTimer != null:
		waveTimer.visible = false

func _format_time(sec: float) -> String:
	var total: int = int(ceil(sec))
	return "%d:%02d" % [int(total / 60.0), total % 60]

func testSpawnBoss(index: int = -1):
	if(bossList.size() == 0):
		return;

	if(index < 0):
		index = randi_range(0, bossList.size() - 1);

	if(index >= bossList.size()):
		return;

	var boss = bossList[index]; # For testing, spawn the first boss in the list.

	var texture = boss.texture;
	var health = boss.stats.hp
	var def = boss.stats.def
	var mDef = boss.stats.mDef
	var moveSpeed = boss.stats.moveSpeed
	# Deep-dup skills like spawnBoss so debug spawns exercise real boss behavior
	# (skills + scale) - the whole point of the test keys.
	var skills: Array[Skill] = []
	for skill in boss.skills:
		skills.append(Utility.deep_duplicate_resource(skill))

	# Same race-condition guard as spawnEnemy / spawnBoss (debug-only path).
	enemyAliveCount += 1;
	var enemy: Enemy = await createEnemyObject(Enemy.EnemyType.Boss, health, def, mDef, moveSpeed, texture, skills, 0.0, 0.0, boss.scale);
	if enemy == null:
		enemyAliveCount -= 1;
		return;
	enemy.display_name = boss.name;
	connectSignalToEnemy(enemy);
	if bossHpBar != null:
		bossHpBar.track(enemy, boss.name);

func connectSignalToEnemy(enemy: Enemy):
	Utility.ConnectSignal(enemy, "onReachEndPoint", Callable(self, "reduceEnemyCount"));
	Utility.ConnectSignal(enemy, "onReachEndPoint", Callable(self, "enemyReachEndPoint").bind(enemy));
	Utility.ConnectSignal(enemy, "onDead", Callable(self, "enemyDead"));

func createEnemyObject(type: Enemy.EnemyType, health: int, def: int, mDef: int, moveSpeed: int, texture: Texture2D = null, skills: Array[Skill] = [], damageReduction: float = 0.0, pathProgress: float = 0.0, spawnScale: float = 1.0):

	if(enemyFactory == null):
		return;

	var instance = await enemyFactory.createEnemy(type, spawnParent, health, def, mDef, moveSpeed, texture, skills, damageReduction, pathProgress, spawnScale);
	return instance

func enemyReachEndPoint(enemy: Enemy):
	data.onEnemyReachEndpoint.call(PlayerHealth.DAMAGE_BY_MONSTER_TYPE.get(enemy.enemyType, 10));

func _allGroupsSpawned() -> bool:
	if waveData == null:
		return false
	for group in range(0, waveData.groupList.size()):
		if groupSpawnRemain.get(group, 0) > 0:
			return false
	return true

func checkEndWave():
	if isBossWave:
		if isSpawnAllEnemy && enemyAliveCount <= 0:
			endWave()
	else:
		if isSpawnAllEnemy && enemyAliveCount <= 0 && _allGroupsSpawned():
			groupSpawnRemain.clear()
			endWave()

func enemyDead(enemy: Enemy, cause: Damage, reward: EnemyReward):
	if(deadList.has(enemy)):
		return

	deadList.append(enemy);
	onEnemyDead.emit(enemy, cause, reward);
	reduceEnemyCount();

func reduceEnemyCount():
	enemyAliveCount -= 1;
	checkEndWave();

func _on_next_wave_delay_timer_timeout():
	startNextWave()

signal onWaveStart();
signal onEnemyDead(enemy: Enemy, cause: Damage, reward: EnemyReward);
