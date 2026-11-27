class_name MusicManager
extends Node

# Procedural Pompous Patriotic Military March Synthesizer & Sequencer
# Synthesizes crisp 16-bit PCM orchestral/marching-band instrument samples once at startup
# (<25 ms), then drives a multi-track step sequencer in real time (unaffected by Engine.time_scale).
# Features:
#   - MENU mode: Ceremonial brass fanfare opening into a stately patriotic cadence
#   - COMBAT mode: Upbeat Sousa-style military march (A / B / C sections)
#   - FESTIVE mode (north_pole): Holiday toy-soldier march with sleigh bells
#   - Random completely unmotivated "Grosse Pointe Blank" fortissimo crescendos!
#     Every ~28–52 seconds of combat, regardless of whether the map is totally empty or calm,
#     the band suddenly swells into a wildly over-the-top timpani-roll, soaring piccolo,
#     full-brass & crashing-cymbal climax for 8 bars, then calmly returns to the polite march.
#   - Victory fanfare & Defeat sad-tuba stingers.

const SAMPLE_RATE: int = 22050
const POOL_SIZE: int = 24
const BASE_C4: float = 261.6256
const BASE_C2: float = 65.4064
const BASE_C5: float = 523.2511
const MUSIC_BUS_NAME: String = "Music"
const MAX_MUSIC_VOLUME: float = 1.10

enum Mode {
	NONE,
	MENU,
	COMBAT,
	FESTIVE,
	SILENT,
}

var mode: Mode = Mode.NONE
var music_volume: float = 0.50
var music_muted: bool = false
var master_muted: bool = false
var paused_duck: bool = false

var _samples: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _music_bus_idx: int = -1
var _fx_dist: AudioEffectDistortion
var _fx_hp: AudioEffectHighPassFilter
var _fx_lp: AudioEffectLowPassFilter
var _fx_eq: AudioEffectEQ6

# Sequencer timing (16th-note grid, driven by real unscaled delta)
var _step_accum: float = 0.0
var _step_index: int = 0
var _bpm: float = 122.0

# Completely unmotivated crescendo state (combat & festive only)
var _crescendo_cooldown: float = 26.0
var _crescendo_active: bool = false
var _crescendo_steps_left: int = 0
var _crescendo_total_steps: int = 160 # 6 bars slow creeping swell + 4 full bars held at max fortissimo!

# Pending stinger notes (played over time without blocking)
var _stinger_queue: Array[Dictionary] = []

# Scale helper: semitone offsets from C4 (0 = C4, 2 = D4, 4 = E4, 5 = F4, 7 = G4, 9 = A4, 11 = B4, 12 = C5)
# -999 = rest
const R: int = -999

# MENU: Ceremonial Fanfare (32 16th-note steps = 2 bars of 4/4, then loops stately)
const MENU_MELODY: Array[int] = [
	0, R, 0, 0,  4, R, 7, R,  12, R, R, 11,  12, R, 7, R,
	9, R, 7, R,  5, R, 4, R,  2, R, 7, R,   7, R, R, R,
	0, R, 4, R,  7, R, 12, R, 14, R, 12, R, 11, R, 9, R,
	7, R, 12, R, 11, R, 14, R, 12, R, R, R,  R, R, R, R,
]
const MENU_BASS: Array[int] = [
	0, R, R, R,  7, R, R, R,  0, R, R, R,   7, R, R, R,
	5, R, R, R,  0, R, R, R,  7, R, R, R,   7, R, 2, R,
	0, R, R, R,  4, R, R, R,  5, R, R, R,   7, R, R, R,
	0, R, R, R,  7, R, R, R,  0, R, R, R,   7, R, R, R,
]

