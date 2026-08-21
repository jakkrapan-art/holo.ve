extends Node2D;
class_name GameScene;

# Load the pop-up panel scene
var PopupPanelScene = preload("res://resources/ui_component/tower_select/tower_select.tscn");
const DEV_TOOLS_SCENE := "res://dev_tools/dev_tools_panel.tscn"

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

var t: Tower = null
var state: String = ""
var _popup_open: bool = false
# Ref to the popup currently on screen (tower-select or deck-select). Used so _on_staff_died()
# can dismiss it; cleared via _on_popup_closed() when the popup frees itself normally.
var _active_popup: UITowerSelect = null

# Staff skill casting state — indicator follows mouse; LeftClick commits, RightClick / ESC cancels.
var _skill_cast_indicator: SkillCastIndicator = null
var _state_before_skill_cast: String = ""
# Ref to the Staff HUD widget for setup and signal wiring.
var _staff_widget: StaffWidget = null

# Bottom-left stats panels (display-only selection surfaces). They share the
# slot: one selection at a time - showing one always clears the other.
var _tower_stats_panel: TowerStatsPanel = null
var _enemy_stats_panel: EnemyStatsPanel = null
var _placement_prompt: Label = null
var _placement_prompt_tween: Tween = null

const PLACEMENT_PROMPT_FADE_IN := 0.12
const DECK_OFFER_PAGE_SIZE := 3
const DECK_MAX_PREPARED_CANDIDATES := 6

var _deck_run_generation: int = 0
var _deck_offer_milestone: int = -1
var _deck_offer_pages: Array = []
var _deck_offer_page_cursor: int = 0
var _deck_current_page: Array = []
var _deck_dev_pending_page: Array = []
var _deck_preparation_keys: Array = []
var _deck_shader_warm_allowed: bool = false
var _deck_processed_milestones: Dictionary = {}

func _unhandled_input(event):
	# GUI Controls receive input first. Only input the HUD did not consume can
	# commit a world action here.
	if state == "tower_placement" and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if t != null and !t.isOnValidCell:
			return

		t.exitPlaceMode()
		t = null
		_hide_placement_ui()
		startWave()
		return

	if state == "staff_skill_casting":
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				get_viewport().set_input_as_handled()
				_commit_staff_skill_cast()
				return
			if event.button_index == MOUSE_BUTTON_RIGHT:
				get_viewport().set_input_as_handled()
				_cancel_staff_skill_cast()
				return
		elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_cancel_staff_skill_cast()
			return

	# Tower select via a direct pick-box lookup, NOT physics picking: GUI-consumed
	# clicks never reach here, active world actions are handled above, and (unlike
	# Area2D input_event, which missed clicks while a tower was mid-cast) this path
	# has no physics dependency at all.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if state == "tower_placement" or state == "staff_skill_casting" or _popup_is_blocking() or state == "game_over":
			return
		if _tower_stats_panel == null:
			return
		# Tower first: its pick box is the exact grid square; the enemy pick is
		# a radius. A scaled boss overhanging a tower's cell selects the tower
		# (accepted - Director 2026-07-17).
		var world_pos := get_global_mouse_position()
		var tower := _pick_tower_at(world_pos)
		if tower != null:
			_tower_stats_panel.show_tower(tower)
			if _enemy_stats_panel != null:
				_enemy_stats_panel.clear()
			return
		var enemy := _pick_enemy_at(world_pos)
		if enemy != null and _enemy_stats_panel != null:
			_enemy_stats_panel.show_enemy(enemy)
			_tower_stats_panel.clear()
			return
		_tower_stats_panel.clear()
		if _enemy_stats_panel != null:
			_enemy_stats_panel.clear()

# Square pick box = the tower's own visible grid square (tower.position is the
# square's center), so neighbor squares tile exactly with no overlap (Director
# feedback 2026-07-16).
func _pick_tower_at(world_pos: Vector2) -> Tower:
	var half := GridHelper.CELL_SIZE / 2.0
	for node in get_tree().get_nodes_in_group("tower"):
		var tower := node as Tower
		if tower == null or tower.inPlaceMode:
			continue
		var local := world_pos - tower.position
		if absf(local.x) <= half and absf(local.y) <= half:
			return tower
	return null

