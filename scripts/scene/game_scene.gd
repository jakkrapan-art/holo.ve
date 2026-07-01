extends Node2D;
class_name GameScene;

# Load the pop-up panel scene
var PopupPanelScene = preload("res://resources/ui_component/tower_select/tower_select.tscn");

@onready var waveController: WaveController = $WaveController;
@onready var player: Player = $Player
@onready var map: Map = $TileMap
# @export var mapData: MapData = null;
@onready var towerFactory: TowerFactory = $TowerFactory;

# Staff system — instantiated in _ready() once StaffCenter resolves the selected staff.
var staff: Staff = null

# Wave numbers (1-indexed, end-of-wave) at which the player is offered an extra deck
# to merge into the tower pool. Demo default = [5]. Inspector-editable.
@export var deck_unlock_waves: Array[int] = [5]

# Pause between boss-wave end and the wave-end popup opening, so the
# EvoTokenDrop pop-in / hold / float-fade sequence is visible before the
# popup overlays it. Slightly shorter than EvoTokenDrop.TOTAL_DURATION
# (currently 2.5 s) so the popup arrives during the last fade beat.
const BOSS_WAVE_END_POPUP_DELAY := 2.2

# Pacing beat between a regular (non-boss) wave end and the wave-end popup, so the
# wave-clear effects land before the UI cuts in. Inspector-editable feel knob.
@export var wave_end_popup_delay: float = 0.8

var mission: Mission = null;
var t: Tower = null
var state: String = ""
var _popup_open: bool = false
# Ref to the popup currently on screen (tower-select or deck-select). Used so _on_staff_died()
# can dismiss it; cleared via _on_popup_closed() when the popup frees itself normally.
var _active_popup: UITowerSelect = null

# Staff skill casting state — indicator follows mouse; LeftClick commits, RightClick / ESC cancels.
var _skill_cast_indicator: SkillCastIndicator = null
var _state_before_skill_cast: String = ""
# Ref to the Staff HUD widget so _input can ask whether a click landed on the skill button.
var _staff_widget: StaffWidget = null

func _input(event):
	if state == "tower_placement" and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if(t != null && !t.isOnValidCell):
			return;

		t.exitPlaceMode();
		t = null;
		if(map != null):
			map.toggle_grid(false);
		startWave();
	elif state == "staff_skill_casting":
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				# Click on the skill button itself -> let the button's pressed signal
				# toggle-cancel (MOBA-style); do NOT commit a cast under the button.
				if _staff_widget != null and _staff_widget.is_skill_button_hovered():
					return
				_commit_staff_skill_cast()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_cancel_staff_skill_cast()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_cancel_staff_skill_cast()

func _process(_delta):
	if state == "staff_skill_casting" and _skill_cast_indicator != null:
		_skill_cast_indicator.update_position_from_world(get_global_mouse_position())

func _ready():
	TowerCenter.clearData();
	# Map folder name = selected_map_file minus ".yaml" (e.g. "forest01.yaml" ->
	# "forest01"). Single source of identity for this run's enemy/boss data so the
	# boss pool key matches the getBossList lookup below.
	var mapName := TowerCenter.selected_map_file.get_basename();
	var b: BossLibrary = BossLibrary.new(mapName);

	TowerCenter.addDeck(TowerCenter.selected_deck)
	var default = TowerDataLoader.load_data("res://resources/database/towers/", "default_tower")
	TowerCenter.setDefaultTowerData(default)
	# (tower-scene cache + skill-effect shader warm are both handled inside
	# TowerCenter.addDeck above)

	# Staff system: load data → instantiate entity → wire widget → spawn endpoint sprite.
	setup_staff()
	var camera = get_node("Camera2D")
	camera.make_current()
	if(map != null):
		map.setup();

	show_popup_panel();

	# Preload this run's enemy set (sprites + stats/skills registry) for the map.
	ResourceManager.preloadEnemy(mapName);

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
		waveControllerData.stageModifiers = mapData.stageModifiers;
		waveControllerData.onEnemyReachEndpoint = Callable(self, "reducePlayerHp");
		waveControllerData.onWaveEnd = Callable(self, "on_wave_ended");

		waveController.setup(waveControllerData);

		var bossList: Array[BossDBData] = b.getBossList(mapName);
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
	# HP ownership moved from Player to Staff — Player retains wallet/inventory only.
	if staff != null:
		staff.takeDamage(amount)

