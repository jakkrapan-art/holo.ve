class_name SoundDatabase

enum BGM_NAME {
	main
}

enum SFX_NAME { #ทำให้รู้ว่าอะไรเป็นเสียง (ประกาศตัวแปร)
	hit,
	hit_syrios,
	hit_hakka,
	hit_bettel,
	hit_gura,
	hit_shinri,
	hit_flayon,
	hit_caliope,
	hit_ina,
	hit_altare,
	hit_kiara,
	hit_amelia
}

enum VOICE_NAME {
	debut_syrios,
	debut_hakka,
	debut_bettel,
	debut_gura,
	debut_shinri,
	debut_flayon,
	debut_caliope,
	debut_ina,
	debut_altare,
	debut_kiara,
	debut_amelia
}

static var bgm: Dictionary = {
	BGM_NAME.main: "lobby_seishun_akaibu_Instrumental.mp3"
}

static var sfx: Dictionary = { #สิ่งนั้นคือไฟล์ไหน (value ของตัวแปร)
	SFX_NAME.hit: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3",
	SFX_NAME.hit_syrios: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3",
	SFX_NAME.hit_hakka: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3",
	SFX_NAME.hit_bettel: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3",
	SFX_NAME.hit_gura: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3",
	SFX_NAME.hit_shinri: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3",
	SFX_NAME.hit_flayon: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3",
	SFX_NAME.hit_caliope: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3",
	SFX_NAME.hit_ina: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3",
	SFX_NAME.hit_altare: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3",
	SFX_NAME.hit_kiara: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3",
	SFX_NAME.hit_amelia: "sfx_Metal_Weapon/nomal_great_sword_atk.mp3"
}

static var voice: Dictionary = { #ตอนนี้ยังไม่เปิดใช้นะ แต่ใส่เผื่อมาก่อน //เสียงเปิดตัว (ขอเป็น debut_voice)
	VOICE_NAME.debut_syrios: "voice/gura/greeting_gura(keep).mp3",
	VOICE_NAME.debut_hakka: "voice/gura/greeting_gura(keep).mp3",
	VOICE_NAME.debut_bettel: "voice/gura/greeting_gura(keep).mp3",
	VOICE_NAME.debut_gura: "voice/gura/greeting_gura(keep).mp3",
	VOICE_NAME.debut_shinri: "voice/gura/greeting_gura(keep).mp3",
	VOICE_NAME.debut_flayon: "voice/gura/greeting_gura(keep).mp3",
	VOICE_NAME.debut_caliope: "voice/gura/greeting_gura(keep).mp3",
	VOICE_NAME.debut_ina: "voice/gura/greeting_gura(keep).mp3",
	VOICE_NAME.debut_altare: "voice/gura/greeting_gura(keep).mp3",
	VOICE_NAME.debut_kiara: "voice/gura/greeting_gura(keep).mp3",
	VOICE_NAME.debut_amelia: "voice/gura/greeting_gura(keep).mp3"
} 