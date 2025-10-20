class_name Wallet

var gold: Currency = Currency.new(0, "Gold", "", null, 0)
var evoToken: Currency = Currency.new(1, "Evo Token", "", null, 0)

func updateGold(value: int):
	print("update gold", value);
	gold.update(value);

func getGold():
	return gold.value;

func updateEvoToken(value: int):
	print("update evo token", value);
	evoToken.update(value);

func getEvoToken():
	return evoToken.value;
