extends Node2D
class_name Player

var maxHp: int;
var currentHp: int;

var inventory: Inventory;
var wallet: Wallet;

var ui: PlayerUI;
@export var uiTemplate: PackedScene;

var currencyUI: CurrencyUI;

func _ready():
	setup(1000);

func setup(hp: int):
	currentHp = hp;
	maxHp = hp;

	createUI();

	wallet = Wallet.new(Callable(self, "updateGoldUI"), Callable(self, "updateEvoTokenUI"));
	inventory = Inventory.new();

	currencyUI = $"../GameUI/CurrencyUI"

func createUI():
	if(!uiTemplate.can_instantiate()):
		return;

	var uiCanvas = CanvasLayer.new();
	add_child(uiCanvas);

	ui = uiTemplate.instantiate() as PlayerUI
	uiCanvas.add_child(ui);
	ui.setup(maxHp);

func updateHp(updateAmount: int):
	currentHp += updateAmount;
	ui.updateBar(currentHp);

func getItem(item: InventoryItem):
	inventory.addItem(item);

func useItem(item: InventoryItem):
	inventory.removeItem(item);

func checkItemAmount(item: InventoryItem) -> bool:
	var targetItem = inventory.getItemAmount(item.id);
	return targetItem.stack >= item.stack;

func processReward(__, reward: EnemyReward):
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