# Enemies move along paths and overlap, so the pick is a radius, not a cell box:
# nearest enemy within half a cell (scaled up for big bosses) wins; a near-tie
# (overlapping column) prefers the one closest to the path end - matches the
# targeting convention and reads as "the front one".
const ENEMY_PICK_TIE_EPSILON := 32.0

func _pick_enemy_at(world_pos: Vector2) -> Enemy:
	var best: Enemy = null
	var best_dist := INF
	# Both the enemy root and its Area2D child sit in this group; the `as Enemy`
	# cast nulls the Area2D so each enemy is considered once (PR #21 lesson).
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null or not enemy.initialized:
			continue
		var radius := GridHelper.CELL_SIZE / 2.0 * enemy.scale.x
		var dist := world_pos.distance_to(enemy.global_position)
		if dist > radius:
			continue
		if best == null or dist < best_dist - ENEMY_PICK_TIE_EPSILON:
			best = enemy
			best_dist = dist
		elif absf(dist - best_dist) <= ENEMY_PICK_TIE_EPSILON and enemy.progress_ratio > best.progress_ratio:
			best = enemy
			best_dist = dist
	return best

func _process(_delta):
	if state == "staff_skill_casting" and _skill_cast_indicator != null:
		_skill_cast_indicator.update_position_from_world(get_global_mouse_position())

func _ready():
	TowerCenter.clearData();
	_deck_run_generation = TowerCenter.getRunGeneration()
	# Map folder name = selected_map_file minus ".yaml" (e.g. "forest01.yaml" ->
	# "forest01"). Single source of identity for this run's enemy/boss data so the
	# boss pool key matches the getBossList lookup below.
	var mapName := TowerCenter.selected_map_file.get_basename();
	var b: BossLibrary = BossLibrary.new(mapName);

	TowerCenter.loadInitialDeck(TowerCenter.selected_deck)
	var default = TowerDataLoader.load_data("res://resources/database/towers/", "default_tower")
	TowerCenter.setDefaultTowerData(default)
	# (tower-scene cache + skill-effect shader warm are both handled inside
	# TowerCenter.loadInitialDeck above)

	# Staff system: load data → instantiate entity → wire widget → spawn endpoint sprite.
	setup_staff()
	_tower_stats_panel = get_node_or_null("GameUI/TowerStatsPanel") as TowerStatsPanel
	_enemy_stats_panel = get_node_or_null("GameUI/EnemyStatsPanel") as EnemyStatsPanel
	_placement_prompt = get_node_or_null("GameUI/PlacementPrompt") as Label
	var camera = get_node("Camera2D")
	camera.make_current()
	if(map != null):
		map.setup();

	show_popup_panel();

	# Preload this run's enemy set (sprites + stats/skills registry) for the map.
	ResourceManager.preloadEnemy(mapName);

	if (towerFactory):
		towerFactory.setup(Callable(self, "placeTower"), Callable(self, "removeTower"));

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
		Utility.ConnectSignal(waveController, "onEnemyDead", Callable(towerFactory, "onEnemyKilled"));
		Utility.ConnectSignal(waveController, "onEnemyDead", Callable(self, "_on_enemy_dead_visual"));

	_setup_dev_tools()

func _exit_tree() -> void:
	TowerCenter.endRun(_deck_run_generation)

func _setup_dev_tools() -> void:
	if not (OS.has_feature("editor") or OS.has_feature("dev_tools")):
		return
	var dev_scene := load(DEV_TOOLS_SCENE) as PackedScene
	if dev_scene == null:
		push_warning("GameScene: developer tools scene is unavailable")
		return
	var panel := dev_scene.instantiate()
	add_child(panel)
	if panel.has_method("setup"):
		panel.call("setup", waveController, Callable(self, "request_dev_add_evo_token"))

