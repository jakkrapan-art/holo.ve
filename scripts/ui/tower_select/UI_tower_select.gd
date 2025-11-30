extends Control
class_name UITowerSelect

# Signal to send selection back to the stage
signal tower_select(num_select)

var _dealer: RandomCardsDealer;
var test_deck = ['1','2','3','4','5']
@onready var refreshText: Label = $CanvasLayer/PopupPanel/Panel/RefreshButton/RefreshText
var refreshLeft = 0;
var maxRefresh = 0;


func _ready() -> void:
	setupRefreshText(refreshLeft, maxRefresh);

func setup(evolutionList: Array, excludeList: Array, evoToken: int = 0, maxRefresh: int = 0):
	print("Deck passed in:", Global.selected_deck)
	print("tower_data: ", Global.towers_data.keys())

	maxRefresh = 10000;

	self.refreshLeft = maxRefresh;
	self.maxRefresh = maxRefresh;
	_setup_buttons(evolutionList, excludeList, evoToken);
	var refresh_button = get_node("CanvasLayer/PopupPanel/Panel/RefreshButton")
	refresh_button.pressed.connect(Callable(self, "refreshList").bind(evolutionList, evoToken))

	setupRefreshText(refreshLeft, maxRefresh)

func setupRefreshText(refreshCount: int, maxRefresh: int):
	if(refreshText):
		refreshText.text = str(refreshCount) + "/" + str(maxRefresh)

func refreshList(evolutionList: Array, excludeList: Array, evoToken: int = 0):
	if(refreshLeft <= 0):
		return
	refreshLeft -= 1;
	_setup_buttons(evolutionList, excludeList, evoToken);
	setupRefreshText(refreshLeft, maxRefresh)

func _setup_buttons(evolutionList: Array, excludeList: Array, evoToken: int = 0):
	var cards: Array = []

	# Show valid evolution towers first
	if(evolutionList.size() >= 3):
		cards = evolutionList
	else:
		var remain: int = 3 - evolutionList.size();
		if (!_dealer):
			_dealer = $RandomCardsDealer
		var finalList = evolutionList.duplicate()
		var available_towers = []
		for t in Global.towers_data.keys():
			if not excludeList.has(t.to_lower()) and not evolutionList.has(t):
				available_towers.append(t)
		finalList.append_array(_dealer.get_random_cards(available_towers, remain))
		cards = finalList

	var buttons = get_tree().get_nodes_in_group("tower_buttons")
	for button: TowerSelectButton in buttons:
		button.pressed.disconnect(Callable(self, "_on_select_tower_button"))  # ✅ Prevent duplicate connections

	for index in range(min(buttons.size(), cards.size())):
		var cardSelectData: TowerSelectData = cards[index] as TowerSelectData;
		buttons[index].setup(cardSelectData.name, cardSelectData.icon, cardSelectData.level, cardSelectData.evolutionCost)
		buttons[index].pressed.connect(Callable(self, "_on_select_tower_button").bind(cardSelectData.name))

func _on_select_tower_button(name):
	print("signal: tower_select,"+str(name))
	emit_signal("tower_select", name)
	# emit_signal("tower_select", "gawr_gura") #temp
	queue_free()
	#get_tree().quit()
