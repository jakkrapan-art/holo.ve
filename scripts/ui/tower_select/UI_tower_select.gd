extends Control
class_name UITowerSelect

# Signal to send selection back to the stage
signal tower_select(num_select)
# Emitted when no valid tower cards can be built (e.g. all towers maxed/evolved
# and evoToken insufficient). Caller should resume wave flow without selection.
signal tower_select_skipped

var _dealer: RandomCardsDealer;
@onready var refreshText: Label = $CanvasLayer/PopupPanel/Panel/RefreshButton/RefreshText
var refreshLeft = 0;
var maxRefresh = 0;
var _card_provider: Callable = Callable()
var _candidate_count: int = 0
var _current_card_count: int = 0
# Programmatic title header — lazy-created on first _apply_setup() call when a title is provided.
# Lives as a child of Panel; anchored top-center above the HBoxContainer card row. Avoids editing
# tower_select.tscn (RULES.md §5: Engineer cannot modify the node tree in the Scene editor).
var _title_label: Label = null


func _ready() -> void:
	# PopupPanel is a full-rect Control that draws nothing - its only effect was eating
	# mouse input across the whole screen, which made every tooltip UNDER the popup
	# unreachable (synergy rows, Staff skill button, stats-panel icons): Godot's built-in
	# tooltips only fire on the topmost mouse hit. Modality does not depend on it -
	# GameScene._popup_is_blocking() already gates field clicks and the Staff skill press.
	# IGNORE lets hover through; the Panel card below still STOPs clicks on its own rect.
	# Set here rather than in tower_select.tscn for the same reason as _title_label above.
	$CanvasLayer/PopupPanel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("dev_reroll_surface")
	$CanvasLayer/PopupPanel/Panel/RefreshButton.pressed.connect(refreshList)
	sync_dev_reroll_state()

func setup(evoToken: int = 0, p_maxRefresh: int = 0, title: String = ""):
	_card_provider = Callable(self, "_build_tower_card_result").bind(evoToken)
	_apply_setup(_card_provider.call(), p_maxRefresh, title)

# Provider contract: return {"cards": Array[TowerSelectData], "candidate_count": int}.
# Rebuilding through the provider makes both Tower Select and Deck Select rerollable.
func setup_with_card_provider(provider: Callable, p_maxRefresh: int = 0, title: String = ""):
	_card_provider = provider
	_apply_setup(_card_provider.call(), p_maxRefresh, title)

func _apply_setup(result: Dictionary, max_refresh: int, title: String = ""):
	self.refreshLeft = max_refresh;
	self.maxRefresh = max_refresh;
	var cards: Array = result.get("cards", [])
	_candidate_count = int(result.get("candidate_count", cards.size()))
	_current_card_count = cards.size()

	if cards.is_empty():
		tower_select_skipped.emit()
		queue_free()
		return

	if title != "":
		_ensure_title_label(title)

	_apply_cards_to_buttons(cards)
	sync_dev_reroll_state()

func _ensure_title_label(title: String) -> void:
	# Lazy-create a single header Label inside Panel. Anchored top-stretch so it remains centered
	# regardless of Panel width; offset_top/bottom defines a fixed-height header band above the
	# HBoxContainer card row.
	if _title_label == null:
		_title_label = Label.new()
		_title_label.name = "TitleLabel"
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_title_label.anchor_left = 0.0
		_title_label.anchor_right = 1.0
		_title_label.anchor_top = 0.0
		_title_label.anchor_bottom = 0.0
		_title_label.offset_top = 12
		_title_label.offset_bottom = 56
		var ls := LabelSettings.new()
		ls.font_size = 28
		_title_label.label_settings = ls
		var panel: Panel = $CanvasLayer/PopupPanel/Panel
		panel.add_child(_title_label)
	_title_label.text = title

func refreshList():
	if not _card_provider.is_valid():
		return
	var unlimited := _dev_unlimited_rerolls()
	if not unlimited and refreshLeft <= 0:
		return
	if not unlimited:
		refreshLeft -= 1;

	var result: Dictionary = _card_provider.call()
	var cards: Array = result.get("cards", [])
	if cards.is_empty():
		tower_select_skipped.emit()
		queue_free()
		return

	_candidate_count = int(result.get("candidate_count", cards.size()))
	_current_card_count = cards.size()
	_apply_cards_to_buttons(cards)
	sync_dev_reroll_state()

