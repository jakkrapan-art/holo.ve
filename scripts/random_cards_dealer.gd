extends Node
class_name RandomCardsDealer

#init with cards[] input
#random 3 cards
#send out 3 cards to ui_tower_select

func get_random_cards(deck, count: int, evoToken: int) -> Array:
	if deck.size() < count:
		push_error("Not enough cards in the deck!")
		return []

	var shuffled_deck = deck.duplicate().filter(func(card): return TowerCenter.validateSelectTower(card, evoToken))
	shuffled_deck.shuffle()  # Shuffle the deck randomly
	var selected_cards = shuffled_deck.slice(0, count);
	var result: Array[TowerSelectData] = []
	for card in selected_cards:
		var selectData = TowerCenter.getTowerSelectDataByName(card);
		result.append(TowerSelectData.new(card, selectData.level if selectData.level is String else selectData.level + 1, selectData.evoCost))

	return result  # Get the first 3 random cards
