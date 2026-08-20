extends SkillAction
class_name SkillActionPlaySound

# Fire-and-forget SFX beat: plays a SoundDatabase.SFX_NAME entry and returns
# without awaiting. Place it after the beat's play_animation so the sound lands
# on the impact frame together with the damage.

@export var sfxName: String = ""

func execute(_context: SkillContext):
	AudioManager.playSfxByName(sfxName)
