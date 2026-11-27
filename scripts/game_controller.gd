class_name GameController
extends Node2D

const AIRSTRIKE_COOLDOWN: float = 36.0
const AIRSTRIKE_RADIUS: float = 120.0
const INTER_WAVE_TIME: float = 14.0
const HUD_TOP_SAFE: float = 58.0
const HUD_BOTTOM_SAFE: float = 104.0

var map_data: Dictionary = {}
var waves: Array[Dictionary] = []
var difficulty: WaveData.Difficulty = WaveData.Difficulty.NORMAL
var diff_cfg: Dictionary = {}

# Economy & state
var game_started: bool = false
var game_over: bool = false
var paused: bool = false
var pause_menu_open: bool = false
var game_speed: float = 1.0
var cash: int = 280
var lives: int = 20
var max_lives: int = 20
var total_kills: int = 0
var _play_time_accum: float = 0.0
var _callout_cd: float = 18.0
var _leak_taunt_cd: float = 0.0

# Wave state
var current_wave_index: int = -1 # -1 before Wave 1
var active_spawners: Array[Dictionary] = []
var inter_wave_timer: float = 0.0
var waiting_for_next_wave: bool = false
var _unclaimed_wave_bonuses: Array[int] = []

# Placement / selection / ability state
var placing_type: Variant = null # TurretData.TurretType or null
var selected_turret: Turret = null
var airstrike_cd: float = 0.0
var airstrike_aiming: bool = false
var drone_assign_aiming: bool = false
var pending_bombs: Array[Dictionary] = []

# Camera & input state
var _cam_target_pos: Vector2 = Vector2(800, 480)
var _cam_target_zoom: float = 0.82
var _shake_strength: float = 0.0
var _panning: bool = false
var _pan_dragged: bool = false
var _last_mouse_screen: Vector2 = Vector2.ZERO
var _secret_code_buf: String = ""

# Scene nodes
var _camera: Camera2D
var _terrain: TerrainLayer
var _sim_world: Node2D
var _decals: DecalLayer
var _turrets_node: Node2D
var _enemies_node: Node2D
var _projectiles_node: Node2D
var _fx: FxManager
var _sfx: SfxManager
var _voice: VoiceManager
var _music: MusicManager
var _save: SaveManager
var _hud: GameHud

func _ready() -> void:
	map_data = MapData.get_iron_valley()
	waves = WaveData.get_waves_for_map(String(map_data["id"]))
	diff_cfg = WaveData.get_difficulty_config(difficulty)
	_save = SaveManager.new()

	_build_scene_tree()
	_connect_hud()
	_apply_saved_audio_settings()
	_hud.set_sector_records(_save.get_all_sector_records())
	_hud.set_medals_data(_save.get_unlocked_medals(), _save.get_stats(), _save.get_all_sector_records())
	_hud.set_general_avatar(_save.get_general_avatar())
	get_viewport().size_changed.connect(_on_viewport_resized)
	_reset_camera()
	_hud.show_menu()
	_music.set_mode(MusicManager.Mode.MENU)
	_refresh_hud()

func _on_viewport_resized() -> void:
	if _camera == null or map_data.is_empty():
		return
	var fit := _get_fit_zoom()
	if not game_started or _cam_target_zoom < fit:
		_cam_target_zoom = fit
	_clamp_camera_target()

func _build_scene_tree() -> void:
	_camera = Camera2D.new()
	_camera.position = Vector2(float(map_data["width"]) * 0.5, float(map_data["height"]) * 0.5)
	_camera.zoom = Vector2(_cam_target_zoom, _cam_target_zoom)
	_camera.position_smoothing_enabled = false
	add_child(_camera)
	_camera.make_current()

	_terrain = TerrainLayer.new()
	_terrain.z_index = 0
	add_child(_terrain)
	_terrain.setup(map_data)

	_sim_world = Node2D.new()
	add_child(_sim_world)

	_decals = DecalLayer.new()
	_decals.z_index = 5
	_sim_world.add_child(_decals)

	_enemies_node = Node2D.new()
	_enemies_node.z_index = 15
	_sim_world.add_child(_enemies_node)

	_turrets_node = Node2D.new()
	_turrets_node.z_index = 20
	_sim_world.add_child(_turrets_node)

	_projectiles_node = Node2D.new()
	_projectiles_node.z_index = 40
	_sim_world.add_child(_projectiles_node)

	_fx = FxManager.new()
	_fx.z_index = 50
	_fx.airstrike_radius = AIRSTRIKE_RADIUS
	_sim_world.add_child(_fx)

	_sfx = SfxManager.new()
	add_child(_sfx)

	_voice = VoiceManager.new()
	add_child(_voice)

	_music = MusicManager.new()
	add_child(_music)

	_hud = GameHud.new()
	add_child(_hud)

func _connect_hud() -> void:
	_hud.start_game_requested.connect(_on_start_game)
	_hud.sector_selected.connect(_on_sector_selected)
	_hud.next_sector_requested.connect(_on_next_sector_requested)
	_hud.secret_sector_requested.connect(_on_secret_sector_requested)
	_hud.turret_card_selected.connect(_on_turret_card_selected)
	_hud.airstrike_requested.connect(_on_airstrike_requested)
	_hud.next_wave_requested.connect(_on_next_wave_requested)
	_hud.speed_changed.connect(_on_speed_changed)
	_hud.pause_toggled.connect(_on_pause_toggled)
	_hud.pause_menu_requested.connect(_on_pause_menu_requested)
	_hud.pause_menu_resumed.connect(_on_pause_menu_resumed)
	_hud.mute_toggled.connect(_on_mute_toggled)
	_hud.audio_settings_changed.connect(_on_audio_settings_changed)
	_hud.avatar_style_changed.connect(_on_avatar_style_changed)
	_hud.reset_save_requested.connect(_on_reset_save_requested)
	_hud.restart_requested.connect(_on_restart_requested)
	_hud.replay_sector_requested.connect(_on_replay_sector_requested)
	_hud.upgrade_requested.connect(_on_upgrade_selected)
	_hud.target_mode_requested.connect(_on_cycle_target_mode)
	_hud.sell_requested.connect(_on_sell_selected)
	_hud.drone_hold_toggled.connect(_on_drone_hold_toggled)
	_hud.drone_assign_requested.connect(_on_drone_assign_requested)

func _get_fit_zoom() -> float:
	var vp: Vector2 = get_viewport_rect().size
	var usable_w: float = maxf(320.0, vp.x - 16.0)
	var usable_h: float = maxf(240.0, vp.y - HUD_TOP_SAFE - HUD_BOTTOM_SAFE)
	var fit_x: float = usable_w / float(map_data["width"])
	var fit_y: float = usable_h / float(map_data["height"])
	return clampf(minf(fit_x, fit_y), 0.45, 1.2)

