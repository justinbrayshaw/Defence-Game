class_name VoiceManager
extends Node

# Military Field-Radio Vocal Callout Manager
# Plays compact 16kHz .wav voice clips from res://assets/audio/vo/ through a dedicated
# "Radio" audio bus (bandpass + warm overdrive + walkie-talkie squelch clicks).
# Easily extensible: swap any res://assets/audio/vo/*.wav file to customize voices!

const RADIO_BUS_NAME: String = "Radio"
const SAMPLE_RATE: int = 22050

const CATALOG: Dictionary = {
	"kill": [
		{"id": "vo_kill_01", "text": "ZONING ENFORCED! MAGNIFICENT!"},
		{"id": "vo_kill_02", "text": "PARKING PERMIT REVOKED!"},
		{"id": "vo_kill_03", "text": "WARRANTY VOIDED! SPLENDID!"},
		{"id": "vo_kill_04", "text": "TOWED AT OWNER EXPENSE!"},
		{"id": "vo_kill_05", "text": "ILLEGAL U-TURN PENALIZED!"},
		{"id": "vo_kill_06", "text": "PERMIT DENIED! CARRY ON!"},
	],
	"airstrike": [
		{"id": "vo_airstrike_01", "text": "HELLFIRE INBOUND! AGGRESSIVE REZONING!"},
		{"id": "vo_airstrike_02", "text": "AERIAL CITATION ISSUED!"},
		{"id": "vo_airstrike_03", "text": "NO STANDING ANYTIME! FIRE EVERYTHING!"},
	],
	"upgrade": [
		{"id": "vo_upgrade_01", "text": "EXTRA BARRELS BOLTED! GLORIOUS!"},
		{"id": "vo_upgrade_02", "text": "CONCRETE EXCELLENCE! BUDGET APPROVED!"},
	],
	"promotion": [
		{"id": "vo_upgrade_03", "text": "FIELD PROMOTION! PIN ANOTHER MEDAL!"},
	],
	"rare": [
		{"id": "vo_rare_fish_and_chips", "text": "FISH AND CHIPS!"},
	],
	"leak_ground": [
		{"id": "vo_leak_01", "text": "OI! FREE PARKING!"},
		{"id": "vo_leak_02", "text": "YOUR ARTISANAL JAM IS OURS!"},
		{"id": "vo_leak_03", "text": "QUEUE JUMPED! HA HA HA!"},
		{"id": "vo_leak_04", "text": "NICE CONCRETE, LOSER!"},
		{"id": "vo_leak_05", "text": "TERRIBLE GOLF HANDICAP!"},
		{"id": "vo_leak_06", "text": "WE DOG-EARED YOUR LIBRARY BOOKS!"},
	],
	"leak_air": [
		{"id": "vo_leak_air_01", "text": "AIRSPACE? WHAT AIRSPACE?!"},
		{"id": "vo_leak_air_02", "text": "SHOULD HAVE BUILT A SAM BATTERY!"},
		{"id": "vo_leak_02", "text": "YOUR ARTISANAL JAM IS OURS!"},
		{"id": "vo_leak_05", "text": "TERRIBLE GOLF HANDICAP!"},
	],
}

var sfx_volume: float = 0.85
var sfx_muted: bool = false
var master_muted: bool = false

var _radio_bus_idx: int = -1
var _voice_player: AudioStreamPlayer
var _squelch_player: AudioStreamPlayer
var _streams: Dictionary = {}
var _squelch_in: AudioStreamWAV
var _squelch_out: AudioStreamWAV

var _pending_stream: AudioStream = null
var _pending_delay: float = 0.0
var _last_clip_id: String = ""
var _last_spoken_sec: float = -10.0

func _ready() -> void:
	_setup_radio_bus()
	_squelch_in = _make_squelch(true)
	_squelch_out = _make_squelch(false)

	var bus_name := RADIO_BUS_NAME if _radio_bus_idx >= 0 else "Master"
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = bus_name
	_voice_player.finished.connect(_on_voice_finished)
	add_child(_voice_player)

	_squelch_player = AudioStreamPlayer.new()
	_squelch_player.bus = bus_name
	add_child(_squelch_player)

	_preload_clips()

