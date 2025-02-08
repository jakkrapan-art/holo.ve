extends ProgressBar
class_name  HealthBar

@export var hpText: Label;

func setup(maxValue: float, showText: bool = true):
	max_value = maxValue;
	value = maxValue;
	hpText.visible = showText;
	updateText();
	
func updateValue(currentValue: float):
	value = currentValue;
	updateText()

func updateText():
	hpText.text =  String.num(value) + "/" + String.num(max_value) + " (" + String.num(value / max_value * 100) + "%)";
