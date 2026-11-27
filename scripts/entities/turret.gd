class_name Turret
extends Node2D

var turret_type: TurretData.TurretType = TurretData.TurretType.VULCAN
var config: Dictionary = {}
var pad_index: int = -1
var level: int = 0 # 0..3 (displayed as Lv 1..4)
var total_invested: int = 0
var kills: int = 0
var target_mode: TurretData.TargetMode = TurretData.TargetMode.FIRST
var selected: bool = false

var turret_angle: float = -PI * 0.5
var recoil: float = 0.0

var _cooldown: float = 0.0
var _barrel_toggle: int = 0
var _cryo_pulse: float = 0.0
var _laser_target: Enemy = null
var _laser_ramp_t: float = 0.0
var _laser_active: bool = false
var _laser_spark_cd: float = 0.0
var _salvo_remaining: int = 0
var _salvo_timer: float = 0.0
var _salvo_target: Enemy = null
var _salvo_base_pos: Vector2 = Vector2.ZERO
var _salvo_index: int = 0

var drone_hold_mode: bool = false
var active_drone: HunterDrone = null
var rearm_timer: float = 0.0

var _enemies_container: Node = null
var _projectiles_container: Node = null
var _fx: FxManager = null
var _decals: DecalLayer = null
var _sfx: SfxManager = null
var _on_shake: Callable

func setup(
	type: TurretData.TurretType,
	pad_idx: int,
	pos: Vector2,
	enemies_container: Node,
	projectiles_container: Node,
	fx_manager: FxManager,
	decals: DecalLayer,
	sfx: SfxManager,
	on_shake: Callable
) -> void:
	turret_type = type
	config = TurretData.get_config(type)
	pad_index = pad_idx
	position = pos
	level = 0
	total_invested = int(config["base_cost"])
	if turret_type == TurretData.TurretType.DRONE:
		target_mode = TurretData.TargetMode.STRONGEST
	_enemies_container = enemies_container
	_projectiles_container = projectiles_container
	_fx = fx_manager
	_decals = decals
	_sfx = sfx
	_on_shake = on_shake
	z_index = 22
	queue_redraw()

func get_stats() -> Dictionary:
	var levels: Array = config["levels"]
	return levels[clampi(level, 0, levels.size() - 1)]

func get_range() -> float:
	return float(get_stats()["range"])

func can_upgrade() -> bool:
	var levels: Array = config["levels"]
	return level < levels.size() - 1

func get_upgrade_cost() -> int:
	if not can_upgrade():
		return 0
	var levels: Array = config["levels"]
	return int(levels[level + 1]["cost"])

func get_next_stats() -> Dictionary:
	if not can_upgrade():
		return {}
	var levels: Array = config["levels"]
	return levels[level + 1]

func get_sell_value() -> int:
	return int(round(float(total_invested) * TurretData.SELL_REFUND_RATIO))

func apply_upgrade() -> void:
	if not can_upgrade():
		return
	var cost := get_upgrade_cost()
	level += 1
	total_invested += cost
	if _fx != null:
		_fx.spawn_spark_hit(position, config["accent"], 10)
	queue_redraw()

func cycle_target_mode() -> void:
	var next_val := (int(target_mode) + 1) % 4
	target_mode = next_val as TurretData.TargetMode

func get_target_mode_label() -> String:
	return String(TurretData.TARGET_MODE_NAMES.get(target_mode, "FIRST"))

func get_veteran_tier() -> int:
	if kills >= 60:
		return 3
	elif kills >= 35:
		return 2
	elif kills >= 15:
		return 1
	return 0

func get_veteran_title() -> String:
	match get_veteran_tier():
		1:
			return "DECORATED"
		2:
			return "TENURED"
		3:
			return "EMERITUS"
	return ""

func register_kill() -> bool:
	var prev_tier := get_veteran_tier()
	kills += 1
	var new_tier := get_veteran_tier()
	if new_tier > prev_tier:
		queue_redraw()
		if _fx != null:
			_fx.spawn_spark_hit(position, Color(1.0, 0.84, 0.24), 10)
			_fx.spawn_floating_text(position + Vector2(0, -28), "PROMOTED: %s!" % get_veteran_title(), Color(1.0, 0.88, 0.30), 2.1, true)
		return true
	return false

func can_launch_drone() -> bool:
	if turret_type != TurretData.TurretType.DRONE:
		return false
	return (active_drone == null or not is_instance_valid(active_drone)) and rearm_timer <= 0.0

func toggle_drone_hold() -> void:
	if turret_type != TurretData.TurretType.DRONE:
		return
	drone_hold_mode = not drone_hold_mode

func get_drone_status_label() -> String:
	if active_drone != null and is_instance_valid(active_drone):
		return "HUNTING"
	if rearm_timer > 0.0:
		return "REARM %.1fs" % rearm_timer
	return "HOLD • READY" if drone_hold_mode else "AUTO • READY"

func assign_manual_target(target: Enemy) -> bool:
	if not can_launch_drone():
		return false
	if target == null or not is_instance_valid(target) or not target.alive:
		return false
	_launch_drone(target)
	return true

func cleanup_on_sell() -> void:
	if active_drone != null and is_instance_valid(active_drone):
		active_drone.source_turret = null
		active_drone.force_self_destruct()
		active_drone = null

func _process(delta: float) -> void:
	_cryo_pulse += delta * 3.5
	if recoil > 0.0:
		recoil = maxf(0.0, recoil - delta * 26.0)
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)

	match turret_type:
		TurretData.TurretType.LASER:
			_process_laser(delta)
		TurretData.TurretType.MLRS:
			_process_mlrs(delta)
		TurretData.TurretType.DRONE:
			_process_drone_pad(delta)
		_:
			var target := _acquire_target()
			if target != null:
				var aim_pos := _predict_aim_position(target)
				var desired := (aim_pos - position).angle()
				var turn_rate := 16.0 if turret_type == TurretData.TurretType.VULCAN else 9.5
				turret_angle = lerp_angle(turret_angle, desired, minf(1.0, delta * turn_rate))

				var angle_diff := absf(wrapf(desired - turret_angle, -PI, PI))
				if _cooldown <= 0.0 and angle_diff < 0.34:
					_fire_at(target, aim_pos)

	queue_redraw()

