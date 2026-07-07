extends Control
class_name BossHealthBar

# Top-center boss HP bar - placeholder guiding the artist pass (Director
# 2026-07-07); the bar deliberately reuses the overhead HealthBar script so
# colors and the "current/max (percent%)" format stay identical. Tracks one
# boss per boss wave: shown on track(), hidden when the boss dies or leaks.

@export var bossName: Label
@export var healthBar: HealthBar

var _boss: Enemy = null

func _ready():
	visible = false

func track(boss: Enemy, displayName: String):
	if boss == null or not is_instance_valid(boss) or boss.stats == null:
		return
	untrack()
	_boss = boss
	if bossName != null:
		bossName.text = displayName
	if healthBar != null:
		healthBar.setup(boss.stats.maxHp)
		healthBar.updateValue(boss.stats.currentHp)
	Utility.ConnectSignal(boss, "onHpChanged", Callable(self, "_onBossHpChanged"))
	Utility.ConnectSignal(boss, "onDead", Callable(self, "_onBossDead"))
	Utility.ConnectSignal(boss, "onReachEndPoint", Callable(self, "_onBossLeft"))
	visible = true

func untrack():
	# Signal connections die with the freed boss; just drop the ref and hide.
	_boss = null
	visible = false

func _onBossHpChanged(current: float, _maxHp: float):
	if healthBar != null:
		healthBar.updateValue(maxf(current, 0.0))

func _onBossDead(_enemy: Enemy, _cause: Damage, _reward: EnemyReward):
	untrack()

func _onBossLeft():
	untrack()