func request_dev_add_evo_token(amount: int = 1) -> bool:
	if not (OS.has_feature("editor") or OS.has_feature("dev_tools")):
		return false
	if amount <= 0 or player == null or player.wallet == null:
		return false
	player.wallet.updateEvoToken(amount)
	return true

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
	TowerCenter.cancelDeckPreparation(_deck_run_generation)
	_deck_run_generation = TowerCenter.getRunGeneration()
	_hide_placement_ui()
	if waveController != null:
		waveController.active = false
	# Drop the inspected tower/enemy. The end screen is a centred panel, not a
	# full-screen cover, so an outline or range ring left behind it stays visible
	# - and _unhandled_input early-returns on game_over, so the player could
	# never clear it.
	_clear_inspection()
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
	# once a popup is open or the run is over. The button stays hoverable so the player
	# can still READ the skill tooltip while choosing a tower - only the press is refused.
	if _popup_is_blocking() or state == "game_over":
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
	await get_tree().create_timer(popup_delay, false).timeout
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
	_prepareUpcomingDeckOfferIfNeeded()

	# At configured wave milestones, offer one of the remaining decks BEFORE
	# the normal tower-select popup. Pre-filter empty decks so the popup never
	# opens with nothing to pick.
	if deck_unlock_waves.has(waveController.currWave) and !TowerCenter.getAvailableDecks().is_empty():
		_deck_processed_milestones[waveController.currWave] = true
		if _deck_offer_milestone == waveController.currWave and not _deck_preparation_keys.is_empty():
			state = "deck_preparing"
			_clear_inspection()
			_deck_shader_warm_allowed = true
			while (
					state != "game_over"
					and _deck_run_generation == TowerCenter.getRunGeneration()
					and not TowerCenter.areDeckPreparationsSettled(
							_deck_preparation_keys, _deck_run_generation)
			):
				await get_tree().process_frame
			_deck_shader_warm_allowed = false
			if state == "game_over" or _deck_run_generation != TowerCenter.getRunGeneration():
				return
			state = "wave"
			_pruneDeckOfferPages()
		if not _deck_offer_pages.is_empty():
			show_deck_popup()
		else:
			_clearDeckOffer()
			show_popup_panel()
	else:
		if deck_unlock_waves.has(waveController.currWave):
			_deck_processed_milestones[waveController.currWave] = true
		show_popup_panel()

func show_deck_popup():
	# End-game guard: if the staff has died, never open a new popup over the end screen.
	if state == "game_over":
		return
	if _popup_open:
		return
	_deck_offer_page_cursor = 0
	_deck_current_page = []
	_deck_dev_pending_page = []
	# Initial candidates are already READY. Keep the management window eligible
	# for later dev-unlimited pages, which may need their own shader warm pass.
	_deck_shader_warm_allowed = true

	var popup: UITowerSelect = PopupPanelScene.instantiate() as UITowerSelect
	_popup_open = true
	_active_popup = popup
	_clear_inspection()
	get_tree().root.add_child(popup)

	popup.tower_select.connect(Callable(self, "_on_deck_selected"))
	Utility.ConnectSignal(popup, "tower_select_skipped", Callable(self, "_on_deck_skipped"))
	# NOTE: tree_exited intentionally NOT connected here. The deck popup's deferred
	# queue_free would fire tree_exited AFTER the follow-up tower popup is already
	# open, and would erroneously reset _popup_open while the tower popup is alive.
	# Flag handoff is explicit in _on_deck_selected / _on_deck_skipped below; the
	# tower popup wires its own tree_exited via show_popup_panel().

	popup.setup_with_card_provider(Callable(self, "_build_available_deck_card_result"), 1, "Select Additional Deck")