func _process_laser(delta: float) -> void:
	_laser_active = false
	var target := _acquire_target()
	if target == null:
		_laser_target = null
		_laser_ramp_t = 0.0
		return

	if target != _laser_target:
		_laser_target = target
		_laser_ramp_t = 0.0

	var desired := (target.position - position).angle()
	turret_angle = lerp_angle(turret_angle, desired, minf(1.0, delta * 14.0))
	var angle_diff := absf(wrapf(desired - turret_angle, -PI, PI))
	if angle_diff < 0.24:
		var stats := get_stats()
		var ramp_time: float = maxf(0.2, float(stats.get("ramp_time", 3.0)))
		var max_ramp: float = float(stats.get("max_ramp", 2.2))
		_laser_ramp_t = minf(ramp_time, _laser_ramp_t + delta)
		var ramp_u: float = clampf(_laser_ramp_t / ramp_time, 0.0, 1.0)
		var ramp_mult: float = lerpf(1.0, max_ramp, ramp_u)
		var dps: float = float(stats["damage"]) * ramp_mult
		var shield_bonus: float = float(config.get("shield_bonus", 2.0))
		var muzzle_pos := position + Vector2.from_angle(turret_angle) * 20.0

		_laser_active = true
		if _fx != null:
			_fx.add_beam(muzzle_pos, target.position, ramp_u, config["accent"])
			_laser_spark_cd -= delta
			if _laser_spark_cd <= 0.0:
				_laser_spark_cd = 0.065
				_fx.spawn_spark_hit(target.position, Color(1.0, 0.55, 0.80), 3)
		if _sfx != null:
			_sfx.play("laser", -7.5 + ramp_u * 2.5, 0.05, 0.14)

		target.take_damage(dps * delta, float(stats["armor_pierce"]), self, shield_bonus)
		if not target.alive:
			_laser_target = null
			_laser_ramp_t = 0.0

func _process_mlrs(delta: float) -> void:
	if _salvo_remaining > 0:
		_salvo_timer -= delta
		if _salvo_target != null and is_instance_valid(_salvo_target) and _salvo_target.alive:
			_salvo_base_pos = _predict_aim_position(_salvo_target)
		var desired := (_salvo_base_pos - position).angle()
		turret_angle = lerp_angle(turret_angle, desired, minf(1.0, delta * 9.0))
		if _salvo_timer <= 0.0:
			_fire_mlrs_rocket()
			_salvo_remaining -= 1
			_salvo_timer = 0.11
		return

	var target := _acquire_target()
	if target != null:
		var aim_pos := _predict_aim_position(target)
		var desired := (aim_pos - position).angle()
		turret_angle = lerp_angle(turret_angle, desired, minf(1.0, delta * 7.5))
		var angle_diff := absf(wrapf(desired - turret_angle, -PI, PI))
		if _cooldown <= 0.0 and angle_diff < 0.30:
			var stats := get_stats()
			_cooldown = 1.0 / maxf(0.05, float(stats["fire_rate"]))
			_salvo_remaining = int(stats.get("salvo_count", 3))
			_salvo_timer = 0.0
			_salvo_target = target
			_salvo_base_pos = aim_pos
			_salvo_index = 0
			_fire_mlrs_rocket()
			_salvo_remaining -= 1
			_salvo_timer = 0.11

func _fire_mlrs_rocket() -> void:
	var stats := get_stats()
	var salvo_total: int = maxi(1, int(stats.get("salvo_count", 3)))
	var dir := Vector2.from_angle(turret_angle)
	var perp := Vector2(-dir.y, dir.x)
	var tube_frac: float = (float(_salvo_index % salvo_total) / maxf(1.0, float(salvo_total - 1))) * 2.0 - 1.0 if salvo_total > 1 else 0.0
	var lateral: float = tube_frac * 9.5
	var muzzle_pos := position + dir * 15.0 + perp * lateral
	recoil = 3.2

	# Slight tactical carpet spread along & across the convoy
	var spread_offset := Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0))
	if _salvo_index == 0:
		spread_offset *= 0.25
	var impact_pos: Vector2 = _salvo_base_pos + spread_offset
	_salvo_index += 1

	var proj := Projectile.new()
	proj.setup({
		"turret_type": turret_type,
		"source_turret": self,
		"target_enemy": null,
		"start_pos": muzzle_pos,
		"target_pos": impact_pos,
		"speed": float(stats["proj_speed"]),
		"damage": float(stats["damage"]),
		"air_bonus": 1.0,
		"splash_radius": float(stats["splash"]),
		"slow_amount": 0.0,
		"slow_duration": 0.0,
		"armor_pierce": float(stats["armor_pierce"]),
		"can_hit_air": false,
		"burn_dps": float(stats.get("burn_dps", 14.0)),
		"burn_dur": float(stats.get("burn_dur", 3.4)),
		"burn_radius": float(stats.get("burn_radius", 44.0)),
		"fx": _fx,
		"decals": _decals,
		"sfx": _sfx,
		"enemies_container": _enemies_container,
		"on_shake": _on_shake,
	})
	_projectiles_container.add_child(proj)

	if _fx != null:
		_fx.spawn_muzzle_flash(muzzle_pos, turret_angle, 11.0, Color(1.0, 0.70, 0.24))
		_fx.spawn_smoke(position - dir * 12.0 + perp * lateral, 7.5, 0.55, 0.52)
	if _sfx != null:
		_sfx.play("mlrs", -3.0, 0.12, 0.06)

func _process_drone_pad(delta: float) -> void:
	if active_drone != null and is_instance_valid(active_drone):
		var desired := (active_drone.position - position).angle()
		turret_angle = lerp_angle(turret_angle, desired, minf(1.0, delta * 6.0))
		return

	active_drone = null
	if rearm_timer > 0.0:
		rearm_timer = maxf(0.0, rearm_timer - delta)
		turret_angle += delta * 1.4
		return

	# Armed & waiting on pad
	if not drone_hold_mode:
		var target := _acquire_target()
		if target != null:
			_launch_drone(target)
			return
	turret_angle += delta * 0.65

