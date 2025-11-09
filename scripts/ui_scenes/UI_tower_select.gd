extends Node
class_name UITowerSelect

# Signal to send selection back to the stage
signal tower_select(num_select)

var _dealer: RandomCardsDealer;
var test_deck = ['1','2','3','4','5']

func setup(evolutionList: Array[String]):
	print("Deck passed in:", Global.selected_deck)
	print("tower_data: ", Global.towers_data.keys())
	_setup_buttons(evolutionList);
	var refresh_button = get_node("CanvasLayer/PopupPanel/Panel/RefreshButton")
	refresh_button.pressed.connect(Callable(self, "_setup_buttons").bind(evolutionList))

func _setup_buttons(evolutionList: Array):
	var cards: Array = []
	if(evolutionList.size() >= 3):
		cards = evolutionList
	else:
		var remain: int = 3 - evolutionList.size();
		if (!_dealer):
			_dealer = $RandomCardsDealer
		var finalList = evolutionList.duplicate()
		finalList.append_array(_dealer.get_random_cards(Global.towers_data.keys(), remain))
		cards = finalList

	var buttons = get_tree().get_nodes_in_group("tower_buttons")

	for button in buttons:
		button.pressed.disconnect(Callable(self, "_on_select_tower_button"))  # ✅ Prevent duplicate connections

	for index in range(min(buttons.size(), cards.size())):
		buttons[index].setup(cards[index])
		buttons[index].pressed.connect(Callable(self, "_on_select_tower_button").bind(cards[index]))

func _on_select_tower_button(num):
	print("signal: tower_select,"+str(num))
	emit_signal("tower_select", num)
	queue_free()
	#get_tree().quit()
