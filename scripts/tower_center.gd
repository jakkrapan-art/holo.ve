extends Node

enum DeckPreparationStatus {
	NONE,
	PENDING,
	LOADING,
	WARMING,
	READY,
	FAILED,
}

const DEFAULT_SKILL_PROJECTILE := "res://resources/combat/bullets/gawr_gura_skill_projectile.tscn"

var _towers_data: Dictionary
var _default_tower_data: Object;
var _towers_data_by_name: Dictionary

var _tower_portrait: Dictionary
var _tower_portrait_by_name: Dictionary

var _own_towers: Dictionary = {}

var _canEvoList = [];

#var selected_deck: String = ""
var selected_deck: String = "Myth" #temporary
var selected_data_file: String = "myth.yaml" #temporary
var selected_map_file: String = "forest01.yaml"

# Deck registry: static metadata from decks.yaml, loaded once at autoload init.
# added_decks tracks which decks have been merged into the live tower pool during a run.
var _decks_registry: Dictionary = {}
var added_decks: Array[String] = []
var _run_shared_resources_loaded: bool = false
var _deck_preparations: Dictionary = {}
var _committed_deck_dependencies: Dictionary = {}
var _failed_decks: Dictionary = {}
var _run_generation: int = 0
var _preparation_batch_active: bool = false
var _preparation_serial: int = 0

func _ready():
	_decks_registry = YamlParser.load_data("res://resources/database/towers/decks/decks.yaml")

func clearData():
	_run_generation += 1
	_towers_data = {}
	_default_tower_data = null

	_towers_data_by_name = {}

	_tower_portrait = {}
	_tower_portrait_by_name = {}

	_own_towers = {}

	_canEvoList = []

	added_decks = []
	_run_shared_resources_loaded = false
	_deck_preparations = {}
	_committed_deck_dependencies = {}
	_failed_decks = {}
	_preparation_batch_active = false
	ResourceManager.clearRunTowerResources()

func loadInitialDeck(deck_key: String) -> bool:
	if added_decks.has(deck_key):
		return false
	var deck_info = _decks_registry.get(deck_key, null)
	if deck_info == null:
		push_error("TowerCenter.loadInitialDeck: unknown deck_key " + deck_key)
		return false

	var data_file_path = "res://resources/database/towers/decks/" + deck_info.data_file
	var tower_list = YamlParser.load_data(data_file_path)
	if not (tower_list is Dictionary) or tower_list.is_empty():
		push_error("TowerCenter.loadInitialDeck: failed to load deck data " + data_file_path)
		return false
	_loadRunSharedResources()
	for k in tower_list:
		var td = tower_list[k]
		td.data = TowerDataLoader.load_data("res://resources/database/towers/", td.data_name.to_lower())

	if not _commitDeckData(deck_key, tower_list):
		return false
	# Pre-compile this deck's skill/bullet shaders (behind the deck / loading
	# screen, or the wave-clear popup for a mid-run unlock) so the first in-run
	# cast doesn't hitch. self (TowerCenter autoload) is the in-tree host; the
	# _warmed guard makes repeat calls only warm new shaders. Fire-and-forget.
	ResourceManager.warmSkillEffectShaders(self, tower_list.values());
	return true

func _commitDeckData(
		deck_key: String,
		tower_list: Dictionary,
		prepared_portraits: Dictionary = {},
		prepared_scenes: Dictionary = {}) -> bool:
	if added_decks.has(deck_key):
		return false
	setTowerData(tower_list, prepared_portraits)
	if prepared_scenes.is_empty():
		var new_tower_names: Array = []
		for entry in tower_list.values():
			new_tower_names.append(entry.data_name)
		ResourceManager.loadResources(new_tower_names)
	else:
		ResourceManager.cacheTowerScenes(prepared_scenes)
	added_decks.append(deck_key)
	return true

func _loadRunSharedResources() -> void:
	if _run_shared_resources_loaded:
		return
	ResourceManager.preloadSynergy()
	ResourceManager.loadSynergyData()
	EffectRegistry.load_all()
	EffectRegistry.preload_icons()
	_run_shared_resources_loaded = true

func getAvailableDecks() -> Array:
	var result := []
	for key in _decks_registry.keys():
		if !added_decks.has(key) and not _failed_decks.has(key):
			result.append({"key": key, "info": _decks_registry[key]})
	return result

