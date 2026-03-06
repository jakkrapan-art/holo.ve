class_name SoundDatabase

enum BGM_NAME {
	main
}

enum SFX_NAME {
	hit
}

enum VOICE_NAME {
	none
}

static var bgm: Dictionary = {
	BGM_NAME.main: "lobby_seishun_akaibu_Instrumental.mp3"
}

static var sfx: Dictionary = {
	SFX_NAME.hit: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3"
}

static var voice: Dictionary = {}