# COMBAT: 128-step (8-bar) Sousa-style patriotic military march in C major / G major
const MARCH_MELODY: Array[int] = [
	# Section A (Bars 1-4): Brisk brass theme
	7, R, 12, R,  12, 11, 12, 14,  16, R, 12, R,  14, R, 11, R,
	12, R, 7, R,  9, R, 5, R,      7, R, R, 7,    7, R, R, R,
	7, R, 12, R,  12, 11, 12, 14,  16, R, 19, R,  17, R, 14, R,
	16, R, 12, R, 14, R, 11, R,    12, R, R, R,   12, R, R, R,
	# Section B (Bars 5-8): Pompous trio / counter-fanfare
	16, R, 16, 17, 19, R, 16, R,   14, R, 14, 16, 17, R, 14, R,
	12, R, 12, 14, 16, R, 12, R,   14, R, 11, R,  7, R, 9, 11,
	12, R, 16, R,  19, R, 16, R,   17, R, 14, R,  12, R, 9, R,
	7, R, 12, R,   14, R, 11, R,   12, R, 16, R,  12, R, R, R,
]
const MARCH_BASS: Array[int] = [
	# Classic oom-pah tuba bassline (beats 1 & 3, alternating root & fifth)
	0, R, R, R,  7, R, R, R,   0, R, R, R,  7, R, R, R,
	0, R, R, R,  5, R, R, R,   7, R, R, R,  2, R, 7, R,
	0, R, R, R,  7, R, R, R,   0, R, R, R,  5, R, R, R,
	0, R, R, R,  7, R, R, R,   0, R, 7, R,  0, R, R, R,
	0, R, R, R,  4, R, R, R,   7, R, R, R,  2, R, R, R,
	0, R, R, R,  4, R, R, R,   7, R, 2, R,  7, R, R, R,
	0, R, R, R,  4, R, R, R,   5, R, R, R,  9, R, R, R,
	7, R, R, R,  7, R, R, R,   0, R, 7, R,  0, R, R, R,
]
# Soaring piccolo / over-the-top harmony played ONLY during unmotivated crescendos!
const CRESCENDO_PICCOLO: Array[int] = [
	12, 14, 16, 17,  19, R, 19, 17,  16, 17, 19, 21,  24, R, 19, R,
	21, 19, 17, 16,  14, 16, 17, 19, 21, R, 23, R,    24, R, 24, R,
	19, 21, 23, 24,  24, 23, 21, 19, 17, 19, 21, 24,  23, R, 19, R,
	24, R, 24, 24,   26, R, 23, R,   24, R, 19, R,    24, R, R, R,
]

# FESTIVE (north_pole): 64-step upbeat Christmas toy-soldier march
const FESTIVE_MELODY: Array[int] = [
	16, R, 16, R,  16, R, R, R,   16, R, 16, R,  16, R, R, R,
	16, R, 19, R,  12, R, 14, R,  16, R, R, R,   R, R, R, R,
	17, R, 17, R,  17, R, 17, R,  17, R, 16, R,  16, R, 16, 16,
	19, R, 19, R,  17, R, 14, R,  12, R, R, R,   19, R, R, R,
]
const FESTIVE_BASS: Array[int] = [
	0, R, R, R,  7, R, R, R,   0, R, R, R,  7, R, R, R,
	0, R, R, R,  5, R, R, R,   0, R, 4, R,  7, R, R, R,
	5, R, R, R,  0, R, R, R,   5, R, R, R,  0, R, R, R,
	7, R, R, R,  2, R, R, R,   0, R, 7, R,  0, R, R, R,
]

func _ready() -> void:
	_setup_music_bus()
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = MUSIC_BUS_NAME if _music_bus_idx >= 0 else "Master"
		add_child(p)
		_players.append(p)
	_generate_instruments()
	_reset_crescendo_timer()
	_update_overload_fx()