func getRunGeneration() -> int:
	return _run_generation

func prepareDecks(
		deck_keys: Array,
		host: Node,
		run_generation: int,
		can_prepare: Callable,
		can_warm: Callable) -> void:
	if run_generation != _run_generation or host == null or not is_instance_valid(host):
		return
	var queued_any := false
	for raw_key in deck_keys:
		var deck_key := str(raw_key)
		if added_decks.has(deck_key) or _failed_decks.has(deck_key):
			continue
		var existing: Dictionary = _deck_preparations.get(deck_key, {})
		if int(existing.get("generation", -1)) == run_generation:
			continue
		_preparation_serial += 1
		_deck_preparations[deck_key] = {
			"status": DeckPreparationStatus.PENDING,
			"generation": run_generation,
			"token": _preparation_serial,
			"failure_reported": false,
			"resource_refs": {},
		}
		queued_any = true
	if queued_any and not _preparation_batch_active:
		_prepareDeckBatch(host, run_generation, can_prepare, can_warm)

func _prepareDeckBatch(
		host: Node,
		run_generation: int,
		can_prepare: Callable,
		can_warm: Callable) -> void:
	_preparation_batch_active = true
	while run_generation == _run_generation and is_instance_valid(host):
		var deck_key := ""
		for raw_key in _deck_preparations.keys():
			var candidate: Dictionary = _deck_preparations.get(raw_key, {})
			if (
					int(candidate.get("generation", -1)) == run_generation
					and int(candidate.get("status", DeckPreparationStatus.NONE)) == DeckPreparationStatus.PENDING
			):
				deck_key = str(raw_key)
				break
		if deck_key != "":
			await _prepareDeck(deck_key, host, run_generation, can_prepare)
			continue
		# Prepare every candidate's CPU/file bundle before waiting on GPU warmup.
		# This lets the one-wave-early window do useful work for all candidates.
		for raw_key in _deck_preparations.keys():
			var candidate: Dictionary = _deck_preparations.get(raw_key, {})
			if (
					int(candidate.get("generation", -1)) == run_generation
					and int(candidate.get("status", DeckPreparationStatus.NONE)) == DeckPreparationStatus.WARMING
			):
				deck_key = str(raw_key)
				break
		if deck_key != "":
			await _warmPreparedDeck(deck_key, host, run_generation, can_warm)
			continue
		break
	if run_generation == _run_generation:
		_preparation_batch_active = false

