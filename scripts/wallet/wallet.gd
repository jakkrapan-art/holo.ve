class_name Wallet

var gold: Currency = Currency.new(0, "Gold", "", null, 0)
var evoToken: Currency = Currency.new(1, "Evo Token", "", null, 0)

func _init(onGoldUpdate: Callable, onEvoTokenUpdate: Callable):
	gold.subscribeOnUpdate("ui", onGoldUpdate);
	evoToken.subscribeOnUpdate("ui", onEvoTokenUpdate);

func updateGold(value: int):
	if value == 0:
		return
	print("update gold", value);
	gold.update(value);

func getGold() -> int:
	return gold.value;

func updateEvoToken(amount: int):
	if amount == 0:
		return
	print("update evo token", amount);
	evoToken.update(amount);

func getEvoToken() -> int:
	return evoToken.value;
