extends Control
class_name PlayerUI

@export var healthBar: HealthBar;

func setup(hp: int):
	scale = get_screen_transform().get_scale();
	healthBar.setup(hp);

func updateBar(currentHealth: float):
	healthBar.updateValue(currentHealth);