func sync_dev_reroll_state() -> void:
	if not is_node_ready():
		return
	var refresh_button: Button = $CanvasLayer/PopupPanel/Panel/RefreshButton
	var has_alternatives := _card_provider.is_valid() and _candidate_count > _current_card_count
	refresh_button.visible = has_alternatives
	var unlimited := _dev_unlimited_rerolls()
	refresh_button.disabled = not unlimited and refreshLeft <= 0
	if refreshText != null:
		refreshText.text = "UNLIMITED" if unlimited else str(refreshLeft) + "/" + str(maxRefresh)

func _dev_unlimited_rerolls() -> bool:
	return bool(get_tree().get_meta(&"_dev_unlimited_card_rerolls", false))

func _build_tower_card_result(evoToken: int) -> Dictionary:
	var cards := _build_card_list(evoToken)
	var eligible := 0
	var evolution_names: Array = TowerCenter.getEvolutionList(3)
	for tower_name in evolution_names:
		if TowerCenter.validateSelectTower(tower_name, evoToken):
			eligible += 1
	var seen := {}
	for tower_name in TowerCenter.getTowerNames():
		if seen.has(tower_name) or evolution_names.has(tower_name):
			continue
		seen[tower_name] = true
		if TowerCenter.validateSelectTower(tower_name, evoToken):
			eligible += 1
	return {"cards": cards, "candidate_count": eligible}

func _build_card_list(evoToken: int) -> Array:
	if (!_dealer):
		_dealer = $RandomCardsDealer

	var remain: int = 3
	var finalList: Array = []

	var evoList = TowerCenter.getEvolutionList(3);
	for tName in evoList:
		var d = TowerCenter.getTowerSelectDataByName(tName);
		var level = d.level;
		var evolutionCost = d.evoCost;

		if(TowerCenter.validateSelectTower(tName, evoToken)):
			finalList.append(TowerSelectData.new(tName, level, evolutionCost))

	remain -= finalList.size()
	var available_towers = [] #initial
	var towerNames = TowerCenter.getTowerNames();
	for t in towerNames:
		if (!available_towers.has(t) && !evoList.has(t)):
			available_towers.append(t)

	if remain > 0:
		finalList.append_array(_dealer.get_random_cards(available_towers, remain, evoToken))

	return finalList

func _apply_cards_to_buttons(cards: Array) -> void:
	# Filter the "tower_buttons" group to descendants of THIS popup. The group is
	# scene-tree-global, so a deck popup awaiting deferred queue_free leaks its
	# buttons into a tower popup opened in the same frame — causing the tower
	# popup's own buttons to be hidden (cards consumed by the dying popup).
	var buttons: Array = []
	for b in get_tree().get_nodes_in_group("tower_buttons"):
		if is_ancestor_of(b):
			buttons.append(b)
	var select_callable = Callable(self, "_on_select_tower_button")
	for button: TowerSelectButton in buttons:
		# Guard: pressed has no fixed binding so disconnecting an unbound callable errors
		# on the first setup pass. Only disconnect prior bindings recorded on the button.
		var prior: Callable = button.get_meta("_select_binding", Callable())
		if prior.is_valid() and button.pressed.is_connected(prior):
			button.pressed.disconnect(prior)
			button.remove_meta("_select_binding")

	for index in range(buttons.size()):
		if index < cards.size():
			var cardSelectData: TowerSelectData = cards[index] as TowerSelectData;
			# Deck popup callsite passes deck keys (e.g. "myth") as card name, which
			# are not registered tower names - tClass/tGen stay 0 (no real trait)
			# and Setup() hides the synergy chip bar for those cards.
			var entry = TowerCenter.getTowerDataByName(cardSelectData.name);
			var tClass: int = 0;
			var tGen: int = 0;
			if entry != null and entry.data != null:
				tClass = entry.data.towerClass;
				tGen = entry.data.generation;

			buttons[index].Setup(cardSelectData.name, cardSelectData.icon, tClass, tGen, cardSelectData.level, cardSelectData.evolutionCost)
			var bound: Callable = select_callable.bind(cardSelectData.name)
			buttons[index].pressed.connect(bound)
			buttons[index].set_meta("_select_binding", bound)
			buttons[index].visible = true
		else:
			buttons[index].visible = false

func _on_select_tower_button(p_name):
	tower_select.emit(p_name)
	# emit_signal("tower_select", "gawr_gura") #temp
	queue_free()
	#get_tree().quit()
