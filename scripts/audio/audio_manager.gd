extends Node

var soundPrefix = "res://resources/sound/"
var bgmPrefix = soundPrefix + "bgm/"
var sfxPrefix = soundPrefix + "sfx/"
var voicePrefix = soundPrefix + "voice/"

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var voice_players: Array[AudioStreamPlayer] = []

var sfx: Dictionary = {}
var bgm: Dictionary = {}
var voice: Dictionary = {}

var soundCache: Dictionary = {}
var reported_unknown_names: Dictionary = {}

const SFX_POOL_SIZE = 10
const VOICE_POOL_SIZE = 5

func _ready():
	preloadAudio();
	# music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "bgm"
	add_child(music_player)

	# create sfx pool
	for _i in SFX_POOL_SIZE:
		sfx_players.append(_create_player(&"sfx"))
	# create voice pool
	for _i in VOICE_POOL_SIZE:
		voice_players.append(_create_player(&"voice"))

func _create_player(bus_name: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player

func preloadAudio():
	var sfxList = SoundDatabase.sfx.keys()
	for key in sfxList:
		var filePath = SoundDatabase.sfx[key]
		var fullPath = sfxPrefix + filePath
		if(soundCache.has(fullPath)):
			sfx[key] = soundCache[fullPath]
			continue;
		var sound = ResourceLoader.load(fullPath)
		if sound:
			sfx[key] = sound
			soundCache[fullPath] = sound
		else:
			push_warning("Failed to load SFX: " + fullPath)

	var bgmList = SoundDatabase.bgm.keys()
	for key in bgmList:
		var filePath = SoundDatabase.bgm[key]
		var fullPath = bgmPrefix + filePath
		if(soundCache.has(fullPath)):
			bgm[key] = soundCache[fullPath]
			continue;
		var sound = ResourceLoader.load(fullPath)
		if sound:
			bgm[key] = sound
			soundCache[fullPath] = sound
		else:
			push_warning("Failed to load BGM: " + fullPath)

	var voiceList = SoundDatabase.voice.keys()
	for key in voiceList:
		var filePath = SoundDatabase.voice[key]
		var fullPath = voicePrefix + filePath

		if(soundCache.has(fullPath)):
			voice[key] = soundCache[fullPath]
			continue;

		var sound = ResourceLoader.load(fullPath)
		if sound:
			voice[key] = sound
			soundCache[fullPath] = sound
		else:
			push_warning("Failed to load Voice: " + fullPath)

func playMusic(music_name: SoundDatabase.BGM_NAME, loop := true):
	var stream = bgm.get(music_name, null)
	if stream == null:
		push_warning("Music not found: " + str(music_name))
		return

	if music_player.stream == stream:
		return

	music_player.stop()
	music_player.stream = stream
	music_player.stream.loop = loop
	music_player.play()

func playSfx(sfx_name: SoundDatabase.SFX_NAME) -> bool:
	var stream = sfx.get(sfx_name)

	if stream == null:
		push_warning("SFX not found: " + str(sfx_name))
		return false

	for player in sfx_players:
		if !player.playing:
			player.stream = stream
			player.play()
			return true

	# Keep active one-shots intact. Overflow players remain in the pool and are
	# reused after their stream finishes.
	var overflow_player := _create_player(&"sfx")
	sfx_players.append(overflow_player)
	overflow_player.stream = stream
	overflow_player.play()
	return true

func playSfxByName(sfx_name: String) -> bool:
	var normalized := sfx_name.strip_edges()
	if normalized == "":
		return false
	var resolved = _resolve_audio_name(SoundDatabase.SFX_NAME, normalized, "SFX")
	if resolved == null:
		return false
	return playSfx(int(resolved))

func playVoice(voice_name: SoundDatabase.VOICE_NAME) -> bool:
	var stream = voice.get(voice_name)

	if stream == null:
		push_warning("Voice not found: " + str(voice_name))
		return false

	for player in voice_players:
		if !player.playing:
			player.stream = stream
			player.play()
			return true
	return false

func playVoiceByName(voice_name: String) -> bool:
	var normalized := voice_name.strip_edges()
	if normalized == "":
		return false
	var resolved = _resolve_audio_name(SoundDatabase.VOICE_NAME, normalized, "Voice")
	if resolved == null:
		return false
	return playVoice(int(resolved))

func _resolve_audio_name(enum_dict: Dictionary, value: String, label: String):
	var target := value.to_lower()
	for key in enum_dict.keys():
		if str(key).to_lower() == target:
			return enum_dict[key]
	var report_key := label.to_lower() + ":" + target
	if not reported_unknown_names.has(report_key):
		reported_unknown_names[report_key] = true
		push_error(label + " name not found: " + value)
	return null