func _reset_camera() -> void:
	_cam_target_zoom = _get_fit_zoom()
	var vertical_bias: float = (HUD_BOTTOM_SAFE - HUD_TOP_SAFE) * 0.5 / _cam_target_zoom
	_cam_target_pos = Vector2(float(map_data["width"]) * 0.5, float(map_data["height"]) * 0.5 + vertical_bias)
	_clamp_camera_target()
	_camera.position = _cam_target_pos
	_camera.zoom = Vector2(_cam_target_zoom, _cam_target_zoom)

func _clear_battlefield() -> void:
	for c in _enemies_node.get_children():
		c.queue_free()
	for c in _turrets_node.get_children():
		c.queue_free()
	for c in _projectiles_node.get_children():
		c.queue_free()
	_terrain.occupied_pads.clear()
	_decals.clear_all()
	_fx.clear_all()
	active_spawners.clear()
	_unclaimed_wave_bonuses.clear()
	pending_bombs.clear()
	selected_turret = null
	placing_type = null
	airstrike_aiming = false
	drone_assign_aiming = false
	_terrain.placement_active = false
	_terrain.hovered_pad_index = -1

func _load_sector(map_id: String) -> void:
	if String(map_data.get("id", "")) == map_id and _terrain != null:
		return
	map_data = MapData.get_map_by_id(map_id)
	waves = WaveData.get_waves_for_map(map_id)
	_terrain.setup(map_data)
	_reset_camera()

func _on_sector_selected(map_id: String) -> void:
	_sfx.play("ui_click")
	_clear_battlefield()
	_load_sector(map_id)
	_refresh_hud()

func _get_next_sector_id() -> String:
	var all_maps := MapData.get_all_maps()
	var cur_id: String = String(map_data["id"])
	for i in range(all_maps.size() - 1):
		if String(all_maps[i]["id"]) == cur_id:
			return String(all_maps[i + 1]["id"])
	return ""

func _on_next_sector_requested() -> void:
	var next_id := _get_next_sector_id()
	if next_id == "":
		_on_restart_requested()
		return
	_hud.select_sector_external(next_id)
	_on_start_game(next_id, difficulty)

func _is_festive_map() -> bool:
	return bool(map_data.get("festive_mode", false))

func _on_secret_sector_requested(map_id: String) -> void:
	_hud.hide_menu()
	_on_start_game(map_id, _hud.get_selected_difficulty(), false)

func _on_start_game(map_id: String, selected_diff: WaveData.Difficulty, allow_seasonal_intercept: bool = true) -> void:
	var target_map_id: String = map_id
	var intercepted_banner: String = ""

	# During active seasonal windows (e.g. Nov 20 – Jan 6 for Christmas), ~5% chance of
	# intercepting a secret seasonal distress signal instead of the chosen regular sector!
	if allow_seasonal_intercept and target_map_id != "north_pole":
		var season := SeasonalData.get_active_seasonal_event()
		if not season.is_empty() and randf() < SeasonalData.RANDOM_INTERCEPT_CHANCE:
			target_map_id = String(season["map_id"])
			intercepted_banner = String(season["banner"])

	_clear_battlefield()
	_load_sector(target_map_id)
	difficulty = selected_diff
	diff_cfg = WaveData.get_difficulty_config(difficulty)

	cash = int(diff_cfg["start_cash"]) + int(map_data.get("cash_bonus", 0))
	max_lives = int(diff_cfg["start_lives"])
	lives = max_lives
	total_kills = 0
	_callout_cd = randf_range(16.0, 26.0)
	_leak_taunt_cd = 0.0
	current_wave_index = -1
	inter_wave_timer = 0.0
	waiting_for_next_wave = true
	_unclaimed_wave_bonuses.clear()
	airstrike_cd = 0.0
	game_started = true
	game_over = false
	paused = false
	pause_menu_open = false
	game_speed = 1.0
	Engine.time_scale = 1.0
	_sim_world.process_mode = Node.PROCESS_MODE_INHERIT
	_fx.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.hide_pause_menu()
	_voice.stop_all()
	_music.set_paused_duck(false)
	_music.set_mode(MusicManager.Mode.FESTIVE if _is_festive_map() else MusicManager.Mode.COMBAT)

	if _is_festive_map():
		_sfx.play("festive_chime", -1.0, 0.0, 0.0)
		var b_text: String = intercepted_banner if intercepted_banner != "" else ("%s  •  PRESS [N] TO START!" % String(map_data["name"]))
		_hud.show_wave_banner(b_text)
	else:
		_sfx.play("wave_start", -2.0, 0.0)
		_hud.show_wave_banner("%s  •  PRESS [N] TO LAUNCH WAVE 1" % String(map_data["name"]))
	_refresh_hud()

func _on_replay_sector_requested() -> void:
	_sfx.play("ui_click")
	_on_start_game(String(map_data["id"]), difficulty, false)

func _on_restart_requested() -> void:
	_flush_play_time()
	_sfx.play("ui_click")
	_clear_battlefield()
	game_started = false
	game_over = false
	paused = false
	pause_menu_open = false
	game_speed = 1.0
	Engine.time_scale = 1.0
	_sim_world.process_mode = Node.PROCESS_MODE_INHERIT
	_fx.process_mode = Node.PROCESS_MODE_INHERIT
	_voice.stop_all()
	_music.set_paused_duck(false)
	_music.set_mode(MusicManager.Mode.MENU)
	_hud.set_sector_records(_save.get_all_sector_records())
	_hud.set_medals_data(_save.get_unlocked_medals(), _save.get_stats(), _save.get_all_sector_records())
	_hud.show_menu()
	_refresh_hud()

