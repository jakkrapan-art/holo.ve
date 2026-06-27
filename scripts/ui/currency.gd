extends Control
class_name CurrencyUI

@onready var essenceOfMem: Control = $EssenseOfMem
@onready var essenceOfMemText: Label = $EssenseOfMem/ValuePanel/Amount;

func updateEssenceOfMem(amount: int):
	essenceOfMem.visible = amount >= 1
	essenceOfMemText.text = str(amount);

func updateGold(_value: int):
	pass
