extends Node

# Damage table for enemy → player HP on leak. Consumed by WaveController →
# GameScene.reducePlayerHp → Staff.takeDamage. HP ownership moved to Staff
# (per a_chan.yaml + StaffData.max_hp); this autoload holds only the shared
# damage-per-enemy-type constants.
const DAMAGE_BY_MONSTER_TYPE = {
	Enemy.EnemyType.Normal: 1,
	Enemy.EnemyType.Elite: 10,
	Enemy.EnemyType.Boss: 20
}
