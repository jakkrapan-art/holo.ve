extends Node
class_name HealthController

var maxHealth: int = 0
var currHealth: int = 0

func setup(max: int, current: int):
	maxHealth = max
	currHealth = current

func _ready():
	pass

func _process(delta):
	pass
	
func updateHealth(updateAmount: int):
	currHealth = min(currHealth + updateAmount, maxHealth)
	if(updateAmount < 0):
		onRecvDamage.emit(updateAmount)
	elif(updateAmount > 0):
		onHeal.emit(updateAmount)
	
	if currHealth <= 0:
		onDead.emit()

signal onDead()
signal onRecvDamage(damageAmount: int)
signal onHeal(healAmount: int)