func _launch_drone(target: Enemy) -> void:
	var stats := get_stats()
	var drone := HunterDrone.new()
	drone.setup({
		"source_turret": self,
		"target_enemy": target,
		"start_pos": position,
		"damage": float(stats["damage"]),
		"fire_rate": float(stats["fire_rate"]),
		"speed": float(stats.get("drone_speed", 240.0)),
		"armor_pierce": float(stats["armor_pierce"]),
		"level": level,
		"accent": config["accent"],
		"fx": _fx,
		"sfx": _sfx,
	})
	drone.finished.connect(_on_drone_finished)
	_projectiles_container.add_child(drone)
	active_drone = drone
	turret_angle = (target.position - position).angle()

	if _fx != null:
		_fx.spawn_spark_hit(position, config["accent"], 8)
		_fx.spawn_smoke(position, 6.5, 0.40, 0.65)
	if _sfx != null:
		_sfx.play("drone_launch", -2.5, 0.06, 0.05)

func _on_drone_finished(drone: HunterDrone) -> void:
	if active_drone == drone:
		active_drone = null
		var stats := get_stats()
		rearm_timer = float(stats.get("rearm_time", 4.0))

func _acquire_target() -> Enemy:
	if _enemies_container == null:
		return null
	var rng := get_range()
	var rng_sq := rng * rng
	var hit_gnd: bool = bool(config["can_hit_ground"])
	var hit_air: bool = bool(config["can_hit_air"])

	var best: Enemy = null
	var best_score := -INF
	var best_air: Enemy = null
	var best_air_score := -INF
	var prioritize_air := (turret_type == TurretData.TurretType.MISSILE)

	for child in _enemies_container.get_children():
		if not (child is Enemy) or not is_instance_valid(child):
			continue
		var e: Enemy = child
		if not e.alive:
			continue
		if e.is_air and not hit_air:
			continue
		if (not e.is_air) and not hit_gnd:
			continue
		var d_sq := position.distance_squared_to(e.position)
		if d_sq > rng_sq:
			continue

		var score := 0.0
		match target_mode:
			TurretData.TargetMode.FIRST:
				score = e.get_progress()
			TurretData.TargetMode.STRONGEST:
				score = e.hp * 1000.0 + e.get_progress()
			TurretData.TargetMode.WEAKEST:
				score = -e.hp * 1000.0 + e.get_progress()
			TurretData.TargetMode.NEAREST:
				score = -d_sq

		# SAM batteries always prioritize aircraft in range over ground units across all target modes
		if prioritize_air and e.is_air:
			if score > best_air_score:
				best_air_score = score
				best_air = e
		elif score > best_score:
			best_score = score
			best = e

	return best_air if (prioritize_air and best_air != null) else best

func _predict_aim_position(target: Enemy) -> Vector2:
	var stats := get_stats()
	var proj_spd: float = float(stats["proj_speed"])
	if turret_type == TurretData.TurretType.CANNON or turret_type == TurretData.TurretType.CRYO or turret_type == TurretData.TurretType.MLRS:
		var dist := position.distance_to(target.position)
		var t_flight := dist / maxf(100.0, proj_spd)
		return target.position + target.get_velocity_vector() * (t_flight * 0.72)
	return target.position

func _fire_at(target: Enemy, aim_pos: Vector2) -> void:
	var stats := get_stats()
	_cooldown = 1.0 / maxf(0.05, float(stats["fire_rate"]))
	_barrel_toggle = 1 - _barrel_toggle

	var dir := Vector2.from_angle(turret_angle)
	var perp := Vector2(-dir.y, dir.x)
	var lateral := (4.5 if _barrel_toggle == 0 else -4.5)
	var muzzle_len := 22.0
	match turret_type:
		TurretData.TurretType.VULCAN:
			recoil = 3.2
			muzzle_len = 22.0
			lateral = (3.8 if _barrel_toggle == 0 else -3.8)
		TurretData.TurretType.CANNON:
			recoil = 7.5
			muzzle_len = 26.0
			lateral = (4.0 if _barrel_toggle == 0 else -4.0) if level >= 3 else 0.0
		TurretData.TurretType.MISSILE:
			recoil = 3.8
			muzzle_len = 16.0
			lateral = (8.0 if _barrel_toggle == 0 else -8.0)
		TurretData.TurretType.CRYO:
			recoil = 3.0
			muzzle_len = 21.0
			lateral = 0.0

	var muzzle_pos := position + dir * muzzle_len + perp * lateral

	var proj := Projectile.new()
	proj.setup({
		"turret_type": turret_type,
		"source_turret": self,
		"target_enemy": target,
		"start_pos": muzzle_pos,
		"target_pos": aim_pos,
		"speed": float(stats["proj_speed"]),
		"damage": float(stats["damage"]),
		"air_bonus": float(config.get("air_bonus", 1.0)),
		"splash_radius": float(stats["splash"]),
		"slow_amount": float(stats["slow"]),
		"slow_duration": float(stats["slow_dur"]),
		"armor_pierce": float(stats["armor_pierce"]),
		"can_hit_air": bool(config["can_hit_air"]),
		"fx": _fx,
		"decals": _decals,
		"sfx": _sfx,
		"enemies_container": _enemies_container,
		"on_shake": _on_shake,
	})
	_projectiles_container.add_child(proj)

	# Muzzle VFX & SFX
	if _fx != null:
		match turret_type:
			TurretData.TurretType.VULCAN:
				_fx.spawn_muzzle_flash(muzzle_pos, turret_angle, 10.0, Color(1.0, 0.88, 0.42))
				if randf() < 0.55:
					_fx.spawn_shell_casing(position + perp * 8.0, turret_angle + PI * 0.52)
			TurretData.TurretType.CANNON:
				_fx.spawn_muzzle_flash(muzzle_pos, turret_angle, 18.0, Color(1.0, 0.72, 0.25))
				_fx.spawn_smoke(muzzle_pos + dir * 4.0, 7.0, 0.45, 0.40)
				_fx.spawn_shell_casing(position - dir * 8.0, turret_angle + PI * 0.8)
			TurretData.TurretType.MISSILE:
				_fx.spawn_muzzle_flash(muzzle_pos, turret_angle, 11.0, Color(1.0, 0.78, 0.35))
				_fx.spawn_smoke(position - dir * 10.0 + perp * lateral, 8.0, 0.55, 0.65)
			TurretData.TurretType.CRYO:
				_fx.spawn_muzzle_flash(muzzle_pos, turret_angle, 13.0, Color(0.55, 0.92, 1.0))

	if _sfx != null:
		match turret_type:
			TurretData.TurretType.VULCAN:
				_sfx.play("vulcan", -5.0, 0.10, 0.055)
			TurretData.TurretType.CANNON:
				_sfx.play("cannon", -1.5, 0.08, 0.08)
			TurretData.TurretType.MISSILE:
				_sfx.play("missile", -2.5, 0.08, 0.08)
			TurretData.TurretType.CRYO:
				_sfx.play("cryo", -4.0, 0.08, 0.08)