func setup_staff():
	StaffCenter.loadAllStaffs()
	var staffData: StaffData = StaffCenter.getSelectedStaff()
	if staffData == null:
		push_warning("GameScene.setup_staff: no selected staff in StaffCenter; HP / widget / endpoint sprite will be skipped")
		return

	staff = Staff.new()
	staff.name = "Staff"
	add_child(staff)
	staff.setup(staffData)
	Utility.ConnectSignal(staff, "died", Callable(self, "_on_staff_died"))

	# Wire HUD widget — replaces the legacy ManagerImg / PlayerUI HealthBar binding.
	_staff_widget = get_node_or_null("GameUI/PlayerUI/Player/StaffWidget") as StaffWidget
	if _staff_widget != null:
		_staff_widget.setup(staff)
		# Widget button click → toggle: cancel if already aiming, else request a cast.
		Utility.ConnectSignal(_staff_widget, "skill_pressed", Callable(self, "_on_staff_skill_button_pressed"))
	else:
		push_warning("GameScene.setup_staff: StaffWidget not found at GameUI/PlayerUI/Player/StaffWidget")

	# Enter casting state when Staff confirms the cast is valid (uses remaining, skill defined).
	Utility.ConnectSignal(staff, "skill_cast_requested", Callable(self, "_on_staff_skill_cast_requested"))

	# Spawn the staff sprite at the path-end Marker2D (data-driven per staff) AND
	# hand the AnimatedSprite2D reference back to Staff so cast animation can fire on it.
	if staffData.end_sprite_scene != "":
		var sprite_path = "res://resources/" + staffData.end_sprite_scene
		if ResourceLoader.exists(sprite_path):
			var marker = map.get_node_or_null("StaffEndPoint")
			if marker != null:
				var sprite_scene: PackedScene = load(sprite_path)
				if sprite_scene != null:
					var sprite_instance = sprite_scene.instantiate()
					marker.add_child(sprite_instance)
					if sprite_instance is AnimatedSprite2D:
						staff.staff_sprite = sprite_instance
			else:
				push_warning("GameScene.setup_staff: StaffEndPoint Marker2D not found in TileMap")

	# Cast indicator — instantiated lazily here (no .tscn since visual is minimal).
	# z_index above map but below CanvasLayer popups; hidden until cast starts.
	if _skill_cast_indicator == null:
		_skill_cast_indicator = SkillCastIndicator.new()
		_skill_cast_indicator.name = "SkillCastIndicator"
		_skill_cast_indicator.z_index = 5
		add_child(_skill_cast_indicator)
	_skill_cast_indicator.set_aoe_size(staffData.skill_aoe_width, staffData.skill_aoe_height)

func _on_staff_died():
	# Game-over flow — previously inside Player.updateHp; now lives here so Staff owns HP lifecycle.
	# Mark game over BEFORE any UI work so popup factories early-return if they fire
	# concurrently from a wave-end timer or deferred callback.
	state = "game_over"
	# Dismiss any tower-select / deck popup currently open so it can't sit on top of
	# the end screen or accept clicks after the game is over.
	if _active_popup != null and is_instance_valid(_active_popup):
		_active_popup.queue_free()
	var endScreen = UIEndDemo.create()
	if endScreen:
		get_tree().current_scene.add_child(endScreen)

# === Staff skill casting ===

func _on_staff_skill_button_pressed():
	# Skill button toggle (MOBA-style): press while aiming = cancel, otherwise request a cast.
	if staff == null:
		return
	# Guard against re-entry across the wave-end popup beat (PR #51): never enter aiming
	# once a popup is open or the run is over.
	if _popup_open or state == "game_over":
		return
	if state == "staff_skill_casting":
		_cancel_staff_skill_cast()
	else:
		staff.requestCastSkill()

func _on_staff_skill_cast_requested():
	# Player pressed the Staff Widget skill button + Staff confirmed cast is valid.
	# Enter input-mode "staff_skill_casting"; mouse position drives the indicator.
	if state == "staff_skill_casting":
		return  # already aiming; guard a future re-entrant caller from clobbering _state_before_skill_cast
	if staff == null or _skill_cast_indicator == null:
		return
	_state_before_skill_cast = state
	state = "staff_skill_casting"
	_skill_cast_indicator.set_aoe_size(staff.data.skill_aoe_width, staff.data.skill_aoe_height)
	_skill_cast_indicator.update_position_from_world(get_global_mouse_position())
	_skill_cast_indicator.visible = true