func _setup_music_bus() -> void:
	_music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if _music_bus_idx < 0:
		_music_bus_idx = AudioServer.bus_count
		AudioServer.add_bus(_music_bus_idx)
		AudioServer.set_bus_name(_music_bus_idx, MUSIC_BUS_NAME)
		AudioServer.set_bus_send(_music_bus_idx, "Master")

	# Clear any pre-existing effects on the Music bus before attaching our clean overload chain
	while AudioServer.get_bus_effect_count(_music_bus_idx) > 0:
		AudioServer.remove_bus_effect(_music_bus_idx, 0)

	# 1. Hard-clipping distortion FIRST so full bass+brass slams into genuine speaker cone breakup!
	_fx_dist = AudioEffectDistortion.new()
	_fx_dist.mode = AudioEffectDistortion.MODE_CLIP
	AudioServer.add_bus_effect(_music_bus_idx, _fx_dist, 0)

	# 2. Steep 24 dB/oct High-pass filter: brutally guts all warmth/bass -> ultra tinny cheap speaker!
	_fx_hp = AudioEffectHighPassFilter.new()
	_fx_hp.db = AudioEffectFilter.FILTER_24DB
	_fx_hp.cutoff_hz = 1200.0
	_fx_hp.resonance = 1.4
	AudioServer.add_bus_effect(_music_bus_idx, _fx_hp, 1)

	# 3. Steep 18 dB/oct Low-pass filter: papery cheap speaker cone bandwidth cap
	_fx_lp = AudioEffectLowPassFilter.new()
	_fx_lp.db = AudioEffectFilter.FILTER_18DB
	_fx_lp.cutoff_hz = 2900.0
	_fx_lp.resonance = 1.3
	AudioServer.add_bus_effect(_music_bus_idx, _fx_lp, 2)

	# 4. Nasal megaphone EQ: scoops lows, spikes harsh tinny 1kHz–3.2kHz plastic speaker honk
	_fx_eq = AudioEffectEQ6.new()
	AudioServer.add_bus_effect(_music_bus_idx, _fx_eq, 3)

	for idx in range(4):
		AudioServer.set_bus_effect_enabled(_music_bus_idx, idx, false)

func _update_overload_fx() -> void:
	if _music_bus_idx < 0:
		return
	var overload: float = clampf((music_volume - 1.0) / (MAX_MUSIC_VOLUME - 1.0), 0.0, 1.0)
	var active: bool = overload > 0.001
	for idx in range(4):
		AudioServer.set_bus_effect_enabled(_music_bus_idx, idx, active)
	# Apply pause ducking at bus output AFTER distortion so testing 101-110% in Pause Menu still crunches!
	AudioServer.set_bus_volume_db(_music_bus_idx, -6.5 if paused_duck else 0.0)
	if not active:
		return
	# Steep perceptual ramp: even 102% sounds noticeably buzzy/tinny, 110% is full blown-out $2 megaphone!
	var curve: float = pow(overload, 0.72)
	_fx_dist.pre_gain = lerpf(18.0, 36.0, curve)
	_fx_dist.drive = lerpf(0.62, 0.96, curve)
	_fx_dist.keep_hf_hz = lerpf(4600.0, 2600.0, curve)
	_fx_dist.post_gain = lerpf(-9.5, -14.5, curve)

	_fx_hp.cutoff_hz = lerpf(780.0, 1650.0, curve)
	_fx_hp.resonance = lerpf(1.1, 1.85, curve)

	_fx_lp.cutoff_hz = lerpf(4200.0, 2500.0, curve)
	_fx_lp.resonance = lerpf(1.0, 1.65, curve)

	# EQ6 bands: 0=32Hz, 1=100Hz, 2=320Hz, 3=1kHz, 4=3.2kHz, 5=10kHz
	_fx_eq.set_band_gain_db(0, lerpf(-16.0, -24.0, curve))
	_fx_eq.set_band_gain_db(1, lerpf(-16.0, -24.0, curve))
	_fx_eq.set_band_gain_db(2, lerpf(-12.0, -22.0, curve))
	_fx_eq.set_band_gain_db(3, lerpf(4.5, 9.5, curve))
	_fx_eq.set_band_gain_db(4, lerpf(6.0, 12.0, curve))
	_fx_eq.set_band_gain_db(5, lerpf(-8.0, -14.0, curve))

func set_mode(new_mode: Mode) -> void:
	if mode == new_mode:
		return
	mode = new_mode
	_step_index = 0
	_step_accum = 0.0
	_crescendo_active = false
	_crescendo_steps_left = 0
	_reset_crescendo_timer()
	match mode:
		Mode.MENU:
			_bpm = 104.0
		Mode.COMBAT:
			_bpm = 124.0
		Mode.FESTIVE:
			_bpm = 128.0
		_:
			_bpm = 120.0

func set_paused_duck(ducked: bool) -> void:
	paused_duck = ducked
	_update_overload_fx()

func set_audio_state(vol: float, muted_music: bool, muted_master: bool) -> void:
	music_volume = clampf(vol, 0.0, MAX_MUSIC_VOLUME)
	music_muted = muted_music
	master_muted = muted_master
	_update_overload_fx()
	if _is_silenced():
		for p in _players:
			if p.playing:
				p.stop()