func _build_available_deck_card_result() -> Dictionary:
	var page := _takeNextPreparedDeckPage()
	var cards: Array = []
	for deck_key in page:
		var card = TowerSelectData.new(deck_key, 0, 0)
		card.icon = TowerCenter.getPreparedDeckCover(deck_key, _deck_run_generation)
		cards.append(card)
	var candidate_count := _preparedDeckCandidateCount()
	if _devUnlimitedDeckRerolls() and _deck_offer_page_cursor >= _deck_offer_pages.size():
		_beginDevDeckPagePreparation()
	return {"cards": cards, "candidate_count": candidate_count}

func _on_deck_selected(deck_key: String):
	var committed := TowerCenter.commitPreparedDeck(deck_key, _deck_run_generation)
	# Hand off the popup flag from the (about-to-free) deck popup to the tower popup.
	_popup_open = false
	if not committed:
		TowerCenter.rejectPreparedDeck(
				deck_key, _deck_run_generation, "commit validation:" + deck_key)
		_pruneDeckOfferPages()
		if not _deck_offer_pages.is_empty():
			show_deck_popup()
		else:
			_clearDeckOffer()
			show_popup_panel()
	else:
		_clearDeckOffer()
		show_popup_panel()

func _on_deck_skipped():
	# Safety net: getAvailableDecks() pre-filter prevents an empty deck popup
	# in normal flow. If the popup self-skips anyway, fall through to tower select.
	_popup_open = false
	_clearDeckOffer()
	show_popup_panel()

func _prepareUpcomingDeckOfferIfNeeded() -> void:
	if state == "game_over" or waveController == null:
		return
	var milestone := _nextUnprocessedDeckMilestone()
	if milestone < 0 or milestone > waveController.currWave + 2:
		return
	if _deck_offer_milestone == milestone and not _deck_offer_pages.is_empty():
		return
	var available_keys := _availableDeckKeys()
	if available_keys.is_empty():
		return

	_clearDeckOffer()
	_deck_offer_milestone = milestone
	var first_page := _rollDeckOfferPage(available_keys)
	var reroll_page := _rollDeckOfferPage(available_keys)
	_deck_offer_pages = [first_page, reroll_page]
	var unique_candidates: Dictionary = {}
	for page in _deck_offer_pages:
		for deck_key in page:
			unique_candidates[deck_key] = true
	_deck_preparation_keys = unique_candidates.keys().slice(0, DECK_MAX_PREPARED_CANDIDATES)
	_deck_shader_warm_allowed = true
	TowerCenter.prepareDecks(
			_deck_preparation_keys,
			self,
			_deck_run_generation,
			Callable(self, "_canPrepareDeckCpu"),
			Callable(self, "_canWarmDeckShaders"))

func _nextUnprocessedDeckMilestone() -> int:
	var next_milestone := -1
	for milestone in deck_unlock_waves:
		if milestone < waveController.currWave or _deck_processed_milestones.has(milestone):
			continue
		if next_milestone < 0 or milestone < next_milestone:
			next_milestone = milestone
	return next_milestone

func _availableDeckKeys() -> Array:
	var keys: Array = []
	for deck in TowerCenter.getAvailableDecks():
		keys.append(str(deck.key))
	return keys

func _rollDeckOfferPage(available_keys: Array) -> Array:
	var shuffled := available_keys.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, mini(DECK_OFFER_PAGE_SIZE, shuffled.size()))

func _canPrepareDeckCpu() -> bool:
	return (
			state != "game_over"
			and _deck_run_generation == TowerCenter.getRunGeneration()
			and waveController != null
			and not waveController.active
			and (_popup_open or state == "deck_preparing")
	)

func _canWarmDeckShaders() -> bool:
	return _deck_shader_warm_allowed and _canPrepareDeckCpu()

func _pruneDeckOfferPages() -> void:
	var valid_pages: Array = []
	for page in _deck_offer_pages:
		var valid_page: Array = []
		for deck_key in page:
			if (
					not TowerCenter.added_decks.has(deck_key)
					and TowerCenter.isDeckPrepared(deck_key, _deck_run_generation)
			):
				valid_page.append(deck_key)
		if not valid_page.is_empty():
			valid_pages.append(valid_page)
	_deck_offer_pages = valid_pages
	_deck_offer_page_cursor = 0

