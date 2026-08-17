class_name WaveEnemyGroup
extends RefCounted

# A spawn group references one enemy by id (defined in the map's enemy roster,
# resources/database/enemy/<map>/<tier>/<id>.yaml); stats + skills live there, not inline.
var enemy: String
var count: int
var spawnInterval: float = 1
# Second on the wave's spawn timeline this group begins spawning (0 = wave start).
var startAt: float = 0
