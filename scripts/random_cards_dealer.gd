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
	var selected_cards = shuffled_deck.slice(0, count);
	var result: Array[TowerSelectData] = []
	for card in selected_cards:
		result.append(TowerSelectData.new(card, 1, 0))

	return result  # Get the first 3 random cards