func _draw() -> void:
	var accent: Color = config["accent"]

	# Selection range ring drawn behind turret
	if selected:
		var r: float = get_range()
		draw_circle(Vector2.ZERO, r, Color(accent.r, accent.g, accent.b, 0.09))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 72, Color(accent.r, accent.g, accent.b, 0.78), 2.0, true)
		draw_arc(Vector2.ZERO, r - 6.0, 0.0, TAU, 72, Color(accent.r, accent.g, accent.b, 0.18), 1.0, true)
		draw_arc(Vector2.ZERO, 26.5, 0.0, TAU, 40, Color(1.0, 0.96, 0.75, 0.94), 2.4, true)

	# Heavy armored octagonal steel hardpoint base + cast shadow
	draw_circle(Vector2(4.2, 5.2), 22.0, Color(0.0, 0.0, 0.0, 0.44))
	var oct := PackedVector2Array()
	var oct_inner := PackedVector2Array()
	for i in range(8):
		var a: float = float(i) * (TAU / 8.0) + PI / 8.0
		oct.append(Vector2.from_angle(a) * 21.0)
		oct_inner.append(Vector2.from_angle(a) * 18.0)
	draw_colored_polygon(oct, Color(0.24, 0.26, 0.24))
	var oct_closed := PackedVector2Array(oct)
	oct_closed.append(oct[0])
	draw_polyline(oct_closed, Color(0.10, 0.11, 0.10), 1.4, true)
	draw_colored_polygon(oct_inner, Color(0.18, 0.20, 0.18))

	# Anchor bolts around base flange
	for i in range(8):
		var ba: float = float(i) * (TAU / 8.0)
		var bp := Vector2.from_angle(ba) * 17.8
		draw_circle(bp, 1.5, Color(0.42, 0.45, 0.41))
		draw_circle(bp + Vector2(0.4, 0.4), 0.7, Color(0.14, 0.15, 0.14))

	# Recessed turret slew bearing ring
	draw_circle(Vector2.ZERO, 15.2, Color(0.12, 0.13, 0.12))
	draw_arc(Vector2.ZERO, 15.2, 0.0, TAU, 32, Color(0.38, 0.41, 0.36), 1.6, true)
	draw_arc(Vector2.ZERO, 12.6, 0.0, TAU, 24, Color(0.24, 0.26, 0.23), 1.0, true)

	# Rotating upper weapon assembly
	match turret_type:
		TurretData.TurretType.VULCAN:
			_draw_vulcan(accent)
		TurretData.TurretType.CANNON:
			_draw_cannon(accent)
		TurretData.TurretType.MISSILE:
			_draw_missile(accent)
		TurretData.TurretType.CRYO:
			_draw_cryo(accent)
		TurretData.TurretType.LASER:
			_draw_laser(accent)
		TurretData.TurretType.MLRS:
			_draw_mlrs(accent)
		TurretData.TurretType.DRONE:
			_draw_drone_pad(accent)

	# Upgrade level tactical pips along lower rim
	var pip_count: int = level + 1
	var total_w: float = float(pip_count - 1) * 7.5
	for i in range(pip_count):
		var px: float = -total_w * 0.5 + float(i) * 7.5
		var ppos := Vector2(px, 20.5)
		draw_circle(ppos, 3.3, Color(0.05, 0.06, 0.05, 0.96))
		draw_circle(ppos, 2.2, accent)
		draw_circle(ppos + Vector2(-0.6, -0.6), 0.9, Color(1.0, 1.0, 1.0, 0.55))

	# Veteran kill-milestone golden chevrons along top rim (15 / 35 / 60 kills)
	var vet_tier := get_veteran_tier()
	if vet_tier > 0:
		var gold := Color(1.0, 0.84, 0.24)
		for i in range(vet_tier):
			var cy := -21.5 - float(i) * 4.0
			var pts := PackedVector2Array([
				Vector2(-5.4, cy + 2.4),
				Vector2(0.0, cy - 1.8),
				Vector2(5.4, cy + 2.4),
			])
			draw_polyline(pts, Color(0.06, 0.06, 0.05, 0.95), 3.6, true)
			draw_polyline(pts, gold, 1.8, true)

func _xf(pt: Vector2) -> Vector2:
	return pt.rotated(turret_angle)

