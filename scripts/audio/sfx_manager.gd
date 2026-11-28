class_name SfxManager
extends Node

const SAMPLE_RATE: int = 22050
const POOL_SIZE: int = 18

var muted: bool = false
var sfx_muted: bool = false
var master_muted: bool = false
var sfx_volume: float = 0.85
var master_volume_db: float = -6.0

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _last_played: Dictionary = {}

var _pool_size: int = POOL_SIZE

func _ready() -> void:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web"):
		_pool_size = 12
	for i in range(_pool_size):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_generate_all_sfx()

func is_silenced() -> bool:
	return muted or master_muted or sfx_muted or sfx_volume <= 0.001

func play(sound_name: String, volume_offset_db: float = 0.0, pitch_jitter: float = 0.06, min_interval: float = 0.03) -> void:
	if is_silenced():
		return
	if not _streams.has(sound_name):
		return
	var now := Time.get_ticks_msec() * 0.001
	var prev: float = _last_played.get(sound_name, -10.0)
	if now - prev < min_interval:
		return
	_last_played[sound_name] = now

	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _pool_size
	player.stream = _streams[sound_name]
	var base_db: float = linear_to_db(clampf(sfx_volume, 0.001, 1.0)) - 4.0
	player.volume_db = base_db + volume_offset_db
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()

func set_muted(value: bool) -> void:
	muted = value
	master_muted = value

func set_audio_state(vol: float, muted_sfx: bool, muted_master: bool) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	sfx_muted = muted_sfx
	master_muted = muted_master
	muted = muted_master or muted_sfx

func _generate_all_sfx() -> void:
	_streams["vulcan"] = _make_vulcan()
	_streams["cannon"] = _make_cannon()
	_streams["missile"] = _make_missile()
	_streams["cryo"] = _make_cryo()
	_streams["laser"] = _make_laser()
	_streams["mlrs"] = _make_mlrs()
	_streams["drone_launch"] = _make_drone_launch()
	_streams["drone_fire"] = _make_drone_fire()
	_streams["uav_launch"] = _make_uav_launch()
	_streams["explosion_small"] = _make_explosion(0.28, 120.0, 0.72)
	_streams["explosion_big"] = _make_explosion(0.62, 72.0, 0.95)
	_streams["airstrike_jet"] = _make_jet_flyby()
	_streams["place"] = _make_place()
	_streams["upgrade"] = _make_upgrade()
	_streams["sell"] = _make_sell()
	_streams["wave_start"] = _make_wave_horn()
	_streams["base_hit"] = _make_base_hit()
	_streams["ui_click"] = _make_click()
	_streams["festive_chime"] = _make_festive_chime()

func _build_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v := clampi(int(clampf(samples[i], -1.0, 1.0) * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, v)
	wav.data = bytes
	return wav

func _make_vulcan() -> AudioStreamWAV:
	var dur := 0.068
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 48.0)
		var punch := sin(TAU * lerpf(240.0, 75.0, minf(t / 0.025, 1.0)) * t)
		var noise := randf_range(-1.0, 1.0)
		lp = lp * 0.55 + noise * 0.45
		buf[i] = (punch * 0.48 + lp * 0.52) * env * 0.55
	return _build_wav(buf)

func _make_cannon() -> AudioStreamWAV:
	var dur := 0.34
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(155.0, 32.0, minf(t / 0.14, 1.0))
		phase += TAU * freq / SAMPLE_RATE
		var boom := sin(phase) * exp(-t * 9.5)
		var crack := randf_range(-1.0, 1.0) * exp(-t * 28.0)
		lp = lp * 0.82 + randf_range(-1.0, 1.0) * 0.18
		var rumble := lp * exp(-t * 6.5)
		buf[i] = clampf((boom * 0.72 + crack * 0.42 + rumble * 0.48) * 0.85, -1.0, 1.0)
	return _build_wav(buf)

func _make_missile() -> AudioStreamWAV:
	var dur := 0.26
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	var hp := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var attack := minf(t / 0.03, 1.0)
		var env := attack * exp(-t * 7.5)
		var raw := randf_range(-1.0, 1.0)
		lp = lp * 0.76 + raw * 0.24
		hp = raw - lp
		var whistle := sin(TAU * lerpf(380.0, 740.0, t / dur) * t) * 0.14
		buf[i] = (lp * 0.55 + hp * 0.35 + whistle) * env * 0.65
	return _build_wav(buf)