func _takeNextPreparedDeckPage() -> Array:
	while _deck_offer_page_cursor < _deck_offer_pages.size():
		var page: Array = _deck_offer_pages[_deck_offer_page_cursor]
		_deck_offer_page_cursor += 1
		var ready_page: Array = []
		for deck_key in page:
			if TowerCenter.isDeckPrepared(deck_key, _deck_run_generation):
				ready_page.append(deck_key)
		if not ready_page.is_empty():
			_deck_current_page = ready_page
			return ready_page

	if _devUnlimitedDeckRerolls():
		if not _deck_dev_pending_page.is_empty() and TowerCenter.areDeckPreparationsSettled(
				_deck_dev_pending_page, _deck_run_generation):
			var ready_page: Array = []
			for deck_key in _deck_dev_pending_page:
				if TowerCenter.isDeckPrepared(deck_key, _deck_run_generation):
					ready_page.append(deck_key)
			_deck_dev_pending_page = []
			if not ready_page.is_empty():
				_deck_current_page = ready_page
				return ready_page
	return _deck_current_page

func _preparedDeckCandidateCount() -> int:
	var eligible_count := _availableDeckKeys().size()
	if _devUnlimitedDeckRerolls() or _deck_offer_page_cursor < _deck_offer_pages.size():
		return eligible_count
	return _deck_current_page.size()

func _beginDevDeckPagePreparation() -> void:
	if not _devUnlimitedDeckRerolls() or not _deck_dev_pending_page.is_empty():
		return
	var available_keys := _availableDeckKeys()
	if available_keys.is_empty():
		return
	_deck_dev_pending_page = _rollDeckOfferPage(available_keys)
	var retained: Dictionary = {}
	for deck_key in _deck_current_page + _deck_dev_pending_page:
		retained[deck_key] = true
	var retained_keys: Array = retained.keys().slice(0, DECK_MAX_PREPARED_CANDIDATES)
	TowerCenter.retainDeckPreparations(retained_keys, _deck_run_generation)
	TowerCenter.prepareDecks(
			_deck_dev_pending_page,
			self,
			_deck_run_generation,
			Callable(self, "_canPrepareDeckCpu"),
			Callable(self, "_canWarmDeckShaders"))

func _devUnlimitedDeckRerolls() -> bool:
	return bool(get_tree().get_meta(&"_dev_unlimited_card_rerolls", false))

func _clearDeckOffer() -> void:
	TowerCenter.clearDeckPreparations(_deck_run_generation)
	_deck_offer_milestone = -1
	_deck_offer_pages = []
	_deck_offer_page_cursor = 0
	_deck_current_page = []
	_deck_dev_pending_page = []
	_deck_preparation_keys = []
	_deck_shader_warm_allowed = false

func show_popup_panel():
	# End-game guard: if the staff has died, never open a new popup over the end screen.
	if state == "game_over":
		return
	# Prevent opening multiple popups if this function is called repeatedly
	if _popup_open:
		return
	_prepareUpcomingDeckOfferIfNeeded()
	if not _deck_preparation_keys.is_empty():
		_deck_shader_warm_allowed = true

	var popup: UITowerSelect = PopupPanelScene.instantiate() as UITowerSelect;
	_popup_open = true
	_active_popup = popup
	_clear_inspection()
	# Ensure it's added to the UI layer, not just as a child of the 2D scene
	get_tree().root.add_child(popup)

	# Connect signals BEFORE setup() — popup may emit tower_select_skipped during
	# setup() when no valid towers exist (all maxed/evolved with insufficient evoToken).
	popup.tower_select.connect(Callable(self, "_on_option_selected"))
	Utility.ConnectSignal(popup, "tower_select_skipped", Callable(self, "_on_tower_select_skipped"));
	# When the popup is closed/freed, allow it to be opened again
	Utility.ConnectSignal(popup, "tree_exited", Callable(self, "_on_popup_closed"));

	var evoToken = player.wallet.getEvoToken();
	popup.setup(evoToken, 1, "Select Tower");

	return

