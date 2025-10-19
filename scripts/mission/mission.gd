class_name Mission

var missionKeywordCategory: Dictionary = {}
var missionList: Dictionary = {}

func _init():
	pass;

func addMission(mission: MissionDetail):
	if(missionList.has(mission.id)):
		return;

	var category: Array[MissionDetail];

	if(missionKeywordCategory.has(mission.keyword)):
		category = missionKeywordCategory.get(mission.keyword);
	else:
		category = []

	missionList[mission.id] = mission;

	category.append(mission);
	missionKeywordCategory[mission.keyword] = category;

func removeMission(id: int):
	var mission: MissionDetail = missionList.get(id);
	if(mission == null):
		return;

	missionList.erase(id);
	if(missionKeywordCategory.has(mission.keyword)):
		var category: Array[MissionDetail] = missionKeywordCategory[mission.keyword];
		category.erase(mission);
		if(category.is_empty()):
			missionKeywordCategory.erase(mission.keyword);

func updateMissionProgressById(id: int, amount: int):
	if(!missionList.has(id)):
		return;

	var mission: MissionDetail = missionList.get(id);
	mission.updateProgress(amount);

func updateMissionProgressByKeyword(keyword, amount: int):
	if(!missionKeywordCategory.has(keyword)):
		return;

	var category = missionKeywordCategory.get(keyword);
	for mission in category:
		updateMissionProgressById(mission.id, amount);

func getMission(id: int) -> MissionDetail:
	return missionList.get(id, null);

func enemyDeadCheck(cause: Damage, _reward):
	updateMissionProgressByKeyword("kill_enemy", 1);
	if(cause.source is Tower):
		var tower: Tower = cause.source as Tower
		updateMissionProgressByKeyword(str(tower.data.towerClass) + "kill_enemy", 1);
		updateMissionProgressByKeyword(str(tower.data.generation) + "kill_enemy", 1);
