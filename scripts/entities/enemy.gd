class_name Enemy
extends Node2D

signal died(enemy: Enemy, killer_turret: Node)
signal reached_base(enemy: Enemy)
signal spawn_sub_unit(enemy_type: EnemyData.EnemyType, from_pos: Vector2)

var enemy_type: EnemyData.EnemyType = EnemyData.EnemyType.JEEP
var config: Dictionary = {}

var is_air: bool = false
var max_hp: float = 100.0
var hp: float = 100.0
var max_shield: float = 0.0
var shield: float = 0.0
var shield_regen: float = 0.0
var shield_regen_delay: float = 3.4
var base_speed: float = 60.0
var armor: float = 0.0
var reward: int = 15
var lives_cost: int = 1
var hit_radius: float = 12.0

var path_points: PackedVector2Array = PackedVector2Array()
var path_index: int = 1
var distance_traveled: float = 0.0
var total_path_length: float = 1.0
var heading: float = 0.0
var alive: bool = true

var slow_factor: float = 0.0
var slow_timer: float = 0.0
var hit_flash: float = 0.0
var festive_mode: bool = false

var _time: float = 0.0
var _phase_seed: float = 0.0
var _rotor_angle: float = 0.0
var _smoke_timer: float = 0.0
var _dust_timer: float = 0.0
var _shield_delay_timer: float = 0.0
var _shield_flash: float = 0.0
var _uav_timer: float = 0.0
var _uav_interval: float = 4.6
var _uav_spawned: int = 0
var _uav_max_spawns: int = 0
var _fx: FxManager = null

func setup(
	type: EnemyData.EnemyType,
	path: PackedVector2Array,
	hp_mult: float,
	speed_mult: float,
	reward_mult: float,
	fx_manager: FxManager,
	is_festive: bool = false
) -> void:
	enemy_type = type
	config = EnemyData.get_config(type)
	_fx = fx_manager
	festive_mode = is_festive
	_phase_seed = randf_range(0.0, TAU)

	is_air = bool(config["is_air"])
	max_hp = float(config["hp"]) * hp_mult
	hp = max_hp
	max_shield = float(config.get("shield", 0.0)) * hp_mult
	shield = max_shield
	shield_regen = float(config.get("shield_regen", 0.0)) * hp_mult
	shield_regen_delay = float(config.get("shield_regen_delay", 3.4))
	_shield_delay_timer = 0.0
	_shield_flash = 0.0

	_uav_interval = float(config.get("uav_spawn_interval", 4.6))
	_uav_timer = float(config.get("uav_first_delay", 2.2))
	_uav_max_spawns = int(config.get("uav_max_spawns", 0))
	_uav_spawned = 0

	base_speed = float(config["speed"]) * speed_mult
	armor = float(config["armor"])
	var base_rew: int = int(config["reward"])
	reward = 0 if base_rew <= 0 else maxi(1, int(round(float(base_rew) * reward_mult)))
	lives_cost = int(config["lives_cost"])
	hit_radius = float(config["radius"])

	path_points = path
	path_index = 1
	distance_traveled = 0.0
	total_path_length = _compute_path_length(path)

	if path_points.size() >= 2:
		position = path_points[0]
		heading = (path_points[1] - path_points[0]).angle()
	z_index = 35 if is_air else 15

func get_progress() -> float:
	return distance_traveled / maxf(1.0, total_path_length)

func get_current_speed() -> float:
	var mult: float = 1.0 - slow_factor if slow_timer > 0.0 else 1.0
	return base_speed * clampf(mult, 0.28, 1.0)

func get_velocity_vector() -> Vector2:
	return Vector2.from_angle(heading) * get_current_speed()

func apply_slow(amount: float, duration: float) -> void:
	if amount >= slow_factor or slow_timer <= 0.0:
		slow_factor = maxf(slow_factor, amount)
		slow_timer = maxf(slow_timer, duration)
	else:
		slow_timer = maxf(slow_timer, duration * 0.85)

func take_damage(raw_damage: float, armor_pierce: float, source_turret: Node = null, shield_mult: float = 1.0) -> void:
	if not alive:
		return

	var remaining_raw: float = raw_damage
	if max_shield > 0.0:
		_shield_delay_timer = shield_regen_delay
		if shield > 0.0:
			var shield_dmg: float = raw_damage * maxf(0.1, shield_mult)
			_shield_flash = 0.16
			if shield_dmg < shield:
				shield -= shield_dmg
				return
			else:
				remaining_raw = (shield_dmg - shield) / maxf(0.1, shield_mult)
				shield = 0.0
				if _fx != null:
					_fx.spawn_shield_break(position, hit_radius + 10.0)

	if remaining_raw <= 0.0:
		return
	var eff_armor: float = maxf(0.0, armor * (1.0 - clampf(armor_pierce, 0.0, 1.0)))
	var final_dmg: float = maxf(0.2, remaining_raw * (1.0 - eff_armor))
	hp -= final_dmg
	hit_flash = 0.11
	if hp <= 0.0:
		hp = 0.0
		alive = false
		var valid_source: Node = source_turret if is_instance_valid(source_turret) else null
		died.emit(self, valid_source)
		queue_free()

func _process(delta: float) -> void:
	if not alive:
		return

	_time += delta
	if slow_timer > 0.0:
		slow_timer = maxf(0.0, slow_timer - delta)
		if slow_timer <= 0.0:
			slow_factor = 0.0

	if hit_flash > 0.0:
		hit_flash = maxf(0.0, hit_flash - delta)
	if _shield_flash > 0.0:
		_shield_flash = maxf(0.0, _shield_flash - delta)
	if max_shield > 0.0 and shield < max_shield:
		if _shield_delay_timer > 0.0:
			_shield_delay_timer = maxf(0.0, _shield_delay_timer - delta)
		else:
			shield = minf(max_shield, shield + shield_regen * delta)

	# Mobile UAV Carrier periodically launches fast FPV/Shahed air drones!
	if enemy_type == EnemyData.EnemyType.UAV_CARRIER and _uav_spawned < _uav_max_spawns:
		_uav_timer -= delta
		if _uav_timer <= 0.0:
			_uav_timer = _uav_interval
			_uav_spawned += 1
			spawn_sub_unit.emit(EnemyData.EnemyType.FPV_DRONE, position)

	_rotor_angle += delta * 29.0

	# Move along polyline
	var step: float = get_current_speed() * delta
	distance_traveled += step
	var remaining: float = step

	while remaining > 0.0 and path_index < path_points.size():
		var target: Vector2 = path_points[path_index]
		var to_target: Vector2 = target - position
		var dist: float = to_target.length()
		if dist <= remaining:
			position = target
			remaining -= dist
			path_index += 1
		else:
			var move_dir: Vector2 = to_target / dist
			position += move_dir * remaining
			var desired_angle: float = move_dir.angle()
			heading = lerp_angle(heading, desired_angle, minf(1.0, delta * 10.5))
			remaining = 0.0

	# Movement trails: road dust for ground vehicles, wingtip contrails for jets
	if _fx != null:
		_dust_timer += delta
		if not is_air and _dust_timer >= 0.11:
			_dust_timer = 0.0
			var back := Vector2.from_angle(heading)
			var perp := Vector2(-back.y, back.x)
			var sc: float = float(config["scale"])
			var rear_off: float = 11.0 * sc
			var track_w: float = 5.5 * sc
			_fx.spawn_dust(position - back * rear_off + perp * track_w, 3.6 * sc, 0.44)
			_fx.spawn_dust(position - back * rear_off - perp * track_w, 3.6 * sc, 0.44)
		elif enemy_type == EnemyData.EnemyType.BOMBER and _dust_timer >= 0.045:
			_dust_timer = 0.0
			var fwd := Vector2.from_angle(heading)
			var perp := Vector2(-fwd.y, fwd.x)
			_fx.spawn_contrail(position - fwd * 12.0 + perp * 23.0, 2.2, 0.40)
			_fx.spawn_contrail(position - fwd * 12.0 - perp * 23.0, 2.2, 0.40)

		# Toy Train cheerful white steam puffs in festive mode!
		if festive_mode and enemy_type == EnemyData.EnemyType.APC and _dust_timer == 0.0:
			var fwd := Vector2.from_angle(heading)
			_fx.spawn_smoke(position + fwd * 8.0, 4.2, 0.50, 0.92)

		# Battle damage smoke & sparks (sparkly clockwork springs/steam in festive mode!)
		var hp_ratio: float = hp / maxf(1.0, max_hp)
		if hp_ratio < 0.62:
			_smoke_timer += delta
			var rate: float = 0.09 if hp_ratio < 0.35 else 0.17
			if _smoke_timer >= rate:
				_smoke_timer = 0.0
				var dark: float = 0.85 if festive_mode else (0.14 if hp_ratio < 0.35 else 0.28)
				_fx.spawn_smoke(position - Vector2.from_angle(heading) * 4.0, 4.6 * float(config["scale"]), 0.58, dark)
				if hp_ratio < 0.35 and randf() < 0.28:
					var sp_col := Color(1.0, 0.88, 0.32) if festive_mode else Color(1.0, 0.65, 0.20)
					_fx.spawn_spark_hit(position, sp_col, 2)

	if path_index >= path_points.size():
		alive = false
		reached_base.emit(self)
		queue_free()
		return

	queue_redraw()

func _draw() -> void:
	var hull_col: Color = config["hull_color"]
	var trim_col: Color = config["trim_color"]
	if slow_timer > 0.0:
		hull_col = hull_col.lerp(Color(0.38, 0.80, 0.98), 0.36)
	if hit_flash > 0.0:
		hull_col = hull_col.lerp(Color(1.0, 0.96, 0.84), 0.62)

	if festive_mode:
		match enemy_type:
			EnemyData.EnemyType.JEEP:
				_draw_toy_roadster()
			EnemyData.EnemyType.APC:
				_draw_toy_train()
			EnemyData.EnemyType.TANK:
				_draw_toy_nutcracker()
			EnemyData.EnemyType.CHOPPER:
				_draw_toy_whirlybird()
			EnemyData.EnemyType.BOMBER:
				_draw_toy_airship()
			EnemyData.EnemyType.JUGGERNAUT:
				_draw_toy_king_cracker()
			EnemyData.EnemyType.APS_TANK:
				_draw_toy_snowglobe_tank()
			EnemyData.EnemyType.UAV_CARRIER:
				_draw_toy_drone_sleigh()
			EnemyData.EnemyType.FPV_DRONE:
				_draw_toy_ornament_drone()
			EnemyData.EnemyType.SKY_FORTRESS:
				_draw_toy_zeppelin_boss()
	else:
		match enemy_type:
			EnemyData.EnemyType.JEEP:
				_draw_jeep(hull_col, trim_col)
			EnemyData.EnemyType.APC:
				_draw_apc(hull_col, trim_col)
			EnemyData.EnemyType.TANK:
				_draw_tank(hull_col, trim_col)
			EnemyData.EnemyType.CHOPPER:
				_draw_chopper(hull_col, trim_col)
			EnemyData.EnemyType.BOMBER:
				_draw_bomber(hull_col, trim_col)
			EnemyData.EnemyType.JUGGERNAUT:
				_draw_juggernaut(hull_col, trim_col)
			EnemyData.EnemyType.APS_TANK:
				_draw_aps_tank(hull_col, trim_col)
			EnemyData.EnemyType.UAV_CARRIER:
				_draw_uav_carrier(hull_col, trim_col)
			EnemyData.EnemyType.FPV_DRONE:
				_draw_fpv_drone(hull_col, trim_col)
			EnemyData.EnemyType.SKY_FORTRESS:
				_draw_sky_fortress(hull_col, trim_col)

	_draw_damage_and_status()
	_draw_health_bar()

func _xf(local_pt: Vector2, rot: float = 0.0, pivot: Vector2 = Vector2.ZERO) -> Vector2:
	var pt: Vector2 = local_pt
	if rot != 0.0:
		pt = (pt - pivot).rotated(rot) + pivot
	return pt.rotated(heading)