func _make_cryo() -> AudioStreamWAV:
	var dur := 0.20
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var prev := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := minf(t / 0.015, 1.0) * exp(-t * 14.0)
		var raw := randf_range(-1.0, 1.0)
		var hiss := raw - prev * 0.7
		prev = raw
		var chime := sin(TAU * 1320.0 * t) * 0.22 + sin(TAU * 1980.0 * t) * 0.16
		buf[i] = (hiss * 0.38 + chime) * env * 0.48
	return _build_wav(buf)

func _make_explosion(dur: float, start_freq: float, gain: float) -> AudioStreamWAV:
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(start_freq, 22.0, minf(t / (dur * 0.65), 1.0))
		phase += TAU * freq / SAMPLE_RATE
		var raw := randf_range(-1.0, 1.0)
		lp = lp * 0.86 + raw * 0.14
		var sub := sin(phase) * exp(-t * (5.5 / dur) * 0.7)
		var blast := lp * exp(-t * (4.2 / dur))
		var transient := raw * exp(-t * 42.0) * 0.45
		buf[i] = clampf((sub * 0.55 + blast * 0.72 + transient) * gain, -1.0, 1.0)
	return _build_wav(buf)

func _make_jet_flyby() -> AudioStreamWAV:
	var dur := 1.25
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	var phase := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var u := t / dur
		var env := sin(PI * u)
		env = env * env
		var raw := randf_range(-1.0, 1.0)
		var cutoff := lerpf(0.75, 0.92, u)
		lp = lp * cutoff + raw * (1.0 - cutoff)
		var turbine := lerpf(540.0, 165.0, u)
		phase += TAU * turbine / SAMPLE_RATE
		var whine := sin(phase) * 0.18
		buf[i] = clampf((lp * 0.85 + whine) * env * 0.75, -1.0, 1.0)
	return _build_wav(buf)

func _make_place() -> AudioStreamWAV:
	var dur := 0.17
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var clank1 := sin(TAU * 175.0 * t) * exp(-t * 32.0)
		var t2 := maxf(0.0, t - 0.045)
		var clank2 := (sin(TAU * 310.0 * t2) + 0.5 * sin(TAU * 520.0 * t2)) * exp(-t2 * 38.0) * (1.0 if t > 0.045 else 0.0)
		var noise := randf_range(-1.0, 1.0) * exp(-t * 50.0) * 0.25
		buf[i] = clampf((clank1 * 0.6 + clank2 * 0.45 + noise) * 0.7, -1.0, 1.0)
	return _build_wav(buf)

func _make_upgrade() -> AudioStreamWAV:
	var dur := 0.24
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var a := sin(TAU * 440.0 * t) * exp(-t * 24.0)
		var t2 := maxf(0.0, t - 0.075)
		var b := (sin(TAU * 660.0 * t2) + 0.4 * sin(TAU * 990.0 * t2)) * exp(-t2 * 18.0) * (1.0 if t > 0.075 else 0.0)
		buf[i] = clampf((a * 0.45 + b * 0.55) * 0.6, -1.0, 1.0)
	return _build_wav(buf)

func _make_sell() -> AudioStreamWAV:
	var dur := 0.18
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var a := sin(TAU * 520.0 * t) * exp(-t * 26.0)
		var t2 := maxf(0.0, t - 0.055)
		var b := sin(TAU * 360.0 * t2) * exp(-t2 * 22.0) * (1.0 if t > 0.055 else 0.0)
		buf[i] = clampf((a * 0.45 + b * 0.45) * 0.55, -1.0, 1.0)
	return _build_wav(buf)

func _make_wave_horn() -> AudioStreamWAV:
	var dur := 0.44
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var pulse := 1.0 if (t < 0.16 or (t > 0.22 and t < 0.40)) else 0.0
		var freq := 340.0 if t < 0.20 else 440.0
		var sig := sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.0 * t)
		var env := pulse * minf(t / 0.015, 1.0) * exp(-maxf(0.0, t - 0.34) * 28.0)
		buf[i] = clampf(sig * env * 0.35, -1.0, 1.0)
	return _build_wav(buf)

