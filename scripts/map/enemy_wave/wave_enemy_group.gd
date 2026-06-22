class_name WaveEnemyGroup
extends RefCounted

# A spawn group references one enemy by id (defined in the map's enemy roster,
# resources/database/enemy/<map>/<tier>/<id>.yaml); stats + skills live there, not inline.
var enemy: String
var count: int
var spawnInterval: float = 1
# Second on the wave's spawn timeline this group begins spawning (0 = wave start).
var startAt: float = 0

# Compat shim for the dead Google-Sheets map-gen addon (addons/load_map_data),
# which still calls the legacy 6-arg setup(). Maps the old `texture` column to the
# new `enemy` id and ignores the inline stat args (stats now live in the enemy DB).
# Remove together with that dead tool (pending Lead - see coding log).
func setup(texture: String, _health: int = 0, _def: float = 0, _mDef: float = 0, _moveSpeed: float = 0, count: int = 20, spawnInterval: float = 1):
	self.enemy = texture
	self.count = count
	self.spawnInterval = spawnInterval