func _poly(pts: Array[Vector2], offset: Vector2 = Vector2.ZERO, rot: float = 0.0, pivot: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var out := PackedVector2Array()
	for pt in pts:
		out.append(_xf(pt, rot, pivot) + offset)
	return out

func _draw_bevel_poly(pts: Array[Vector2], base_col: Color, outline_col: Color, rot: float = 0.0, pivot: Vector2 = Vector2.ZERO) -> void:
	var poly := _poly(pts, Vector2.ZERO, rot, pivot)
	draw_colored_polygon(poly, base_col)
	var closed := PackedVector2Array(poly)
	closed.append(poly[0])
	draw_polyline(closed, outline_col, 1.15, true)

func _draw_treads(half_len: float, inner_y: float, outer_y: float, cleat_spacing: float) -> void:
	var offset: float = fmod(distance_traveled, cleat_spacing)
	for side: float in [-1.0, 1.0]:
		var y_a: float = side * inner_y
		var y_b: float = side * outer_y
		var y_min: float = minf(y_a, y_b)
		var y_max: float = maxf(y_a, y_b)
		var track_box: Array[Vector2] = [
			Vector2(half_len, y_min), Vector2(half_len, y_max),
			Vector2(-half_len, y_max), Vector2(-half_len, y_min)
		]
		draw_colored_polygon(_poly(track_box), Color(0.10, 0.10, 0.09))
		# Outer steel rim
		var rim_y: float = side * (outer_y - 0.5)
		draw_line(_xf(Vector2(-half_len, rim_y)), _xf(Vector2(half_len, rim_y)), Color(0.24, 0.24, 0.22), 1.0, true)
		# Animated scrolling track links / cleats
		var x: float = -half_len + offset
		while x < half_len:
			draw_line(_xf(Vector2(x, y_min + 0.6)), _xf(Vector2(x, y_max - 0.6)), Color(0.28, 0.27, 0.24, 0.85), 1.3, true)
			x += cleat_spacing

func _draw_jeep(hull: Color, trim: Color) -> void:
	var sh := Vector2(4.0, 4.8)
	var body: Array[Vector2] = [
		Vector2(13.0, -5.8), Vector2(11.5, -7.0), Vector2(-12.0, -7.0),
		Vector2(-13.0, -5.5), Vector2(-13.0, 5.5), Vector2(-12.0, 7.0),
		Vector2(11.5, 7.0), Vector2(13.0, 5.8)
	]
	# Contact AO + directional shadow
	draw_colored_polygon(_poly(body, Vector2(1.2, 1.4)), Color(0.0, 0.0, 0.0, 0.45))
	draw_colored_polygon(_poly(body, sh), Color(0.0, 0.0, 0.0, 0.30))

	# Headlight cones (subtle warm tactical glow)
	for side: float in [-1.0, 1.0]:
		var beam: Array[Vector2] = [
			Vector2(13.0, side * 4.2), Vector2(26.0, side * 8.5), Vector2(26.0, side * 1.2)
		]
		draw_colored_polygon(_poly(beam), Color(1.0, 0.94, 0.72, 0.11))

	# 4 rugged off-road tires with hubs
	for wx: float in [-7.8, 7.6]:
		for wy: float in [-7.6, 7.6]:
			var wbox: Array[Vector2] = [
				Vector2(wx + 3.0, wy - 1.7), Vector2(wx + 3.0, wy + 1.7),
				Vector2(wx - 3.0, wy + 1.7), Vector2(wx - 3.0, wy - 1.7)
			]
			draw_colored_polygon(_poly(wbox), Color(0.08, 0.08, 0.08))
			draw_line(_xf(Vector2(wx - 1.5, wy)), _xf(Vector2(wx + 1.5, wy)), Color(0.26, 0.27, 0.24), 1.2, true)

	# Front bull-bar bumper
	draw_line(_xf(Vector2(13.6, -5.5)), _xf(Vector2(13.6, 5.5)), Color(0.16, 0.17, 0.16), 2.2, true)

	# Armored chassis with bevel outline
	_draw_bevel_poly(body, hull, Color(0.13, 0.15, 0.11))

	# Camo diagonal stripe across hood
	var camo: Array[Vector2] = [Vector2(11.0, -5.5), Vector2(5.5, -5.5), Vector2(8.0, 4.5), Vector2(11.5, 3.0)]
	draw_colored_polygon(_poly(camo), hull.darkened(0.24))

	# Hood vents & sunlit highlight
	draw_line(_xf(Vector2(9.8, -3.5)), _xf(Vector2(9.8, 3.5)), Color(0.14, 0.15, 0.12), 1.4, true)
	draw_line(_xf(Vector2(7.6, -3.5)), _xf(Vector2(7.6, 3.5)), Color(0.14, 0.15, 0.12), 1.4, true)
	draw_line(_xf(Vector2(11.0, -5.8)), _xf(Vector2(-10.5, -5.8)), hull.lightened(0.22), 1.2, true)

	# Sloped armored cab roof
	var cab: Array[Vector2] = [Vector2(4.0, -5.4), Vector2(4.0, 5.4), Vector2(-7.0, 5.4), Vector2(-7.0, -5.4)]
	_draw_bevel_poly(cab, trim.lightened(0.08), Color(0.12, 0.14, 0.10))

	# Split armored windshield with sky specular glint
	draw_line(_xf(Vector2(4.4, -4.4)), _xf(Vector2(4.4, -0.7)), Color(0.42, 0.64, 0.72, 0.92), 2.6, true)
	draw_line(_xf(Vector2(4.4, 0.7)), _xf(Vector2(4.4, 4.4)), Color(0.42, 0.64, 0.72, 0.92), 2.6, true)
	draw_line(_xf(Vector2(4.7, -3.8)), _xf(Vector2(4.7, -1.6)), Color(0.84, 0.94, 0.98, 0.70), 1.0, true)

	# Rear cargo spare wheel & red taillights
	draw_circle(_xf(Vector2(-10.2, 0.0)), 3.0, Color(0.11, 0.11, 0.10))
	draw_circle(_xf(Vector2(-10.2, 0.0)), 1.3, Color(0.32, 0.34, 0.28))
	draw_circle(_xf(Vector2(-12.6, -4.4)), 1.2, Color(0.92, 0.22, 0.16, 0.9))
	draw_circle(_xf(Vector2(-12.6, 4.4)), 1.2, Color(0.92, 0.22, 0.16, 0.9))
	# Headlight lenses
	draw_circle(_xf(Vector2(12.6, -4.2)), 1.3, Color(1.0, 0.94, 0.72))
	draw_circle(_xf(Vector2(12.6, 4.2)), 1.3, Color(1.0, 0.94, 0.72))

	# Roof turret ring + scanning .50 cal HMG
	var gun_sway: float = sin(_time * 2.4 + _phase_seed) * 0.35
	var pivot := Vector2(-1.5, 0.0)
	draw_circle(_xf(pivot), 3.6, Color(0.16, 0.18, 0.15))
	draw_arc(_xf(pivot), 3.6, 0.0, TAU, 16, Color(0.44, 0.47, 0.40), 1.0, true)
	draw_line(_xf(Vector2(-2.0, 0.0), gun_sway, pivot), _xf(Vector2(8.2, 0.0), gun_sway, pivot), Color(0.11, 0.11, 0.11), 2.4, true)
	draw_line(_xf(Vector2(-1.5, 0.0), gun_sway, pivot), _xf(Vector2(7.5, 0.0), gun_sway, pivot), Color(0.45, 0.47, 0.44), 1.1, true)
	# Whip antenna
	draw_line(_xf(Vector2(-10.5, -5.2)), _xf(Vector2(-14.5, -6.4)), Color(0.20, 0.22, 0.20, 0.75), 0.9, true)

func _draw_apc(hull: Color, trim: Color) -> void:
	var sh := Vector2(5.0, 5.8)
	var body: Array[Vector2] = [
		Vector2(17.5, -5.2), Vector2(12.0, -9.2), Vector2(-15.5, -9.2),
		Vector2(-17.0, -6.5), Vector2(-17.0, 6.5), Vector2(-15.5, 9.2),
		Vector2(12.0, 9.2), Vector2(17.5, 5.2)
	]
	draw_colored_polygon(_poly(body, Vector2(1.4, 1.6)), Color(0.0, 0.0, 0.0, 0.48))
	draw_colored_polygon(_poly(body, sh), Color(0.0, 0.0, 0.0, 0.32))

	# 8 armored wheels (BTR-80 style)
	for wx: float in [-11.5, -4.0, 3.5, 10.5]:
		for wy: float in [-9.6, 9.6]:
			var wbox: Array[Vector2] = [
				Vector2(wx + 2.8, wy - 1.7), Vector2(wx + 2.8, wy + 1.7),
				Vector2(wx - 2.8, wy + 1.7), Vector2(wx - 2.8, wy - 1.7)
			]
			draw_colored_polygon(_poly(wbox), Color(0.08, 0.08, 0.08))
			draw_line(_xf(Vector2(wx - 1.2, wy)), _xf(Vector2(wx + 1.2, wy)), Color(0.28, 0.29, 0.26), 1.1, true)

	# Main sloped armored boat-hull
	_draw_bevel_poly(body, hull, Color(0.12, 0.14, 0.11))

	# Woodland camo patches
	var patch1: Array[Vector2] = [Vector2(10.0, -8.5), Vector2(2.0, -8.5), Vector2(5.0, 1.5), Vector2(12.0, -2.0)]
	var patch2: Array[Vector2] = [Vector2(-5.0, 8.5), Vector2(-13.0, 8.5), Vector2(-10.0, -1.0), Vector2(-3.0, 2.0)]
	draw_colored_polygon(_poly(patch1), hull.darkened(0.22))
	draw_colored_polygon(_poly(patch2), Color(0.26, 0.25, 0.18, 0.72))

	# Sloped front armor glacis highlight + visors
	var glacis: Array[Vector2] = [Vector2(17.0, -4.8), Vector2(11.5, -8.4), Vector2(11.5, 8.4), Vector2(17.0, 4.8)]
	draw_colored_polygon(_poly(glacis), hull.lightened(0.11))
	draw_line(_xf(Vector2(13.5, -4.8)), _xf(Vector2(13.5, -1.4)), Color(0.12, 0.16, 0.18), 2.2, true)
	draw_line(_xf(Vector2(13.5, 1.4)), _xf(Vector2(13.5, 4.8)), Color(0.12, 0.16, 0.18), 2.2, true)
	draw_line(_xf(Vector2(16.8, -4.2)), _xf(Vector2(16.8, 4.2)), Color(0.20, 0.22, 0.19), 1.5, true)

	# Upper hull deck + troop roof hatches + side reactive armor plates
	var deck: Array[Vector2] = [Vector2(10.5, -6.5), Vector2(-13.5, -6.5), Vector2(-13.5, 6.5), Vector2(10.5, 6.5)]
	_draw_bevel_poly(deck, hull.lightened(0.06), Color(0.16, 0.18, 0.14))
	draw_line(_xf(Vector2(10.2, -6.4)), _xf(Vector2(-13.2, -6.4)), hull.lightened(0.24), 1.2, true)

	# Rear engine louver grilles
	for gx: float in [-12.0, -9.8, -7.6]:
		draw_line(_xf(Vector2(gx, -4.6)), _xf(Vector2(gx, 4.6)), Color(0.11, 0.12, 0.10), 1.4, true)
	# Twin infantry hatches
	for hy: float in [-3.2, 3.2]:
		var hatch: Array[Vector2] = [Vector2(-1.5, hy - 1.9), Vector2(-1.5, hy + 1.9), Vector2(-5.5, hy + 1.9), Vector2(-5.5, hy - 1.9)]
		draw_colored_polygon(_poly(hatch), trim)

	# Tactical white chevron stripe on rear deck
	var chev: Array[Vector2] = [Vector2(-2.0, -3.5), Vector2(0.8, 0.0), Vector2(-2.0, 3.5)]
	draw_polyline(_poly(chev), Color(0.85, 0.86, 0.78, 0.55), 1.5, true)

	# Headlights & tail lamps
	draw_circle(_xf(Vector2(16.6, -4.5)), 1.4, Color(1.0, 0.94, 0.72))
	draw_circle(_xf(Vector2(16.6, 4.5)), 1.4, Color(1.0, 0.94, 0.72))
	draw_circle(_xf(Vector2(-16.5, -5.5)), 1.2, Color(0.92, 0.20, 0.16))
	draw_circle(_xf(Vector2(-16.5, 5.5)), 1.2, Color(0.92, 0.20, 0.16))

	# Scanning autocannon turret
	var sway: float = sin(_time * 1.9 + _phase_seed) * 0.28
	var pivot := Vector2(4.2, 0.0)
	draw_circle(_xf(pivot) + Vector2(2.0, 2.5), 5.6, Color(0.0, 0.0, 0.0, 0.35))
	draw_line(_xf(Vector2(4.5, 0.0), sway, pivot), _xf(Vector2(19.5, 0.0), sway, pivot), Color(0.11, 0.12, 0.11), 3.4, true)
	draw_line(_xf(Vector2(4.5, 0.0), sway, pivot), _xf(Vector2(18.5, 0.0), sway, pivot), Color(0.52, 0.55, 0.50), 1.6, true)
	# Muzzle flash suppressor
	draw_line(_xf(Vector2(18.2, -1.6), sway, pivot), _xf(Vector2(18.2, 1.6), sway, pivot), Color(0.18, 0.19, 0.18), 2.0, true)
	# Conical BTR turret housing
	var tur: Array[Vector2] = [
		Vector2(9.2, -3.2), Vector2(6.5, -5.5), Vector2(0.5, -5.0),
		Vector2(-1.2, 0.0), Vector2(0.5, 5.0), Vector2(6.5, 5.5), Vector2(9.2, 3.2)
	]
	_draw_bevel_poly(tur, hull.lightened(0.15), Color(0.13, 0.15, 0.12), sway, pivot)
	draw_circle(_xf(Vector2(3.0, -1.5), sway, pivot), 1.8, trim)
	draw_circle(_xf(Vector2(6.5, 1.8), sway, pivot), 1.2, Color(0.35, 0.78, 0.88, 0.85))

func _draw_tank(hull: Color, trim: Color) -> void:
	var sh := Vector2(6.0, 7.0)
	var footprint: Array[Vector2] = [
		Vector2(19.0, -13.5), Vector2(19.0, 13.5), Vector2(-19.0, 13.5), Vector2(-19.0, -13.5)
	]
	draw_colored_polygon(_poly(footprint, Vector2(1.6, 2.0)), Color(0.0, 0.0, 0.0, 0.50))
	draw_colored_polygon(_poly(footprint, sh), Color(0.0, 0.0, 0.0, 0.34))

	# Animated armored tracks
	_draw_treads(19.5, 8.2, 13.6, 4.2)

	# Armored side skirts bolted over upper track runs
	for side: float in [-1.0, 1.0]:
		var y0: float = side * 8.4
		var y1: float = side * 12.2
		var skirt: Array[Vector2] = [
			Vector2(17.0, minf(y0, y1)), Vector2(17.0, maxf(y0, y1)),
			Vector2(-16.5, maxf(y0, y1)), Vector2(-16.5, minf(y0, y1))
		]
		_draw_bevel_poly(skirt, hull.darkened(0.14), Color(0.11, 0.12, 0.10))
		# ERA armor panel divider seams
		for sx: float in [-10.0, -3.5, 3.0, 9.5]:
			draw_line(_xf(Vector2(sx, y0)), _xf(Vector2(sx, y1)), Color(0.12, 0.13, 0.11), 1.1, true)

	# Sloped MBT main hull
	var core: Array[Vector2] = [
		Vector2(18.5, -8.8), Vector2(18.5, 8.8), Vector2(-18.0, 8.8), Vector2(-18.0, -8.8)
	]
	_draw_bevel_poly(core, hull, Color(0.12, 0.14, 0.10))

	# Front sloped glacis armor with reactive armor bricks
	var glacis: Array[Vector2] = [Vector2(18.0, -8.2), Vector2(11.0, -8.2), Vector2(11.0, 8.2), Vector2(18.0, 8.2)]
	draw_colored_polygon(_poly(glacis), hull.lightened(0.12))
	for ey: float in [-5.8, -2.0, 2.0, 5.8]:
		var brick: Array[Vector2] = [
			Vector2(16.8, ey - 1.5), Vector2(16.8, ey + 1.5),
			Vector2(13.2, ey + 1.5), Vector2(13.2, ey - 1.5)
		]
		_draw_bevel_poly(brick, hull.lightened(0.17), Color(0.14, 0.16, 0.12))

	# Rear engine deck grille + twin exhaust louvers + fuel drums
	var engine: Array[Vector2] = [Vector2(-7.5, -7.2), Vector2(-7.5, 7.2), Vector2(-16.8, 7.2), Vector2(-16.8, -7.2)]
	_draw_bevel_poly(engine, trim, Color(0.10, 0.11, 0.09))
	for gx: float in [-15.2, -13.0, -10.8, -8.8]:
		draw_line(_xf(Vector2(gx, -6.2)), _xf(Vector2(gx, 6.2)), Color(0.08, 0.09, 0.08), 1.4, true)
	# Twin external rear fuel drums
	for fy: float in [-4.5, 4.5]:
		var drum: Array[Vector2] = [
			Vector2(-17.8, fy - 2.6), Vector2(-17.8, fy + 2.6),
			Vector2(-20.4, fy + 2.6), Vector2(-20.4, fy - 2.6)
		]
		_draw_bevel_poly(drum, hull.darkened(0.18), Color(0.10, 0.11, 0.09))

	# Headlights
	draw_circle(_xf(Vector2(18.2, -7.0)), 1.4, Color(1.0, 0.94, 0.72))
	draw_circle(_xf(Vector2(18.2, 7.0)), 1.4, Color(1.0, 0.94, 0.72))

	# Independent subtly scanning main battle turret
	var sway: float = sin(_time * 1.45 + _phase_seed) * 0.22
	var pivot := Vector2(1.5, 0.0)
	var tur: Array[Vector2] = [
		Vector2(11.5, -5.2), Vector2(6.5, -9.2), Vector2(-5.5, -8.8),
		Vector2(-10.5, -5.8), Vector2(-10.5, 5.8), Vector2(-5.5, 8.8),
		Vector2(6.5, 9.2), Vector2(11.5, 5.2)
	]
	# Turret shadow on hull
	draw_colored_polygon(_poly(tur, Vector2(2.6, 3.0), sway, pivot), Color(0.0, 0.0, 0.0, 0.36))

	# 120mm main smoothbore gun with fume extractor & muzzle shadow
	draw_line(_xf(Vector2(5.0, 0.0), sway, pivot) + Vector2(2.4, 2.8), _xf(Vector2(28.5, 0.0), sway, pivot) + Vector2(2.4, 2.8), Color(0.0, 0.0, 0.0, 0.32), 4.8, true)
	draw_line(_xf(Vector2(5.0, 0.0), sway, pivot), _xf(Vector2(28.5, 0.0), sway, pivot), Color(0.12, 0.13, 0.11), 5.0, true)
	draw_line(_xf(Vector2(5.0, 0.0), sway, pivot), _xf(Vector2(27.5, 0.0), sway, pivot), hull.lightened(0.18), 2.8, true)
	# Bore evacuator (fume extractor bulge)
	draw_line(_xf(Vector2(15.0, 0.0), sway, pivot), _xf(Vector2(20.5, 0.0), sway, pivot), Color(0.16, 0.18, 0.14), 6.2, true)
	draw_line(_xf(Vector2(15.4, 0.0), sway, pivot), _xf(Vector2(20.1, 0.0), sway, pivot), hull.lightened(0.24), 3.6, true)

	# Turret body + sunlit top bevel + stowage basket + commander cupola + optics
	_draw_bevel_poly(tur, hull.lightened(0.13), Color(0.12, 0.14, 0.10), sway, pivot)
	var tur_top: Array[Vector2] = [
		Vector2(8.5, -3.8), Vector2(4.5, -6.5), Vector2(-5.0, -6.2),
		Vector2(-7.5, -4.0), Vector2(-7.5, 4.0), Vector2(-5.0, 6.2),
		Vector2(4.5, 6.5), Vector2(8.5, 3.8)
	]
	draw_colored_polygon(_poly(tur_top, Vector2.ZERO, sway, pivot), hull.lightened(0.20))

	# Commander hatch & gunner thermal sight
	draw_circle(_xf(Vector2(-1.0, -3.2), sway, pivot), 3.0, trim)
	draw_arc(_xf(Vector2(-1.0, -3.2), sway, pivot), 3.0, 0.0, TAU, 14, hull.lightened(0.28), 1.0, true)
	draw_circle(_xf(Vector2(-1.5, 3.4), sway, pivot), 2.5, trim)
	# Thermal sight box
	var sight: Array[Vector2] = [Vector2(6.5, 2.2), Vector2(6.5, 4.8), Vector2(3.5, 4.8), Vector2(3.5, 2.2)]
	draw_colored_polygon(_poly(sight, Vector2.ZERO, sway, pivot), Color(0.16, 0.20, 0.18))
	draw_line(_xf(Vector2(6.6, 2.5), sway, pivot), _xf(Vector2(6.6, 4.5), sway, pivot), Color(0.32, 0.85, 0.94, 0.9), 1.6, true)

	# Smoke grenade dischargers on turret cheeks
	for side: float in [-1.0, 1.0]:
		draw_line(_xf(Vector2(6.8, side * 8.6), sway, pivot), _xf(Vector2(9.8, side * 10.2), sway, pivot), Color(0.18, 0.20, 0.18), 1.8, true)

	# Twin radio whip antennas
	draw_line(_xf(Vector2(-8.5, -5.0), sway, pivot), _xf(Vector2(-15.5, -7.8), sway, pivot), Color(0.22, 0.24, 0.21, 0.8), 1.0, true)

func _draw_juggernaut(hull: Color, trim: Color) -> void:
	var sh := Vector2(8.0, 9.0)
	var footprint: Array[Vector2] = [
		Vector2(27.0, -21.0), Vector2(27.0, 21.0), Vector2(-27.0, 21.0), Vector2(-27.0, -21.0)
	]
	draw_colored_polygon(_poly(footprint, Vector2(2.0, 2.5)), Color(0.0, 0.0, 0.0, 0.56))
	draw_colored_polygon(_poly(footprint, sh), Color(0.0, 0.0, 0.0, 0.36))

	# Massive quadruple-wide armored siege tracks
	_draw_treads(27.0, 12.5, 20.8, 4.6)

	# Heavy spaced side armor sponsons with rivets
	for side: float in [-1.0, 1.0]:
		var y0: float = side * 12.2
		var y1: float = side * 18.2
		var sponson: Array[Vector2] = [
			Vector2(23.0, minf(y0, y1)), Vector2(23.0, maxf(y0, y1)),
			Vector2(-23.0, maxf(y0, y1)), Vector2(-23.0, minf(y0, y1))
		]
		_draw_bevel_poly(sponson, hull.darkened(0.14), Color(0.09, 0.09, 0.09))
		for rx: float in [-16.0, -8.0, 0.0, 8.0, 16.0]:
			draw_line(_xf(Vector2(rx, y0)), _xf(Vector2(rx, y1)), Color(0.10, 0.10, 0.10), 1.3, true)
			draw_circle(_xf(Vector2(rx + 4.0, side * 15.2)), 1.0, Color(0.55, 0.54, 0.50))

	# Armored siege chassis
	var chassis: Array[Vector2] = [
		Vector2(26.0, -13.2), Vector2(26.0, 13.2), Vector2(-25.5, 13.2), Vector2(-25.5, -13.2)
	]
	_draw_bevel_poly(chassis, hull, Color(0.10, 0.10, 0.09))

	# Front bulldozer ram / heavy composite glacis
	var ram: Array[Vector2] = [
		Vector2(28.5, -11.5), Vector2(25.5, -13.5), Vector2(25.5, 13.5), Vector2(28.5, 11.5)
	]
	_draw_bevel_poly(ram, Color(0.24, 0.24, 0.22), Color(0.08, 0.08, 0.08))
	# Crimson & hazard elite siege stripes
	var stripe: Array[Vector2] = [Vector2(21.5, -12.4), Vector2(21.5, 12.4), Vector2(15.5, 12.4), Vector2(15.5, -12.4)]
	draw_colored_polygon(_poly(stripe), trim)
	for sy: float in [-9.0, -3.0, 3.0, 9.0]:
		draw_line(_xf(Vector2(21.2, sy)), _xf(Vector2(15.8, sy + 2.0)), Color(0.95, 0.78, 0.24, 0.85), 1.8, true)

	# Glowing twin rear reactor exhaust grilles
	var glow_pulse: float = 0.65 + 0.35 * sin(_time * 6.0 + _phase_seed)
	for ey: float in [-6.8, 6.8]:
		var vent: Array[Vector2] = [
			Vector2(-15.0, ey - 3.6), Vector2(-15.0, ey + 3.6),
			Vector2(-23.5, ey + 3.6), Vector2(-23.5, ey - 3.6)
		]
		_draw_bevel_poly(vent, Color(0.14, 0.13, 0.12), Color(0.06, 0.06, 0.06))
		draw_line(_xf(Vector2(-16.5, ey)), _xf(Vector2(-22.2, ey)), Color(1.0, 0.42, 0.12, 0.72 * glow_pulse), 3.4, true)
		for gx: float in [-21.5, -19.2, -17.0]:
			draw_line(_xf(Vector2(gx, ey - 3.2)), _xf(Vector2(gx, ey + 3.2)), Color(0.10, 0.10, 0.10), 1.3, true)

	# Massive twin-cannon rotating siege turret
	var sway: float = sin(_time * 0.95 + _phase_seed) * 0.18
	var pivot := Vector2(1.0, 0.0)
	var tur: Array[Vector2] = [
		Vector2(14.5, -8.5), Vector2(7.5, -14.2), Vector2(-11.0, -13.5),
		Vector2(-16.0, -8.0), Vector2(-16.0, 8.0), Vector2(-11.0, 13.5),
		Vector2(7.5, 14.2), Vector2(14.5, 8.5)
	]
	draw_colored_polygon(_poly(tur, Vector2(3.6, 4.2), sway, pivot), Color(0.0, 0.0, 0.0, 0.44))

	# Twin 155mm siege barrels with heavy muzzle brakes & bore evacuators
	for oy: float in [-5.6, 5.6]:
		draw_line(_xf(Vector2(6.0, oy), sway, pivot) + Vector2(3.0, 3.5), _xf(Vector2(36.0, oy), sway, pivot) + Vector2(3.0, 3.5), Color(0.0, 0.0, 0.0, 0.35), 6.2, true)
		draw_line(_xf(Vector2(6.0, oy), sway, pivot), _xf(Vector2(36.0, oy), sway, pivot), Color(0.10, 0.10, 0.10), 6.6, true)
		draw_line(_xf(Vector2(6.0, oy), sway, pivot), _xf(Vector2(34.5, oy), sway, pivot), Color(0.48, 0.48, 0.45), 3.6, true)
		# Bore evacuator
		draw_line(_xf(Vector2(18.0, oy), sway, pivot), _xf(Vector2(24.5, oy), sway, pivot), Color(0.20, 0.20, 0.19), 7.8, true)
		draw_line(_xf(Vector2(18.5, oy), sway, pivot), _xf(Vector2(24.0, oy), sway, pivot), Color(0.56, 0.56, 0.52), 4.4, true)
		# Slotted muzzle brake
		var brake: Array[Vector2] = [
			Vector2(37.2, oy - 4.0), Vector2(37.2, oy + 4.0),
			Vector2(33.2, oy + 4.0), Vector2(33.2, oy - 4.0)
		]
		_draw_bevel_poly(brake, Color(0.22, 0.22, 0.20), Color(0.08, 0.08, 0.08), sway, pivot)

	# Armored octagonal siege turret body + top plate + commander cupola + red crest
	_draw_bevel_poly(tur, hull.lightened(0.14), Color(0.09, 0.09, 0.09), sway, pivot)
	var tur_deck: Array[Vector2] = [
		Vector2(10.0, -6.5), Vector2(4.5, -10.5), Vector2(-9.0, -10.0),
		Vector2(-12.5, -5.5), Vector2(-12.5, 5.5), Vector2(-9.0, 10.0),
		Vector2(4.5, 10.5), Vector2(10.0, 6.5)
	]
	draw_colored_polygon(_poly(tur_deck, Vector2.ZERO, sway, pivot), hull.lightened(0.21))
	# Red command chevron on turret roof
	var badge: Array[Vector2] = [Vector2(6.0, 0.0), Vector2(-1.5, -6.0), Vector2(-5.5, -6.0), Vector2(1.5, 0.0), Vector2(-5.5, 6.0), Vector2(-1.5, 6.0)]
	draw_colored_polygon(_poly(badge, Vector2.ZERO, sway, pivot), trim)
	# Cupola + secondary AA pintle gun
	draw_circle(_xf(Vector2(-5.5, -4.5), sway, pivot), 3.8, Color(0.20, 0.20, 0.19))
	draw_arc(_xf(Vector2(-5.5, -4.5), sway, pivot), 3.8, 0.0, TAU, 16, Color(0.62, 0.62, 0.58), 1.1, true)
	draw_circle(_xf(Vector2(-5.5, 4.8), sway, pivot), 3.0, Color(0.20, 0.20, 0.19))
	# Glowing red targeting optics
	draw_circle(_xf(Vector2(11.0, 0.0), sway, pivot), 2.2, Color(1.0, 0.26, 0.18, 0.95))

func _draw_chopper(hull: Color, trim: Color) -> void:
	var hover_bob: float = sin(_time * 4.2 + _phase_seed) * 1.4
	var sh := Vector2(24.0 + hover_bob, 28.0 + hover_bob)

	var fuselage: Array[Vector2] = [
		Vector2(19.5, 0.0), Vector2(12.5, 4.6), Vector2(2.0, 5.6),
		Vector2(-7.0, 4.4), Vector2(-23.0, 1.8), Vector2(-24.5, 0.0),
		Vector2(-23.0, -1.8), Vector2(-7.0, -4.4), Vector2(2.0, -5.6),
		Vector2(12.5, -4.6)
	]
	var stub_wings: Array[Vector2] = [
		Vector2(5.5, -15.5), Vector2(1.5, -16.5), Vector2(-3.5, -15.0),
		Vector2(-3.5, 15.0), Vector2(1.5, 16.5), Vector2(5.5, 15.5)
	]
	var tail_stab: Array[Vector2] = [
		Vector2(-19.5, -6.5), Vector2(-22.5, -6.5), Vector2(-22.5, 6.5), Vector2(-19.5, 6.5)
	]

	# High-altitude soft ground shadow
	draw_colored_polygon(_poly(fuselage, sh), Color(0.0, 0.0, 0.0, 0.22))
	draw_colored_polygon(_poly(stub_wings, sh), Color(0.0, 0.0, 0.0, 0.22))
	draw_colored_polygon(_poly(tail_stab, sh), Color(0.0, 0.0, 0.0, 0.20))
	draw_circle(sh, 19.5, Color(0.0, 0.0, 0.0, 0.09))

	# Chin sensor turret & autocannon peeking out front
	draw_line(_xf(Vector2(16.0, 0.0)), _xf(Vector2(24.0, 0.0)), Color(0.14, 0.15, 0.16), 2.2, true)
	draw_circle(_xf(Vector2(17.5, 0.0)), 2.5, Color(0.20, 0.22, 0.24))

	# Stub wings + visible rocket pods & Hellfire missiles
	_draw_bevel_poly(stub_wings, trim.lightened(0.06), Color(0.10, 0.12, 0.14))
	for side: float in [-1.0, 1.0]:
		# Rocket pod
		var pod: Array[Vector2] = [
			Vector2(7.0, side * 9.5 - 2.0), Vector2(7.0, side * 9.5 + 2.0),
			Vector2(-2.5, side * 9.5 + 2.0), Vector2(-2.5, side * 9.5 - 2.0)
		]
		draw_colored_polygon(_poly(pod), Color(0.20, 0.22, 0.23))
		draw_circle(_xf(Vector2(7.2, side * 9.5)), 1.6, Color(0.75, 0.34, 0.20))
		# Outer missile rail
		draw_line(_xf(Vector2(-1.5, side * 14.2)), _xf(Vector2(8.0, side * 14.2)), Color(0.78, 0.80, 0.82), 1.8, true)
		draw_circle(_xf(Vector2(8.2, side * 14.2)), 1.2, Color(0.92, 0.28, 0.22))

	# Tail stabilizer & main armored fuselage
	_draw_bevel_poly(tail_stab, trim, Color(0.10, 0.12, 0.14))
	_draw_bevel_poly(fuselage, hull, Color(0.12, 0.14, 0.16))

	# Twin side turbine nacelles + exhaust ports
	for side: float in [-1.0, 1.0]:
		var nac: Array[Vector2] = [
			Vector2(5.0, side * 5.6 - 2.2), Vector2(5.0, side * 5.6 + 2.2),
			Vector2(-7.5, side * 5.6 + 2.2), Vector2(-7.5, side * 5.6 - 2.2)
		]
		_draw_bevel_poly(nac, hull.lightened(0.10), Color(0.11, 0.13, 0.15))
		draw_circle(_xf(Vector2(-7.8, side * 5.6)), 1.8, Color(0.08, 0.08, 0.08))

	# Tandem armored cockpit glass canopy with sky reflection
	var canopy: Array[Vector2] = [
		Vector2(15.5, 0.0), Vector2(11.5, 3.0), Vector2(3.5, 3.0),
		Vector2(2.0, 0.0), Vector2(3.5, -3.0), Vector2(11.5, -3.0)
	]
	draw_colored_polygon(_poly(canopy), Color(0.14, 0.28, 0.36, 0.96))
	draw_line(_xf(Vector2(13.8, -0.8)), _xf(Vector2(5.5, -1.8)), Color(0.66, 0.90, 0.98, 0.80), 1.6, true)
	# Canopy frame bar
	draw_line(_xf(Vector2(8.8, -2.8)), _xf(Vector2(8.8, 2.8)), Color(0.16, 0.19, 0.21), 1.3, true)

	# Wingtip navigation lights (port red, starboard green)
	var strobe: float = 0.55 + 0.45 * sin(_time * 9.0 + _phase_seed)
	draw_circle(_xf(Vector2(2.5, -16.0)), 1.6, Color(1.0, 0.22, 0.18, strobe))
	draw_circle(_xf(Vector2(2.5, 16.0)), 1.6, Color(0.24, 1.0, 0.42, strobe))

	# Spinning tail rotor blur
	var tail_pos := _xf(Vector2(-23.0, 2.5))
	draw_line(tail_pos - Vector2.from_angle(_rotor_angle * 1.4) * 5.0, tail_pos + Vector2.from_angle(_rotor_angle * 1.4) * 5.0, Color(0.18, 0.20, 0.22, 0.72), 1.6, true)

	# Motion-blurred main rotor disc + 4 composite blades with yellow safety tips
	draw_circle(Vector2.ZERO, 21.0, Color(0.14, 0.17, 0.20, 0.18))
	draw_arc(Vector2.ZERO, 20.5, 0.0, TAU, 36, Color(0.75, 0.80, 0.82, 0.14), 1.4, true)
	for b in range(4):
		var a: float = _rotor_angle + float(b) * (PI * 0.5)
		var bd := Vector2.from_angle(a)
		draw_line(bd * 3.0, bd * 21.5, Color(0.10, 0.11, 0.13, 0.86), 2.5, true)
		draw_line(bd * 18.0, bd * 21.5, Color(0.92, 0.78, 0.22, 0.82), 2.2, true)
	# Mast hub cap
	draw_circle(Vector2.ZERO, 3.8, Color(0.22, 0.25, 0.28))
	draw_circle(Vector2.ZERO, 1.6, Color(0.55, 0.60, 0.64))

func _draw_bomber(hull: Color, trim: Color) -> void:
	var sh := Vector2(32.0, 36.0)
	var wing_body: Array[Vector2] = [
		Vector2(27.0, 0.0), Vector2(14.0, 4.8), Vector2(4.0, 7.2),
		Vector2(-6.5, 26.5), Vector2(-13.5, 26.5), Vector2(-11.0, 8.5),
		Vector2(-22.0, 14.5), Vector2(-25.5, 13.5), Vector2(-23.0, 5.2),
		Vector2(-20.0, 0.0), Vector2(-23.0, -5.2), Vector2(-25.5, -13.5),
		Vector2(-22.0, -14.5), Vector2(-11.0, -8.5), Vector2(-13.5, -26.5),
		Vector2(-6.5, -26.5), Vector2(4.0, -7.2), Vector2(14.0, -4.8)
	]

	# Altitude shadow
	draw_colored_polygon(_poly(wing_body, sh), Color(0.0, 0.0, 0.0, 0.22))

	# Pulsing twin afterburner flames (outer orange + inner blue-white shock cone)
	var burn: float = 0.82 + 0.28 * sin(_time * 34.0 + _phase_seed)
	for side: float in [-1.0, 1.0]:
		var ey: float = side * 3.8
		var flame_outer: Array[Vector2] = [
			Vector2(-21.0, ey - 2.4), Vector2(-21.0, ey + 2.4), Vector2(-21.0 - 13.5 * burn, ey)
		]
		var flame_inner: Array[Vector2] = [
			Vector2(-21.0, ey - 1.3), Vector2(-21.0, ey + 1.3), Vector2(-21.0 - 7.5 * burn, ey)
		]
		draw_colored_polygon(_poly(flame_outer), Color(1.0, 0.52, 0.14, 0.88))
		draw_colored_polygon(_poly(flame_inner), Color(0.82, 0.94, 1.0, 0.94))

	# Main airframe with sharp military outline
	_draw_bevel_poly(wing_body, hull, Color(0.10, 0.12, 0.15))

	# Splinter camouflage panels on wings
	var camo_l: Array[Vector2] = [Vector2(2.0, -8.0), Vector2(-5.5, -22.0), Vector2(-11.0, -21.0), Vector2(-6.0, -8.0)]
	var camo_r: Array[Vector2] = [Vector2(2.0, 8.0), Vector2(-5.5, 22.0), Vector2(-11.0, 21.0), Vector2(-6.0, 8.0)]
	draw_colored_polygon(_poly(camo_l), hull.lightened(0.11))
	draw_colored_polygon(_poly(camo_r), hull.darkened(0.18))

	# Fuselage center spine & twin engine fairings
	var spine: Array[Vector2] = [Vector2(22.0, 0.0), Vector2(6.0, 4.2), Vector2(-19.5, 4.8), Vector2(-19.5, -4.8), Vector2(6.0, -4.2)]
	draw_colored_polygon(_poly(spine), hull.lightened(0.14))

	# Wing panel seams, flap hinges, and underwing ordnance pylons
	for side: float in [-1.0, 1.0]:
		draw_line(_xf(Vector2(-10.5, side * 9.5)), _xf(Vector2(-12.2, side * 24.5)), Color(0.12, 0.15, 0.18, 0.85), 1.2, true)
		draw_line(_xf(Vector2(1.0, side * 12.0)), _xf(Vector2(-7.5, side * 12.0)), trim, 2.8, true)
		draw_line(_xf(Vector2(-1.5, side * 18.0)), _xf(Vector2(-9.5, side * 18.0)), trim, 2.4, true)
		# Red/amber tactical wing roundel bar
		draw_line(_xf(Vector2(-5.0, side * 19.5)), _xf(Vector2(-9.5, side * 19.5)), Color(0.86, 0.30, 0.22, 0.85), 2.4, true)
		# Twin canted vertical tail stabilizers
		draw_line(_xf(Vector2(-14.5, side * 4.5)), _xf(Vector2(-23.5, side * 6.5)), hull.lightened(0.24), 2.4, true)

	# Tinted gold-cyan stealth canopy with specular glare
	var canopy: Array[Vector2] = [
		Vector2(18.5, 0.0), Vector2(13.0, 2.6), Vector2(5.5, 2.4),
		Vector2(3.0, 0.0), Vector2(5.5, -2.4), Vector2(13.0, -2.6)
	]
	draw_colored_polygon(_poly(canopy), Color(0.18, 0.34, 0.42, 0.96))
	draw_line(_xf(Vector2(16.2, -0.7)), _xf(Vector2(7.2, -1.3)), Color(0.76, 0.94, 1.0, 0.82), 1.7, true)

	# Wingtip nav strobes
	var strobe: float = 0.5 + 0.5 * sin(_time * 11.0 + _phase_seed)
	draw_circle(_xf(Vector2(-9.5, -26.2)), 1.8, Color(1.0, 0.24, 0.20, strobe))
	draw_circle(_xf(Vector2(-9.5, 26.2)), 1.8, Color(0.24, 1.0, 0.45, strobe))

func _draw_aps_tank(hull: Color, trim: Color) -> void:
	# Trophy APS Advanced Main Battle Tank with active radar panels & reactive hull
	var sh := Vector2(6.2, 7.2)
	var footprint: Array[Vector2] = [
		Vector2(20.0, -14.2), Vector2(20.0, 14.2), Vector2(-20.0, 14.2), Vector2(-20.0, -14.2)
	]
	draw_colored_polygon(_poly(footprint, Vector2(1.8, 2.0)), Color(0.0, 0.0, 0.0, 0.50))
	draw_colored_polygon(_poly(footprint, sh), Color(0.0, 0.0, 0.0, 0.34))

	_draw_treads(20.5, 8.6, 14.2, 4.2)

	# Composite spaced side skirts with cyan APS emitter strips
	for side: float in [-1.0, 1.0]:
		var y0: float = side * 8.6
		var y1: float = side * 13.0
		var skirt: Array[Vector2] = [
			Vector2(18.0, minf(y0, y1)), Vector2(18.0, maxf(y0, y1)),
			Vector2(-17.5, maxf(y0, y1)), Vector2(-17.5, minf(y0, y1))
		]
		_draw_bevel_poly(skirt, hull.darkened(0.16), Color(0.09, 0.12, 0.14))
		draw_line(_xf(Vector2(11.0, side * 11.0)), _xf(Vector2(-9.0, side * 11.0)), Color(trim.r, trim.g, trim.b, 0.72 if shield > 0.0 else 0.24), 1.6, true)

	# Angular stealth-faceted MBT hull
	var core: Array[Vector2] = [
		Vector2(19.5, -8.5), Vector2(14.0, -9.8), Vector2(-18.5, -9.5),
		Vector2(-18.5, 9.5), Vector2(14.0, 9.8), Vector2(19.5, 8.5)
	]
	_draw_bevel_poly(core, hull, Color(0.10, 0.13, 0.15))

	# Front glacis & cyan tactical trim
	var glacis: Array[Vector2] = [Vector2(18.8, -7.8), Vector2(11.5, -8.6), Vector2(11.5, 8.6), Vector2(18.8, 7.8)]
	draw_colored_polygon(_poly(glacis), hull.lightened(0.14))
	draw_line(_xf(Vector2(14.5, -7.5)), _xf(Vector2(14.5, 7.5)), trim, 1.8, true)

	# Scanning wedge turret with Trophy APS radar array & smoothbore barrel
	var sway: float = sin(_time * 1.55 + _phase_seed) * 0.20
	var pivot := Vector2(1.5, 0.0)
	var tur: Array[Vector2] = [
		Vector2(13.0, -5.0), Vector2(5.5, -10.5), Vector2(-8.0, -9.8),
		Vector2(-12.0, -5.8), Vector2(-12.0, 5.8), Vector2(-8.0, 9.8),
		Vector2(5.5, 10.5), Vector2(13.0, 5.0)
	]
	draw_colored_polygon(_poly(tur, Vector2(2.6, 3.0), sway, pivot), Color(0.0, 0.0, 0.0, 0.36))

	# Rail-shrouded heavy main gun
	draw_line(_xf(Vector2(5.0, 0.0), sway, pivot), _xf(Vector2(29.5, 0.0), sway, pivot), Color(0.10, 0.12, 0.14), 5.4, true)
	draw_line(_xf(Vector2(5.0, 0.0), sway, pivot), _xf(Vector2(28.5, 0.0), sway, pivot), hull.lightened(0.22), 2.8, true)
	draw_line(_xf(Vector2(15.0, 0.0), sway, pivot), _xf(Vector2(21.5, 0.0), sway, pivot), Color(0.16, 0.22, 0.26), 6.4, true)

	_draw_bevel_poly(tur, hull.lightened(0.12), Color(0.09, 0.12, 0.14), sway, pivot)
	# Twin angled Trophy APS radar launchers on turret cheeks
	for side: float in [-1.0, 1.0]:
		var rad_box: Array[Vector2] = [
			Vector2(2.5, side * 9.5), Vector2(2.5, side * 12.6),
			Vector2(-4.5, side * 12.6), Vector2(-4.5, side * 9.5)
		]
		_draw_bevel_poly(rad_box, Color(0.20, 0.26, 0.30), Color(0.08, 0.10, 0.12), sway, pivot)
		draw_circle(_xf(Vector2(-1.0, side * 11.0), sway, pivot), 1.8, trim if shield > 0.0 else Color(0.32, 0.36, 0.38))

	# Central APS core emitter dome
	var core_glow: float = 0.65 + 0.35 * sin(_time * 8.0 + _phase_seed)
	draw_circle(_xf(Vector2(-2.0, 0.0), sway, pivot), 4.6, Color(0.12, 0.18, 0.22))
	draw_circle(_xf(Vector2(-2.0, 0.0), sway, pivot), 2.8, Color(trim.r, trim.g, trim.b, (0.85 * core_glow) if shield > 0.0 else 0.25))

func _draw_uav_carrier(hull: Color, trim: Color) -> void:
	# Mobile 6x6 Armored UAV Launch Truck with catapult rails & stowed Shahed drones
	var sh := Vector2(5.2, 6.0)
	var body: Array[Vector2] = [
		Vector2(18.5, -7.8), Vector2(15.0, -9.6), Vector2(-19.0, -9.6),
		Vector2(-19.5, -7.5), Vector2(-19.5, 7.5), Vector2(-19.0, 9.6),
		Vector2(15.0, 9.6), Vector2(18.5, 7.8)
	]
	draw_colored_polygon(_poly(body, Vector2(1.4, 1.8)), Color(0.0, 0.0, 0.0, 0.46))
	draw_colored_polygon(_poly(body, sh), Color(0.0, 0.0, 0.0, 0.32))

	# 6 heavy off-road truck tires
	for wx: float in [-13.0, -3.5, 11.5]:
		for wy: float in [-10.2, 10.2]:
			var wbox: Array[Vector2] = [
				Vector2(wx + 3.4, wy - 1.9), Vector2(wx + 3.4, wy + 1.9),
				Vector2(wx - 3.4, wy + 1.9), Vector2(wx - 3.4, wy - 1.9)
			]
			draw_colored_polygon(_poly(wbox), Color(0.08, 0.08, 0.08))
			draw_line(_xf(Vector2(wx - 1.4, wy)), _xf(Vector2(wx + 1.4, wy)), Color(0.28, 0.30, 0.26), 1.2, true)

	_draw_bevel_poly(body, hull, Color(0.12, 0.14, 0.11))

	# Forward armored truck cab + windshield
	var cab: Array[Vector2] = [Vector2(17.8, -7.2), Vector2(17.8, 7.2), Vector2(7.0, 8.2), Vector2(7.0, -8.2)]
	_draw_bevel_poly(cab, hull.lightened(0.10), Color(0.12, 0.14, 0.11))
	draw_line(_xf(Vector2(15.2, -5.6)), _xf(Vector2(15.2, 5.6)), Color(0.36, 0.58, 0.66, 0.92), 2.8, true)

	# Rear armored UAV canister rack & launch rail
	var bay: Array[Vector2] = [Vector2(5.5, -8.5), Vector2(5.5, 8.5), Vector2(-18.2, 8.5), Vector2(-18.2, -8.5)]
	_draw_bevel_poly(bay, Color(0.20, 0.23, 0.20), Color(0.10, 0.11, 0.10))
	# Amber drone-bay warning chevrons
	draw_line(_xf(Vector2(4.2, -7.5)), _xf(Vector2(4.2, 7.5)), trim, 2.2, true)
	draw_line(_xf(Vector2(-17.0, -7.5)), _xf(Vector2(-17.0, 7.5)), trim, 2.2, true)

	# Visible stowed delta-wing drones on launch rails (remaining count!)
	var drones_left: int = maxi(0, _uav_max_spawns - _uav_spawned)
	for side: float in [-1.0, 1.0]:
		draw_line(_xf(Vector2(-15.5, side * 4.4)), _xf(Vector2(2.5, side * 4.4)), Color(0.42, 0.46, 0.40), 1.6, true)
	if drones_left > 0:
		var pulse: float = 0.55 + 0.45 * sin(_time * 9.0 + _phase_seed)
		for slot_y: float in [-4.4, 4.4]:
			if slot_y > 0.0 and drones_left < 2:
				continue
			var mini: Array[Vector2] = [
				Vector2(1.5, slot_y), Vector2(-7.5, slot_y - 3.2),
				Vector2(-5.5, slot_y), Vector2(-7.5, slot_y + 3.2)
			]
			_draw_bevel_poly(mini, Color(0.46, 0.48, 0.44), Color(0.14, 0.14, 0.12))
			draw_circle(_xf(Vector2(1.0, slot_y)), 1.3, Color(1.0, 0.42, 0.18, pulse))

	# Spin-scanning telemetry antenna on cab roof
	var ant_p := _xf(Vector2(10.5, -4.5))
	draw_circle(ant_p, 2.4, Color(0.14, 0.16, 0.14))
	draw_line(ant_p, ant_p + Vector2.from_angle(_time * 4.0) * 5.2, trim, 1.5, true)

func _draw_fpv_drone(hull: Color, trim: Color) -> void:
	# Compact fast Shahed-style delta-wing loitering munition
	var sh := Vector2(16.0, 20.0)
	var delta_wing: Array[Vector2] = [
		Vector2(11.5, 0.0), Vector2(-7.5, 10.2), Vector2(-9.5, 9.2),
		Vector2(-6.5, 2.2), Vector2(-9.0, 0.0), Vector2(-6.5, -2.2),
		Vector2(-9.5, -9.2), Vector2(-7.5, -10.2)
	]
	draw_colored_polygon(_poly(delta_wing, sh), Color(0.0, 0.0, 0.0, 0.18))
	_draw_bevel_poly(delta_wing, hull, Color(0.10, 0.11, 0.10))
	# Red warhead nosecone & wingtip fins
	var nose: Array[Vector2] = [Vector2(11.5, 0.0), Vector2(4.5, 2.4), Vector2(4.5, -2.4)]
	draw_colored_polygon(_poly(nose), trim)
	# Rear pusher-prop blur
	var prop_s: float = 4.2 * sin(_rotor_angle * 1.8)
	draw_line(_xf(Vector2(-9.8, -prop_s)), _xf(Vector2(-9.8, prop_s)), Color(0.84, 0.86, 0.84, 0.8), 1.6, true)

func _draw_sky_fortress(hull: Color, trim: Color) -> void:
	# Massive Heavy Twin-Rotor Airborne Assault Gunship (Air Boss!)
	var hover_bob: float = sin(_time * 3.0 + _phase_seed) * 1.6
	var sh := Vector2(34.0 + hover_bob, 38.0 + hover_bob)

	var fuselage: Array[Vector2] = [
		Vector2(30.0, 0.0), Vector2(21.0, 7.8), Vector2(6.0, 10.5),
		Vector2(-14.0, 9.8), Vector2(-29.0, 6.2), Vector2(-32.0, 0.0),
		Vector2(-29.0, -6.2), Vector2(-14.0, -9.8), Vector2(6.0, -10.5),
		Vector2(21.0, -7.8)
	]
	var heavy_wings: Array[Vector2] = [
		Vector2(10.0, -28.0), Vector2(1.0, -29.5), Vector2(-9.0, -26.0),
		Vector2(-9.0, 26.0), Vector2(1.0, 29.5), Vector2(10.0, 28.0)
	]

	# High-altitude cast shadow
	draw_colored_polygon(_poly(fuselage, sh), Color(0.0, 0.0, 0.0, 0.24))
	draw_colored_polygon(_poly(heavy_wings, sh), Color(0.0, 0.0, 0.0, 0.22))

	# Heavy armored gunship stub wings with underwing pods & crimson stripes
	_draw_bevel_poly(heavy_wings, hull.darkened(0.14), Color(0.09, 0.10, 0.12))
	for side: float in [-1.0, 1.0]:
		draw_line(_xf(Vector2(4.0, side * 18.0)), _xf(Vector2(-5.5, side * 18.0)), trim, 3.6, true)
		# Heavy side autocannon barrels
		draw_line(_xf(Vector2(6.0, side * 13.0)), _xf(Vector2(19.0, side * 13.0)), Color(0.12, 0.13, 0.14), 3.4, true)
		draw_line(_xf(Vector2(6.0, side * 13.0)), _xf(Vector2(18.0, side * 13.0)), Color(0.55, 0.58, 0.62), 1.6, true)

	# Armored heavy fuselage + dorsal spine + rear jet thrusters
	_draw_bevel_poly(fuselage, hull, Color(0.09, 0.11, 0.13))
	var spine: Array[Vector2] = [
		Vector2(22.0, 0.0), Vector2(10.0, 6.5), Vector2(-22.0, 6.2),
		Vector2(-26.0, 0.0), Vector2(-22.0, -6.2), Vector2(10.0, -6.5)
	]
	_draw_bevel_poly(spine, hull.lightened(0.11), Color(0.12, 0.14, 0.17))

	# Crimson boss command chevron + armored cockpit glass
	var chev: Array[Vector2] = [Vector2(12.0, 0.0), Vector2(3.0, -6.2), Vector2(-1.0, -6.2), Vector2(7.0, 0.0), Vector2(-1.0, 6.2), Vector2(3.0, 6.2)]
	draw_colored_polygon(_poly(chev), trim)
	var canopy: Array[Vector2] = [
		Vector2(24.5, 0.0), Vector2(18.5, 4.4), Vector2(12.0, 3.8),
		Vector2(10.5, 0.0), Vector2(12.0, -3.8), Vector2(18.5, -4.4)
	]
	draw_colored_polygon(_poly(canopy), Color(0.16, 0.30, 0.40, 0.96))
	draw_line(_xf(Vector2(22.0, -1.2)), _xf(Vector2(14.0, -2.2)), Color(0.76, 0.94, 1.0, 0.82), 1.8, true)

	# Glowing twin rear exhaust flames
	var burn: float = 0.78 + 0.25 * sin(_time * 28.0 + _phase_seed)
	for side: float in [-1.0, 1.0]:
		var exhaust: Array[Vector2] = [
			Vector2(-29.0, side * 4.5 - 2.2), Vector2(-29.0, side * 4.5 + 2.2), Vector2(-29.0 - 11.5 * burn, side * 4.5)
		]
		draw_colored_polygon(_poly(exhaust), Color(1.0, 0.48, 0.14, 0.85))

	# Giant twin counter-rotating tilt-rotors mounted on wingtips!
	for side: float in [-1.0, 1.0]:
		var hub: Vector2 = _xf(Vector2(1.5, side * 26.0))
		draw_circle(hub, 17.5, Color(0.14, 0.17, 0.20, 0.16))
		draw_arc(hub, 17.2, 0.0, TAU, 32, Color(0.72, 0.78, 0.82, 0.20), 1.4, true)
		var dir_sign: float = 1.0 if side > 0.0 else -1.0
		for b in range(4):
			var a: float = _rotor_angle * dir_sign + float(b) * (PI * 0.5)
			var bd := Vector2.from_angle(a)
			draw_line(hub + bd * 2.5, hub + bd * 17.8, Color(0.10, 0.11, 0.13, 0.86), 2.5, true)
			draw_line(hub + bd * 14.5, hub + bd * 17.8, Color(0.95, 0.76, 0.22, 0.86), 2.2, true)
		draw_circle(hub, 4.2, Color(0.22, 0.25, 0.28))
		draw_circle(hub, 1.8, trim)

func _draw_damage_and_status() -> void:
	var hp_ratio: float = hp / maxf(1.0, max_hp)
	if not festive_mode:
		# Scorched battle damage & flickering fire core at low HP
		if hp_ratio < 0.62:
			draw_circle(_xf(Vector2(-4.0, 1.5)), hit_radius * 0.34, Color(0.05, 0.04, 0.03, 0.45))
		if hp_ratio < 0.35:
			var flick: float = 0.65 + 0.35 * sin(_time * 24.0 + _phase_seed)
			draw_circle(_xf(Vector2(-4.0, 1.5)), hit_radius * 0.22 * flick, Color(1.0, 0.46, 0.10, 0.85))
			draw_circle(_xf(Vector2(-4.0, 1.5)), hit_radius * 0.11 * flick, Color(1.0, 0.92, 0.55, 0.92))
	elif hp_ratio < 0.45:
		# Overwound clockwork golden sparkle jitter when nearly ready to re-wrap!
		var flick: float = 0.55 + 0.45 * sin(_time * 28.0 + _phase_seed)
		draw_circle(_xf(Vector2(-2.0, 0.0)), hit_radius * 0.20 * flick, Color(1.0, 0.92, 0.40, 0.78))

	# Cryo frost crystalline ring overlay
	if slow_timer > 0.0:
		draw_arc(Vector2.ZERO, hit_radius + 2.0, 0.0, TAU, 24, Color(0.50, 0.92, 1.0, 0.68), 1.6, true)

	# Trophy APS Active Protection electromagnetic intercept dome
	if max_shield > 0.0 and shield > 0.0:
		var s_ratio: float = clampf(shield / maxf(1.0, max_shield), 0.0, 1.0)
		var pulse: float = 0.72 + 0.28 * sin(_time * 7.0 + _phase_seed)
		var dome_r: float = hit_radius + 5.5
		var flash_boost: float = clampf(_shield_flash / 0.16, 0.0, 1.0)
		var fill_a: float = (0.09 + 0.08 * s_ratio) * pulse + flash_boost * 0.24
		var edge_a: float = (0.45 + 0.42 * s_ratio) * pulse + flash_boost * 0.35
		draw_circle(Vector2.ZERO, dome_r, Color(0.24, 0.84, 1.0, fill_a))
		draw_arc(Vector2.ZERO, dome_r, 0.0, TAU, 32, Color(0.42, 0.92, 1.0, minf(1.0, edge_a)), 1.9 + flash_boost * 1.4, true)
		# Rotating APS radar intercept arcs
		for i in range(3):
			var a: float = _time * 2.1 + float(i) * (TAU / 3.0)
			draw_arc(Vector2.ZERO, dome_r + 2.5, a, a + 0.42, 6, Color(0.72, 0.96, 1.0, 0.72 * s_ratio), 1.5, true)

func _draw_health_bar() -> void:
	var is_boss: bool = (enemy_type == EnemyData.EnemyType.JUGGERNAUT or enemy_type == EnemyData.EnemyType.SKY_FORTRESS)
	var has_shield_vis: bool = (max_shield > 0.0 and (shield > 0.0 or shield < max_shield))
	if hp >= max_hp and not is_boss and not has_shield_vis:
		return
	var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	var bar_w: float = 48.0 if is_boss else 30.0
	var bar_h: float = 5.2 if is_boss else 3.8
	var bar_pos := Vector2(-bar_w * 0.5, -hit_radius - 13.0)

	# Sleek beveled dark steel frame
	draw_rect(Rect2(bar_pos - Vector2(1.5, 1.5), Vector2(bar_w + 3.0, bar_h + 3.0)), Color(0.04, 0.05, 0.04, 0.92))
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.14, 0.15, 0.14, 0.85))
	var fill_col := Color(0.32, 0.90, 0.42)
	if ratio < 0.32:
		fill_col = Color(0.96, 0.24, 0.20)
	elif ratio < 0.62:
		fill_col = Color(0.96, 0.74, 0.22)
	draw_rect(Rect2(bar_pos, Vector2(bar_w * ratio, bar_h)), fill_col)
	# Subtle top highlight sheen on HP bar
	draw_rect(Rect2(bar_pos, Vector2(bar_w * ratio, bar_h * 0.35)), Color(1.0, 1.0, 1.0, 0.22))

	# Cyan APS Shield bar stacked right above HP bar
	if max_shield > 0.0:
		var s_ratio: float = clampf(shield / maxf(1.0, max_shield), 0.0, 1.0)
		var s_pos := bar_pos + Vector2(0.0, -4.6)
		draw_rect(Rect2(s_pos - Vector2(1.2, 1.2), Vector2(bar_w + 2.4, 5.0)), Color(0.03, 0.06, 0.08, 0.90))
		draw_rect(Rect2(s_pos, Vector2(bar_w, 2.6)), Color(0.10, 0.18, 0.22, 0.85))
		if s_ratio > 0.0:
			draw_rect(Rect2(s_pos, Vector2(bar_w * s_ratio, 2.6)), Color(0.32, 0.88, 1.0, 0.96))

	if slow_timer > 0.0:
		draw_rect(Rect2(bar_pos + Vector2(0.0, bar_h + 1.8), Vector2(bar_w * clampf(slow_timer / 3.0, 0.15, 1.0), 1.8)), Color(0.42, 0.88, 1.0, 0.92))