func _xpoly(pts: Array[Vector2], offset: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(_xf(p) + offset)
	return out

func _draw_bevel(pts: Array[Vector2], fill: Color, outline: Color = Color(0.10, 0.11, 0.09)) -> void:
	var poly := _xpoly(pts)
	draw_colored_polygon(poly, fill)
	var closed := PackedVector2Array(poly)
	closed.append(poly[0])
	draw_polyline(closed, outline, 1.15, true)

func _draw_vulcan(accent: Color) -> void:
	var rx: float = -recoil
	var blen: float = 23.0 + float(level) * 1.4

	# Side armored ammo boxes with brass belt feed
	var drum_w: float = 5.8 + float(level) * 1.0
	var drum_l: Array[Vector2] = [Vector2(-7.0, -13.5), Vector2(5.0, -13.5), Vector2(5.0, -13.5 + drum_w), Vector2(-7.0, -13.5 + drum_w)]
	var drum_r: Array[Vector2] = [Vector2(-7.0, 13.5 - drum_w), Vector2(5.0, 13.5 - drum_w), Vector2(5.0, 13.5), Vector2(-7.0, 13.5)]
	draw_colored_polygon(_xpoly(drum_l, Vector2(2.4, 2.8)), Color(0.0, 0.0, 0.0, 0.32))
	draw_colored_polygon(_xpoly(drum_r, Vector2(2.4, 2.8)), Color(0.0, 0.0, 0.0, 0.32))
	_draw_bevel(drum_l, Color(0.28, 0.33, 0.24))
	_draw_bevel(drum_r, Color(0.28, 0.33, 0.24))
	# Exposed brass feed strips
	draw_line(_xf(Vector2(1.0, -7.8)), _xf(Vector2(1.0, -11.5)), Color(0.86, 0.70, 0.24), 2.2, true)
	draw_line(_xf(Vector2(1.0, 7.8)), _xf(Vector2(1.0, 11.5)), Color(0.86, 0.70, 0.24), 2.2, true)

	# Multi-barrel rotary cluster (2 -> 2 heavy -> 3 -> 4 quad)
	var offsets: Array[float] = [-3.6, 3.6]
	if level == 2:
		offsets = [-4.6, 0.0, 4.6]
	elif level >= 3:
		offsets = [-5.8, -2.0, 2.0, 5.8]
	for oy in offsets:
		draw_line(_xf(Vector2(4.0 + rx, oy)) + Vector2(2.2, 2.5), _xf(Vector2(blen + rx, oy)) + Vector2(2.2, 2.5), Color(0.0, 0.0, 0.0, 0.28), 3.2, true)
		draw_line(_xf(Vector2(4.0 + rx, oy)), _xf(Vector2(blen + rx, oy)), Color(0.11, 0.12, 0.11), 3.6, true)
		draw_line(_xf(Vector2(4.0 + rx, oy)), _xf(Vector2(blen - 1.0 + rx, oy)), Color(0.56, 0.60, 0.55), 1.6, true)
	# Barrel cooling clamps
	var span: float = absf(offsets[0]) + 1.5
	draw_line(_xf(Vector2(14.0 + rx, -span)), _xf(Vector2(14.0 + rx, span)), Color(0.22, 0.24, 0.21), 2.4, true)
	draw_line(_xf(Vector2(blen - 3.0 + rx, -span)), _xf(Vector2(blen - 3.0 + rx, span)), Color(0.26, 0.28, 0.25), 2.2, true)

	# Armored gun carriage receiver
	var body: Array[Vector2] = [
		Vector2(9.0, -7.8), Vector2(9.0, 7.8), Vector2(-9.5, 9.8),
		Vector2(-13.0, 4.5), Vector2(-13.0, -4.5), Vector2(-9.5, -9.8)
	]
	draw_colored_polygon(_xpoly(body, Vector2(2.5, 3.0)), Color(0.0, 0.0, 0.0, 0.36))
	_draw_bevel(body, Color(0.36, 0.41, 0.32))
	var top_plate: Array[Vector2] = [Vector2(6.5, -5.2), Vector2(6.5, 5.2), Vector2(-8.0, 6.2), Vector2(-9.5, 0.0), Vector2(-8.0, -6.2)]
	draw_colored_polygon(_xpoly(top_plate), Color(0.44, 0.49, 0.39))
	# Targeting optical pod + status LED
	draw_circle(_xf(Vector2(-2.0, 0.0)), 4.8, Color(0.18, 0.21, 0.17))
	draw_arc(_xf(Vector2(-2.0, 0.0)), 4.8, 0.0, TAU, 16, Color(0.55, 0.60, 0.52), 1.1, true)
	draw_circle(_xf(Vector2(3.5, 0.0)), 2.3, accent)
	draw_circle(_xf(Vector2(4.0, -0.6)), 0.9, Color(1.0, 0.98, 0.85))

func _draw_cannon(accent: Color) -> void:
	var rx: float = -recoil
	var barrel_len: float = 26.5 + float(level) * 2.2

	if level >= 3:
		for oy: float in [-4.6, 4.6]:
			draw_line(_xf(Vector2(4.0 + rx, oy)) + Vector2(2.8, 3.2), _xf(Vector2(barrel_len + rx, oy)) + Vector2(2.8, 3.2), Color(0.0, 0.0, 0.0, 0.32), 5.4, true)
			draw_line(_xf(Vector2(4.0 + rx, oy)), _xf(Vector2(barrel_len + rx, oy)), Color(0.11, 0.12, 0.11), 5.8, true)
			draw_line(_xf(Vector2(4.0 + rx, oy)), _xf(Vector2(barrel_len - 1.5 + rx, oy)), Color(0.48, 0.51, 0.46), 3.0, true)
			# Bore evacuator & slotted muzzle brake
			draw_line(_xf(Vector2(15.0 + rx, oy)), _xf(Vector2(20.5 + rx, oy)), Color(0.24, 0.26, 0.23), 7.0, true)
			draw_line(_xf(Vector2(barrel_len - 1.5 + rx, oy - 3.6)), _xf(Vector2(barrel_len - 1.5 + rx, oy + 3.6)), Color(0.18, 0.19, 0.17), 3.4, true)
	else:
		draw_line(_xf(Vector2(4.0 + rx, 0.0)) + Vector2(2.8, 3.2), _xf(Vector2(barrel_len + rx, 0.0)) + Vector2(2.8, 3.2), Color(0.0, 0.0, 0.0, 0.34), 7.2, true)
		draw_line(_xf(Vector2(4.0 + rx, 0.0)), _xf(Vector2(barrel_len + rx, 0.0)), Color(0.11, 0.12, 0.11), 7.6, true)
		draw_line(_xf(Vector2(4.0 + rx, 0.0)), _xf(Vector2(barrel_len - 2.0 + rx, 0.0)), Color(0.49, 0.52, 0.47), 4.0, true)
		draw_line(_xf(Vector2(15.0 + rx, 0.0)), _xf(Vector2(21.0 + rx, 0.0)), Color(0.24, 0.26, 0.22), 9.0, true)
		draw_line(_xf(Vector2(15.5 + rx, 0.0)), _xf(Vector2(20.5 + rx, 0.0)), Color(0.56, 0.58, 0.53), 5.0, true)
		draw_line(_xf(Vector2(barrel_len - 1.5 + rx, -4.8)), _xf(Vector2(barrel_len - 1.5 + rx, 4.8)), Color(0.18, 0.19, 0.17), 4.0, true)

	# Heavy angular sloped artillery turret housing
	var hull: Array[Vector2] = [
		Vector2(11.0, -9.0), Vector2(4.5, -13.2), Vector2(-12.5, -12.2),
		Vector2(-16.0, -6.5), Vector2(-16.0, 6.5), Vector2(-12.5, 12.2),
		Vector2(4.5, 13.2), Vector2(11.0, 9.0)
	]
	draw_colored_polygon(_xpoly(hull, Vector2(3.0, 3.5)), Color(0.0, 0.0, 0.0, 0.38))
	_draw_bevel(hull, Color(0.35, 0.38, 0.30))

	# Upper armored cap + hydraulic recoil recuperator bars
	var cap: Array[Vector2] = [Vector2(6.5, -6.5), Vector2(-10.0, -7.8), Vector2(-10.0, 7.8), Vector2(6.5, 6.5)]
	_draw_bevel(cap, Color(0.42, 0.45, 0.37), Color(0.16, 0.18, 0.14))
	# Hydraulic side pistons
	for side: float in [-1.0, 1.0]:
		draw_line(_xf(Vector2(10.0 + rx * 0.5, side * 6.5)), _xf(Vector2(16.0 + rx * 0.5, side * 6.5)), Color(0.62, 0.65, 0.60), 2.0, true)
	# Tactical orange artillery stripe + commander hatch
	draw_line(_xf(Vector2(-7.5, -8.5)), _xf(Vector2(-7.5, 8.5)), accent, 2.8, true)
	draw_circle(_xf(Vector2(-2.0, -3.2)), 3.0, Color(0.22, 0.24, 0.20))
	draw_arc(_xf(Vector2(-2.0, -3.2)), 3.0, 0.0, TAU, 14, Color(0.54, 0.58, 0.50), 1.0, true)

func _draw_missile(accent: Color) -> void:
	var rx: float = -recoil * 0.5

	# Twin heavy multi-cell SAM launch pods
	for side: float in [-1.0, 1.0]:
		var y0: float = side * 6.0
		var y1: float = side * 15.2
		var pod: Array[Vector2] = [
			Vector2(10.5 + rx, minf(y0, y1)), Vector2(10.5 + rx, maxf(y0, y1)),
			Vector2(-12.0 + rx, maxf(y0, y1)), Vector2(-12.0 + rx, minf(y0, y1))
		]
		draw_colored_polygon(_xpoly(pod, Vector2(2.6, 3.0)), Color(0.0, 0.0, 0.0, 0.34))
		_draw_bevel(pod, Color(0.30, 0.36, 0.29))
		# Pod panel rib & rear exhaust blast vent
		draw_line(_xf(Vector2(-1.0 + rx, y0)), _xf(Vector2(-1.0 + rx, y1)), Color(0.14, 0.16, 0.14), 1.4, true)
		draw_line(_xf(Vector2(-11.8 + rx, y0 + side * 1.2)), _xf(Vector2(-11.8 + rx, y1 - side * 1.2)), Color(0.10, 0.10, 0.10), 2.4, true)
		# Visible red-nosed SAM warheads peeking from launch tubes
		var tip_y: float = side * 10.6
		draw_circle(_xf(Vector2(11.4 + rx, tip_y)), 2.5, Color(0.92, 0.30, 0.22))
		draw_circle(_xf(Vector2(12.2 + rx, tip_y)), 1.0, Color(1.0, 0.85, 0.72))
		if level >= 2:
			draw_circle(_xf(Vector2(11.2 + rx, side * 7.8)), 2.1, Color(0.92, 0.30, 0.22))
			draw_circle(_xf(Vector2(11.2 + rx, side * 13.4)), 2.1, Color(0.92, 0.30, 0.22))

	# Center armored sensor tower & tracking radar
	var core: Array[Vector2] = [Vector2(9.5, -5.8), Vector2(9.5, 5.8), Vector2(-11.5, 6.8), Vector2(-11.5, -6.8)]
	draw_colored_polygon(_xpoly(core, Vector2(2.4, 2.8)), Color(0.0, 0.0, 0.0, 0.36))
	_draw_bevel(core, Color(0.38, 0.43, 0.36))
	draw_circle(_xf(Vector2(0.0, 0.0)), 4.8, Color(0.16, 0.20, 0.18))
	draw_circle(_xf(Vector2(0.0, 0.0)), 2.6, accent)
	draw_circle(_xf(Vector2(0.8, -0.8)), 1.0, Color(0.88, 1.0, 0.92))
	if level >= 1:
		# Phased-array tracking radar bar
		draw_line(_xf(Vector2(-8.2, -9.2)), _xf(Vector2(-8.2, 9.2)), Color(0.14, 0.16, 0.15), 4.0, true)
		draw_line(_xf(Vector2(-8.2, -8.5)), _xf(Vector2(-8.2, 8.5)), Color(0.72, 0.78, 0.74), 2.0, true)

func _draw_cryo(accent: Color) -> void:
	var rx: float = -recoil * 0.6
	var glow: float = 0.65 + 0.35 * sin(_cryo_pulse)

	# Dual pressurized liquid-nitrogen side tanks with steel retaining straps
	for side: float in [-1.0, 1.0]:
		var cy: float = side * 10.0
		draw_line(_xf(Vector2(-8.5, cy)) + Vector2(2.2, 2.6), _xf(Vector2(6.5, cy)) + Vector2(2.2, 2.6), Color(0.0, 0.0, 0.0, 0.32), 6.6, true)
		draw_line(_xf(Vector2(-8.5, cy)), _xf(Vector2(6.5, cy)), Color(0.14, 0.20, 0.24), 7.2, true)
		draw_line(_xf(Vector2(-7.0, cy)), _xf(Vector2(5.2, cy)), Color(0.36, 0.80, 0.98, glow), 3.6, true)
		# Metallic retaining rings
		for sx: float in [-4.5, 1.5]:
			draw_line(_xf(Vector2(sx, cy - 3.6)), _xf(Vector2(sx, cy + 3.6)), Color(0.45, 0.52, 0.55), 1.6, true)

	# Cryogenic projector barrel + illuminated cooling fins
	draw_line(_xf(Vector2(2.0 + rx, 0.0)) + Vector2(2.4, 2.8), _xf(Vector2(22.5 + rx, 0.0)) + Vector2(2.4, 2.8), Color(0.0, 0.0, 0.0, 0.30), 7.4, true)
	draw_line(_xf(Vector2(2.0 + rx, 0.0)), _xf(Vector2(22.5 + rx, 0.0)), Color(0.15, 0.20, 0.24), 7.6, true)
	draw_line(_xf(Vector2(4.0 + rx, 0.0)), _xf(Vector2(21.5 + rx, 0.0)), Color(0.42, 0.52, 0.58), 3.2, true)
	for cx: float in [10.0, 14.5, 19.0]:
		if cx > 15.0 and level < 1:
			continue
		draw_line(_xf(Vector2(cx + rx, -5.2)), _xf(Vector2(cx + rx, 5.2)), Color(accent.r, accent.g, accent.b, glow), 2.4, true)
	# Flared frost nozzle
	draw_line(_xf(Vector2(22.5 + rx, -4.4)), _xf(Vector2(22.5 + rx, 4.4)), Color(0.75, 0.95, 1.0, glow), 2.6, true)

	# Armored pressure-vessel core dome
	draw_circle(_xf(Vector2(-1.0, 0.0)) + Vector2(2.2, 2.6), 9.6, Color(0.0, 0.0, 0.0, 0.35))
	draw_circle(_xf(Vector2(-1.0, 0.0)), 9.6, Color(0.28, 0.34, 0.38))
	draw_arc(_xf(Vector2(-1.0, 0.0)), 9.6, 0.0, TAU, 24, Color(0.12, 0.15, 0.17), 1.4, true)
	draw_circle(_xf(Vector2(-1.0, 0.0)), 5.8, Color(0.20, 0.66, 0.88, glow))
	draw_circle(_xf(Vector2(-1.6, -0.8)), 2.8, Color(0.84, 0.98, 1.0, glow))

func _draw_laser(accent: Color) -> void:
	# DragonFire Directed-Energy High-Energy Laser Turret
	var ramp_u: float = clampf(_laser_ramp_t / 2.6, 0.0, 1.0) if _laser_active else 0.0
	var pulse: float = 0.65 + 0.35 * sin(_cryo_pulse * 1.4)
	var glow_col: Color = accent.lerp(Color(1.0, 0.88, 0.95), ramp_u * 0.65)

	# Side capacitor heat-sink rails (grow with upgrades)
	var rail_len: float = 15.0 + float(level) * 1.8
	for side: float in [-1.0, 1.0]:
		var y0: float = side * 6.5
		var y1: float = side * (11.5 + float(level) * 0.7)
		var rail: Array[Vector2] = [
			Vector2(rail_len * 0.55, minf(y0, y1)), Vector2(rail_len * 0.55, maxf(y0, y1)),
			Vector2(-rail_len * 0.65, maxf(y0, y1)), Vector2(-rail_len * 0.65, minf(y0, y1))
		]
		draw_colored_polygon(_xpoly(rail, Vector2(2.4, 2.8)), Color(0.0, 0.0, 0.0, 0.32))
		_draw_bevel(rail, Color(0.24, 0.26, 0.30))
		# Illuminated thermal radiator fins
		for fx: float in [-7.0, -2.5, 2.0, 6.5]:
			if fx > 3.0 and level < 2:
				continue
			draw_line(_xf(Vector2(fx, y0)), _xf(Vector2(fx, y1)), Color(glow_col.r, glow_col.g, glow_col.b, 0.55 + ramp_u * 0.45), 1.6, true)

	# Sleek armored optical director housing
	var body: Array[Vector2] = [
		Vector2(12.5, -6.4), Vector2(6.0, -10.0), Vector2(-11.0, -9.5),
		Vector2(-14.0, -4.5), Vector2(-14.0, 4.5), Vector2(-11.0, 9.5),
		Vector2(6.0, 10.0), Vector2(12.5, 6.4)
	]
	draw_colored_polygon(_xpoly(body, Vector2(2.6, 3.0)), Color(0.0, 0.0, 0.0, 0.36))
	_draw_bevel(body, Color(0.32, 0.34, 0.38))

	# Focusing beam director barrel & sapphire emitter lens
	var emitter_len: float = 20.5 + float(level) * 1.4
	draw_line(_xf(Vector2(6.0, 0.0)), _xf(Vector2(emitter_len, 0.0)), Color(0.12, 0.13, 0.16), 8.2, true)
	draw_line(_xf(Vector2(7.0, 0.0)), _xf(Vector2(emitter_len - 1.5, 0.0)), Color(0.46, 0.50, 0.56), 4.2, true)
	# Focusing collar rings
	for rx_pos: float in [11.5, 16.0, 19.5]:
		if rx_pos > 17.0 and level < 1:
			continue
		draw_line(_xf(Vector2(rx_pos, -5.2)), _xf(Vector2(rx_pos, 5.2)), glow_col, 2.0, true)

	# Glowing optical crystal aperture at muzzle
	draw_circle(_xf(Vector2(emitter_len, 0.0)), 3.6 + ramp_u * 1.6, Color(glow_col.r, glow_col.g, glow_col.b, 0.85))
	draw_circle(_xf(Vector2(emitter_len, 0.0)), 1.8 + ramp_u * 0.9, Color(1.0, 0.95, 0.98, 0.96))

	# Central power core dome
	draw_circle(_xf(Vector2(-2.0, 0.0)), 6.2, Color(0.16, 0.17, 0.20))
	draw_arc(_xf(Vector2(-2.0, 0.0)), 6.2, 0.0, TAU, 20, Color(0.54, 0.58, 0.64), 1.2, true)
	draw_circle(_xf(Vector2(-2.0, 0.0)), 3.6, Color(glow_col.r, glow_col.g, glow_col.b, 0.65 + 0.35 * pulse))
	if level >= 3:
		# Dual auxiliary beam-splitter prongs at Lv 4
		for side: float in [-1.0, 1.0]:
			draw_line(_xf(Vector2(10.0, side * 6.8)), _xf(Vector2(emitter_len + 1.5, side * 3.2)), Color(0.55, 0.58, 0.64), 1.8, true)

func _draw_mlrs(accent: Color) -> void:
	# HIMARS / GMLRS Precision Rocket Salvo Pod
	var rx: float = -recoil * 0.55
	var tubes: int = 3 + level # 3 -> 4 -> 5 -> 6 tubes

	# Heavy armored slew cradle & rear blast deflector
	var cradle: Array[Vector2] = [
		Vector2(10.0 + rx, -13.5), Vector2(10.0 + rx, 13.5),
		Vector2(-14.5 + rx, 13.5), Vector2(-14.5 + rx, -13.5)
	]
	draw_colored_polygon(_xpoly(cradle, Vector2(3.0, 3.6)), Color(0.0, 0.0, 0.0, 0.38))
	_draw_bevel(cradle, Color(0.32, 0.35, 0.28))

	# Side armored truss frames + amber tactical hazard stripe
	var top_deck: Array[Vector2] = [
		Vector2(8.5 + rx, -11.5), Vector2(8.5 + rx, 11.5),
		Vector2(-12.5 + rx, 11.5), Vector2(-12.5 + rx, -11.5)
	]
	_draw_bevel(top_deck, Color(0.38, 0.41, 0.34), Color(0.14, 0.16, 0.12))
	draw_line(_xf(Vector2(-8.0 + rx, -11.2)), _xf(Vector2(-8.0 + rx, 11.2)), accent, 2.8, true)

	# Rear exhaust blast vent plate
	draw_line(_xf(Vector2(-14.2 + rx, -11.5)), _xf(Vector2(-14.2 + rx, 11.5)), Color(0.10, 0.10, 0.10), 3.4, true)

	# Individual GMLRS rocket launch tubes + glowing orange warhead tips
	for i in range(tubes):
		var frac: float = (float(i) / maxf(1.0, float(tubes - 1))) * 2.0 - 1.0
		var ty: float = frac * 9.8
		draw_line(_xf(Vector2(-6.5 + rx, ty)), _xf(Vector2(12.5 + rx, ty)), Color(0.12, 0.13, 0.11), 3.4, true)
		draw_line(_xf(Vector2(-5.5 + rx, ty)), _xf(Vector2(11.0 + rx, ty)), Color(0.46, 0.48, 0.43), 1.6, true)
		# Ready warhead nosecone (dims slightly during reload)
		var loaded: bool = (_cooldown <= 0.6 or _salvo_remaining > 0)
		var tip_col: Color = accent if loaded else Color(0.24, 0.24, 0.22)
		draw_circle(_xf(Vector2(12.2 + rx, ty)), 1.9, tip_col)
		if loaded:
			draw_circle(_xf(Vector2(12.8 + rx, ty)), 0.8, Color(1.0, 0.94, 0.72))

	# Fire-control GPS / target acquisition mast on side
	draw_circle(_xf(Vector2(-11.0, -9.5)), 2.8, Color(0.18, 0.20, 0.18))
	draw_circle(_xf(Vector2(-11.0, -9.5)), 1.3, Color(0.45, 0.96, 0.56))

func _draw_drone_pad(accent: Color) -> void:
	# Tactical Hunter-Killer UAV Launch & Control Pad
	var armed: bool = can_launch_drone()
	var hunting: bool = (active_drone != null and is_instance_valid(active_drone))

	# Helipad / UAV launch deck markings (non-rotating clean landing H-pad)
	draw_circle(Vector2.ZERO, 14.5, Color(0.16, 0.19, 0.17))
	draw_arc(Vector2.ZERO, 13.8, 0.0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.65 if armed else 0.28), 1.6, true)

	# Pad corner strobe LEDs
	var pulse: float = 0.5 + 0.5 * sin(_cryo_pulse * 1.6)
	var led_col: Color = accent if armed else (Color(1.0, 0.72, 0.22) if hunting else Color(0.95, 0.34, 0.24))
	for i in range(4):
		var a: float = float(i) * PI * 0.5 + PI * 0.25
		draw_circle(Vector2.from_angle(a) * 14.2, 1.8, Color(led_col.r, led_col.g, led_col.b, 0.55 + 0.45 * pulse))

	# Rearm progress arc when rearming
	if not armed and not hunting and rearm_timer > 0.0:
		var max_r: float = maxf(0.1, float(get_stats().get("rearm_time", 4.0)))
		var frac: float = clampf(1.0 - rearm_timer / max_r, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 11.2, -PI * 0.5, -PI * 0.5 + TAU * frac, 28, accent, 2.4, true)

	# Rotating ISR datalink radar bar on rim
	var dish_pos := _xf(Vector2(-10.5, 0.0))
	var dish_p1 := _xf(Vector2(-10.5, -6.8))
	var dish_p2 := _xf(Vector2(-10.5, 6.8))
	draw_line(dish_p1, dish_p2, Color(0.12, 0.14, 0.12), 4.0, true)
	draw_line(dish_p1, dish_p2, Color(0.70, 0.78, 0.70), 1.8, true)
	draw_circle(dish_pos, 2.2, led_col)

	# HOLD mode amber indicator badge on pad
	if drone_hold_mode:
		draw_arc(Vector2.ZERO, 16.8, 0.0, TAU, 28, Color(1.0, 0.76, 0.24, 0.72), 1.5, true)

	# Visible docked Hunter-Killer Quad-UAV sitting on the pad when ARMED!
	if armed:
		for ao: Vector2 in [Vector2(6.8, -6.8), Vector2(6.8, 6.8), Vector2(-6.8, -6.8), Vector2(-6.8, 6.8)]:
			var p := _xf(ao)
			draw_line(Vector2.ZERO, p, Color(0.14, 0.16, 0.14), 2.2, true)
			draw_circle(p, 3.8, Color(0.24, 0.28, 0.25, 0.75))
			draw_arc(p, 3.8, 0.0, TAU, 12, Color(accent.r, accent.g, accent.b, 0.55), 1.0, true)
		var uav: Array[Vector2] = [
			Vector2(8.8, 0.0), Vector2(3.5, 3.6), Vector2(-7.2, 2.8),
			Vector2(-8.5, 0.0), Vector2(-7.2, -2.8), Vector2(3.5, -3.6)
		]
		_draw_bevel(uav, Color(0.26, 0.31, 0.26), Color(0.08, 0.10, 0.08))
		draw_circle(_xf(Vector2(4.6, 0.0)), 2.0, accent)
		if level >= 2:
			for side: float in [-1.0, 1.0]:
				draw_line(_xf(Vector2(1.5, side * 3.0)), _xf(Vector2(-4.5, side * 6.5)), accent, 1.6, true)
	else:
		# Empty launch cradle crosshairs
		draw_line(Vector2(-5.5, 0.0), Vector2(5.5, 0.0), Color(0.32, 0.36, 0.32, 0.7), 1.4, true)
		draw_line(Vector2(0.0, -5.5), Vector2(0.0, 5.5), Color(0.32, 0.36, 0.32, 0.7), 1.4, true)
