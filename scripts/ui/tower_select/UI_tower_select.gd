extends Control
class_name UITowerSelect

# Signal to send selection back to the stage
signal tower_select(num_select)
# Emitted when no valid tower cards can be built (e.g. all towers maxed/evolved
# and evoToken insufficient). Caller should resume wave flow without selection.
signal tower_select_skipped

var _dealer: RandomCardsDealer;
var test_deck = ['1','2','3','4','5']
@onready var refreshText: Label = $CanvasLayer/PopupPanel/Panel/RefreshButton/RefreshText
var refreshLeft = 0;
var maxRefresh = 0;


func _ready() -> void:
	setupRefreshText(refreshLeft, maxRefresh);

func setup(evoToken: int = 0, maxRefresh: int = 0):
	var cards = _build_card_list(evoToken)
	_apply_setup(cards, maxRefresh, evoToken)

# Entry point for callers that already have a card list (e.g. deck-add popup at wave-5 end).
# Bypasses _build_card_list so the popup is not tied to TowerCenter tower pool.
func setup_with_cards(cards: Array, maxRefresh: int = 0):
	_apply_setup(cards, maxRefresh, 0)

func _apply_setup(cards: Array, max_refresh: int, evoTokenForRefresh: int):
	self.refreshLeft = max_refresh;
	self.maxRefresh = max_refresh;

	if cards.is_empty():
		emit_signal("tower_select_skipped")
		queue_free()
		return

	_apply_cards_to_buttons(cards)

	var refresh_button = get_node("CanvasLayer/PopupPanel/Panel/RefreshButton")
	refresh_button.visible = max_refresh > 0
	if max_refresh > 0:
		refresh_button.pressed.connect(Callable(self, "refreshList").bind(evoTokenForRefresh))

	setupRefreshText(refreshLeft, maxRefresh)

func setupRefreshText(refreshCount: int, maxRefresh: int):
	if(refreshText):
		refreshText.text = str(refreshCount) + "/" + str(maxRefresh)

func refreshList(evoToken: int = 0):
	if(refreshLeft <= 0):
		return
	refreshLeft -= 1;

	var cards = _build_card_list(evoToken)
	if cards.is_empty():
		emit_signal("tower_select_skipped")
		queue_free()
		return

	_apply_cards_to_buttons(cards)
	setupRefreshText(refreshLeft, maxRefresh)

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

	print("available towers: ", available_towers);
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
			buttons[index].setup(cardSelectData.name, cardSelectData.icon, cardSelectData.level, cardSelectData.evolutionCost)
			var bound: Callable = select_callable.bind(cardSelectData.name)
			buttons[index].pressed.connect(bound)
			buttons[index].set_meta("_select_binding", bound)
			buttons[index].visible = true
		else:
			buttons[index].visible = false

func _on_select_tower_button(name):
	print("signal: tower_select,"+str(name))
	emit_signal("tower_select", name)
	# emit_signal("tower_select", "gawr_gura") #temp
	queue_free()
	#get_tree().quit()