func _process(delta: float) -> void:
	var real_delta := delta / maxf(0.01, Engine.time_scale)
	_update_camera(real_delta)
	_update_hover_feedback()

	if not game_started or game_over or paused:
		return

	# Track real duty time for career medals (flushed every 5s)
	_play_time_accum += real_delta
	if _play_time_accum >= 5.0:
		_flush_play_time()

	# Ability cooldown
	if airstrike_cd > 0.0:
		airstrike_cd = maxf(0.0, airstrike_cd - delta)
	if _callout_cd > 0.0:
		_callout_cd = maxf(0.0, _callout_cd - real_delta)
	if _leak_taunt_cd > 0.0:
		_leak_taunt_cd = maxf(0.0, _leak_taunt_cd - real_delta)

	# Staggered Air Strike bombs
	_update_pending_bombs(delta)

	# Active wave spawners
	_update_spawners(delta)

	# Award wave-clear bonus per wave as soon as all units of that wave are cleared
	# (even if the player manually called the next wave early!)
	_check_unclaimed_wave_bonuses()

	# Check wave completion & inter-wave auto-launch countdown
	# (auto-launch waits until all enemies are cleared; manual [N] early call is available once spawning finishes)
	var enemies_alive := _count_alive_enemies()
	var spawning_done := active_spawners.is_empty()

	if spawning_done and enemies_alive == 0 and current_wave_index >= 0:
		if current_wave_index == waves.size() - 1:
			_trigger_end_game(true)
			return
		if not waiting_for_next_wave:
			waiting_for_next_wave = true
			inter_wave_timer = INTER_WAVE_TIME
		else:
			inter_wave_timer -= delta
			if inter_wave_timer <= 0.0:
				_launch_next_wave(false)

	_refresh_hud()

func _update_camera(real_delta: float) -> void:
	var move := Vector2.ZERO
	if game_started and not game_over and not pause_menu_open:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			move.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			move.y += 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			move.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			move.x += 1.0
	if move.length_squared() > 0.0:
		_cam_target_pos += move.normalized() * (560.0 / _cam_target_zoom) * real_delta

	_clamp_camera_target()

	var cam_lerp: float = minf(1.0, real_delta * 15.0)
	_camera.zoom = _camera.zoom.lerp(Vector2(_cam_target_zoom, _cam_target_zoom), cam_lerp)
	var shake_off := Vector2.ZERO
	if _shake_strength > 0.05:
		shake_off = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
		_shake_strength = lerpf(_shake_strength, 0.0, minf(1.0, real_delta * 11.0))
	else:
		_shake_strength = 0.0
	_camera.position = _camera.position.lerp(_cam_target_pos, cam_lerp) + shake_off

func _zoom_camera_at(zoom_factor: float, screen_pos: Vector2) -> void:
	var vp_center: Vector2 = get_viewport_rect().size * 0.5
	var offset_from_center: Vector2 = screen_pos - vp_center
	var old_zoom: float = _cam_target_zoom
	var min_zoom: float = _get_fit_zoom()
	var new_zoom: float = clampf(old_zoom * zoom_factor, min_zoom, 2.0)
	if is_equal_approx(old_zoom, new_zoom):
		return
	var world_under_cursor: Vector2 = _cam_target_pos + offset_from_center / old_zoom
	_cam_target_zoom = new_zoom
	_cam_target_pos = world_under_cursor - offset_from_center / new_zoom
	_clamp_camera_target()

func _clamp_camera_target() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var mw: float = float(map_data["width"])
	var mh: float = float(map_data["height"])
	var z: float = maxf(0.1, _cam_target_zoom)
	var half_vis_w: float = (vp.x * 0.5) / z
	var half_vis_h: float = (vp.y * 0.5) / z
	var top_world: float = HUD_TOP_SAFE / z
	var bot_world: float = HUD_BOTTOM_SAFE / z

	var min_x: float = half_vis_w - 8.0 / z
	var max_x: float = mw - half_vis_w + 8.0 / z
	if min_x >= max_x:
		_cam_target_pos.x = mw * 0.5
	else:
		_cam_target_pos.x = clampf(_cam_target_pos.x, min_x, max_x)

	var min_y: float = half_vis_h - top_world
	var max_y: float = mh - half_vis_h + bot_world
	if min_y >= max_y:
		_cam_target_pos.y = mh * 0.5 + (bot_world - top_world) * 0.5
	else:
		_cam_target_pos.y = clampf(_cam_target_pos.y, min_y, max_y)

func _add_camera_shake(amount: float) -> void:
	_shake_strength = minf(16.0, maxf(_shake_strength, amount))

func _get_world_mouse_pos() -> Vector2:
	return get_global_mouse_position()

func _update_hover_feedback() -> void:
	var mpos := _get_world_mouse_pos()
	_fx.airstrike_aiming = airstrike_aiming
	if airstrike_aiming:
		_fx.airstrike_aim_pos = mpos

	if drone_assign_aiming:
		if selected_turret == null or not is_instance_valid(selected_turret) or not selected_turret.can_launch_drone():
			drone_assign_aiming = false
	_fx.drone_assign_aiming = drone_assign_aiming
	if drone_assign_aiming:
		_fx.drone_assign_pos = mpos
		var hov := _find_enemy_at(mpos, 46.0)
		_fx.drone_assign_has_target = (hov != null)
		if hov != null:
			_fx.drone_assign_target_pos = hov.position
			_fx.drone_assign_target_radius = hov.hit_radius

	if placing_type != null:
		var cfg := TurretData.get_config(placing_type)
		var lv0: Dictionary = cfg["levels"][0]
		_terrain.placement_active = true
		_terrain.placement_range = float(lv0["range"])
		_terrain.placement_affordable = cash >= int(cfg["base_cost"])
		_terrain.placement_accent = cfg["accent"]
	else:
		_terrain.placement_active = false

	_terrain.hovered_pad_index = _find_pad_at(mpos, 32.0)

func _find_enemy_at(world_pos: Vector2, max_dist: float) -> Enemy:
	if _enemies_node == null:
		return null
	var best: Enemy = null
	var best_d: float = max_dist
	for child in _enemies_node.get_children():
		if not (child is Enemy) or not is_instance_valid(child):
			continue
		var e: Enemy = child
		if not e.alive:
			continue
		var d: float = world_pos.distance_to(e.position) - e.hit_radius * 0.55
		if d < best_d:
			best_d = d
			best = e
	return best

func _find_pad_at(world_pos: Vector2, max_dist: float) -> int:
	var pads: Array = map_data["pads"]
	var best_idx := -1
	var best_d := max_dist
	for i in range(pads.size()):
		var d := world_pos.distance_to(pads[i])
		if d < best_d:
			best_d = d
			best_idx = i
	return best_idx