func _commit_staff_skill_cast():
	if staff == null:
		return
	# Snap mouse to grid cell center (same logic as the indicator) and execute.
	var cell: Vector2i = GridHelper.WorldToCell(get_global_mouse_position())
	var snapped_pos: Vector2 = GridHelper.CellToWorld(cell)
	_exit_skill_cast_state()
	staff.executeSkillAtPosition(snapped_pos)

func _cancel_staff_skill_cast():
	_exit_skill_cast_state()

func _exit_skill_cast_state():
	state = _state_before_skill_cast
	_state_before_skill_cast = ""
	if _skill_cast_indicator != null:
		_skill_cast_indicator.visible = false

func on_wave_ended():
	if towerFactory != null:
		towerFactory.onWaveEnd()

	# Pacing beat before the popup so wave-clear effects land first. Boss waves hold
	# longer (token-drop visual); regular waves get the short feel beat.
	var popup_delay: float = BOSS_WAVE_END_POPUP_DELAY if (waveController != null and waveController.isBossWave) else wave_end_popup_delay
	await get_tree().create_timer(popup_delay).timeout
	# Re-entry guard: scene may have been freed mid-wait (e.g. game-over) OR the staff
	# may have died during the await window leaving the scene alive but the game over.
	if !is_instance_valid(self):
		return
	if state == "game_over":
		return
	# The beat keeps state == "wave", so the staff-skill button stays live during it.
	# If the player entered targeting mid-beat, cancel it so the popup does not open over
	# the cast indicator and a card-click cannot also commit a (limited-use) staff skill
	# onto the now-empty field. Field is clear, so a pending cast has no value anyway.
	if state == "staff_skill_casting":
		_cancel_staff_skill_cast()

	# At configured wave milestones, offer one of the remaining decks BEFORE
	# the normal tower-select popup. Pre-filter empty decks so the popup never
	# opens with nothing to pick.
	if deck_unlock_waves.has(waveController.currWave) and !TowerCenter.getAvailableDecks().is_empty():
		show_deck_popup()
	else:
		show_popup_panel()

func show_deck_popup():
	# End-game guard: if the staff has died, never open a new popup over the end screen.
	if state == "game_over":
		return
	if _popup_open:
		return

	var popup: UITowerSelect = PopupPanelScene.instantiate() as UITowerSelect
	_popup_open = true
	_active_popup = popup
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

	popup.setup_with_cards(cards, 0, "Select Additional Deck")

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
	# End-game guard: if the staff has died, never open a new popup over the end screen.
	if state == "game_over":
		return
	# Prevent opening multiple popups if this function is called repeatedly
	if _popup_open:
		return

	var popup: UITowerSelect = PopupPanelScene.instantiate() as UITowerSelect;
	_popup_open = true
	_active_popup = popup
	# Ensure it's added to the UI layer, not just as a child of the 2D scene
	get_tree().root.add_child(popup)

	# Connect signals BEFORE setup() — popup may emit tower_select_skipped during
	# setup() when no valid towers exist (all maxed/evolved with insufficient evoToken).
	popup.tower_select.connect(Callable(self, "_on_option_selected"))
	Utility.ConnectSignal(popup, "tower_select_skipped", Callable(self, "_on_tower_select_skipped"));
	# When the popup is closed/freed, allow it to be opened again
	Utility.ConnectSignal(popup, "tree_exited", Callable(self, "_on_popup_closed"));

	var evoToken = player.wallet.getEvoToken();
	popup.setup(evoToken, 1000, "Select Tower");

	return

func _on_popup_closed():
	_popup_open = false
	_active_popup = null

func _on_tower_select_skipped():
	push_warning("Tower select skipped - no valid towers available")
	startWave()

# Handle the selection from the popup
func _on_option_selected(selection):
	# selection = "gawr_gura"
	var tower = TowerCenter.getTowerDataByName(selection);
	if(tower == null):
		push_error("Tower data not found for selection: ", selection)
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