func _is_silenced() -> bool:
	return master_muted or music_muted or music_volume <= 0.001

func _reset_crescendo_timer() -> void:
	# Random 26–50 seconds before the next completely unmotivated orchestral outburst!
	_crescendo_cooldown = randf_range(26.0, 50.0)

func play_victory_stinger() -> void:
	_crescendo_active = false
	_stinger_queue.clear()
	# Glorious pompous brass victory fanfare (C-G-C-E-G-C + cymbal crash!)
	var seq: Array[Dictionary] = [
		{"delay": 0.00, "inst": "brass", "semi": 0, "vol": 0.0},
		{"delay": 0.00, "inst": "tuba", "semi": 0, "vol": -2.0},
		{"delay": 0.00, "inst": "timpani", "semi": 0, "vol": -1.0},
		{"delay": 0.14, "inst": "brass", "semi": 7, "vol": 0.0},
		{"delay": 0.28, "inst": "brass", "semi": 12, "vol": 0.5},
		{"delay": 0.42, "inst": "brass", "semi": 16, "vol": 1.0},
		{"delay": 0.58, "inst": "brass", "semi": 19, "vol": 1.5},
		{"delay": 0.58, "inst": "brass", "semi": 12, "vol": 0.0},
		{"delay": 0.58, "inst": "tuba", "semi": 0, "vol": 0.5},
		{"delay": 0.58, "inst": "cymbal", "semi": 0, "vol": 0.0},
		{"delay": 0.58, "inst": "piccolo", "semi": 12, "vol": -2.0},
		{"delay": 0.92, "inst": "brass", "semi": 24, "vol": 2.0},
		{"delay": 0.92, "inst": "brass", "semi": 16, "vol": 0.5},
		{"delay": 0.92, "inst": "tuba", "semi": 0, "vol": 1.0},
		{"delay": 0.92, "inst": "timpani", "semi": 0, "vol": 1.0},
		{"delay": 0.92, "inst": "cymbal", "semi": 0, "vol": 1.0},
	]
	_stinger_queue = seq

func play_defeat_stinger() -> void:
	_crescendo_active = false
	_stinger_queue.clear()
	# Deadpan descending sad-tuba / brass wah-wah-wah-waaaah
	var seq: Array[Dictionary] = [
		{"delay": 0.00, "inst": "tuba", "semi": 7, "vol": 0.5},
		{"delay": 0.00, "inst": "brass", "semi": 7, "vol": -3.0},
		{"delay": 0.34, "inst": "tuba", "semi": 6, "vol": 0.5},
		{"delay": 0.34, "inst": "brass", "semi": 6, "vol": -3.0},
		{"delay": 0.68, "inst": "tuba", "semi": 5, "vol": 0.5},
		{"delay": 0.68, "inst": "brass", "semi": 5, "vol": -3.0},
		{"delay": 1.04, "inst": "tuba", "semi": 4, "vol": 1.0},
		{"delay": 1.04, "inst": "brass", "semi": 4, "vol": -2.5},
		{"delay": 1.04, "inst": "snare", "semi": 0, "vol": -6.0},
	]
	_stinger_queue = seq

func _process(delta: float) -> void:
	# Always run in real wall-clock seconds so 2x/3x game speed does NOT chipmunk-speed the music
	var real_delta: float = delta / maxf(0.01, Engine.time_scale)
	real_delta = minf(real_delta, 0.1)

	# Process any active victory/defeat stinger queue
	if not _stinger_queue.is_empty():
		for i in range(_stinger_queue.size() - 1, -1, -1):
			var ev: Dictionary = _stinger_queue[i]
			ev["delay"] = float(ev["delay"]) - real_delta
			if float(ev["delay"]) <= 0.0:
				_trigger_note(String(ev["inst"]), int(ev["semi"]), float(ev["vol"]))
				_stinger_queue.remove_at(i)

	if mode == Mode.NONE or mode == Mode.SILENT or _is_silenced():
		return

	# Tick completely unmotivated crescendo timer during COMBAT / FESTIVE (even while calm/empty!)
	if (mode == Mode.COMBAT or mode == Mode.FESTIVE) and not paused_duck:
		if not _crescendo_active:
			_crescendo_cooldown -= real_delta
			if _crescendo_cooldown <= 0.0 and (_step_index % 16 == 0):
				_crescendo_active = true
				_crescendo_total_steps = 160 # 6 bars slow ramp (96 steps) + 4 full bars at max (64 steps)
				_crescendo_steps_left = _crescendo_total_steps
				_reset_crescendo_timer()

	var step_dur: float = 60.0 / (_bpm * 4.0) # 16th-note duration
	_step_accum += real_delta
	while _step_accum >= step_dur:
		_step_accum -= step_dur
		_play_step(_step_index)
		_step_index += 1
		if _crescendo_active:
			_crescendo_steps_left -= 1
			if _crescendo_steps_left <= 0:
				_crescendo_active = false