func _unhandled_input(event: InputEvent) -> void:
	# Listen for secret seasonal codes (e.g. HOHOHO / XMAS) while on the Mission Briefing screen
	if not game_started:
		if event is InputEventKey and event.pressed and not event.echo:
			var kc: Key = event.keycode
			if kc == KEY_ESCAPE:
				if _hud.is_medals_hall_visible():
					_hud.hide_medals_hall()
					return
				if _hud.is_about_overlay_visible():
					_hud.hide_about_overlay()
					return
				if _hud.is_audio_overlay_visible():
					_hud.hide_audio_overlay()
					return
			if _hud.is_medals_hall_visible() or _hud.is_about_overlay_visible() or _hud.is_audio_overlay_visible():
				return
			if kc >= KEY_A and kc <= KEY_Z:
				var ch: String = char(int(kc))
				_secret_code_buf = (_secret_code_buf + ch).right(12)
				var matched_map := SeasonalData.check_secret_code(_secret_code_buf)
				if matched_map != "":
					_secret_code_buf = ""
					_on_secret_sector_requested(matched_map)
		return
	if game_over:
		return

	if pause_menu_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			if _hud.is_medals_hall_visible():
				_hud.hide_medals_hall()
			else:
				_close_pause_menu()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var kc: Key = event.keycode
		if kc >= KEY_1 and kc <= KEY_7:
			var ordered := TurretData.get_all_types()
			var idx: int = int(kc) - int(KEY_1)
			if idx >= 0 and idx < ordered.size():
				_on_turret_card_selected(ordered[idx])
			return
		match kc:
			KEY_Q:
				_on_airstrike_requested()
			KEY_F:
				_on_drone_assign_requested()
			KEY_H:
				_on_drone_hold_toggled()
			KEY_N:
				_on_next_wave_requested()
			KEY_SPACE:
				_on_pause_toggled()
			KEY_U:
				_on_upgrade_selected()
			KEY_T:
				_on_cycle_target_mode()
			KEY_BACKSPACE, KEY_DELETE:
				_on_sell_selected()
			KEY_ESCAPE:
				if _has_active_mode():
					_cancel_modes()
				else:
					_open_pause_menu()

	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_camera_at(1.14, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_camera_at(1.0 / 1.14, mb.position)
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_panning = true
				_pan_dragged = false
				_last_mouse_screen = mb.position
			else:
				if mb.button_index == MOUSE_BUTTON_RIGHT and not _pan_dragged:
					_cancel_modes()
				_panning = false
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_handle_left_click(_get_world_mouse_pos())

	elif event is InputEventMouseMotion:
		if _panning:
			var delta_screen: Vector2 = event.position - _last_mouse_screen
			_last_mouse_screen = event.position
			if delta_screen.length_squared() > 2.0:
				_pan_dragged = true
			_cam_target_pos -= delta_screen / _camera.zoom.x
			_clamp_camera_target()

func _has_active_mode() -> bool:
	return placing_type != null or airstrike_aiming or drone_assign_aiming or (selected_turret != null and is_instance_valid(selected_turret))

func _cancel_modes() -> void:
	placing_type = null
	airstrike_aiming = false
	drone_assign_aiming = false
	_select_turret(null)
	_refresh_hud()

func _handle_left_click(world_pos: Vector2) -> void:
	# 1. Execute Hellfire Air Strike if aiming
	if airstrike_aiming:
		_trigger_airstrike(world_pos)
		return

	# 1.5. Execute Manual Hunter Drone target lock if aiming
	if drone_assign_aiming:
		var target_enemy := _find_enemy_at(world_pos, 46.0)
		if target_enemy != null and selected_turret != null and is_instance_valid(selected_turret):
			if selected_turret.assign_manual_target(target_enemy):
				_fx.spawn_floating_text(target_enemy.position + Vector2(0, -18), "DRONE LOCKED!", Color(0.56, 0.96, 0.34))
		drone_assign_aiming = false
		_refresh_hud()
		return

	var pad_idx := _find_pad_at(world_pos, 32.0)

	# 2. Place turret if in placement mode
	if placing_type != null:
		if pad_idx != -1 and not _terrain.occupied_pads.has(pad_idx):
			_try_place_turret(placing_type, pad_idx)
		elif pad_idx != -1 and _terrain.occupied_pads.has(pad_idx):
			placing_type = null
			_select_turret(_terrain.occupied_pads[pad_idx])
		else:
			placing_type = null
		_refresh_hud()
		return

	# 3. Select existing turret on pad
	if pad_idx != -1 and _terrain.occupied_pads.has(pad_idx):
		_select_turret(_terrain.occupied_pads[pad_idx])
	else:
		_select_turret(null)
	_refresh_hud()

func _try_place_turret(t_type: TurretData.TurretType, pad_idx: int) -> void:
	var cfg := TurretData.get_config(t_type)
	var cost: int = int(cfg["base_cost"])
	if cash < cost:
		_sfx.play("base_hit", -6.0)
		_fx.spawn_floating_text(map_data["pads"][pad_idx], "NEED $%d" % cost, Color(0.96, 0.32, 0.25))
		return

	cash -= cost
	var pad_pos: Vector2 = map_data["pads"][pad_idx]
	var turret := Turret.new()
	turret.setup(
		t_type,
		pad_idx,
		pad_pos,
		_enemies_node,
		_projectiles_node,
		_fx,
		_decals,
		_sfx,
		Callable(self, "_add_camera_shake")
	)
	_turrets_node.add_child(turret)
	_terrain.occupied_pads[pad_idx] = turret

	_sfx.play("place")
	_fx.spawn_spark_hit(pad_pos, cfg["accent"], 8)
	_fx.spawn_floating_text(pad_pos + Vector2(0, -18), "-$%d" % cost, Color(0.96, 0.78, 0.34))

	var st: Dictionary = _save.get_stats()
	st["turrets_placed"] = int(st.get("turrets_placed", 0)) + 1
	if t_type == TurretData.TurretType.CRYO:
		st["cryo_builds_upgrades"] = int(st.get("cryo_builds_upgrades", 0)) + 1
	if not bool(st.get("all_seven_turrets_achieved", false)) and _has_all_seven_turret_types():
		st["all_seven_turrets_achieved"] = true
	_check_medals()

	# Keep placement active if Shift held and still affordable, else select newly built turret
	if not Input.is_key_pressed(KEY_SHIFT) or cash < cost:
		placing_type = null
		_select_turret(turret)

func _select_turret(t: Turret) -> void:
	drone_assign_aiming = false
	if selected_turret != null and is_instance_valid(selected_turret):
		selected_turret.selected = false
		selected_turret.queue_redraw()
	selected_turret = t
	if selected_turret != null and is_instance_valid(selected_turret):
		selected_turret.selected = true
		selected_turret.queue_redraw()
		_sfx.play("ui_click", -3.0)

func _on_turret_card_selected(t_type: TurretData.TurretType) -> void:
	if not game_started or game_over:
		return
	_sfx.play("ui_click")
	airstrike_aiming = false
	drone_assign_aiming = false
	if placing_type == t_type:
		placing_type = null
	else:
		placing_type = t_type
		_select_turret(null)
	_refresh_hud()

func _on_airstrike_requested() -> void:
	if not game_started or game_over or airstrike_cd > 0.0:
		return
	_sfx.play("ui_click")
	placing_type = null
	drone_assign_aiming = false
	_select_turret(null)
	airstrike_aiming = not airstrike_aiming
	_refresh_hud()

func _on_drone_hold_toggled() -> void:
	if selected_turret == null or not is_instance_valid(selected_turret):
		return
	if selected_turret.turret_type != TurretData.TurretType.DRONE:
		return
	selected_turret.toggle_drone_hold()
	_sfx.play("ui_click")
	_refresh_hud()

func _on_drone_assign_requested() -> void:
	if selected_turret == null or not is_instance_valid(selected_turret):
		return
	if not selected_turret.can_launch_drone():
		return
	_sfx.play("ui_click")
	placing_type = null
	airstrike_aiming = false
	drone_assign_aiming = not drone_assign_aiming
	_refresh_hud()

func _trigger_airstrike(target_pos: Vector2) -> void:
	airstrike_aiming = false
	airstrike_cd = AIRSTRIKE_COOLDOWN

	var run_dir := Vector2(1.0, -0.25).normalized()
	_fx.spawn_airstrike_jets(target_pos, run_dir)
	_sfx.play("airstrike_jet", 1.5, 0.03, 0.0)
	if randf() < 0.80:
		_voice.play_category("airstrike", 1.5)
	else:
		_fx.spawn_floating_text(target_pos + Vector2(0, -28), "HELLFIRE INBOUND!", Color(1.0, 0.50, 0.24), 1.2, false)

	var st: Dictionary = _save.get_stats()
	st["airstrikes_called"] = int(st.get("airstrikes_called", 0)) + 1
	_check_medals()

	# Schedule 5 staggered carpet bombs along the flight vector
	for i in range(5):
		var offset_along := lerpf(-84.0, 84.0, float(i) / 4.0)
		var jitter := Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))
		pending_bombs.append({
			"pos": target_pos + run_dir * offset_along + jitter,
			"delay": 0.44 + float(i) * 0.09,
			"radius": 105.0,
			"damage": 265.0,
		})
	_refresh_hud()