func _compute_path_length(pts: PackedVector2Array) -> float:
	var total: float = 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	return maxf(1.0, total)

# ==============================================================================
# SECRET CHRISTMAS LEVEL — RUNAWAY CLOCKWORK TOY RENDERERS
# ==============================================================================

func _tint_toy(c: Color) -> Color:
	var out: Color = c
	if slow_timer > 0.0:
		out = out.lerp(Color(0.45, 0.86, 1.0), 0.36)
	if hit_flash > 0.0:
		out = out.lerp(Color(1.0, 0.98, 0.86), 0.55)
	return out

func _draw_windup_key(local_pos: Vector2, key_scale: float = 1.0) -> void:
	var spin: float = sin(_time * 11.0 + _phase_seed)
	var span: float = 6.2 * key_scale * absf(spin)
	var center := _xf(local_pos)
	var perp := Vector2.from_angle(heading + PI * 0.5)
	var gold := Color(0.96, 0.80, 0.24)
	var gold_dark := Color(0.58, 0.42, 0.08)
	draw_line(center - perp * span, center + perp * span, gold_dark, 4.2 * key_scale, true)
	draw_line(center - perp * span, center + perp * span, gold, 2.4 * key_scale, true)
	draw_circle(center - perp * span, 2.2 * key_scale, gold)
	draw_circle(center + perp * span, 2.2 * key_scale, gold)
	draw_circle(center, 2.2 * key_scale, gold_dark)
	draw_circle(center, 1.3 * key_scale, Color(1.0, 0.94, 0.58))

