class_name HunterDrone
extends Node2D

signal finished(drone: HunterDrone)

var source_turret: Node = null
var target_enemy: Enemy = null
var damage: float = 18.0
var fire_rate: float = 4.2
var speed: float = 240.0
var armor_pierce: float = 0.65
var turret_level: int = 0
var accent: Color = Color(0.56, 0.90, 0.30)

var heading: float = -PI * 0.5
var _orbit_angle: float = 0.0
var _fire_cd: float = 0.0
var _rotor_angle: float = 0.0
var _time: float = 0.0
var _tracer_timer: float = 0.0
var _tracer_end: Vector2 = Vector2.ZERO
var _done: bool = false

var _fx: FxManager = null
var _sfx: SfxManager = null

func setup(params: Dictionary) -> void:
	source_turret = params["source_turret"]
	target_enemy = params["target_enemy"]
	position = params["start_pos"]
	damage = float(params["damage"])
	fire_rate = float(params["fire_rate"])
	speed = float(params["speed"])
	armor_pierce = float(params["armor_pierce"])
	turret_level = int(params.get("level", 0))
	accent = params.get("accent", Color(0.56, 0.90, 0.30))
	_fx = params["fx"]
	_sfx = params["sfx"]

	if target_enemy != null and is_instance_valid(target_enemy):
		var to_t := target_enemy.position - position
		heading = to_t.angle() if to_t.length_squared() > 1.0 else -PI * 0.5
		_orbit_angle = (position - target_enemy.position).angle()
	z_as_relative = false
	z_index = 42
	queue_redraw()

func force_self_destruct() -> void:
	if _done:
		return
	_done = true
	if _fx != null:
		_fx.spawn_spark_hit(position, accent, 8)
		_fx.spawn_smoke(position, 6.0, 0.45, 0.28)
	finished.emit(self)
	queue_free()

func _process(delta: float) -> void:
	if _done:
		return
	_time += delta
	_rotor_angle += delta * 36.0
	if _tracer_timer > 0.0:
		_tracer_timer = maxf(0.0, _tracer_timer - delta)
	if _fire_cd > 0.0:
		_fire_cd = maxf(0.0, _fire_cd - delta)

	# Drone is strictly committed to its locked target — when the target dies or exits, the drone dies too!
	if target_enemy == null or not is_instance_valid(target_enemy) or not target_enemy.alive:
		force_self_destruct()
		return

	var target_pos: Vector2 = target_enemy.position
	var orbit_r: float = 28.0 + target_enemy.hit_radius
	var dist_to_target: float = position.distance_to(target_pos)

	if dist_to_target > orbit_r + 22.0:
		# High-speed intercept approach
		var dir := (target_pos - position).normalized()
		var desired_ang := dir.angle()
		heading = lerp_angle(heading, desired_ang, minf(1.0, delta * 9.0))
		position += Vector2.from_angle(heading) * speed * delta
		_orbit_angle = (position - target_pos).angle()
	else:
		# Tight tactical orbit around locked vehicle
		var ang_spd: float = clampf((speed * 0.72) / maxf(24.0, orbit_r), 2.2, 4.6)
		_orbit_angle += ang_spd * delta
		var desired_pos: Vector2 = target_pos + Vector2.from_angle(_orbit_angle) * orbit_r
		var to_orbit := desired_pos - position
		var step_len: float = speed * 1.15 * delta
		if to_orbit.length() <= step_len:
			position = desired_pos
		else:
			position += to_orbit.normalized() * step_len
		var tangent := Vector2.from_angle(_orbit_angle + PI * 0.5)
		heading = lerp_angle(heading, tangent.angle(), minf(1.0, delta * 12.0))

	# Engage locked target once in strike envelope
	if dist_to_target <= orbit_r + 68.0 and _fire_cd <= 0.0:
		_fire_cd = 1.0 / maxf(0.2, fire_rate)
		_fire_burst()

	queue_redraw()

func _fire_burst() -> void:
	if target_enemy == null or not is_instance_valid(target_enemy) or not target_enemy.alive:
		return
	var killer: Node = source_turret if is_instance_valid(source_turret) else null
	var hit_pos: Vector2 = target_enemy.position + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	_tracer_end = hit_pos
	_tracer_timer = 0.055

	var shot_ang: float = (hit_pos - position).angle()
	if _fx != null:
		_fx.spawn_muzzle_flash(position + Vector2.from_angle(shot_ang) * 9.0, shot_ang, 7.5, Color(0.86, 1.0, 0.56))
		_fx.spawn_spark_hit(hit_pos, accent, 3)
	if _sfx != null:
		_sfx.play("drone_fire", -7.5, 0.14, 0.065)

	target_enemy.take_damage(damage, armor_pierce, killer, 1.0)

