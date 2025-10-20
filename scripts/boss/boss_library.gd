class_name BossLibrary

var sourcePrefix: String = "res://resources/database/boss/";
var source: String = sourcePrefix + "boss_library.yaml";

var bossPool: Dictionary = {};

func _init():
	var data = YamlParser.load_data(source);
	for d in data:
		var fileName = d["fileName"];
		var bossDatas = YamlParser.load_data(sourcePrefix + fileName + ".yaml");
		var bossList: Array[BossDBData] = [];
		# var skillPool = [];
		for bd in bossDatas:
			var name = bd.name;
			var texturePath = "res://resources/enemy/basic_map01/boss/" + bd.texture + "/" + bd.texture + ".png";
			var texture = load(texturePath);
			if texture == null:
				print("Error: Failed to load texture at path:", texturePath);

			var bossSkills: Array[Skill] = [];
			if bd.has("skill") and bd.skill.size() > 0:
				bossSkills = SkillUtility.ParseSkill(bd.skill);

			var bossDBData = BossDBData.new(name, texture, bd.scale, bd.stats, bossSkills);
			bossList.append(bossDBData);
		bossPool[d.map] = {"boss": bossList, "skill": []};

func getBossList(key: String) -> Array[BossDBData]:
	if bossPool.has(key):
		return bossPool[key]["boss"];
	return [];