func _on_popup_closed():
	_popup_open = false
	_active_popup = null

# "A popup is covering the field", split from _popup_open's other meaning ("a popup exists,
# do not open a second one"). The hide-popup button (coding log) flips only this half.
func _popup_is_blocking() -> bool:
	return _popup_open or state == "deck_preparing"

# Inspection and the card-pick modal are mutually exclusive (Director 2026-07-20): the popup
# draws above the field, so a stats panel - with its inspect outline, and the planned tower
# range ring - would sit half-covered under it. Clearing on open keeps the choosing moment
# clean; re-selecting is already refused while _popup_is_blocking(). When the hide-popup
# button lands, consider hiding + restoring the selection instead of dropping it.
func _clear_inspection() -> void:
	if _tower_stats_panel != null:
		_tower_stats_panel.clear()
	if _enemy_stats_panel != null:
		_enemy_stats_panel.clear()

func _on_tower_select_skipped():
	push_warning("Tower select skipped - no valid towers available")
	startWave()

# Handle the selection from the popup
func _on_option_selected(selection):
	# Stop a background shader warm before the management popup hands control
	# back to placement or the next wave.
	_deck_shader_warm_allowed = false
	# selection = "gawr_gura"
	var tower = TowerCenter.getTowerDataByName(selection);
	if(tower == null):
		push_error("Tower data not found for selection: ", selection)
		return

	var evoToken = player.wallet.getEvoToken();
	var result: GetTowerResult = towerFactory.getTower(tower.data_name, evoToken);
	if(result == null):
		startWave();
		return;

	match result.state:
		GetTowerResult.State.New:
			TowerCenter.upgradeTowerLevelByName(selection);
			# Enter build mode with the new tower
			result.tower.enterPlaceMode();
			add_child(result.tower);
			t = result.tower
			state = "tower_placement"
			_show_placement_ui()

		GetTowerResult.State.Upgrade:
			TowerCenter.upgradeTowerLevelByName(selection);
			startWave();

		GetTowerResult.State.Evolve:
			var cost = result.tower.data.evolutionCost;
			if TowerCenter.evolveTowerByName(selection):
				player.useEvoToken(cost);
			else:
				push_error("Evolution record commit failed after live tower evolved: ", selection)
			startWave();

		GetTowerResult.State.Unavailable:
			push_warning("Tower selection unavailable: ", selection)
			startWave();

func _on_enemy_dead_visual(enemy: Enemy, _cause, _reward):
	# World-space loot-drop feedback bound to enemy TYPE, not reward contents.
	# Today only Boss spawns the visual; future normal-mob token drops (if any)
	# stay invisible unless explicitly opted-in via a different visual.
	if enemy.enemyType == Enemy.EnemyType.Boss:
		EvoTokenDrop.spawn(enemy.global_position, get_tree().current_scene)

func startWave():
	_deck_shader_warm_allowed = false
	_hide_placement_ui()
	state = "wave"
	if(waveController):
		waveController.start()

func _show_placement_ui() -> void:
	if map != null:
		map.toggle_grid(true)
	if _placement_prompt == null:
		return

	_kill_placement_prompt_tween()
	_placement_prompt.visible = true
	_placement_prompt.modulate.a = 0.0
	_placement_prompt_tween = create_tween()
	_placement_prompt_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_placement_prompt_tween.tween_property(
			_placement_prompt, "modulate:a", 1.0, PLACEMENT_PROMPT_FADE_IN)

func _hide_placement_ui() -> void:
	if map != null:
		map.toggle_grid(false)
	if _placement_prompt == null:
		return

	_kill_placement_prompt_tween()
	_placement_prompt.modulate.a = 1.0
	_placement_prompt.visible = false

func _kill_placement_prompt_tween() -> void:
	if _placement_prompt_tween != null and _placement_prompt_tween.is_valid():
		_placement_prompt_tween.kill()
	_placement_prompt_tween = null