func _draw_toy_roadster() -> void:
	# Wind-Up Tin Toy Racing Car
	var red := _tint_toy(Color(0.88, 0.15, 0.18))
	var cream := _tint_toy(Color(0.96, 0.94, 0.88))
	var gold := Color(0.96, 0.78, 0.24)
	var body: Array[Vector2] = [
		Vector2(13.5, -4.5), Vector2(9.5, -6.8), Vector2(-11.0, -6.8),
		Vector2(-13.0, -4.8), Vector2(-13.0, 4.8), Vector2(-11.0, 6.8),
		Vector2(9.5, 6.8), Vector2(13.5, 4.5)
	]
	draw_colored_polygon(_poly(body, Vector2(3.5, 4.2)), Color(0.06, 0.12, 0.22, 0.36))
	# Chunky painted toy wheels with brass hubcaps
	for wx: float in [-7.5, 7.2]:
		for wy: float in [-7.6, 7.6]:
			var wbox: Array[Vector2] = [
				Vector2(wx + 3.0, wy - 1.8), Vector2(wx + 3.0, wy + 1.8),
				Vector2(wx - 3.0, wy + 1.8), Vector2(wx - 3.0, wy - 1.8)
			]
			draw_colored_polygon(_poly(wbox), Color(0.14, 0.12, 0.12))
			draw_circle(_xf(Vector2(wx, wy)), 1.3, gold)
	_draw_bevel_poly(body, red, Color(0.36, 0.06, 0.08))
	# White center racing stripe + chrome grille
	var stripe: Array[Vector2] = [Vector2(12.8, -1.8), Vector2(12.8, 1.8), Vector2(-12.4, 1.8), Vector2(-12.4, -1.8)]
	draw_colored_polygon(_poly(stripe), cream)
	# Toy cockpit seat & curved windshield
	var cab: Array[Vector2] = [Vector2(3.5, -4.5), Vector2(3.5, 4.5), Vector2(-5.5, 4.5), Vector2(-5.5, -4.5)]
	_draw_bevel_poly(cab, Color(0.14, 0.56, 0.28), Color(0.08, 0.26, 0.14))
	draw_line(_xf(Vector2(4.0, -4.0)), _xf(Vector2(4.0, 4.0)), Color(0.70, 0.92, 1.0, 0.92), 2.4, true)
	# Shiny brass headlights
	draw_circle(_xf(Vector2(12.6, -4.2)), 1.6, Color(1.0, 0.94, 0.62))
	draw_circle(_xf(Vector2(12.6, 4.2)), 1.6, Color(1.0, 0.94, 0.62))
	# Rapidly spinning golden wind-up key!
	_draw_windup_key(Vector2(-8.8, 0.0), 0.95)