func _draw() -> void:
	# 1. Target lock-on tactical reticle drawn around the pursued target
	if target_enemy != null and is_instance_valid(target_enemy) and target_enemy.alive:
		var t_local: Vector2 = target_enemy.position - position
		var lock_r: float = target_enemy.hit_radius + 7.5 + sin(_time * 8.0) * 1.6
		var lock_col := Color(accent.r, accent.g, accent.b, 0.85)
		for i in range(4):
			var a: float = _time * 1.5 + float(i) * PI * 0.5
			draw_arc(t_local, lock_r, a - 0.26, a + 0.26, 6, lock_col, 1.8, true)
		# Subtle laser designator sightline
		draw_line(Vector2.ZERO, t_local, Color(accent.r, accent.g, accent.b, 0.18), 1.0, true)

	# 2. Active burst tracer
	if _tracer_timer > 0.0:
		var end_local: Vector2 = _tracer_end - position
		draw_line(Vector2.ZERO, end_local, Color(accent.r, accent.g, accent.b, 0.82), 2.4, true)
		draw_line(Vector2.ZERO, end_local, Color(0.95, 1.0, 0.86, 0.96), 1.1, true)

	# 3. Altitude ground shadow
	var sh := Vector2(18.0, 22.0)
	draw_circle(sh, 10.0, Color(0.0, 0.0, 0.0, 0.18))

	# 4. Quad-rotor Tactical Hunter-Killer UCAV silhouette
	var fwd := Vector2.from_angle(heading)
	var perp := Vector2(-fwd.y, fwd.x)

	# Carbon-fiber X-frame arms & spinning rotors
	var arm_offsets: Array[Vector2] = [
		Vector2(8.5, -8.5), Vector2(8.5, 8.5),
		Vector2(-8.5, -8.5), Vector2(-8.5, 8.5),
	]
	for ao in arm_offsets:
		var wp: Vector2 = fwd * ao.x + perp * ao.y
		draw_line(Vector2.ZERO, wp, Color(0.14, 0.16, 0.14), 2.4, true)
		draw_line(Vector2.ZERO, wp, Color(0.36, 0.40, 0.36), 1.1, true)
		# Rotor blur disc + blade
		draw_circle(wp, 5.2, Color(0.75, 0.85, 0.78, 0.16))
		draw_arc(wp, 5.0, 0.0, TAU, 14, Color(0.55, 0.65, 0.58, 0.34), 1.0, true)
		var b_dir := Vector2.from_angle(_rotor_angle + ao.x)
		draw_line(wp - b_dir * 4.6, wp + b_dir * 4.6, Color(0.10, 0.12, 0.10, 0.82), 1.4, true)
		draw_circle(wp, 1.4, Color(0.24, 0.27, 0.24))

	# Armored central fuselage + forward EO/IR camera pod
	var hull_pts := PackedVector2Array([
		fwd * 10.5,
		fwd * 4.5 + perp * 4.2,
		-fwd * 8.5 + perp * 3.4,
		-fwd * 10.0,
		-fwd * 8.5 - perp * 3.4,
		fwd * 4.5 - perp * 4.2,
	])
	draw_colored_polygon(hull_pts, Color(0.22, 0.26, 0.23))
	var outline := PackedVector2Array(hull_pts)
	outline.append(hull_pts[0])
	draw_polyline(outline, Color(0.08, 0.10, 0.08), 1.2, true)

	# Upgrade winglet fins on Lv 2+
	if turret_level >= 1:
		for side: float in [-1.0, 1.0]:
			draw_line(fwd * 2.0 + perp * (side * 3.5), -fwd * 5.0 + perp * (side * 7.8), accent, 1.8, true)

	# Glowing green optical sensor eye + tail status strobe
	draw_circle(fwd * 5.5, 2.3, accent)
	draw_circle(fwd * 6.0, 1.0, Color(0.92, 1.0, 0.86))
	var strobe: float = 0.4 + 0.6 * sin(_time * 14.0)
	draw_circle(-fwd * 7.2, 1.5, Color(1.0, 0.32, 0.22, strobe))