func _prepareDeck(
		deck_key: String,
		host: Node,
		run_generation: int,
		can_prepare: Callable) -> void:
	var bundle: Dictionary = _deck_preparations.get(deck_key, {})
	var token := int(bundle.get("token", -1))
	if not await _waitForPreparationWindow(deck_key, token, host, run_generation, can_prepare):
		return
	bundle["status"] = DeckPreparationStatus.LOADING

	var deck_info = _decks_registry.get(deck_key, null)
	if not (deck_info is Dictionary):
		_failDeckPreparation(deck_key, token, run_generation, "decks.yaml:" + deck_key)
		return
	var data_file := str(deck_info.get("data_file", ""))
	var deck_path := "res://resources/database/towers/decks/" + data_file
	if data_file == "" or not FileAccess.file_exists(deck_path):
		_failDeckPreparation(deck_key, token, run_generation, deck_path)
		return
	var tower_list = YamlParser.load_data(deck_path)
	if not (tower_list is Dictionary) or tower_list.is_empty():
		_failDeckPreparation(deck_key, token, run_generation, deck_path)
		return

	var resource_paths: Dictionary = {}
	var portrait_paths: Dictionary = {}
	var tower_scene_paths: Dictionary = {}
	var raw_tower_data: Dictionary = {}
	var deck_cover_path := "res://resources/" + str(deck_info.get("sprite", ""))
	if not _addRequiredResourcePath(deck_cover_path, resource_paths):
		_failDeckPreparation(deck_key, token, run_generation, deck_cover_path)
		return

	for wrapper_key in tower_list.keys():
		if not await _waitForPreparationWindow(deck_key, token, host, run_generation, can_prepare):
			return
		var entry = tower_list[wrapper_key]
		if not (entry is Dictionary):
			_failDeckPreparation(deck_key, token, run_generation, deck_path + ":" + str(wrapper_key))
			return
		var data_name := str(entry.get("data_name", ""))
		if data_name == "":
			_failDeckPreparation(deck_key, token, run_generation, deck_path + ":" + str(wrapper_key) + ".data_name")
			return
		var tower_yaml_path := "res://resources/database/towers/" + data_name.to_lower() + ".yaml"
		if not FileAccess.file_exists(tower_yaml_path):
			_failDeckPreparation(deck_key, token, run_generation, tower_yaml_path)
			return
		var raw_data = YamlParser.load_data(tower_yaml_path)
		if not (raw_data is Dictionary) or raw_data.is_empty():
			_failDeckPreparation(deck_key, token, run_generation, tower_yaml_path)
			return
		raw_tower_data[data_name] = raw_data
		_collectResourcePaths(raw_data, resource_paths)

		var portrait_path := "res://resources/tower/portrait/" + data_name + ".png"
		var tower_scene_path: String = (
				ResourceManager.towerDirPrefix + data_name.to_lower() + ".tscn")
		portrait_paths[data_name] = portrait_path
		tower_scene_paths[data_name] = tower_scene_path
		if not _addRequiredResourcePath(portrait_path, resource_paths):
			_failDeckPreparation(deck_key, token, run_generation, portrait_path)
			return
		if not _addRequiredResourcePath(tower_scene_path, resource_paths):
			_failDeckPreparation(deck_key, token, run_generation, tower_scene_path)
			return

	# Several skill action loaders use this default when their YAML omits a path.
	if not _addRequiredResourcePath(DEFAULT_SKILL_PROJECTILE, resource_paths):
		_failDeckPreparation(deck_key, token, run_generation, DEFAULT_SKILL_PROJECTILE)
		return
	if not await _loadPreparedResourcePaths(
			deck_key, token, bundle, resource_paths.keys(), host, run_generation):
		return

	# Build typed data only after loader-visible resources are cached, one tower per
	# safe frame. Any load() inside TowerDataLoader is therefore a cache hit.
	for wrapper_key in tower_list.keys():
		if not await _waitForPreparationWindow(deck_key, token, host, run_generation, can_prepare):
			return
		var entry: Dictionary = tower_list[wrapper_key]
		var data_name := str(entry.get("data_name", ""))
		var typed_data := TowerDataLoader.load_from_dict(
				raw_tower_data[data_name], data_name.to_lower())
		if typed_data == null:
			_failDeckPreparation(
					deck_key,
					token,
					run_generation,
					"res://resources/database/towers/" + data_name.to_lower() + ".yaml")
			return
		entry.data = typed_data

	# Effect scripts are now cached, so discovering their SHADER_PATH constants is
	# cache-only. Request any discovered shaders before the GPU warm pass.
	var shader_paths := ResourceManager.collectSkillEffectShaderPaths(tower_list.values())
	if not await _loadPreparedResourcePaths(
			deck_key, token, bundle, shader_paths, host, run_generation):
		return

	var prepared_portraits: Dictionary = {}
	for data_name in portrait_paths.keys():
		var portrait = bundle.resource_refs.get(portrait_paths[data_name], null)
		if not (portrait is Texture2D):
			_failDeckPreparation(deck_key, token, run_generation, str(portrait_paths[data_name]))
			return
		prepared_portraits[data_name] = portrait
	var prepared_scenes: Dictionary = {}
	for data_name in tower_scene_paths.keys():
		var tower_scene = bundle.resource_refs.get(tower_scene_paths[data_name], null)
		if not (tower_scene is PackedScene):
			_failDeckPreparation(deck_key, token, run_generation, str(tower_scene_paths[data_name]))
			return
		prepared_scenes[data_name] = tower_scene
	var deck_cover = bundle.resource_refs.get(deck_cover_path, null)
	if not (deck_cover is Texture2D):
		_failDeckPreparation(deck_key, token, run_generation, deck_cover_path)
		return

	bundle["tower_list"] = tower_list
	bundle["portraits"] = prepared_portraits
	bundle["tower_scenes"] = prepared_scenes
	bundle["deck_cover"] = deck_cover
	bundle["shader_paths"] = shader_paths
	bundle["status"] = DeckPreparationStatus.WARMING