func _draw_toy_train() -> void:
	# Clockwork Festive Steam Locomotive (Choo-Choo Toy Train!)
	var green := _tint_toy(Color(0.12, 0.54, 0.26))
	var red := _tint_toy(Color(0.86, 0.16, 0.18))
	var gold := Color(0.96, 0.80, 0.26)
	var body: Array[Vector2] = [
		Vector2(15.0, -6.5), Vector2(-16.5, -8.5), Vector2(-16.5, 8.5), Vector2(15.0, 6.5)
	]
	draw_colored_polygon(_poly(body, Vector2(4.5, 5.2)), Color(0.06, 0.12, 0.22, 0.38))

	# Golden front cowcatcher
	var cow: Array[Vector2] = [Vector2(21.0, 0.0), Vector2(14.0, -7.2), Vector2(14.0, 7.2)]
	_draw_bevel_poly(cow, gold, Color(0.45, 0.32, 0.06))
	draw_line(_xf(Vector2(19.0, 0.0)), _xf(Vector2(14.5, -4.5)), Color(0.45, 0.32, 0.06), 1.1, true)
	draw_line(_xf(Vector2(19.0, 0.0)), _xf(Vector2(14.5, 4.5)), Color(0.45, 0.32, 0.06), 1.1, true)

	# Red painted wooden wheels along sides
	for wx: float in [-11.0, -2.5, 6.5]:
		for wy: float in [-9.2, 9.2]:
			draw_circle(_xf(Vector2(wx, wy)), 2.8, red)
			draw_circle(_xf(Vector2(wx, wy)), 1.2, gold)

	# Rounded emerald steam boiler front
	var boiler: Array[Vector2] = [Vector2(15.0, -6.4), Vector2(-3.0, -6.8), Vector2(-3.0, 6.8), Vector2(15.0, 6.4)]
	_draw_bevel_poly(boiler, green, Color(0.06, 0.24, 0.12))
	# Brass boiler bands
	for bx: float in [1.5, 6.5, 11.5]:
		draw_line(_xf(Vector2(bx, -6.2)), _xf(Vector2(bx, 6.2)), gold, 1.8, true)
	# Festive red engineer cab at rear
	var cab: Array[Vector2] = [Vector2(-3.0, -8.8), Vector2(-16.5, -8.8), Vector2(-16.5, 8.8), Vector2(-3.0, 8.8)]
	_draw_bevel_poly(cab, red, Color(0.40, 0.08, 0.10))
	var cab_roof: Array[Vector2] = [Vector2(-4.5, -7.0), Vector2(-14.5, -7.0), Vector2(-14.5, 7.0), Vector2(-4.5, 7.0)]
	draw_colored_polygon(_poly(cab_roof), red.lightened(0.18))
	# Brass smokestack + warm headlight
	draw_circle(_xf(Vector2(10.0, 0.0)), 4.0, Color(0.16, 0.16, 0.18))
	draw_arc(_xf(Vector2(10.0, 0.0)), 4.0, 0.0, TAU, 16, gold, 1.8, true)
	draw_circle(_xf(Vector2(15.2, 0.0)), 2.4, Color(1.0, 0.94, 0.56))
	# Spinning clockwork wind-up key on cab roof
	_draw_windup_key(Vector2(-9.5, 0.0), 1.05)