func _update_pending_bombs(delta: float) -> void:
	for i in range(pending_bombs.size() - 1, -1, -1):
		var b := pending_bombs[i]
		b["delay"] = float(b["delay"]) - delta
		if float(b["delay"]) <= 0.0:
			var pos: Vector2 = b["pos"]
			var rad: float = float(b["radius"])
			var dmg: float = float(b["damage"])
			_fx.spawn_explosion(pos, rad * 0.72, true)
			_decals.add_crater(pos, 26.0)
			_sfx.play("explosion_big", 0.5, 0.14, 0.05)
			_add_camera_shake(10.5)

			for child in _enemies_node.get_children():
				if child is Enemy and is_instance_valid(child) and child.alive:
					var e: Enemy = child
					var dist := pos.distance_to(e.position)
					if dist <= rad + e.hit_radius:
						var falloff := lerpf(1.0, 0.5, clampf(dist / rad, 0.0, 1.0))
						e.take_damage(dmg * falloff, 0.9, null)
			pending_bombs.remove_at(i)

func _on_next_wave_requested() -> void:
	if not game_started or game_over:
		return
	if current_wave_index >= waves.size() - 1:
		return
	if not waiting_for_next_wave and not active_spawners.is_empty():
		return
	var is_early := (current_wave_index >= 0 and _get_early_wave_bonus() > 0)
	_launch_next_wave(is_early)

func _launch_next_wave(early_call: bool) -> void:
	if current_wave_index >= waves.size() - 1:
		return
	if early_call:
		var early_bonus := _get_early_wave_bonus()
		if early_bonus > 0:
			cash += early_bonus
			_fx.spawn_floating_text(map_data["base_pos"] + Vector2(-40, -50), "EARLY +$%d" % early_bonus, Color(0.40, 0.95, 0.52))
			var st: Dictionary = _save.get_stats()
			st["early_waves_called"] = int(st.get("early_waves_called", 0)) + 1
			_check_medals()

	current_wave_index += 1
	waiting_for_next_wave = false
	inter_wave_timer = 0.0
	_unclaimed_wave_bonuses.append(current_wave_index)

	var wave_def: Dictionary = waves[current_wave_index]
	var groups: Array = wave_def["groups"]
	for g in groups:
		active_spawners.append({
			"type": g["type"],
			"remaining": int(g["count"]),
			"interval": float(g["interval"]),
			"timer": float(g["delay"]),
			"lane": int(g.get("lane", 0)),
			"spawned": 0,
			"wave_index": current_wave_index,
		})

	_sfx.play("wave_start", -1.5, 0.0)
	_hud.show_wave_banner("WAVE %02d / %02d  —  %s" % [current_wave_index + 1, waves.size(), String(wave_def["title"])])
	_refresh_hud()

func _get_early_wave_bonus() -> int:
	if current_wave_index < 0:
		return 0
	if waiting_for_next_wave:
		if inter_wave_timer <= 0.5:
			return 0
		return maxi(5, int(round(inter_wave_timer * 2.2)))
	if active_spawners.is_empty():
		return int(round(INTER_WAVE_TIME * 2.2))
	return 0

func _check_unclaimed_wave_bonuses() -> void:
	for i in range(_unclaimed_wave_bonuses.size() - 1, -1, -1):
		var w_idx: int = _unclaimed_wave_bonuses[i]
		var still_spawning := false
		for sp in active_spawners:
			if int(sp.get("wave_index", -1)) == w_idx:
				still_spawning = true
				break
		if still_spawning:
			continue
		var still_alive := false
		for c in _enemies_node.get_children():
			if c is Enemy and is_instance_valid(c) and c.alive and int(c.get_meta("wave_index", -1)) == w_idx:
				still_alive = true
				break
		if not still_alive:
			var bonus: int = int(waves[w_idx]["bonus"])
			cash += bonus
			_fx.spawn_floating_text(map_data["base_pos"] + Vector2(-45, -40), "WAVE CLEAR +$%d" % bonus, Color(0.40, 0.94, 0.54))
			_unclaimed_wave_bonuses.remove_at(i)

func _update_spawners(delta: float) -> void:
	for i in range(active_spawners.size() - 1, -1, -1):
		var sp := active_spawners[i]
		sp["timer"] = float(sp["timer"]) - delta
		if float(sp["timer"]) <= 0.0:
			var lane_cfg: int = int(sp["lane"])
			var spawned_idx: int = int(sp["spawned"])
			var lane_idx: int = (spawned_idx if lane_cfg < 0 else lane_cfg)
			_spawn_enemy(sp["type"], lane_idx, int(sp.get("wave_index", current_wave_index)))
			sp["spawned"] = spawned_idx + 1
			sp["remaining"] = int(sp["remaining"]) - 1
			if int(sp["remaining"]) <= 0:
				active_spawners.remove_at(i)
			else:
				sp["timer"] = float(sp["interval"])

