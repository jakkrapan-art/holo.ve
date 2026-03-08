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

const SFX_POOL_SIZE = 10
const VOICE_POOL_SIZE = 5

func _ready():
	preloadAudio();
	# music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "bgm"
	add_child(music_player)

	# create sfx pool
	for i in SFX_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "sfx"
		add_child(player)
		sfx_players.append(player)
	# create voice pool
	for i in VOICE_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "voice"
		add_child(player)
		voice_players.append(player)

func preloadAudio():
	var sfxList = SoundDatabase.sfx.keys()
	for key in sfxList:
		var filePath = SoundDatabase.sfx[key]
		var fullPath = sfxPrefix + filePath
		var sound = ResourceLoader.load(fullPath)
		print("Loaded SFX: ", fullPath, " for key: ", key)
		if sound:
			print("Successfully loaded SFX: ", key)
			sfx[key] = sound
		else:
			print("Failed to load SFX: " + fullPath)

	var bgmList = SoundDatabase.bgm.keys()
	for key in bgmList:
		var filePath = SoundDatabase.bgm[key]
		var fullPath = bgmPrefix + filePath
		var sound = ResourceLoader.load(fullPath)
		print("Loaded BGM: ", fullPath, " for key: ", key)
		if sound:
			print("Successfully loaded BGM: ", key)
			bgm[key] = sound
		else:
			print("Failed to load BGM: " + fullPath)

	var voiceList = SoundDatabase.voice.keys()
	for key in voiceList:
		var filePath = SoundDatabase.voice[key]
		var fullPath = voicePrefix + filePath
		var sound = ResourceLoader.load(fullPath)
		if sound:
			voice[key] = sound
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

func playSfx(sfx_name: SoundDatabase.SFX_NAME):
	var stream = sfx.get(sfx_name)

	if stream == null:
		push_warning("SFX not found: " + str(sfx_name))
		return

	for player in sfx_players:
		if !player.playing:
			player.stream = stream
			player.play()
			return

func playVoice(voice_name: SoundDatabase.VOICE_NAME):
	var stream = voice.get(voice_name)

	if stream == null:
		push_warning("Voice not found: " + str(voice_name))
		return

	for player in voice_players:
		if !player.playing:
			player.stream = stream
			player.play()
			return