func _draw_toy_nutcracker() -> void:
	# Royal Clockwork Nutcracker Music-Box Tank!
	var crimson := _tint_toy(Color(0.84, 0.14, 0.18))
	var royal_blue := _tint_toy(Color(0.14, 0.28, 0.62))
	var gold := Color(0.96, 0.80, 0.24)
	var white := Color(0.96, 0.96, 0.98)

	var footprint: Array[Vector2] = [
		Vector2(19.0, -13.5), Vector2(19.0, 13.5), Vector2(-19.0, 13.5), Vector2(-19.0, -13.5)
	]
	draw_colored_polygon(_poly(footprint, Vector2(5.5, 6.5)), Color(0.06, 0.12, 0.22, 0.40))

	# Candy-cane striped animated tracks!
	var off: float = fmod(distance_traveled, 6.0)
	for side: float in [-1.0, 1.0]:
		var y0: float = side * 8.4
		var y1: float = side * 13.6
		var tr: Array[Vector2] = [
			Vector2(19.5, minf(y0, y1)), Vector2(19.5, maxf(y0, y1)),
			Vector2(-19.5, maxf(y0, y1)), Vector2(-19.5, minf(y0, y1))
		]
		draw_colored_polygon(_poly(tr), white)
		var x: float = -19.0 + off
		while x < 19.0:
			draw_line(_xf(Vector2(x, minf(y0, y1) + 0.5)), _xf(Vector2(x + 1.5, maxf(y0, y1) - 0.5)), crimson, 2.6, true)
			x += 6.0

	# Royal crimson & navy gilded toy soldier hull
	var hull: Array[Vector2] = [Vector2(18.5, -8.8), Vector2(18.5, 8.8), Vector2(-18.0, 8.8), Vector2(-18.0, -8.8)]
	_draw_bevel_poly(hull, crimson, Color(0.38, 0.06, 0.08))
	# Golden military coat braids across chest
	for bx: float in [11.0, 14.5]:
		draw_line(_xf(Vector2(bx, -7.2)), _xf(Vector2(bx, 7.2)), gold, 2.0, true)
	# Rear royal blue music-box deck
	var rear: Array[Vector2] = [Vector2(-7.5, -7.5), Vector2(-7.5, 7.5), Vector2(-16.5, 7.5), Vector2(-16.5, -7.5)]
	_draw_bevel_poly(rear, royal_blue, Color(0.08, 0.14, 0.34))
	_draw_windup_key(Vector2(-12.5, 0.0), 1.25)

	# Scanning Nutcracker turret with peppermint candy-cane cannon!
	var sway: float = sin(_time * 1.6 + _phase_seed) * 0.24
	var pivot := Vector2(1.5, 0.0)
	# Peppermint candy-cane barrel
	draw_line(_xf(Vector2(5.0, 0.0), sway, pivot), _xf(Vector2(27.5, 0.0), sway, pivot), white, 5.4, true)
	for sx: float in [8.0, 14.0, 20.0, 25.5]:
		draw_line(_xf(Vector2(sx, 0.0), sway, pivot), _xf(Vector2(sx + 2.8, 0.0), sway, pivot), crimson, 5.2, true)
	draw_circle(_xf(Vector2(27.5, 0.0), sway, pivot), 3.0, gold)

	# Nutcracker gilded turret & golden crown crest
	var tur: Array[Vector2] = [
		Vector2(11.0, -5.5), Vector2(6.0, -9.2), Vector2(-6.0, -8.8),
		Vector2(-9.5, -5.5), Vector2(-9.5, 5.5), Vector2(-6.0, 8.8),
		Vector2(6.0, 9.2), Vector2(11.0, 5.5)
	]
	_draw_bevel_poly(tur, royal_blue, Color(0.08, 0.14, 0.34), sway, pivot)
	# Iconic white Nutcracker mustache across front of turret
	draw_line(_xf(Vector2(8.5, -5.8), sway, pivot), _xf(Vector2(9.8, 0.0), sway, pivot), white, 2.4, true)
	draw_line(_xf(Vector2(8.5, 5.8), sway, pivot), _xf(Vector2(9.8, 0.0), sway, pivot), white, 2.4, true)
	# Golden royal star crown on top
	draw_circle(_xf(Vector2(-1.0, 0.0), sway, pivot), 5.2, gold)
	draw_circle(_xf(Vector2(-1.0, 0.0), sway, pivot), 2.5, crimson)