func _play_step(step: int) -> void:
	if _is_silenced():
		return

	if mode == Mode.MENU:
		var idx: int = step % MENU_MELODY.size()
		var mel: int = MENU_MELODY[idx]
		var bas: int = MENU_BASS[idx]
		if mel != R:
			_trigger_note("brass", mel, -4.5)
		if bas != R:
			_trigger_note("tuba", bas, -6.0)
		if idx % 16 == 0:
			_trigger_note("timpani", bas if bas != R else 0, -9.0)
		elif idx % 8 == 4:
			_trigger_note("snare", 0, -11.0)
		return

	var is_festive := (mode == Mode.FESTIVE)
	var mel_arr: Array[int] = FESTIVE_MELODY if is_festive else MARCH_MELODY
	var bas_arr: Array[int] = FESTIVE_BASS if is_festive else MARCH_BASS
	var m_idx: int = step % mel_arr.size()
	var mel: int = mel_arr[m_idx]
	var bas: int = bas_arr[m_idx]

	# Compute crescendo intensity curve:
	#   Bars 1-6 (steps 0..95): Slow, stealthy creeping build from 0.0 -> 1.0
	#   Bars 7-10 (steps 96..159): 4 full bars sustained at maximum 1.0 fortissimo bombast
	#   Step 160: Abrupt deadpan return to the polite little march!
	var cresc: float = 0.0
	var c_step: int = 0
	if _crescendo_active:
		c_step = _crescendo_total_steps - _crescendo_steps_left
		var ramp_steps: float = 96.0
		var ramp_u: float = clampf(float(c_step) / ramp_steps, 0.0, 1.0)
		cresc = pow(ramp_u, 1.35)

	var dyn_boost_db: float = lerpf(0.0, 5.8, cresc)

	# 1. Lead Brass Melody (extra voices fade in smoothly as the slow swell builds!)
	if mel != R:
		_trigger_note("brass", mel, -4.0 + dyn_boost_db)
		if cresc > 0.25:
			var horn_u := clampf((cresc - 0.25) / 0.55, 0.0, 1.0)
			_trigger_note("brass", mel - 5, lerpf(-13.5, -2.0, horn_u)) # Fat French horn harmony swelling in
		if cresc > 0.78 and (step % 4 == 0):
			var oct_u := clampf((cresc - 0.78) / 0.22, 0.0, 1.0)
			_trigger_note("brass", mel + 12, lerpf(-11.5, -2.2, oct_u)) # Screaming trumpet octave at climax

	# 2. Oom-Pah Tuba Bass
	if bas != R:
		_trigger_note("tuba", bas, -4.5 + dyn_boost_db * 0.85)

	# 3. Marching Percussion (Snare + Bass Drum + Sleigh Bells on North Pole)
	var beat16: int = step % 16
	if beat16 == 0 or beat16 == 8:
		_trigger_note("bass_drum", 0, -5.5 + dyn_boost_db)
	if beat16 == 4 or beat16 == 12:
		_trigger_note("snare", 0, -7.5 + dyn_boost_db * 0.8)
	elif beat16 == 14 or beat16 == 15:
		_trigger_note("snare", 0, -11.5 + dyn_boost_db * 0.8) # Crisp marching grace-note ruff

	if is_festive and (beat16 % 4 == 0 or (cresc > 0.45 and beat16 % 2 == 0)):
		_trigger_note("sleigh_bell", 0, -8.5 + dyn_boost_db * 0.7)

	# 4. Unmotivated "Grosse Pointe Blank" Crescendo Bombast!
	if _crescendo_active:
		# Creeping orchestral timpani: enters quietly on quarter beats, accelerates to relentless 8th-note thunder
		if cresc > 0.08:
			var timp_div: int = 2 if cresc > 0.45 else 4
			if c_step % timp_div == 0:
				var timp_u := clampf((cresc - 0.08) / 0.82, 0.0, 1.0)
				var timp_semi: int = bas if bas != R else (7 if (c_step % 8 >= 4) else 0)
				_trigger_note("timpani", timp_semi, lerpf(-15.0, -3.2, timp_u))

		# Soaring patriotic piccolo obligato (fades in smoothly during middle of swell)
		var pic: int = CRESCENDO_PICCOLO[c_step % CRESCENDO_PICCOLO.size()]
		if pic != R and cresc > 0.42:
			var pic_u := clampf((cresc - 0.42) / 0.48, 0.0, 1.0)
			_trigger_note("piccolo", pic - 12, lerpf(-14.5, -3.5, pic_u))

		# Double-time snare frenzy swelling in ahead of the peak
		if cresc > 0.62 and (c_step % 2 == 1):
			var sn_u := clampf((cresc - 0.62) / 0.35, 0.0, 1.0)
			_trigger_note("snare", 0, lerpf(-14.0, -5.2, sn_u))

		# MASSIVE CYMBAL CRASHES across the 4-bar sustained maximum plateau (bars 7-10: steps 96..159)
		if c_step == 96 or c_step == 112 or c_step == 128 or c_step == 144 or c_step == 152 or c_step == 156:
			_trigger_note("cymbal", 0, -0.5)