func _warmPreparedDeck(
		deck_key: String,
		host: Node,
		run_generation: int,
		can_warm: Callable) -> void:
	var bundle: Dictionary = _deck_preparations.get(deck_key, {})
	var token := int(bundle.get("token", -1))
	var shader_paths: Array = bundle.get("shader_paths", [])
	var warmed := await ResourceManager.warmPreparedShaderPaths(
			host,
			shader_paths,
			can_warm,
			Callable(self, "_isDeckPreparationCurrent").bind(deck_key, token, run_generation))
	if not _isDeckPreparationCurrent(deck_key, token, run_generation):
		return
	if not warmed:
		_failDeckPreparation(deck_key, token, run_generation, "shader warmup:" + deck_key)
		return
	bundle["status"] = DeckPreparationStatus.READY

func _waitForPreparationWindow(
		deck_key: String,
		token: int,
		host: Node,
		run_generation: int,
		can_prepare: Callable) -> bool:
	while _isDeckPreparationCurrent(deck_key, token, run_generation):
		if host == null or not is_instance_valid(host) or not host.is_inside_tree():
			return false
		if can_prepare.call():
			# CPU-side YAML/typed parsing is deliberately limited to one chunk per
			# frame so preparation cannot create a new long frame of its own.
			await host.get_tree().process_frame
			if (
					_isDeckPreparationCurrent(deck_key, token, run_generation)
					and is_instance_valid(host)
					and can_prepare.call()
			):
				return true
			continue
		await host.get_tree().process_frame
	return false

func _loadPreparedResourcePaths(
		deck_key: String,
		token: int,
		bundle: Dictionary,
		paths: Array,
		host: Node,
		run_generation: int) -> bool:
	var pending: Dictionary = {}
	for raw_path in paths:
		var path := str(raw_path)
		if path == "" or bundle.resource_refs.has(path):
			continue
		if not ResourceLoader.exists(path):
			_failDeckPreparation(deck_key, token, run_generation, path)
			return false
		var cached = null
		if ResourceLoader.has_cached(path):
			cached = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
		if cached != null:
			bundle.resource_refs[path] = cached
			continue
		var error := ResourceLoader.load_threaded_request(
				path, "", false, ResourceLoader.CACHE_MODE_REUSE)
		if error != OK:
			var existing_status := ResourceLoader.load_threaded_get_status(path)
			if existing_status != ResourceLoader.THREAD_LOAD_IN_PROGRESS \
					and existing_status != ResourceLoader.THREAD_LOAD_LOADED:
				_failDeckPreparation(deck_key, token, run_generation, path)
				return false
		pending[path] = true

	while not pending.is_empty():
		if not _isDeckPreparationCurrent(deck_key, token, run_generation):
			return false
		if host == null or not is_instance_valid(host) or not host.is_inside_tree():
			return false
		for path in pending.keys():
			var status := ResourceLoader.load_threaded_get_status(path)
			if status == ResourceLoader.THREAD_LOAD_FAILED \
					or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_failDeckPreparation(deck_key, token, run_generation, path)
				return false
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				var resource = ResourceLoader.load_threaded_get(path)
				if resource == null:
					_failDeckPreparation(deck_key, token, run_generation, path)
					return false
				bundle.resource_refs[path] = resource
				pending.erase(path)
		if not pending.is_empty():
			await host.get_tree().process_frame
	return true

func _addRequiredResourcePath(path: String, paths: Dictionary) -> bool:
	if path == "" or not path.begins_with("res://") or not ResourceLoader.exists(path):
		return false
	paths[path] = true
	return true

func _collectResourcePaths(value, paths: Dictionary) -> void:
	if value is Dictionary:
		for child in value.values():
			_collectResourcePaths(child, paths)
		return
	if value is Array:
		for child in value:
			_collectResourcePaths(child, paths)
		return
	if not (value is String):
		return
	var path := str(value)
	if path.begins_with("res://"):
		paths[path] = true
		return
	var extension := path.get_extension().to_lower()
	if extension in ["tscn", "tres", "res", "gd", "gdshader", "png", "webp", "svg", "ogg", "wav", "mp3"]:
		paths["res://resources/" + path] = true