func _spawn_enemy(e_type: EnemyData.EnemyType, lane_idx: int = 0, wave_idx: int = -1) -> void:
	var cfg := EnemyData.get_config(e_type)
	var is_air: bool = bool(cfg["is_air"])
	var g_paths: Array = map_data["ground_paths"]
	var path: PackedVector2Array = map_data["air_path"] if is_air else g_paths[lane_idx % g_paths.size()]
	var eff_wave_idx: int = current_wave_index if wave_idx < 0 else wave_idx

	# Per-wave + per-sector HP escalation & gentle late-wave reward taper
	var wave_scale: float = WaveData.get_wave_hp_scale(eff_wave_idx, waves.size())
	var sector_hp_scale: float = float(map_data.get("hp_scale", 1.0))
	var hp_mult: float = float(diff_cfg["hp_mult"]) * wave_scale * sector_hp_scale
	var spd_mult: float = float(diff_cfg["speed_mult"])
	var rew_mult: float = float(diff_cfg["reward_mult"]) * WaveData.get_wave_reward_scale(eff_wave_idx, waves.size())

	var enemy := Enemy.new()
	enemy.set_meta("wave_index", eff_wave_idx)
	enemy.setup(e_type, path, hp_mult, spd_mult, rew_mult, _fx, _is_festive_map())
	enemy.died.connect(_on_enemy_died)
	enemy.reached_base.connect(_on_enemy_reached_base)
	enemy.spawn_sub_unit.connect(_on_enemy_spawn_sub_unit)
	_enemies_node.add_child(enemy)

func _on_enemy_spawn_sub_unit(sub_type: EnemyData.EnemyType, from_pos: Vector2) -> void:
	if game_over or not game_started:
		return
	var air_pts: PackedVector2Array = map_data["air_path"]
	var sub_path := PackedVector2Array()
	sub_path.append(from_pos)

	# Join the air corridor ahead of the launch truck so micro-drones fly cleanly toward HQ
	var best_idx: int = air_pts.size() - 1
	var best_d: float = INF
	for i in range(air_pts.size()):
		var d: float = from_pos.distance_to(air_pts[i])
		if d < best_d:
			best_d = d
			best_idx = i
	var start_idx: int = mini(air_pts.size() - 1, best_idx + 1)
	for i in range(start_idx, air_pts.size()):
		sub_path.append(air_pts[i])
	if sub_path.size() < 2:
		sub_path.append(map_data["base_pos"])

	var wave_scale: float = WaveData.get_wave_hp_scale(current_wave_index, waves.size())
	var sector_hp_scale: float = float(map_data.get("hp_scale", 1.0))
	var hp_mult: float = float(diff_cfg["hp_mult"]) * wave_scale * sector_hp_scale
	var spd_mult: float = float(diff_cfg["speed_mult"])
	var rew_mult: float = float(diff_cfg["reward_mult"]) * WaveData.get_wave_reward_scale(current_wave_index, waves.size())

	var drone_enemy := Enemy.new()
	drone_enemy.setup(sub_type, sub_path, hp_mult, spd_mult, rew_mult, _fx, _is_festive_map())
	drone_enemy.died.connect(_on_enemy_died)
	drone_enemy.reached_base.connect(_on_enemy_reached_base)
	_enemies_node.add_child(drone_enemy)

	_fx.spawn_spark_hit(from_pos, Color(1.0, 0.62, 0.20), 5)
	_sfx.play("uav_launch", -4.5, 0.10, 0.08)

func _on_enemy_died(enemy: Enemy, killer_turret: Node) -> void:
	cash += enemy.reward
	total_kills += 1
	var killer_id: String = ""
	var turret_promoted: bool = false
	if killer_turret != null and is_instance_valid(killer_turret) and killer_turret is Turret:
		var kt := killer_turret as Turret
		turret_promoted = kt.register_kill()
		killer_id = String(kt.config.get("id", ""))

	var is_boss := (enemy.enemy_type == EnemyData.EnemyType.JUGGERNAUT or enemy.enemy_type == EnemyData.EnemyType.SKY_FORTRESS)
	var is_heavy := is_boss or (enemy.enemy_type == EnemyData.EnemyType.TANK or enemy.enemy_type == EnemyData.EnemyType.APS_TANK or enemy.enemy_type == EnemyData.EnemyType.BOMBER)

	# Career stat tracking for Decorations
	var st: Dictionary = _save.get_stats()
	st["total_kills"] = int(st.get("total_kills", 0)) + 1
	if enemy.is_air:
		st["air_kills"] = int(st.get("air_kills", 0)) + 1
	if is_boss:
		st["boss_kills"] = int(st.get("boss_kills", 0)) + 1
	if enemy.enemy_type == EnemyData.EnemyType.APS_TANK:
		st["aps_kills"] = int(st.get("aps_kills", 0)) + 1
	elif enemy.enemy_type == EnemyData.EnemyType.FPV_DRONE:
		st["fpv_kills"] = int(st.get("fpv_kills", 0)) + 1
	if killer_id != "" and st.has("turret_kills"):
		var tk: Dictionary = st["turret_kills"]
		tk[killer_id] = int(tk.get(killer_id, 0)) + 1
	_check_medals()
	var blast_r := 56.0 if is_boss else (36.0 if is_heavy else (18.0 if enemy.enemy_type == EnemyData.EnemyType.FPV_DRONE else 24.0))
	if _is_festive_map():
		_fx.spawn_festive_pop(enemy.position, blast_r)
		if enemy.reward > 0:
			_fx.spawn_floating_text(enemy.position + Vector2(0, -14), "+$%d" % enemy.reward, Color(1.0, 0.90, 0.36))
		if not enemy.is_air:
			_decals.add_gift_box(enemy.position, enemy.heading, float(enemy.config["scale"]))
		if is_boss:
			_sfx.play("festive_chime", -1.5, 0.04, 0.08)
			_add_camera_shake(5.5)
		else:
			_sfx.play("upgrade" if is_heavy else "explosion_small", -4.5, 0.16, 0.05)
	else:
		_fx.spawn_explosion(enemy.position, blast_r, is_heavy)
		if enemy.reward > 0:
			_fx.spawn_floating_text(enemy.position + Vector2(0, -14), "+$%d" % enemy.reward, Color(0.98, 0.86, 0.36))
		if not enemy.is_air:
			_decals.add_wreck(enemy.position, enemy.heading, float(enemy.config["scale"]))
		if is_heavy:
			_sfx.play("explosion_big", -1.5, 0.12, 0.06)
			_add_camera_shake(7.5 if is_boss else 4.2)
		else:
			_sfx.play("explosion_small", -3.0, 0.14, 0.05)

	if turret_promoted:
		_voice.play_category("promotion", 2.0)
		_callout_cd = maxf(_callout_cd, 22.0)
	elif is_boss and randf() < 0.85:
		_voice.play_category("kill", 1.8)
		_callout_cd = randf_range(26.0, 42.0)
	elif _callout_cd <= 0.0 and (is_heavy or enemy.enemy_type == EnemyData.EnemyType.APC or enemy.enemy_type == EnemyData.EnemyType.UAV_CARRIER):
		_voice.play_category("kill", 2.5)
		_callout_cd = randf_range(34.0, 52.0)

	_refresh_hud()