func _trigger_note(inst: String, semitone_offset: int, vol_offset_db: float) -> void:
	if _is_silenced():
		return
	if not _samples.has(inst):
		return
	var p: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	p.stream = _samples[inst]
	var overload: float = clampf((music_volume - 1.0) / (MAX_MUSIC_VOLUME - 1.0), 0.0, 1.0)
	var base_db: float = linear_to_db(clampf(music_volume, 0.001, 1.0)) - 7.5 + lerpf(0.0, 1.8, overload)
	p.volume_db = base_db + vol_offset_db
	if inst == "snare" or inst == "bass_drum" or inst == "cymbal" or inst == "sleigh_bell":
		p.pitch_scale = 1.0 + randf_range(-0.02, 0.02)
	else:
		p.pitch_scale = pow(2.0, float(semitone_offset) / 12.0)
	p.play()

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

func _generate_instruments() -> void:
	_samples["brass"] = _make_brass(BASE_C4, 0.34)
	_samples["tuba"] = _make_tuba(BASE_C2, 0.36)
	_samples["piccolo"] = _make_piccolo(BASE_C5, 0.22)
	_samples["snare"] = _make_snare()
	_samples["bass_drum"] = _make_bass_drum()
	_samples["timpani"] = _make_timpani(BASE_C2 * 1.5)
	_samples["cymbal"] = _make_cymbal()
	_samples["sleigh_bell"] = _make_sleigh_bell()

func _make_brass(freq: float, dur: float) -> AudioStreamWAV:
	# Bright pompous trumpet/horn additive harmonic stack with slight brassy swell attack
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var attack := minf(t / 0.024, 1.0)
		var decay := exp(-maxf(0.0, t - 0.10) * 9.5)
		var env := attack * decay
		var bright := minf(t / 0.055, 1.0)
		var vib := 1.0 + 0.004 * sin(TAU * 5.8 * t)
		var f := freq * vib
		var sig := (
			sin(TAU * f * t) * 0.45
			+ sin(TAU * f * 2.0 * t) * (0.28 + 0.10 * bright)
			+ sin(TAU * f * 3.0 * t) * (0.18 * bright)
			+ sin(TAU * f * 4.0 * t) * (0.11 * bright)
			+ sin(TAU * f * 5.0 * t) * (0.06 * bright)
		)
		buf[i] = clampf(sig * env * 0.62, -1.0, 1.0)
	return _build_wav(buf)

