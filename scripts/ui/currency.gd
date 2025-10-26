extends Control
class_name CurrencyUI

@onready var essenceOfMemText: Label = $EssenseOfMem/ValuePanel/Amount;

func updateEssenceOfMem(amount: int):
	essenceOfMemText.text = str(amount);

func updateGold(value: int):
	pass