func _draw_toy_whirlybird() -> void:
	# Wind-Up Wooden/Tin Toy Whirlybird Copter
	var red := _tint_toy(Color(0.90, 0.18, 0.20))
	var green := _tint_toy(Color(0.14, 0.64, 0.30))
	var gold := Color(0.98, 0.82, 0.26)
	var white := Color(0.96, 0.96, 0.98)
	var sh := Vector2(24.0, 28.0)

	var body: Array[Vector2] = [
		Vector2(17.0, 0.0), Vector2(11.0, 6.2), Vector2(-4.0, 5.8),
		Vector2(-21.0, 2.2), Vector2(-21.0, -2.2), Vector2(-4.0, -5.8), Vector2(11.0, -6.2)
	]
	draw_colored_polygon(_poly(body, sh), Color(0.06, 0.12, 0.22, 0.22))
	draw_circle(sh, 18.0, Color(0.06, 0.12, 0.22, 0.10))

	# Festive green tail fin & golden gift-skid runners
	var tail: Array[Vector2] = [Vector2(-17.0, -7.5), Vector2(-22.0, -7.5), Vector2(-22.0, 7.5), Vector2(-17.0, 7.5)]
	_draw_bevel_poly(tail, green, Color(0.06, 0.28, 0.12))
	for side: float in [-1.0, 1.0]:
		draw_line(_xf(Vector2(10.0, side * 9.5)), _xf(Vector2(-8.0, side * 9.5)), gold, 2.2, true)
	_draw_bevel_poly(body, red, Color(0.42, 0.06, 0.08))
	# Gold fuselage belt & glassy toy bubble cockpit
	draw_line(_xf(Vector2(-2.0, -5.6)), _xf(Vector2(-2.0, 5.6)), gold, 2.6, true)
	draw_circle(_xf(Vector2(9.5, 0.0)), 4.6, Color(0.62, 0.90, 1.0, 0.92))
	draw_circle(_xf(Vector2(11.0, -1.5)), 1.8, Color(1.0, 1.0, 1.0, 0.85))

	# Giant spinning candy-cane striped wooden toy rotor!
	draw_circle(Vector2.ZERO, 20.5, Color(1.0, 0.96, 0.90, 0.16))
	for b in range(4):
		var a: float = _rotor_angle + float(b) * (PI * 0.5)
		var bd := Vector2.from_angle(a)
		draw_line(bd * 3.0, bd * 21.0, white, 3.0, true)
		draw_line(bd * 7.0, bd * 12.5, red if (b % 2 == 0) else green, 3.0, true)
		draw_line(bd * 16.5, bd * 21.0, gold, 2.8, true)
	draw_circle(Vector2.ZERO, 4.0, gold)
	draw_circle(Vector2.ZERO, 1.8, red)

func _draw_toy_airship() -> void:
	# Ornate Clockwork Holiday Tin Dirigible / Toy Zeppelin!
	var red := _tint_toy(Color(0.86, 0.16, 0.20))
	var green := _tint_toy(Color(0.14, 0.58, 0.28))
	var gold := Color(0.98, 0.82, 0.28)
	var cream := Color(0.96, 0.93, 0.84)
	var sh := Vector2(30.0, 34.0)

	var hull: Array[Vector2] = [
		Vector2(26.0, 0.0), Vector2(18.0, 8.5), Vector2(4.0, 12.5),
		Vector2(-12.0, 11.2), Vector2(-23.0, 6.0), Vector2(-27.0, 0.0),
		Vector2(-23.0, -6.0), Vector2(-12.0, -11.2), Vector2(4.0, -12.5), Vector2(18.0, -8.5)
	]
	var fins: Array[Vector2] = [
		Vector2(-14.0, -19.5), Vector2(-24.0, -19.5), Vector2(-24.0, 19.5), Vector2(-14.0, 19.5)
	]
	draw_colored_polygon(_poly(hull, sh), Color(0.06, 0.12, 0.22, 0.22))
	draw_colored_polygon(_poly(fins, sh), Color(0.06, 0.12, 0.22, 0.20))

	# Gold-trimmed tail fins & spinning brass rear propeller
	_draw_bevel_poly(fins, green, Color(0.06, 0.26, 0.12))
	var prop_span: float = 8.0 * sin(_rotor_angle * 1.4)
	draw_line(_xf(Vector2(-28.0, -prop_span)), _xf(Vector2(-28.0, prop_span)), gold, 3.0, true)

	# Striped festive balloon envelope
	_draw_bevel_poly(hull, red, Color(0.40, 0.06, 0.08))
	var band1: Array[Vector2] = [Vector2(18.0, -4.5), Vector2(-18.0, -4.5), Vector2(-18.0, 4.5), Vector2(18.0, 4.5)]
	draw_colored_polygon(_poly(band1), cream)
	var band2: Array[Vector2] = [Vector2(21.0, -1.6), Vector2(-21.0, -1.6), Vector2(-21.0, 1.6), Vector2(21.0, 1.6)]
	draw_colored_polygon(_poly(band2), green)
	# Golden nose cone & ornament rings
	draw_circle(_xf(Vector2(25.0, 0.0)), 3.2, gold)
	for rx: float in [-12.0, 0.0, 12.0]:
		draw_line(_xf(Vector2(rx, -10.5)), _xf(Vector2(rx, 10.5)), gold, 1.8, true)
	# Twinkling fairy lights along the sides of the toy zeppelin!
	var light_cols: Array[Color] = [Color(1.0, 0.90, 0.30), Color(0.30, 0.98, 0.55), Color(1.0, 0.32, 0.32), Color(0.45, 0.90, 1.0)]
	for i in range(4):
		var lx: float = lerpf(-14.0, 14.0, float(i) / 3.0)
		var pulse: float = 0.55 + 0.45 * sin(_time * 8.0 + float(i) * 1.6 + _phase_seed)
		var lc: Color = light_cols[i]
		lc.a = pulse
		draw_circle(_xf(Vector2(lx, -10.8)), 2.2, lc)
		draw_circle(_xf(Vector2(lx, 10.8)), 2.2, lc)

