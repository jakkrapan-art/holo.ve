class_name WaveData
extends RefCounted

# Wave-timeline length in seconds; drives the spawn-time countdown HUD only.
# It does NOT end the wave - wave end stays spawn-done + field-clear.
var duration: float = 60
var groupList: Array[WaveEnemyGroup]
var isBossWave: bool = false
# Stat modifiers applied to enemies of THIS wave only (special cases).
# Each entry: { stat, op, value } - validated by EnemyModifier.
var waveModifiers: Array = []

func addGroup(group: WaveEnemyGroup):
	self.groupList.append(group);
