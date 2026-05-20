extends Node2D
class_name Player

# Player owns wallet / inventory / currency UI binding.
# HP lives on the Staff entity (scripts/entity/staff/staff.gd) — game-over flow is wired
# in game_scene.gd via Staff.died signal.

var inventory: Inventory;
var wallet: Wallet;

var currencyUI: CurrencyUI;

func _ready():
	setup();

func setup():
	wallet = Wallet.new(Callable(self, "updateGoldUI"), Callable(self, "updateEvoTokenUI"));
	inventory = Inventory.new();

	currencyUI = $"../GameUI/CurrencyUI"

func getItem(item: InventoryItem):
	inventory.addItem(item);

func useItem(item: InventoryItem):
	inventory.removeItem(item);

func checkItemAmount(item: InventoryItem) -> bool:
	var targetItem = inventory.getItemAmount(item.id);
	return targetItem.stack >= item.stack;

func processReward(_enemy, _cause, reward: EnemyReward):
	if(reward == null):
		return;

	wallet.updateGold(reward.gold);
	wallet.updateEvoToken(reward.evoToken);

func getGold():
	return wallet.getGold();

func useGold(value: int):
	wallet.updateGold(-value);

func getEvoToken():
	return wallet.getEvoToken();

func useEvoToken(value: int):
	wallet.updateEvoToken(-value);

func updateEvoTokenUI(value: int):
	if currencyUI:
		currencyUI.updateEssenceOfMem(value);

func updateGoldUI(value: int):
	if currencyUI:
		currencyUI.updateGold(value);
