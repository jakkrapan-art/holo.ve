class_name MapParser

static func ParseData(data: Dictionary) -> MapData:
	var mapData: MapData = MapData.new();
	mapData.mapName = data.get("mapName", "default_map");
	mapData.width = data.get("width", 20);
	mapData.height = data.get("height", 15);
	var waveRaw = data.get("waves", []);
	for waveDict in waveRaw:
		var waveData: WaveData = WaveData.new();
		waveData.waveTime = waveDict.get("waveTime", 60);
		waveData.isBossWave = waveDict.get("boss", false);
		if(waveData.isBossWave):
			mapData.waves.append(waveData);
			continue;
		var groupRaw = waveDict.get("groupList", []);
		for groupDict in groupRaw:
			var group: WaveEnemyGroup = WaveEnemyGroup.new();
			group.texture = groupDict.get("texture", "default");
			group.health = groupDict.get("health", 20);
			group.def = groupDict.get("def", 1);
			group.mDef = groupDict.get("mDef", 1);
			group.moveSpeed = groupDict.get("moveSpeed", 5);
			group.count = groupDict.get("count", 20);
			group.spawnInterval = groupDict.get("spawnInterval", 1);
			var skillDataRaw = groupDict.get("skill", []);
			if(skillDataRaw != null && skillDataRaw is Array && skillDataRaw.size() > 0):
				var skillDataArray: Array[Skill] = SkillUtility.ParseSkill(skillDataRaw);
				group.skill = skillDataArray;
			waveData.addGroup(group);
		mapData.waves.append(waveData);
	return mapData;
