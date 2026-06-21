class_name MapParser

static func ParseData(data: Dictionary) -> MapData:
	var mapData: MapData = MapData.new();
	mapData.mapName = data.get("mapName", "default_map");
	mapData.width = data.get("width", 20);
	mapData.height = data.get("height", 15);
	mapData.stageModifiers = EnemyModifier.parse(data.get("stageModifiers", []));

	var waveRaw = data.get("waves", []);
	var waveNum := 0;
	for waveDict in waveRaw:
		waveNum += 1;
		var waveData: WaveData = WaveData.new();
		waveData.duration = waveDict.get("duration", 60);
		waveData.isBossWave = waveDict.get("boss", false);
		waveData.waveModifiers = EnemyModifier.parse(waveDict.get("waveModifiers", []));
		if(waveData.isBossWave):
			mapData.waves.append(waveData);
			continue;
		var groupRaw = waveDict.get("groupList", []);
		for groupDict in groupRaw:
			var group: WaveEnemyGroup = WaveEnemyGroup.new();
			group.enemy = groupDict.get("enemy", "");
			group.count = groupDict.get("count", 20);
			group.spawnInterval = groupDict.get("spawnInterval", 1);
			group.startAt = groupDict.get("startAt", 0);
			_checkSpawnFitsDuration(waveNum, waveData.duration, group);
			waveData.addGroup(group);
		mapData.waves.append(waveData);
	return mapData;

# Load-time guard (runs once at map parse, NOT per frame): warn when a group's
# spawn schedule runs past the wave timer, i.e. enemies would still spawn after the
# countdown reaches 0. Last spawn time = startAt + (count - 1) * spawnInterval.
static func _checkSpawnFitsDuration(waveNum: int, duration: float, group: WaveEnemyGroup) -> void:
	if group.count <= 0:
		return;
	var last_spawn: float = group.startAt + float(group.count - 1) * group.spawnInterval;
	if last_spawn > duration:
		var max_interval: float = (duration - group.startAt) / float(group.count);
		push_warning("MapParser: wave %d group '%s' spawns past the wave timer (last spawn %.1fs > duration %.1fs). Lower spawnInterval to <= (duration - startAt)/count = %.2f." % [waveNum, group.enemy, last_spawn, duration, max_interval]);