func _isDeckPreparationCurrent(deck_key: String, token: int, run_generation: int) -> bool:
	if run_generation != _run_generation:
		return false
	var bundle: Dictionary = _deck_preparations.get(deck_key, {})
	return int(bundle.get("token", -1)) == token

func _failDeckPreparation(
		deck_key: String,
		token: int,
		run_generation: int,
		failed_path: String) -> void:
	if not _isDeckPreparationCurrent(deck_key, token, run_generation):
		return
	var bundle: Dictionary = _deck_preparations[deck_key]
	bundle["status"] = DeckPreparationStatus.FAILED
	bundle["failed_path"] = failed_path
	_failed_decks[deck_key] = true
	if not bool(bundle.get("failure_reported", false)):
		bundle["failure_reported"] = true
		push_error("Deck preparation failed: deck=%s path=%s" % [deck_key, failed_path])

func getDeckPreparationStatus(deck_key: String, run_generation: int) -> int:
	if run_generation != _run_generation:
		return DeckPreparationStatus.NONE
	var bundle: Dictionary = _deck_preparations.get(deck_key, {})
	return int(bundle.get("status", DeckPreparationStatus.NONE))

func isDeckPrepared(deck_key: String, run_generation: int) -> bool:
	return getDeckPreparationStatus(deck_key, run_generation) == DeckPreparationStatus.READY

func areDeckPreparationsSettled(deck_keys: Array, run_generation: int) -> bool:
	if run_generation != _run_generation:
		return true
	for raw_key in deck_keys:
		var status := getDeckPreparationStatus(str(raw_key), run_generation)
		if status != DeckPreparationStatus.READY and status != DeckPreparationStatus.FAILED:
			return false
	return true

func getPreparedDeckCover(deck_key: String, run_generation: int) -> Texture2D:
	if not isDeckPrepared(deck_key, run_generation):
		return null
	return _deck_preparations[deck_key].get("deck_cover", null) as Texture2D

func commitPreparedDeck(deck_key: String, run_generation: int) -> bool:
	if not isDeckPrepared(deck_key, run_generation) or added_decks.has(deck_key):
		return false
	var bundle: Dictionary = _deck_preparations[deck_key]
	var tower_list: Dictionary = bundle.get("tower_list", {})
	var portraits: Dictionary = bundle.get("portraits", {})
	var tower_scenes: Dictionary = bundle.get("tower_scenes", {})
	if tower_list.is_empty() or portraits.size() != tower_list.size() or tower_scenes.size() != tower_list.size():
		return false
	if not _commitDeckData(deck_key, tower_list, portraits, tower_scenes):
		return false
	_committed_deck_dependencies[deck_key] = bundle.get("resource_refs", {})
	return true

func rejectPreparedDeck(deck_key: String, run_generation: int, reason: String) -> void:
	if run_generation != _run_generation:
		return
	var bundle: Dictionary = _deck_preparations.get(deck_key, {})
	var token := int(bundle.get("token", -1))
	if token >= 0:
		_failDeckPreparation(deck_key, token, run_generation, reason)
	else:
		_failed_decks[deck_key] = true
		push_error("Deck preparation rejected: deck=%s reason=%s" % [deck_key, reason])

func retainDeckPreparations(deck_keys: Array, run_generation: int) -> void:
	if run_generation != _run_generation:
		return
	var retain: Dictionary = {}
	for raw_key in deck_keys:
		retain[str(raw_key)] = true
	for deck_key in _deck_preparations.keys():
		if not retain.has(deck_key):
			_deck_preparations.erase(deck_key)

func clearDeckPreparations(run_generation: int) -> void:
	if run_generation == _run_generation:
		_deck_preparations = {}

func cancelDeckPreparation(run_generation: int) -> void:
	if run_generation != _run_generation:
		return
	_run_generation += 1
	_deck_preparations = {}
	_committed_deck_dependencies = {}
	_failed_decks = {}
	_preparation_batch_active = false
	ResourceManager.clearRunTowerResources()

func endRun(run_generation: int) -> void:
	if run_generation == _run_generation:
		clearData()

