extends Node
class_name UITowerSelect

# Signal to send selection back to the stage
signal tower_select(num_select)

@onready var dealer: RandomCardsDealer = $RandomCardsDealer
var test_deck = ['1','2','3','4','5']

func _ready():
	print("Deck passed in:", Global.selected_deck)
	_setup_buttons()
	var refresh_button = get_node("CanvasLayer/PopupPanel/Panel/RefreshButton")
	refresh_button.pressed.connect(Callable(self, "_setup_buttons"))

func _setup_buttons():
	var cards = dealer.get_random_cards(test_deck)
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
