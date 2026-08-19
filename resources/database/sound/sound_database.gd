class_name SoundDatabase

enum BGM_NAME {
	main
}

enum SFX_NAME {
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
	hit_amelia,
	skill_syrios_spear,
	skill_syrios_sword,
	skill_syrios_axe,
	ui_button_click,
	hit_flayon_evo,
	skill_hakka,
	skill_bettel,
	skill_gura,
	skill_shinri,
	skill_flayon,
	skill_flayon_active_sys,
	skill_caliope,
	skill_ina,
	skill_altare,
	skill_altare_shoot,
	skill_kiara,
	skill_amelia
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
	debut_amelia,
	evo_syrios,
	evo_hakka,
	evo_bettel,
	evo_gura,
	evo_shinri,
	evo_flayon,
	evo_caliope,
	evo_ina,
	evo_altare,
	evo_kiara,
	evo_amelia
}

static var bgm: Dictionary = {
	BGM_NAME.main: "lobby_seishun_akaibu_Instrumental.mp3"
}

static var sfx: Dictionary = {
	SFX_NAME.ui_button_click: "ui/finger_click.mp3",
	SFX_NAME.hit: "weapon/normal_great_sword_attack.mp3",
	SFX_NAME.hit_syrios: "weapon/normal_great_sword_attack.mp3",
	SFX_NAME.hit_hakka: "magic/normal_banzoin_hakka.mp3",
	SFX_NAME.hit_bettel: "magic/normal_attack_bloom.mp3",
	SFX_NAME.hit_gura: "weapon/trident_miss_1.mp3",
	SFX_NAME.hit_shinri: "weapon/fast_arrow.mp3",
	SFX_NAME.hit_flayon: "magic/normal_laser_attack_flayon.mp3",
	SFX_NAME.hit_flayon_evo: "magic/normal_laser_attack_flayon_evolved.mp3",
	SFX_NAME.hit_caliope: "weapon/normal_calliope_sickle_slash_2.mp3",
	SFX_NAME.hit_ina: "magic/normal_magic_attack.mp3",
	SFX_NAME.hit_altare: "magic/laser_shot_regis.mp3",
	SFX_NAME.hit_kiara: "weapon/normal_great_sword_attack.mp3",
	SFX_NAME.hit_amelia: "weapon/gun_3_shot.mp3",
	SFX_NAME.skill_syrios_spear: "weapon/spear_charge_axel.mp3",
	SFX_NAME.skill_syrios_sword: "weapon/sword_axel.mp3",
	SFX_NAME.skill_syrios_axe: "weapon/axe_axel.mp3",
	SFX_NAME.skill_hakka: "magic/skill_banzoin_hakka.mp3",
	SFX_NAME.skill_bettel: "magic/skill_bloom.mp3",
	SFX_NAME.skill_gura: "weapon/weapon_knife_sword_1.mp3",
	SFX_NAME.skill_shinri: "weapon/arrow.mp3",
	SFX_NAME.skill_flayon: "magic/skill_flayon.mp3",
	SFX_NAME.skill_flayon_active_sys: "magic/skill_flayon_active_sys.mp3",
	SFX_NAME.skill_caliope: "weapon/skill_calliope_weapon_sickle_hit_whoosh_bloody.mp3",
	SFX_NAME.skill_ina: "magic/skill_use_ina.mp3",
	SFX_NAME.skill_altare: "magic/light_saber_swing_regis.mp3",
	SFX_NAME.skill_altare_shoot: "magic/skill_laser_beam_regis.mp3",
	SFX_NAME.skill_kiara: "weapon/skill_use_takanashi_kiara_2.mp3",
	SFX_NAME.skill_amelia: "mechanical/skill_ame_clock_tick.mp3"
}

static var voice: Dictionary = {
	VOICE_NAME.debut_syrios: "axel_Syrios/greeting_axel.mp3",
	VOICE_NAME.debut_hakka: "hakkito/greeting_Banzoin_Hakka.mp3",
	VOICE_NAME.debut_bettel: "gavis_bettel/greeting_gavis.mp3",
	VOICE_NAME.debut_gura: "gura/greeting_gura(keep).mp3",
	VOICE_NAME.debut_shinri: "josuiji_shinri/greeting_josuiji.mp3",
	VOICE_NAME.debut_flayon: "machina_x_flayon/greeting_flayon.mp3",
	VOICE_NAME.debut_caliope: "calliope/greeting_colliope_minnasan.mp3",
	VOICE_NAME.debut_ina: "ina/greeting_ina.mp3",
	VOICE_NAME.debut_altare: "regis_altare/greeting_regis.mp3",
	VOICE_NAME.debut_kiara: "kiara/greeting_Takanashi_Kiara.mp3",
	VOICE_NAME.debut_amelia: "ame/greeting_ame_hello(keep).mp3",
	VOICE_NAME.evo_syrios: "axel_Syrios/evo_axel.mp3",
	VOICE_NAME.evo_hakka: "hakkito/evo_Banzoin_Hakka.mp3",
	VOICE_NAME.evo_bettel: "gavis_bettel/evo_gavis_likeapee.mp3",
	VOICE_NAME.evo_gura: "gura/evo_gura_oh_nyoo.mp3",
	VOICE_NAME.evo_shinri: "josuiji_shinri/evo_josuiji.mp3",
	VOICE_NAME.evo_flayon: "machina_x_flayon/evo_flayon.mp3",
	VOICE_NAME.evo_caliope: "calliope/evo_Colliope_Sumimasen.mp3",
	VOICE_NAME.evo_ina: "ina/eVO_ina_yawning.mp3",
	VOICE_NAME.evo_altare: "regis_altare/evo_regis.mp3",
	VOICE_NAME.evo_kiara: "kiara/evo_takanashi_kiara.mp3",
	VOICE_NAME.evo_amelia: "ame/evo_Ame.mp3"
}