func _on_enemy_reached_base(enemy: Enemy) -> void:
	lives = maxi(0, lives - enemy.lives_cost)
	_sfx.play("base_hit", 0.0, 0.04, 0.08)
	_fx.spawn_explosion(map_data["base_pos"], 38.0, true)
	_fx.spawn_floating_text(map_data["base_pos"] + Vector2(-20, -35), "-%d HQ" % enemy.lives_cost, Color(0.98, 0.28, 0.24))
	if lives > 0 and _leak_taunt_cd <= 0.0:
		_voice.play_category("leak_air" if enemy.is_air else "leak_ground", 2.0)
		_leak_taunt_cd = 6.0
	_add_camera_shake(8.0)

	if lives <= 0:
		_trigger_end_game(false)
	else:
		_refresh_hud()

func _count_alive_enemies() -> int:
	var count := 0
	for c in _enemies_node.get_children():
		if c is Enemy and is_instance_valid(c) and c.alive:
			count += 1
	return count

func _get_total_turrets_sell_value() -> int:
	var total := 0
	for c in _turrets_node.get_children():
		if c is Turret and is_instance_valid(c):
			total += (c as Turret).get_sell_value()
	return total

func _trigger_end_game(victory: bool) -> void:
	game_over = true
	paused = false
	pause_menu_open = false
	Engine.time_scale = 1.0
	_sim_world.process_mode = Node.PROCESS_MODE_DISABLED
	_music.set_paused_duck(false)
	_music.set_mode(MusicManager.Mode.SILENT)
	placing_type = null
	airstrike_aiming = false
	drone_assign_aiming = false
	_select_turret(null)

	var turrets_val: int = _get_total_turrets_sell_value()
	var cleared := waves.size() if victory else maxi(0, current_wave_index)
	var secret_evt: Dictionary = {} if bool(map_data.get("is_secret", false)) else SeasonalData.get_active_seasonal_event()

	_flush_play_time()
	var st: Dictionary = _save.get_stats()

	if victory:
		var eval_res := RankData.evaluate_victory(cash, turrets_val, lives, max_lives, map_data, waves, diff_cfg, INTER_WAVE_TIME)
		if lives == max_lives:
			st["perfect_hq_wins"] = int(st.get("perfect_hq_wins", 0)) + 1
		if lives <= 3:
			st["close_call_wins"] = int(st.get("close_call_wins", 0)) + 1
		if cash >= 1000:
			st["rich_bank_wins"] = int(st.get("rich_bank_wins", 0)) + 1
		st["best_rank_ever"] = maxi(int(st.get("best_rank_ever", 0)), int(eval_res.get("rank_num", 0)))
		var is_new_best: bool = _save.record_sector_victory(String(map_data["id"]), int(difficulty), eval_res)
		_check_medals()
		_hud.set_sector_records(_save.get_all_sector_records())
		_music.play_victory_stinger()
		# Launch pompous celebratory fireworks over Command HQ behind the Victory screen!
		_fx.process_mode = Node.PROCESS_MODE_ALWAYS
		var fw_count := 12 if (int(eval_res.get("rank_num", 1)) >= 35 or int(difficulty) >= int(WaveData.Difficulty.HARD)) else 7
		_fx.spawn_victory_fireworks(map_data["base_pos"], fw_count)
		_hud.show_end_screen(true, String(map_data["name"]), cleared, waves.size(), total_kills, String(diff_cfg["name"]), _get_next_sector_id() != "", eval_res, is_new_best, {})
	else:
		st["defeats"] = int(st.get("defeats", 0)) + 1
		_save.save()
		_check_medals()
		var eval_res := RankData.evaluate_defeat(cleared, waves.size(), cash, turrets_val)
		_music.play_defeat_stinger()
		_hud.show_end_screen(false, String(map_data["name"]), cleared, waves.size(), total_kills, String(diff_cfg["name"]), false, eval_res, false, secret_evt)

func _on_upgrade_selected() -> void:
	if selected_turret == null or not is_instance_valid(selected_turret):
		return
	if not selected_turret.can_upgrade():
		return
	var cost := selected_turret.get_upgrade_cost()
	if cash < cost:
		_sfx.play("base_hit", -6.0)
		return
	cash -= cost
	selected_turret.apply_upgrade()
	_sfx.play("upgrade")
	_fx.spawn_floating_text(selected_turret.position + Vector2(0, -22), "LV %d!" % (selected_turret.level + 1), Color(0.42, 0.96, 0.56))
	var st: Dictionary = _save.get_stats()
	if selected_turret.turret_type == TurretData.TurretType.CRYO:
		st["cryo_builds_upgrades"] = int(st.get("cryo_builds_upgrades", 0)) + 1
	if not selected_turret.can_upgrade():
		st["max_level_upgrades"] = int(st.get("max_level_upgrades", 0)) + 1
		if randf() < 0.75:
			var uq := _voice.play_category("upgrade", 1.8)
			_fx.spawn_floating_text(selected_turret.position + Vector2(0, -40), uq, Color(0.98, 0.88, 0.34), 2.2, true)
	_check_medals()
	_refresh_hud()

func _on_cycle_target_mode() -> void:
	if selected_turret == null or not is_instance_valid(selected_turret):
		return
	selected_turret.cycle_target_mode()
	_sfx.play("ui_click")
	_refresh_hud()

