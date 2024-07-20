extends Area2D
class_name Entity

@onready var health: HealthController = $HealthController
@export var stats: Stats

func _ready():
	health.setup(stats.healh, stats.healh)
	health.connect("onDead", Callable(self, "onDead"))

func _process(delta):
	pass

func getDamage() -> int:
	return stats.attack
	
func getCurrentHealth() -> int:
	return health.currHealth

func recvDamage(damageAmount: int):
	var damageReduce = 2
	#TODO: calculate damage reduction and return truely damage receive 
	var damageDone = max(damageAmount - damageReduce, 0)
	
	health.updateHealth(-damageDone)
	return damageDone 

func recvHeal(healAmount: int):
	health.updateHealth(healAmount)
	
func onDead():
	queue_free()