func _make_tuba(freq: float, dur: float) -> AudioStreamWAV:
	# Warm, fat marching tuba oom-pah note
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var attack := minf(t / 0.020, 1.0)
		var env := attack * exp(-maxf(0.0, t - 0.09) * 8.5)
		var sig := (
			sin(TAU * freq * t) * 0.58
			+ sin(TAU * freq * 2.0 * t) * 0.30
			+ sin(TAU * freq * 3.0 * t) * 0.14
			+ sin(TAU * freq * 4.0 * t) * 0.05
		)
		buf[i] = clampf(sig * env * 0.72, -1.0, 1.0)
	return _build_wav(buf)

func _make_piccolo(freq: float, dur: float) -> AudioStreamWAV:
	# Crisp Sousa piccolo/fife note with gentle airy chiff
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := minf(t / 0.014, 1.0) * exp(-maxf(0.0, t - 0.07) * 14.0)
		var vib := 1.0 + 0.006 * sin(TAU * 6.5 * t)
		var f := freq * vib
		var tone := sin(TAU * f * t) * 0.72 + sin(TAU * f * 2.0 * t) * 0.18
		var chiff := randf_range(-1.0, 1.0) * exp(-t * 45.0) * 0.12
		buf[i] = clampf((tone + chiff) * env * 0.45, -1.0, 1.0)
	return _build_wav(buf)

func _make_snare() -> AudioStreamWAV:
	# Crisp military parade snare drum
	var dur := 0.14
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var prev := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var raw := randf_range(-1.0, 1.0)
		var hp := raw - prev * 0.55
		prev = raw
		var body := sin(TAU * lerpf(230.0, 155.0, minf(t / 0.04, 1.0)) * t) * exp(-t * 36.0)
		var wires := hp * exp(-t * 24.0)
		buf[i] = clampf((body * 0.35 + wires * 0.65) * 0.68, -1.0, 1.0)
	return _build_wav(buf)

func _make_bass_drum() -> AudioStreamWAV:
	# Booming marching bass drum thump
	var dur := 0.24
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(118.0, 44.0, minf(t / 0.08, 1.0))
		phase += TAU * freq / SAMPLE_RATE
		var env := exp(-t * 14.0)
		var thump := sin(phase) * env
		var mallet := randf_range(-1.0, 1.0) * exp(-t * 55.0) * 0.22
		buf[i] = clampf((thump * 0.85 + mallet) * 0.80, -1.0, 1.0)
	return _build_wav(buf)

func _make_timpani(freq: float) -> AudioStreamWAV:
	# Resonant orchestral kettle drum
	var dur := 0.42
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var f := lerpf(freq * 1.18, freq, minf(t / 0.05, 1.0))
		phase += TAU * f / SAMPLE_RATE
		var env := minf(t / 0.008, 1.0) * exp(-t * 7.2)
		var drum := sin(phase) * 0.72 + sin(phase * 1.5) * 0.22
		var hit := randf_range(-1.0, 1.0) * exp(-t * 48.0) * 0.16
		buf[i] = clampf((drum + hit) * env * 0.72, -1.0, 1.0)
	return _build_wav(buf)

func _make_cymbal() -> AudioStreamWAV:
	# Dramatic brass orchestral crash cymbal
	var dur := 0.95
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var prev := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var raw := randf_range(-1.0, 1.0)
		var hp := raw - prev * 0.72
		prev = raw
		var shimmer := sin(TAU * 3140.0 * t) * 0.14 + sin(TAU * 4720.0 * t) * 0.12 + sin(TAU * 6310.0 * t) * 0.08
		var env := minf(t / 0.012, 1.0) * exp(-t * 3.4)
		buf[i] = clampf((hp * 0.68 + shimmer * hp) * env * 0.62, -1.0, 1.0)
	return _build_wav(buf)

func _make_sleigh_bell() -> AudioStreamWAV:
	# Bright holiday sleigh-bell jingle
	var dur := 0.16
	var n := int(dur * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := minf(t / 0.008, 1.0) * exp(-t * 22.0)
		var metal := sin(TAU * 2860.0 * t) * 0.35 + sin(TAU * 4120.0 * t) * 0.30 + sin(TAU * 5680.0 * t) * 0.20
		var rattle := randf_range(-1.0, 1.0) * 0.28
		buf[i] = clampf((metal + rattle) * env * 0.45, -1.0, 1.0)
	return _build_wav(buf)