func _draw_toy_king_cracker() -> void:
	# KING CRACKER — Giant Clockwork Gingerbread & Nutcracker Toybox Fortress!
	var ginger := _tint_toy(Color(0.68, 0.42, 0.20))
	var crimson := _tint_toy(Color(0.88, 0.14, 0.18))
	var emerald := _tint_toy(Color(0.12, 0.56, 0.28))
	var gold := Color(0.98, 0.82, 0.24)
	var icing := Color(0.98, 0.97, 0.95)

	var footprint: Array[Vector2] = [
		Vector2(27.0, -21.0), Vector2(27.0, 21.0), Vector2(-27.0, 21.0), Vector2(-27.0, -21.0)
	]
	draw_colored_polygon(_poly(footprint, Vector2(7.5, 8.5)), Color(0.06, 0.12, 0.22, 0.44))

	# Animated candy-cane tracks
	var off: float = fmod(distance_traveled, 6.5)
	for side: float in [-1.0, 1.0]:
		var y0: float = side * 12.8
		var y1: float = side * 20.8
		var tr: Array[Vector2] = [
			Vector2(27.0, minf(y0, y1)), Vector2(27.0, maxf(y0, y1)),
			Vector2(-27.0, maxf(y0, y1)), Vector2(-27.0, minf(y0, y1))
		]
		draw_colored_polygon(_poly(tr), icing)
		var x: float = -26.0 + off
		while x < 26.0:
			draw_line(_xf(Vector2(x, minf(y0, y1) + 0.8)), _xf(Vector2(x + 2.0, maxf(y0, y1) - 0.8)), crimson, 3.2, true)
			x += 6.5

	# Gilded gingerbread & royal-crimson fortress hull with white icing border + gumdrops!
	var hull: Array[Vector2] = [
		Vector2(26.0, -13.5), Vector2(26.0, 13.5), Vector2(-25.5, 13.5), Vector2(-25.5, -13.5)
	]
	_draw_bevel_poly(hull, ginger, Color(0.36, 0.20, 0.08))
	# White frosting perimeter trim
	var frost := _poly([Vector2(24.0, -11.5), Vector2(24.0, 11.5), Vector2(-23.5, 11.5), Vector2(-23.5, -11.5), Vector2(24.0, -11.5)])
	draw_polyline(frost, icing, 2.2, true)

	# Colorful gumdrop lights along sides
	var gums: Array[Color] = [crimson, emerald, gold, Color(0.35, 0.84, 1.0)]
	for i in range(4):
		var gx: float = lerpf(-17.0, 18.0, float(i) / 3.0)
		draw_circle(_xf(Vector2(gx, -11.5)), 2.4, gums[i])
		draw_circle(_xf(Vector2(gx, 11.5)), 2.4, gums[3 - i])

	# Giant spinning golden clockwork key at the rear!
	_draw_windup_key(Vector2(-20.0, 0.0), 1.85)

	# Twin peppermint & brass confetti cannons on scanning royal Nutcracker turret
	var sway: float = sin(_time * 1.1 + _phase_seed) * 0.20
	var pivot := Vector2(1.5, 0.0)
	for oy: float in [-6.0, 6.0]:
		draw_line(_xf(Vector2(6.0, oy), sway, pivot), _xf(Vector2(36.0, oy), sway, pivot), icing, 6.6, true)
		for sx: float in [9.0, 15.5, 22.0, 28.5]:
			draw_line(_xf(Vector2(sx, oy), sway, pivot), _xf(Vector2(sx + 3.2, oy), sway, pivot), crimson, 6.4, true)
		draw_circle(_xf(Vector2(36.0, oy), sway, pivot), 3.6, gold)

	var tur: Array[Vector2] = [
		Vector2(14.5, -8.5), Vector2(7.5, -14.0), Vector2(-10.5, -13.5),
		Vector2(-15.0, -8.0), Vector2(-15.0, 8.0), Vector2(-10.5, 13.5),
		Vector2(7.5, 14.0), Vector2(14.5, 8.5)
	]
	_draw_bevel_poly(tur, crimson, Color(0.42, 0.06, 0.08), sway, pivot)
	var inner_tur: Array[Vector2] = [
		Vector2(9.5, -6.0), Vector2(4.0, -10.0), Vector2(-8.5, -9.5),
		Vector2(-11.5, -5.0), Vector2(-11.5, 5.0), Vector2(-8.5, 9.5),
		Vector2(4.0, 10.0), Vector2(9.5, 6.0)
	]
	_draw_bevel_poly(inner_tur, emerald, gold, sway, pivot)
	# Glowing golden 5-pointed star crown on King Cracker's roof!
	var star := PackedVector2Array()
	for s in range(10):
		var sa: float = float(s) * (TAU / 10.0) + _time * 0.8
		var sr: float = 8.2 if (s % 2 == 0) else 3.6
		star.append(_xf(Vector2(-1.0 + cos(sa) * sr, sin(sa) * sr), sway, pivot))
	draw_colored_polygon(star, gold)
	draw_circle(_xf(Vector2(-1.0, 0.0), sway, pivot), 2.8, icing)

func _draw_toy_snowglobe_tank() -> void:
	# Festive Snowglobe Shield Tank (North Pole APS Tank!)
	var ice_blue := _tint_toy(Color(0.24, 0.62, 0.88))
	var crimson := _tint_toy(Color(0.86, 0.16, 0.20))
	var gold := Color(0.98, 0.82, 0.26)
	var white := Color(0.96, 0.98, 1.0)

	var footprint: Array[Vector2] = [Vector2(19.5, -14.0), Vector2(19.5, 14.0), Vector2(-19.5, 14.0), Vector2(-19.5, -14.0)]
	draw_colored_polygon(_poly(footprint, Vector2(5.5, 6.5)), Color(0.06, 0.12, 0.22, 0.38))
	_draw_treads(19.5, 8.5, 13.8, 5.0)

	var hull: Array[Vector2] = [Vector2(19.0, -9.0), Vector2(19.0, 9.0), Vector2(-18.5, 9.0), Vector2(-18.5, -9.0)]
	_draw_bevel_poly(hull, ice_blue, Color(0.10, 0.26, 0.44))
	draw_line(_xf(Vector2(12.0, -8.2)), _xf(Vector2(12.0, 8.2)), gold, 2.2, true)
	draw_line(_xf(Vector2(-12.0, -8.2)), _xf(Vector2(-12.0, 8.2)), crimson, 2.2, true)

	# Glass snowglobe turret dome with swirling snowflakes inside!
	draw_circle(_xf(Vector2(0.0, 0.0)), 10.2, gold)
	draw_circle(_xf(Vector2(0.0, 0.0)), 8.6, Color(0.66, 0.92, 1.0, 0.88))
	for i in range(4):
		var a: float = _time * 3.5 + float(i) * (PI * 0.5)
		draw_circle(_xf(Vector2(cos(a) * 4.5, sin(a) * 4.5)), 1.5, white)
	draw_circle(_xf(Vector2(2.8, -2.8)), 2.2, Color(1.0, 1.0, 1.0, 0.72))
	_draw_windup_key(Vector2(-14.5, 0.0), 1.15)

func _draw_toy_drone_sleigh() -> void:
	# Festive Toy Drone-Launching Sleigh (North Pole UAV Carrier!)
	var crimson := _tint_toy(Color(0.88, 0.14, 0.18))
	var emerald := _tint_toy(Color(0.14, 0.58, 0.28))
	var gold := Color(0.98, 0.82, 0.24)

	var body: Array[Vector2] = [Vector2(18.0, -8.5), Vector2(18.0, 8.5), Vector2(-18.5, 9.5), Vector2(-18.5, -9.5)]
	draw_colored_polygon(_poly(body, Vector2(4.8, 5.4)), Color(0.06, 0.12, 0.22, 0.36))

	# Golden sleigh runners
	for side: float in [-1.0, 1.0]:
		draw_line(_xf(Vector2(21.0, side * 10.2)), _xf(Vector2(-19.0, side * 10.2)), gold, 2.8, true)
		draw_circle(_xf(Vector2(21.0, side * 10.2)), 2.2, gold)

	_draw_bevel_poly(body, crimson, Color(0.42, 0.06, 0.08))
	var deck: Array[Vector2] = [Vector2(9.0, -7.2), Vector2(9.0, 7.2), Vector2(-16.0, 7.2), Vector2(-16.0, -7.2)]
	_draw_bevel_poly(deck, emerald, gold)
	# Toy ornament drone pods sitting in the sleigh bed
	var left: int = maxi(0, _uav_max_spawns - _uav_spawned)
	if left > 0:
		draw_circle(_xf(Vector2(-2.0, -3.5)), 3.2, gold)
		if left > 1:
			draw_circle(_xf(Vector2(-2.0, 3.5)), 3.2, Color(0.38, 0.88, 1.0))
	_draw_windup_key(Vector2(-12.5, 0.0), 1.1)

func _draw_toy_ornament_drone() -> void:
	# Tiny Clockwork Flying Ornament Drone!
	var gold := Color(0.98, 0.82, 0.26)
	var red := _tint_toy(Color(0.94, 0.22, 0.24))
	draw_circle(Vector2(14.0, 18.0), 6.5, Color(0.06, 0.12, 0.22, 0.18))
	var wings: Array[Vector2] = [Vector2(2.0, -9.5), Vector2(-3.0, -9.5), Vector2(-3.0, 9.5), Vector2(2.0, 9.5)]
	_draw_bevel_poly(wings, gold, Color(0.46, 0.32, 0.08))
	draw_circle(Vector2.ZERO, 6.2, red)
	draw_arc(Vector2.ZERO, 6.2, 0.0, TAU, 16, gold, 1.4, true)
	draw_circle(Vector2(-1.8, -1.8), 1.8, Color(1.0, 1.0, 1.0, 0.72))

func _draw_toy_zeppelin_boss() -> void:
	# Giant Royal Holiday Zeppelin Fortress (North Pole Air Boss!)
	var crimson := _tint_toy(Color(0.88, 0.14, 0.18))
	var emerald := _tint_toy(Color(0.12, 0.56, 0.28))
	var gold := Color(0.98, 0.84, 0.28)
	var cream := Color(0.98, 0.95, 0.88)
	var sh := Vector2(34.0, 38.0)

	var hull: Array[Vector2] = [
		Vector2(34.0, 0.0), Vector2(22.0, 12.5), Vector2(4.0, 17.0),
		Vector2(-16.0, 15.0), Vector2(-29.0, 8.0), Vector2(-34.0, 0.0),
		Vector2(-29.0, -8.0), Vector2(-16.0, -15.0), Vector2(4.0, -17.0), Vector2(22.0, -12.5)
	]
	var fins: Array[Vector2] = [Vector2(-16.0, -25.5), Vector2(-28.0, -25.5), Vector2(-28.0, 25.5), Vector2(-16.0, 25.5)]
	draw_colored_polygon(_poly(hull, sh), Color(0.06, 0.12, 0.22, 0.24))
	draw_colored_polygon(_poly(fins, sh), Color(0.06, 0.12, 0.22, 0.20))

	_draw_bevel_poly(fins, emerald, gold)
	_draw_bevel_poly(hull, crimson, Color(0.42, 0.06, 0.08))
	var band: Array[Vector2] = [Vector2(24.0, -5.5), Vector2(-24.0, -5.5), Vector2(-24.0, 5.5), Vector2(24.0, 5.5)]
	draw_colored_polygon(_poly(band), cream)
	for rx: float in [-16.0, -4.0, 8.0, 20.0]:
		draw_line(_xf(Vector2(rx, -14.5)), _xf(Vector2(rx, 14.5)), gold, 2.2, true)
	draw_circle(_xf(Vector2(32.0, 0.0)), 4.5, gold)
	# Twin brass wingtip propellers
	for side: float in [-1.0, 1.0]:
		var hub: Vector2 = _xf(Vector2(0.0, side * 22.0))
		var ps: float = 9.0 * sin(_rotor_angle * 1.4)
		draw_line(hub - Vector2(0.0, ps), hub + Vector2(0.0, ps), gold, 3.2, true)
		draw_circle(hub, 3.2, emerald)