func _make_base_hit() -> AudioStreamWAV:
	var dur := 0.36
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(210.0, 110.0, t / dur)
		var buzz := signf(sin(TAU * freq * t)) * 0.45 + sin(TAU * freq * 0.5 * t) * 0.55
		var env := exp(-t * 7.5)
		buf[i] = clampf(buzz * env * 0.5, -1.0, 1.0)
	return _build_wav(buf)

func _make_click() -> AudioStreamWAV:
	var dur := 0.04
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var sig := sin(TAU * 920.0 * t) * exp(-t * 85.0)
		buf[i] = sig * 0.42
	return _build_wav(buf)

func _make_festive_chime() -> AudioStreamWAV:
	# Sparkling 4-note sleigh-bell / music-box holiday jingle (E5-E5-E5-G5-C5-D5-E5 cadence!)
	var dur := 0.72
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var notes: Array[float] = [659.25, 783.99, 1046.50, 1318.51]
	var starts: Array[float] = [0.0, 0.11, 0.22, 0.34]
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0
		for k in range(notes.size()):
			var dt := t - starts[k]
			if dt >= 0.0:
				var freq: float = notes[k]
				var bell := sin(TAU * freq * dt) + 0.35 * sin(TAU * freq * 2.0 * dt) + 0.15 * sin(TAU * freq * 3.0 * dt)
				sample += bell * exp(-dt * 9.0) * 0.28
		# Subtle sleigh-bell shimmer
		var jingle := randf_range(-1.0, 1.0) * sin(TAU * 4200.0 * t) * exp(-t * 4.5) * 0.08
		buf[i] = clampf(sample + jingle, -1.0, 1.0)
	return _build_wav(buf)

func _make_laser() -> AudioStreamWAV:
	# High-energy directed-energy hum + crisp thermal sizzle
	var dur := 0.16
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := sin(PI * clampf(t / dur, 0.0, 1.0))
		var hum := sin(TAU * 220.0 * t) * 0.42 + sin(TAU * 440.0 * t) * 0.28 + sin(TAU * 880.0 * t) * 0.14
		var sizzle := randf_range(-1.0, 1.0) * 0.16
		buf[i] = clampf((hum + sizzle) * env * 0.48, -1.0, 1.0)
	return _build_wav(buf)

func _make_mlrs() -> AudioStreamWAV:
	# Punchy rapid HIMARS rocket ignition whoosh
	var dur := 0.20
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := minf(t / 0.018, 1.0) * exp(-t * 10.5)
		var raw := randf_range(-1.0, 1.0)
		lp = lp * 0.70 + raw * 0.30
		var roar := sin(TAU * lerpf(210.0, 520.0, t / dur) * t) * 0.24
		buf[i] = clampf((lp * 0.72 + roar) * env * 0.72, -1.0, 1.0)
	return _build_wav(buf)

func _make_drone_launch() -> AudioStreamWAV:
	# Rising brushless rotor spool-up + pneumatic launch snap
	var dur := 0.28
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var u := t / dur
		var freq := lerpf(260.0, 960.0, u * u)
		phase += TAU * freq / SAMPLE_RATE
		var env := minf(t / 0.025, 1.0) * exp(-maxf(0.0, t - 0.14) * 14.0)
		var whirr := sin(phase) * 0.55 + sin(phase * 2.0) * 0.22
		var pop := randf_range(-1.0, 1.0) * exp(-t * 45.0) * 0.35
		buf[i] = clampf((whirr + pop) * env * 0.52, -1.0, 1.0)
	return _build_wav(buf)

func _make_drone_fire() -> AudioStreamWAV:
	# Tight suppressed tactical micro-burst
	var dur := 0.055
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 62.0)
		var snap := sin(TAU * lerpf(640.0, 180.0, t / dur) * t) * 0.55
		var crack := randf_range(-1.0, 1.0) * 0.45
		buf[i] = clampf((snap + crack) * env * 0.46, -1.0, 1.0)
	return _build_wav(buf)

func _make_uav_launch() -> AudioStreamWAV:
	# Hostile catapult buzz launch
	var dur := 0.22
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(190.0, 480.0, t / dur)
		phase += TAU * freq / SAMPLE_RATE
		var env := minf(t / 0.02, 1.0) * exp(-t * 9.0)
		var buzz := signf(sin(phase)) * 0.25 + sin(phase) * 0.45
		buf[i] = clampf(buzz * env * 0.42, -1.0, 1.0)
	return _build_wav(buf)