func setTowerData(datas: Dictionary, prepared_portraits: Dictionary = {}):
	for k in datas.keys():
		var data = datas.get(k, null)
		if(data != null):
			_towers_data[data.data_name] = data;
			_towers_data_by_name[data.name.to_lower()] = data

			var portrait: Texture2D = prepared_portraits.get(data.data_name, null)
			if portrait == null:
				portrait = preloadPortrait(data.data_name)
			else:
				ResourceManager.cacheImage("portrait", data.data_name, portrait)

			_tower_portrait[data.data_name] = portrait
			_tower_portrait_by_name[data.name.to_lower()] = portrait

func setDefaultTowerData(data):
	_default_tower_data = data

func preloadPortrait(p_name: String):
	return ResourceManager.loadImage("portrait", p_name, "tower/portrait/" + p_name + ".png")

func getTowerData(key: String):
	if(key == "default"):
		return _default_tower_data;

	if _towers_data == null:
		return null

	return _towers_data.get(key, null)

func getTowerDataByName(p_name: String):
	if(p_name == "default"):
		return _default_tower_data;

	if _towers_data_by_name == null:
		return null

	return _towers_data_by_name.get(p_name.to_lower(), null)

func getTowerNames():
	var names = []
	for k in _towers_data.keys():
		var data = _towers_data.get(k, null)
		if(data != null):
			names.append(data.name)

	return names

func getTowerSelectDataByName(p_name: String):
	if _own_towers == null:
		return null

	var data = _own_towers.get(p_name.to_lower(), null);
	if(data != null):
		var maxed: bool = data.level >= data.maxLevel and not data.isEvolved
		return {"level": data.level, "evoCost": data.evoCost if maxed else 0}

	return {"level":0, "evoCost":0}

func validateSelectTower(p_name: String, evoToken: int):
	if _own_towers == null:
		return false

	var data = _own_towers.get(p_name.to_lower(), null);
	if(data != null):
		if data.isEvolved:
			return false
		var maxed: bool = data.level >= data.maxLevel
		if maxed:
			return canEvolveTowerByName(p_name, evoToken, data.evoCost)

		return true

	return true

func canEvolveTowerByName(p_name: String, available_tokens: int, expected_cost: int) -> bool:
	if _own_towers == null:
		return false

	var data = _own_towers.get(p_name.to_lower(), null);
	if data == null:
		return false

	return (
		data.level >= data.maxLevel
		and not data.isEvolved
		and data.evoCost == expected_cost
		and available_tokens >= expected_cost
	)

func getTowerEvolutionCostByName(p_name: String):
	if _own_towers == null:
		return null

	var data = _own_towers.get(p_name.to_lower(), null);
	if(data != null):
		if(data.level >= data.maxLevel):
			return data.evoCost
		else:
			return 0;

	return 0

func upgradeTowerLevelByName(p_name: String):
	if _own_towers == null:
		return null

	var data = _own_towers.get(p_name.to_lower(), null);
	if(data != null):
		if(data.isEvolved or data.level >= data.maxLevel):
			return
		data.level += 1
		if(data.level >= data.maxLevel):
			if not _canEvoList.has(p_name):
				_canEvoList.append(p_name);
	else:
		var tData = getTowerDataByName(p_name);
		if(tData == null):
			return
		var d = tData.data;
		var evoCost = d.evolutionCost;
		var maxLevel = d.maxLevel;
		_own_towers[p_name.to_lower()] = {"level": 1, "maxLevel": maxLevel, "evoCost": evoCost, "isEvolved": false};

func evolveTowerByName(p_name: String) -> bool:
	if _own_towers == null:
		return false

	var data = _own_towers.get(p_name.to_lower(), null);
	if data == null or data.isEvolved or data.level < data.maxLevel:
		return false

	data.isEvolved = true;
	_canEvoList.erase(p_name);
	return true

func getTowerPortraitByName(p_name: String):
	if _tower_portrait_by_name == null:
		return null
	var portrait = _tower_portrait_by_name.get(p_name.to_lower(), null);
	if(portrait != null):
		return portrait

	return null

func getEvolutionList(count: int):
	if(_canEvoList.size() <= count):
		return _canEvoList;

	var temp = _canEvoList.duplicate();
	var result = []
	for i in range(count):
		var index = randi_range(0, temp.size() - 1);
		var towerName = temp[index];
		result.append(towerName);
		temp.remove_at(index);
	return result;
