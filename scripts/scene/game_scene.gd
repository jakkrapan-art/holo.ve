extends Node2D;
class_name GameScene;

# Load the pop-up panel scene
var PopupPanelScene = preload("res://resources/ui_component/tower_select/tower_select.tscn");

@onready var waveController: WaveController = $WaveController;
@onready var player: Player = $Player
@onready var map: Map = $TileMap
# @export var mapData: MapData = null;
@onready var towerFactory: TowerFactory = $TowerFactory;

# Wave numbers (1-indexed, end-of-wave) at which the player is offered an extra deck
# to merge into the tower pool. Demo default = [5]. Inspector-editable.
@export var deck_unlock_waves: Array[int] = [5]

# Pause between boss-wave end and the wave-end popup opening, so the
# EvoTokenDrop pop-in / hold / float-fade sequence is visible before the
# popup overlays it. Slightly shorter than EvoTokenDrop.TOTAL_DURATION
# (currently 2.5 s) so the popup arrives during the last fade beat.
const BOSS_WAVE_END_POPUP_DELAY := 2.2

var mission: Mission = null;
var t: Tower = null
var state: String = ""
var _popup_open: bool = false

func _input(event):
	if state == "tower_placement" and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if(t != null && !t.isOnValidCell):
			return;

		t.exitPlaceMode();
		t = null;
		if(map != null):
			map.toggle_grid(false);
		startWave();

func _ready():
	TowerCenter.clearData();
	var b: BossLibrary = BossLibrary.new();

	TowerCenter.addDeck(TowerCenter.selected_deck)
	var default = TowerDataLoader.load_data("res://resources/database/towers/", "default_tower")
	TowerCenter.setDefaultTowerData(default)
	ResourceManager.loadResources();
	var camera = get_node("Camera2D")
	camera.make_current()
	print("Camera forced to current:", camera.is_current())
	if(map != null):
		map.setup();

	show_popup_panel();

	ResourceManager.preloadEnemy("forest01", ["boss","elite", "normal"]);

	mission = Mission.new();

	if (towerFactory):
		towerFactory.setup(Callable(self, "placeTower"), Callable(self, "removeTower"));
		Utility.ConnectSignal(towerFactory, "onReceiveMission", Callable(mission, "addMission"));

	if (waveController):
		var mapRaw = YamlParser.load_data("res://resources/database/map/" + TowerCenter.selected_map_file);
		var mapData: MapData= MapParser.ParseData(mapRaw);
		var waves = mapData.waves;

		var waveControllerData: WaveControllerData = WaveControllerData.new();
		waveControllerData.waveDatas = waves;
		waveControllerData.onEnemyReachEndpoint = Callable(self, "reducePlayerHp");
		waveControllerData.onWaveEnd = Callable(self, "on_wave_ended");

		waveController.setup(waveControllerData);

		var bossList: Array[BossDBData] = b.getBossList(mapData.mapName);
		waveController.setBossList(bossList);

		waveController.connect("onWaveStart", Callable(towerFactory, "onWaveStart"));
		Utility.ConnectSignal(waveController, "onEnemyDead", Callable(player, "processReward"));
		Utility.ConnectSignal(waveController, "onEnemyDead", Callable(mission, "enemyDeadCheck"));
		Utility.ConnectSignal(waveController, "onEnemyDead", Callable(self, "_on_enemy_dead_visual"));

func placeTower(cell: Vector2):
	map.removeAvailableCell(cell);

func removeTower(cell: Vector2):
	map.addAvailableCell(cell);

func checkValidCell(cell: Vector2):
	return !map.grids.has(cell);
func reducePlayerHp(amount: int):
	player.updateHp(-amount);

func on_wave_ended():
	if towerFactory != null:
		towerFactory.onWaveEnd()

	# Hold the wave-end popup back briefly on boss waves so the token drop
	# visual at the boss death position is readable before the popup covers it.
	if waveController != null and waveController.isBossWave:
		await get_tree().create_timer(BOSS_WAVE_END_POPUP_DELAY).timeout
		# Re-entry guard: scene may have been freed mid-wait (e.g. game-over).
		if !is_instance_valid(self):
			return

	# At configured wave milestones, offer one of the remaining decks BEFORE
	# the normal tower-select popup. Pre-filter empty decks so the popup never
	# opens with nothing to pick.
	if deck_unlock_waves.has(waveController.currWave) and !TowerCenter.getAvailableDecks().is_empty():
		show_deck_popup()
	else:
		show_popup_panel()