func _setup_radio_bus() -> void:
	_radio_bus_idx = AudioServer.get_bus_index(RADIO_BUS_NAME)
	if _radio_bus_idx < 0:
		_radio_bus_idx = AudioServer.bus_count
		AudioServer.add_bus(_radio_bus_idx)
		AudioServer.set_bus_name(_radio_bus_idx, RADIO_BUS_NAME)
		AudioServer.set_bus_send(_radio_bus_idx, "Master")

	while AudioServer.get_bus_effect_count(_radio_bus_idx) > 0:
		AudioServer.remove_bus_effect(_radio_bus_idx, 0)

	# Military field-radio DSP: tight bandpass + light warm overdrive so speech cuts cleanly over combat
	var hp := AudioEffectHighPassFilter.new()
	hp.db = AudioEffectFilter.FILTER_12DB
	hp.cutoff_hz = 380.0
	hp.resonance = 0.85
	AudioServer.add_bus_effect(_radio_bus_idx, hp, 0)

	var lp := AudioEffectLowPassFilter.new()
	lp.db = AudioEffectFilter.FILTER_12DB
	lp.cutoff_hz = 3600.0
	lp.resonance = 0.72
	AudioServer.add_bus_effect(_radio_bus_idx, lp, 1)

	var dist := AudioEffectDistortion.new()
	dist.mode = AudioEffectDistortion.MODE_OVERDRIVE
	dist.pre_gain = 6.5
	dist.drive = 0.28
	dist.post_gain = -1.5
	AudioServer.add_bus_effect(_radio_bus_idx, dist, 2)

func _preload_clips() -> void:
	var loaded_ids: Dictionary = {}
	for cat_list in CATALOG.values():
		for entry in cat_list:
			var cid: String = String(entry["id"])
			if loaded_ids.has(cid):
				continue
			loaded_ids[cid] = true
			var path := "res://assets/audio/vo/%s.wav" % cid
			if ResourceLoader.exists(path):
				var res := load(path)
				if res is AudioStream:
					_streams[cid] = res

func set_audio_state(vol: float, muted_sfx: bool, muted_master: bool) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	sfx_muted = muted_sfx
	master_muted = muted_master
	if is_silenced():
		stop_all()

func is_silenced() -> bool:
	return master_muted or sfx_muted or sfx_volume <= 0.001

func stop_all() -> void:
	_pending_stream = null
	_pending_delay = 0.0
	if _voice_player != null and _voice_player.playing:
		_voice_player.stop()
	if _squelch_player != null and _squelch_player.playing:
		_squelch_player.stop()

func _process(delta: float) -> void:
	if _pending_stream == null:
		return
	var real_delta := delta / maxf(0.01, Engine.time_scale)
	_pending_delay -= real_delta
	if _pending_delay <= 0.0:
		var st := _pending_stream
		_pending_stream = null
		if not is_silenced() and _voice_player != null:
			_voice_player.stream = st
			_voice_player.volume_db = linear_to_db(clampf(sfx_volume, 0.001, 1.0)) + 1.5
			_voice_player.pitch_scale = 1.0 + randf_range(-0.025, 0.025)
			_voice_player.play()

func _on_voice_finished() -> void:
	if is_silenced() or _squelch_player == null:
		return
	_squelch_player.stream = _squelch_out
	_squelch_player.volume_db = linear_to_db(clampf(sfx_volume, 0.001, 1.0)) - 7.0
	_squelch_player.pitch_scale = 1.0
	_squelch_player.play()

func play_category(category: String, min_gap_sec: float = 2.8) -> String:
	var eff_cat := category
	# Very rare (~2.5%) unexplained General Easter egg on any friendly callout!
	if (category == "kill" or category == "airstrike" or category == "upgrade" or category == "promotion") and randf() < 0.025:
		eff_cat = "rare"

	var list: Array = CATALOG.get(eff_cat, [])
	if list.is_empty():
		return ""

	# Pick a random entry avoiding back-to-back repeats
	var chosen: Dictionary = list[randi() % list.size()]
	if list.size() > 1 and String(chosen["id"]) == _last_clip_id:
		var alt_idx := (list.find(chosen) + 1 + randi() % (list.size() - 1)) % list.size()
		chosen = list[alt_idx]

	var cid: String = String(chosen["id"])
	var txt: String = String(chosen["text"])

	var now := Time.get_ticks_msec() * 0.001
	var busy := (_voice_player != null and _voice_player.playing) or (_pending_stream != null)
	if not is_silenced() and not busy and (now - _last_spoken_sec >= min_gap_sec) and _streams.has(cid):
		_last_clip_id = cid
		_last_spoken_sec = now
		_squelch_player.stream = _squelch_in
		_squelch_player.volume_db = linear_to_db(clampf(sfx_volume, 0.001, 1.0)) - 6.0
		_squelch_player.pitch_scale = 1.0
		_squelch_player.play()
		_pending_stream = _streams[cid]
		_pending_delay = 0.065

	return txt

func _make_squelch(is_open: bool) -> AudioStreamWAV:
	# Short military walkie-talkie static burst + subtle Roger beep
	var dur := 0.075 if is_open else 0.055
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var prev := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var raw := randf_range(-1.0, 1.0)
		var hp := raw - prev * 0.65
		prev = raw
		var env := sin(PI * clampf(t / dur, 0.0, 1.0))
		var beep := sin(TAU * (1520.0 if is_open else 1120.0) * t) * 0.25 if t > dur * 0.45 else 0.0
		buf[i] = clampf((hp * 0.55 + beep) * env * 0.48, -1.0, 1.0)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var v := clampi(int(clampf(buf[i], -1.0, 1.0) * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, v)
	wav.data = bytes
	return wav
