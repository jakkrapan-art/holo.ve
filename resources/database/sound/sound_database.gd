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
	VOICE_NAME.debut_syrios: "axel_Syrios/greeting_axel.mp3",
	VOICE_NAME.debut_hakka: "hakkito/greeting_Banzoin_Hakka.mp3",
	VOICE_NAME.debut_bettel: "gavis_bettel/greeting_gavis.mp3",
	VOICE_NAME.debut_gura: "gura/greeting_gura(keep).mp3",
	VOICE_NAME.debut_shinri: "josuiji_shinri/greeting_josuiji.mp3",
	VOICE_NAME.debut_flayon: "machina_x_flayon/greeting_flayon.mp3",
	VOICE_NAME.debut_caliope: "calliope/greeting_Colliope_MinnaSannn.mp3",
	VOICE_NAME.debut_ina: "ina/greeting_ina.mp3",
	VOICE_NAME.debut_altare: "regis_altare/greeting_regis.mp3",
	VOICE_NAME.debut_kiara: "kiara/greeting_Takanashi_Kiara.mp3",
	VOICE_NAME.debut_amelia: "ame/greeting_ame_hello(keep).mp3"
}