func show_deck_popup():
	if _popup_open:
		print("show_deck_popup: popup already open, ignoring duplicate call")
		return

	var popup: UITowerSelect = PopupPanelScene.instantiate() as UITowerSelect
	_popup_open = true
	get_tree().root.add_child(popup)

	var cards: Array = []
	for deck in TowerCenter.getAvailableDecks():
		var card = TowerSelectData.new(deck.key, 0, 0)
		var sprite_path = "res://resources/" + deck.info.sprite
		if ResourceLoader.exists(sprite_path):
			card.icon = load(sprite_path)
		cards.append(card)

	popup.tower_select.connect(Callable(self, "_on_deck_selected"))
	Utility.ConnectSignal(popup, "tower_select_skipped", Callable(self, "_on_deck_skipped"))
	# NOTE: tree_exited intentionally NOT connected here. The deck popup's deferred
	# queue_free would fire tree_exited AFTER the follow-up tower popup is already
	# open, and would erroneously reset _popup_open while the tower popup is alive.
	# Flag handoff is explicit in _on_deck_selected / _on_deck_skipped below; the
	# tower popup wires its own tree_exited via show_popup_panel().

	popup.setup_with_cards(cards, 0)

func _on_deck_selected(deck_key: String):
	TowerCenter.addDeck(deck_key)
	# Hand off the popup flag from the (about-to-free) deck popup to the tower popup.
	_popup_open = false
	show_popup_panel()

func _on_deck_skipped():
	# Safety net: getAvailableDecks() pre-filter prevents an empty deck popup
	# in normal flow. If the popup self-skips anyway, fall through to tower select.
	_popup_open = false
	show_popup_panel()

func show_popup_panel():
	# Prevent opening multiple popups if this function is called repeatedly
	if _popup_open:
		print("show_popup_panel: popup already open, ignoring duplicate call")
		return

	var popup: UITowerSelect = PopupPanelScene.instantiate() as UITowerSelect;
	_popup_open = true
	# Ensure it's added to the UI layer, not just as a child of the 2D scene
	get_tree().root.add_child(popup)

	# Connect signals BEFORE setup() — popup may emit tower_select_skipped during
	# setup() when no valid towers exist (all maxed/evolved with insufficient evoToken).
	popup.tower_select.connect(Callable(self, "_on_option_selected"))
	Utility.ConnectSignal(popup, "tower_select_skipped", Callable(self, "_on_tower_select_skipped"));
	# When the popup is closed/freed, allow it to be opened again
	Utility.ConnectSignal(popup, "tree_exited", Callable(self, "_on_popup_closed"));

	var evoToken = player.wallet.getEvoToken();
	popup.setup(evoToken, 1000);

	return

func _on_popup_closed():
	_popup_open = false

func _on_tower_select_skipped():
	print("Tower select skipped — no valid towers available")
	startWave()

# Handle the selection from the popup
func _on_option_selected(selection):
	# selection = "gawr_gura"
	print("Selected:", selection)
	var tower = TowerCenter.getTowerDataByName(selection);
	if(tower == null):
		print("Error: Tower data not found for selection:", selection)
		return

	TowerCenter.upgradeTowerLevelByName(selection);
	var evoToken = player.wallet.getEvoToken();
	var result: GetTowerResult = towerFactory.getTower(tower.data_name, evoToken);
	if(result == null):
		startWave();
		return;

	match result.state:
		GetTowerResult.State.New:
			# Enter build mode with the new tower
			result.tower.enterPlaceMode();
			if(map != null):
				map.toggle_grid(true);
			add_child(result.tower);
			t = result.tower
			state = "tower_placement"

		# GetTowerResult.State.Evolve:
		# 	# Check if have enough evo tokens to evolve
		# 	var evoToken = player.wallet.getEvoToken();
		# 	var cost = result.tower.data.evolutionCost;
		# 	if(evoToken >= cost):
		# 	else:
		# 		show_popup_panel();

		GetTowerResult.State.Upgrade:
			startWave();

		GetTowerResult.State.Evolve:
			towerFactory.evolutionTower(selection);

			var cost = result.tower.data.evolutionCost;
			player.wallet.updateEvoToken(-cost);
			startWave();

func _on_enemy_dead_visual(enemy: Enemy, _cause, _reward):
	# World-space loot-drop feedback bound to enemy TYPE, not reward contents.
	# Today only Boss spawns the visual; future normal-mob token drops (if any)
	# stay invisible unless explicitly opted-in via a different visual.
	if enemy.enemyType == Enemy.EnemyType.Boss:
		EvoTokenDrop.spawn(enemy.global_position, get_tree().current_scene)

func startWave():
	state = "wave"
	if(waveController):
		waveController.start()