func _on_sell_selected() -> void:
	if selected_turret == null or not is_instance_valid(selected_turret):
		return
	var sold := selected_turret
	var refund := sold.get_sell_value()
	var pos := sold.position
	var pad_idx := sold.pad_index
	cash += refund
	_terrain.occupied_pads.erase(pad_idx)
	# Clear references from any in-flight projectiles/fire zones fired by the sold turret
	for p in _projectiles_node.get_children():
		if (p is Projectile or p is FireZone) and p.source_turret == sold:
			p.source_turret = null
	sold.cleanup_on_sell()
	drone_assign_aiming = false
	sold.queue_free()
	selected_turret = null
	_sfx.play("sell")
	_fx.spawn_floating_text(pos + Vector2(0, -16), "+$%d" % refund, Color(0.98, 0.84, 0.36))
	var st: Dictionary = _save.get_stats()
	st["turrets_sold"] = int(st.get("turrets_sold", 0)) + 1
	_check_medals()
	_refresh_hud()

func _on_speed_changed(spd: float) -> void:
	if pause_menu_open:
		return
	_sfx.play("ui_click")
	paused = false
	game_speed = spd
	_sim_world.process_mode = Node.PROCESS_MODE_INHERIT
	Engine.time_scale = game_speed
	_music.set_paused_duck(false)
	_refresh_hud()

func _on_pause_toggled() -> void:
	if not game_started or game_over or pause_menu_open:
		return
	_sfx.play("ui_click")
	paused = not paused
	if paused:
		Engine.time_scale = 1.0
		_sim_world.process_mode = Node.PROCESS_MODE_DISABLED
		_music.set_paused_duck(true)
	else:
		_sim_world.process_mode = Node.PROCESS_MODE_INHERIT
		Engine.time_scale = game_speed
		_music.set_paused_duck(false)
	_refresh_hud()

func _open_pause_menu() -> void:
	if not game_started or game_over:
		return
	_flush_play_time()
	_sfx.play("ui_click")
	pause_menu_open = true
	paused = true
	_panning = false
	Engine.time_scale = 1.0
	_sim_world.process_mode = Node.PROCESS_MODE_DISABLED
	_music.set_paused_duck(true)
	_hud.set_medals_data(_save.get_unlocked_medals(), _save.get_stats(), _save.get_all_sector_records())
	_hud.show_pause_menu(String(map_data["name"]), String(diff_cfg["name"]))
	_refresh_hud()

func _close_pause_menu() -> void:
	if not pause_menu_open:
		return
	_sfx.play("ui_click")
	pause_menu_open = false
	paused = false
	_sim_world.process_mode = Node.PROCESS_MODE_INHERIT
	Engine.time_scale = game_speed
	_music.set_paused_duck(false)
	_hud.hide_pause_menu()
	_refresh_hud()

func _on_pause_menu_requested() -> void:
	if not game_started or game_over:
		return
	if pause_menu_open:
		_close_pause_menu()
	else:
		_open_pause_menu()

func _on_pause_menu_resumed() -> void:
	_close_pause_menu()

func _apply_saved_audio_settings() -> void:
	var a := _save.get_audio_settings()
	var m_muted: bool = bool(a["master_muted"])
	var s_vol: float = float(a["sfx_volume"])
	var s_muted: bool = bool(a["sfx_muted"])
	var mu_vol: float = float(a["music_volume"])
	var mu_muted: bool = bool(a["music_muted"])
	_sfx.set_audio_state(s_vol, s_muted, m_muted)
	_voice.set_audio_state(s_vol, s_muted, m_muted)
	_music.set_audio_state(mu_vol, mu_muted, m_muted)
	_hud.set_audio_state(m_muted, s_vol, s_muted, mu_vol, mu_muted)

func _on_audio_settings_changed(master_muted: bool, sfx_vol: float, sfx_muted: bool, music_vol: float, music_muted: bool) -> void:
	_save.set_audio_settings(master_muted, sfx_vol, sfx_muted, music_vol, music_muted)
	_sfx.set_audio_state(sfx_vol, sfx_muted, master_muted)
	_voice.set_audio_state(sfx_vol, sfx_muted, master_muted)
	_music.set_audio_state(music_vol, music_muted, master_muted)
	_refresh_hud()

func _on_mute_toggled() -> void:
	var a := _save.get_audio_settings()
	var next_master: bool = not bool(a["master_muted"])
	_save.set_audio_settings(next_master, float(a["sfx_volume"]), bool(a["sfx_muted"]), float(a["music_volume"]), bool(a["music_muted"]))
	_apply_saved_audio_settings()
	if not next_master:
		_sfx.play("ui_click")
	_refresh_hud()

func _on_avatar_style_changed(style: String) -> void:
	_sfx.play("ui_click")
	_save.set_general_avatar(style)

func _on_reset_save_requested() -> void:
	_sfx.play("ui_click")
	_save.reset_campaign_progress()
	_hud.set_sector_records(_save.get_all_sector_records())
	_hud.set_medals_data(_save.get_unlocked_medals(), _save.get_stats(), _save.get_all_sector_records())

func _has_all_seven_turret_types() -> bool:
	var seen: Dictionary = {}
	for c in _turrets_node.get_children():
		if c is Turret and is_instance_valid(c):
			seen[int((c as Turret).turret_type)] = true
	return seen.size() >= TurretData.get_all_types().size()

func _flush_play_time() -> void:
	if _play_time_accum <= 0.0:
		return
	var st: Dictionary = _save.get_stats()
	st["play_time_sec"] = float(st.get("play_time_sec", 0.0)) + _play_time_accum
	_play_time_accum = 0.0
	_save.save()
	_check_medals()

func _check_medals() -> void:
	var newly := _save.evaluate_and_unlock_medals()
	if not newly.is_empty():
		_sfx.play("upgrade", 1.5, 0.02, 0.05)
		_hud.queue_medal_toasts(newly)
		_hud.set_medals_data(_save.get_unlocked_medals(), _save.get_stats(), _save.get_all_sector_records())

func _refresh_hud() -> void:
	if _hud == null:
		return
	var wave_display := maxi(0, current_wave_index + 1)
	_hud.update_top_bar(String(map_data["short_name"]), cash, lives, max_lives, wave_display, waves.size(), diff_cfg, paused, game_speed, _sfx.master_muted)

	var all_launched := (current_wave_index >= waves.size() - 1)
	var can_call := (not all_launched) and (waiting_for_next_wave or active_spawners.is_empty())
	var early_bonus := _get_early_wave_bonus()
	_hud.update_dock(cash, placing_type, airstrike_cd, AIRSTRIKE_COOLDOWN, airstrike_aiming, can_call, current_wave_index + 2, early_bonus, all_launched)
	_hud.update_inspector(selected_turret, cash, drone_assign_aiming)

	if game_started and not game_over and (current_wave_index + 1) < waves.size():
		_hud.update_wave_preview(true, current_wave_index + 2, waves.size(), waves[current_wave_index + 1])
	else:
		_hud.update_wave_preview(false, 0, waves.size(), {})
