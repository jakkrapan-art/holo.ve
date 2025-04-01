extends Node
class_name RandomCardsDealer

#init with cards[] input
#random 3 cards
#send out 3 cards to ui_tower_select

func get_random_cards(deck, count: int = 3) -> Array:
	if deck.size() < count:
		push_error("Not enough cards in the deck!")
		return []
	
	var shuffled_deck = deck.duplicate()
	shuffled_deck.shuffle()  # Shuffle the deck randomly

	return shuffled_deck.slice(0, count)  # Get the first 3 random cards
