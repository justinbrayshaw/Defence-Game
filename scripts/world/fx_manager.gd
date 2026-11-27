class_name FxManager
extends Node2D

const MAX_PARTICLES: int = 360
const MAX_RINGS: int = 48

var _particles: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var _flashes: Array[Dictionary] = []
var _texts: Array[Dictionary] = []
var _jets: Array[Dictionary] = []
var _beams: Array[Dictionary] = []
var _pending_fireworks: Array[Dictionary] = []

# Air Strike targeting reticle preview
var airstrike_aiming: bool = false
var airstrike_aim_pos: Vector2 = Vector2.ZERO
var airstrike_radius: float = 125.0

# Hunter Drone manual target assignment reticle
var drone_assign_aiming: bool = false
var drone_assign_pos: Vector2 = Vector2.ZERO
var drone_assign_has_target: bool = false
var drone_assign_target_pos: Vector2 = Vector2.ZERO
var drone_assign_target_radius: float = 18.0
var _time: float = 0.0

func clear_all() -> void:
	_particles.clear()
	_rings.clear()
	_flashes.clear()
	_texts.clear()
	_jets.clear()
	_beams.clear()
	_pending_fireworks.clear()
	airstrike_aiming = false
	drone_assign_aiming = false
	queue_redraw()

func add_beam(from_pos: Vector2, to_pos: Vector2, ramp_u: float, color: Color) -> void:
	_beams.append({
		"from": from_pos,
		"to": to_pos,
		"ramp": clampf(ramp_u, 0.0, 1.0),
		"color": color,
		"fresh": true,
	})
	queue_redraw()

func spawn_shield_break(pos: Vector2, radius: float = 28.0) -> void:
	_rings.append({
		"pos": pos,
		"start_r": radius * 0.45,
		"end_r": radius * 1.9,
		"color": Color(0.38, 0.92, 1.0, 0.92),
		"width": 3.4,
		"age": 0.0,
		"life": 0.30,
	})
	spawn_spark_hit(pos, Color(0.45, 0.94, 1.0), 12)

func spawn_muzzle_flash(pos: Vector2, angle: float, size: float = 12.0, color: Color = Color(1.0, 0.88, 0.45)) -> void:
	_flashes.append({
		"pos": pos,
		"angle": angle,
		"size": size,
		"color": color,
		"age": 0.0,
		"life": 0.075,
	})

func spawn_shell_casing(pos: Vector2, eject_angle: float) -> void:
	if _particles.size() >= MAX_PARTICLES:
		return
	var spd := randf_range(38.0, 74.0)
	var ang := eject_angle + randf_range(-0.35, 0.35)
	_particles.append({
		"pos": pos,
		"vel": Vector2.from_angle(ang) * spd,
		"drag": 4.2,
		"size": 2.4,
		"end_size": 1.8,
		"color": Color(0.95, 0.78, 0.32, 0.95),
		"end_color": Color(0.65, 0.52, 0.22, 0.0),
		"age": 0.0,
		"life": 0.42,
		"shape": "casing",
		"rot": randf_range(0.0, TAU),
		"rot_spd": randf_range(-16.0, 16.0),
	})

func spawn_smoke(pos: Vector2, size: float = 7.0, life: float = 0.55, darkness: float = 0.28) -> void:
	if _particles.size() >= MAX_PARTICLES:
		return
	var drift := Vector2(randf_range(-14.0, 14.0), randf_range(-18.0, -6.0))
	_particles.append({
		"pos": pos + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0)),
		"vel": drift,
		"drag": 1.6,
		"size": size,
		"end_size": size * 2.1,
		"color": Color(darkness, darkness, darkness * 0.96, 0.52),
		"end_color": Color(darkness * 0.85, darkness * 0.85, darkness * 0.85, 0.0),
		"age": 0.0,
		"life": life,
		"shape": "circle",
	})

func spawn_dust(pos: Vector2, size: float = 5.0, life: float = 0.48) -> void:
	if _particles.size() >= MAX_PARTICLES:
		return
	var drift := Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
	_particles.append({
		"pos": pos + Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.5)),
		"vel": drift,
		"drag": 2.2,
		"size": size,
		"end_size": size * 2.0,
		"color": Color(0.46, 0.42, 0.33, 0.24),
		"end_color": Color(0.42, 0.39, 0.31, 0.0),
		"age": 0.0,
		"life": life,
		"shape": "circle",
	})

func spawn_contrail(pos: Vector2, size: float = 2.6, life: float = 0.42) -> void:
	if _particles.size() >= MAX_PARTICLES:
		return
	_particles.append({
		"pos": pos,
		"vel": Vector2.ZERO,
		"drag": 1.0,
		"size": size,
		"end_size": size * 2.2,
		"color": Color(0.86, 0.90, 0.94, 0.28),
		"end_color": Color(0.86, 0.90, 0.94, 0.0),
		"age": 0.0,
		"life": life,
		"shape": "circle",
	})

func spawn_spark_hit(pos: Vector2, color: Color = Color(1.0, 0.82, 0.35), count: int = 6) -> void:
	for _i in range(count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(50.0, 155.0)
		_particles.append({
			"pos": pos,
			"vel": Vector2.from_angle(ang) * spd,
			"drag": 5.5,
			"size": randf_range(2.0, 3.4),
			"end_size": 0.5,
			"color": color,
			"end_color": Color(color.r, color.g * 0.5, 0.1, 0.0),
			"age": 0.0,
			"life": randf_range(0.14, 0.28),
			"shape": "spark",
		})

func spawn_explosion(pos: Vector2, radius: float = 42.0, intense: bool = false) -> void:
	# Bright initial shockwave ring
	_rings.append({
		"pos": pos,
		"start_r": radius * 0.18,
		"end_r": radius * 1.25,
		"color": Color(1.0, 0.78, 0.38, 0.85),
		"width": 3.5 if intense else 2.2,
		"age": 0.0,
		"life": 0.32 if intense else 0.24,
	})

	# Secondary dark shockwave ring for heavy blasts
	if intense:
		_rings.append({
			"pos": pos,
			"start_r": radius * 0.1,
			"end_r": radius * 1.55,
			"color": Color(0.95, 0.42, 0.14, 0.55),
			"width": 4.5,
			"age": 0.0,
			"life": 0.45,
		})

	# Core hot flash
	_particles.append({
		"pos": pos,
		"vel": Vector2.ZERO,
		"drag": 1.0,
		"size": radius * 0.52,
		"end_size": radius * 0.92,
		"color": Color(1.0, 0.96, 0.78, 0.95),
		"end_color": Color(1.0, 0.45, 0.10, 0.0),
		"age": 0.0,
		"life": 0.16,
		"shape": "circle",
	})

	# Fireball plumes
	var fire_count := 12 if intense else 7
	for _i in range(fire_count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(radius * 0.4, radius * 2.1)
		_particles.append({
			"pos": pos + Vector2.from_angle(ang) * randf_range(0.0, radius * 0.22),
			"vel": Vector2.from_angle(ang) * spd,
			"drag": 4.6,
			"size": randf_range(radius * 0.22, radius * 0.42),
			"end_size": radius * 0.12,
			"color": Color(1.0, randf_range(0.46, 0.76), 0.12, 0.92),
			"end_color": Color(0.45, 0.12, 0.05, 0.0),
			"age": 0.0,
			"life": randf_range(0.24, 0.48),
			"shape": "circle",
		})

	# Billowing smoke puffs
	var smoke_count := 14 if intense else 8
	for _i in range(smoke_count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(radius * 0.25, radius * 1.45)
		var shade := randf_range(0.14, 0.28)
		_particles.append({
			"pos": pos + Vector2.from_angle(ang) * randf_range(0.0, radius * 0.35),
			"vel": Vector2.from_angle(ang) * spd + Vector2(0.0, -14.0),
			"drag": 2.4,
			"size": randf_range(radius * 0.20, radius * 0.36),
			"end_size": radius * 0.65,
			"color": Color(shade, shade, shade * 0.95, 0.62),
			"end_color": Color(shade * 0.8, shade * 0.8, shade * 0.8, 0.0),
			"age": 0.0,
			"life": randf_range(0.55, 1.05),
			"shape": "circle",
		})

	# Shrapnel / glowing sparks
	var spark_count := 16 if intense else 8
	for _i in range(spark_count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(radius * 2.2, radius * 5.2)
		_particles.append({
			"pos": pos,
			"vel": Vector2.from_angle(ang) * spd,
			"drag": 3.8,
			"size": randf_range(2.2, 3.6),
			"end_size": 0.6,
			"color": Color(1.0, 0.88, 0.42, 1.0),
			"end_color": Color(0.95, 0.28, 0.08, 0.0),
			"age": 0.0,
			"life": randf_range(0.22, 0.52),
			"shape": "spark",
		})

func spawn_cryo_burst(pos: Vector2, radius: float = 65.0) -> void:
	_rings.append({
		"pos": pos,
		"start_r": 10.0,
		"end_r": radius,
		"color": Color(0.45, 0.90, 1.0, 0.78),
		"width": 2.6,
		"age": 0.0,
		"life": 0.34,
	})
	for _i in range(12):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(radius * 0.55, radius * 1.9)
		_particles.append({
			"pos": pos,
			"vel": Vector2.from_angle(ang) * spd,
			"drag": 3.2,
			"size": randf_range(5.0, 11.0),
			"end_size": 18.0,
			"color": Color(0.58, 0.92, 1.0, 0.52),
			"end_color": Color(0.80, 0.96, 1.0, 0.0),
			"age": 0.0,
			"life": randf_range(0.32, 0.58),
			"shape": "circle",
		})

func spawn_festive_pop(pos: Vector2, radius: float = 36.0) -> void:
	_rings.append({
		"pos": pos,
		"start_r": 6.0,
		"end_r": radius * 1.15,
		"color": Color(1.0, 0.88, 0.36, 0.90),
		"width": 2.8,
		"age": 0.0,
		"life": 0.34,
	})
	var colors: Array[Color] = [
		Color(0.96, 0.22, 0.24, 1.0),
		Color(0.22, 0.88, 0.42, 1.0),
		Color(1.0, 0.86, 0.28, 1.0),
		Color(0.42, 0.88, 1.0, 1.0),
		Color(0.98, 0.98, 1.0, 1.0),
	]
	for _i in range(18):
		var ang: float = randf_range(0.0, TAU)
		var spd: float = randf_range(radius * 1.2, radius * 3.8)
		var c: Color = colors[randi() % colors.size()]
		_particles.append({
			"pos": pos,
			"vel": Vector2.from_angle(ang) * spd,
			"drag": 3.4,
			"size": randf_range(2.6, 4.6),
			"end_size": 0.8,
			"color": c,
			"end_color": Color(c.r, c.g, c.b, 0.0),
			"age": 0.0,
			"life": randf_range(0.30, 0.62),
			"shape": "casing" if randf() < 0.6 else "circle",
			"rot": randf_range(0.0, TAU),
			"rot_spd": randf_range(-18.0, 18.0),
		})

func spawn_floating_text(pos: Vector2, text: String, color: Color = Color(0.96, 0.86, 0.36), life: float = 0.85, callout: bool = false) -> void:
	_texts.append({
		"pos": pos,
		"text": text,
		"color": color,
		"age": 0.0,
		"life": life,
		"callout": callout,
	})

func spawn_victory_fireworks(center_pos: Vector2, burst_count: int = 8) -> void:
	var palette: Array[Color] = [
		Color(1.0, 0.84, 0.24, 1.0),
		Color(0.98, 0.26, 0.24, 1.0),
		Color(0.32, 0.92, 0.48, 1.0),
		Color(0.38, 0.88, 1.0, 1.0),
		Color(0.98, 0.42, 0.86, 1.0),
		Color(1.0, 0.96, 0.82, 1.0),
	]
	for i in range(burst_count):
		var ang := randf_range(0.0, TAU)
		var dist := randf_range(28.0, 185.0)
		_pending_fireworks.append({
			"pos": center_pos + Vector2.from_angle(ang) * dist + Vector2(0, randf_range(-65.0, 25.0)),
			"delay": float(i) * 0.26 + randf_range(0.0, 0.14),
			"color": palette[i % palette.size()],
			"radius": randf_range(44.0, 74.0),
		})

func _trigger_firework_burst(pos: Vector2, col: Color, radius: float) -> void:
	_rings.append({
		"pos": pos,
		"start_r": 6.0,
		"end_r": radius * 1.15,
		"color": Color(col.r, col.g, col.b, 0.88),
		"width": 2.6,
		"age": 0.0,
		"life": 0.55,
	})
	_particles.append({
		"pos": pos,
		"vel": Vector2.ZERO,
		"drag": 1.0,
		"size": radius * 0.34,
		"end_size": radius * 0.08,
		"color": Color(1.0, 0.98, 0.90, 0.95),
		"end_color": Color(col.r, col.g, col.b, 0.0),
		"age": 0.0,
		"life": 0.24,
		"shape": "circle",
	})
	var sparks := 26
	for k in range(sparks):
		var a := (float(k) / float(sparks)) * TAU + randf_range(-0.12, 0.12)
		var spd := randf_range(radius * 1.4, radius * 3.1)
		var c := col if (k % 3 != 0) else Color(1.0, 0.95, 0.72, 1.0)
		_particles.append({
			"pos": pos,
			"vel": Vector2.from_angle(a) * spd,
			"drag": 2.4,
			"size": randf_range(2.6, 4.2),
			"end_size": 0.6,
			"color": c,
			"end_color": Color(c.r, c.g, c.b, 0.0),
			"age": 0.0,
			"life": randf_range(0.65, 1.15),
			"shape": "spark" if (k % 2 == 0) else "circle",
		})

func spawn_airstrike_jets(target_pos: Vector2, dir: Vector2) -> void:
	var n_dir := dir.normalized()
	var perp := Vector2(-n_dir.y, n_dir.x)
	# Twin strike jets in close tactical formation
	for side: float in [-1.0, 1.0]:
		var start_pos: Vector2 = target_pos - n_dir * 860.0 + perp * (side * 34.0) - n_dir * (absf(side) * 20.0)
		_jets.append({
			"pos": start_pos,
			"dir": n_dir,
			"speed": 980.0,
			"age": 0.0,
			"life": 2.2,
			"trail_timer": 0.0,
		})

func _process(delta: float) -> void:
	_time += delta
	var had_beams := not _beams.is_empty()
	for i in range(_beams.size() - 1, -1, -1):
		if bool(_beams[i]["fresh"]):
			_beams[i]["fresh"] = false
		else:
			_beams.remove_at(i)

	for i in range(_pending_fireworks.size() - 1, -1, -1):
		var fw: Dictionary = _pending_fireworks[i]
		fw["delay"] = float(fw["delay"]) - delta
		if float(fw["delay"]) <= 0.0:
			_trigger_firework_burst(fw["pos"], fw["color"], float(fw["radius"]))
			_pending_fireworks.remove_at(i)

	var active := airstrike_aiming or drone_assign_aiming or had_beams or not _beams.is_empty() or not _particles.is_empty() or not _rings.is_empty() or not _flashes.is_empty() or not _texts.is_empty() or not _jets.is_empty() or not _pending_fireworks.is_empty()

	if _particles.size() > MAX_PARTICLES:
		_particles = _particles.slice(_particles.size() - MAX_PARTICLES)
	if _rings.size() > MAX_RINGS:
		_rings = _rings.slice(_rings.size() - MAX_RINGS)

	for i in range(_particles.size() - 1, -1, -1):
		var p := _particles[i]
		p["age"] = float(p["age"]) + delta
		if float(p["age"]) >= float(p["life"]):
			_particles.remove_at(i)
			continue
		var vel: Vector2 = p["vel"]
		var drag: float = p["drag"]
		vel = vel.lerp(Vector2.ZERO, minf(1.0, drag * delta))
		p["vel"] = vel
		p["pos"] = Vector2(p["pos"]) + vel * delta
		if p.has("rot"):
			p["rot"] = float(p["rot"]) + float(p["rot_spd"]) * delta

	for i in range(_rings.size() - 1, -1, -1):
		var r := _rings[i]
		r["age"] = float(r["age"]) + delta
		if float(r["age"]) >= float(r["life"]):
			_rings.remove_at(i)

	for i in range(_flashes.size() - 1, -1, -1):
		var f := _flashes[i]
		f["age"] = float(f["age"]) + delta
		if float(f["age"]) >= float(f["life"]):
			_flashes.remove_at(i)

	for i in range(_texts.size() - 1, -1, -1):
		var t := _texts[i]
		t["age"] = float(t["age"]) + delta
		if float(t["age"]) >= float(t["life"]):
			_texts.remove_at(i)
			continue
		t["pos"] = Vector2(t["pos"]) + Vector2(0.0, -28.0 * delta)

	for i in range(_jets.size() - 1, -1, -1):
		var j := _jets[i]
		j["age"] = float(j["age"]) + delta
		if float(j["age"]) >= float(j["life"]):
			_jets.remove_at(i)
			continue
		var jdir: Vector2 = j["dir"]
		j["pos"] = Vector2(j["pos"]) + jdir * float(j["speed"]) * delta
		j["trail_timer"] = float(j["trail_timer"]) + delta
		if float(j["trail_timer"]) >= 0.022:
			j["trail_timer"] = 0.0
			var perp := Vector2(-jdir.y, jdir.x)
			var jp: Vector2 = j["pos"]
			spawn_smoke(jp - jdir * 26.0 + perp * 16.0, 3.2, 0.42, 0.72)
			spawn_smoke(jp - jdir * 26.0 - perp * 16.0, 3.2, 0.42, 0.72)

	if active:
		queue_redraw()

func _draw() -> void:
	# 1. Particles
	for p in _particles:
		var u := clampf(float(p["age"]) / float(p["life"]), 0.0, 1.0)
		var col: Color = Color(p["color"]).lerp(Color(p["end_color"]), u)
		var sz := lerpf(float(p["size"]), float(p["end_size"]), u)
		var pos: Vector2 = p["pos"]
		var shape: String = p["shape"]

		if shape == "circle":
			draw_circle(pos, maxf(0.5, sz), col)
		elif shape == "spark":
			var vel: Vector2 = p["vel"]
			var tail := pos - vel.normalized() * minf(12.0, vel.length() * 0.055)
			draw_line(tail, pos, col, maxf(1.2, sz * 0.75), true)
		elif shape == "casing":
			var d := Vector2.from_angle(float(p["rot"])) * sz
			draw_line(pos - d, pos + d, col, 1.8, true)

	# 2. Shockwave rings
	for r in _rings:
		var u := clampf(float(r["age"]) / float(r["life"]), 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - u, 2.2)
		var rad := lerpf(float(r["start_r"]), float(r["end_r"]), eased)
		var col: Color = r["color"]
		col.a *= (1.0 - u)
		draw_arc(r["pos"], rad, 0.0, TAU, 36, col, float(r["width"]) * (1.0 - u * 0.5), true)

	# 3. Muzzle flashes
	for f in _flashes:
		var u := clampf(float(f["age"]) / float(f["life"]), 0.0, 1.0)
		var pos: Vector2 = f["pos"]
		var ang: float = f["angle"]
		var sz := float(f["size"]) * (1.0 - u * 0.4)
		var col: Color = f["color"]
		col.a = 1.0 - u
		var dir := Vector2.from_angle(ang)
		var perp := Vector2(-dir.y, dir.x)
		var poly := PackedVector2Array([
			pos - perp * (sz * 0.25),
			pos + dir * (sz * 1.45),
			pos + perp * (sz * 0.25),
			pos - dir * (sz * 0.15),
		])
		draw_colored_polygon(poly, col)
		draw_circle(pos + dir * (sz * 0.3), sz * 0.38, Color(1.0, 0.98, 0.88, col.a))

	# 3.5. Directed-Energy HEL Laser beams (rendered cleanly over ground & air units)
	for b in _beams:
		var from_p: Vector2 = b["from"]
		var to_p: Vector2 = b["to"]
		var ramp: float = float(b["ramp"])
		var col: Color = b["color"]
		var outer_w: float = lerpf(5.0, 10.5, ramp)
		var mid_w: float = lerpf(2.6, 5.4, ramp)
		var core_w: float = lerpf(1.2, 2.6, ramp)
		draw_line(from_p, to_p, Color(col.r, col.g, col.b, 0.28 + ramp * 0.20), outer_w, true)
		draw_line(from_p, to_p, Color(col.r, col.g, col.b, 0.86), mid_w, true)
		draw_line(from_p, to_p, Color(1.0, 0.94, 0.98, 0.96), core_w, true)
		# Thermal impact flare at lock point
		var flare_r: float = lerpf(5.0, 11.5, ramp) * (0.85 + 0.15 * sin(_time * 42.0))
		draw_circle(to_p, flare_r, Color(col.r, col.g, col.b, 0.38))
		draw_circle(to_p, flare_r * 0.45, Color(1.0, 0.96, 0.98, 0.92))

	# 4. Strike Jets (high altitude, drawn above everything)
	for j in _jets:
		_draw_strike_jet(j["pos"], j["dir"])

	# 5. Floating texts
	var font := ThemeDB.fallback_font
	for t in _texts:
		var u := clampf(float(t["age"]) / float(t["life"]), 0.0, 1.0)
		var col: Color = t["color"]
		var is_callout: bool = bool(t.get("callout", false))
		col.a = 1.0 - pow(u, 2.2 if is_callout else 1.6)
		var txt := String(t["text"])
		if is_callout:
			var fsize := 15
			var tsz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
			var cx: float = Vector2(t["pos"]).x
			var cy: float = Vector2(t["pos"]).y
			var pad_x := 8.0
			var pad_y := 4.0
			var box := Rect2(cx - tsz.x * 0.5 - pad_x, cy - fsize - pad_y + 2.0, tsz.x + pad_x * 2.0, float(fsize) + pad_y * 2.0)
			draw_rect(box, Color(0.05, 0.06, 0.05, col.a * 0.88))
			draw_rect(box, Color(col.r, col.g, col.b, col.a * 0.85), false, 1.4)
			draw_string(font, Vector2(cx - tsz.x * 0.5, cy), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
		else:
			var pos: Vector2 = Vector2(t["pos"]) - Vector2(90.0, 0.0)
			draw_string(font, pos + Vector2(1.0, 1.0), txt, HORIZONTAL_ALIGNMENT_CENTER, 180.0, 13, Color(0.0, 0.0, 0.0, col.a * 0.85))
			draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, 180.0, 13, col)

	# 6. Air Strike Targeting Reticle
	if airstrike_aiming:
		_draw_airstrike_reticle()

	# 7. Hunter Drone Manual Target Assign Reticle
	if drone_assign_aiming:
		_draw_drone_assign_reticle()

func _draw_strike_jet(pos: Vector2, dir: Vector2) -> void:
	var perp := Vector2(-dir.y, dir.x)
	var shadow_off := Vector2(46.0, 52.0)

	var body_local := PackedVector2Array([
		Vector2(34, 0),
		Vector2(14, 5.5),
		Vector2(4, 8),
		Vector2(-9, 28),
		Vector2(-17, 28),
		Vector2(-12, 8),
		Vector2(-26, 15),
		Vector2(-29, 13),
		Vector2(-26, 5),
		Vector2(-23, 0),
		Vector2(-26, -5),
		Vector2(-29, -13),
		Vector2(-26, -15),
		Vector2(-12, -8),
		Vector2(-17, -28),
		Vector2(-9, -28),
		Vector2(4, -8),
		Vector2(14, -5.5),
	])
	var world_pts := PackedVector2Array()
	var shadow_pts := PackedVector2Array()
	for pt in body_local:
		var wp := pos + dir * pt.x + perp * pt.y
		world_pts.append(wp)
		shadow_pts.append(wp + shadow_off)

	# Ground shadow
	draw_colored_polygon(shadow_pts, Color(0.0, 0.0, 0.0, 0.25))

	# Twin blazing afterburner shock-diamond cones
	for side: float in [-1.0, 1.0]:
		var noz := pos - dir * 25.0 + perp * (side * 3.8)
		var outer := PackedVector2Array([
			noz + perp * 2.4, noz - perp * 2.4, noz - dir * 18.0
		])
		var inner := PackedVector2Array([
			noz + perp * 1.2, noz - perp * 1.2, noz - dir * 10.0
		])
		draw_colored_polygon(outer, Color(1.0, 0.52, 0.14, 0.92))
		draw_colored_polygon(inner, Color(0.84, 0.96, 1.0, 0.96))

	# Jet fuselage & crisp military outline
	draw_colored_polygon(world_pts, Color(0.28, 0.33, 0.36))
	var outline := PackedVector2Array(world_pts)
	outline.append(world_pts[0])
	draw_polyline(outline, Color(0.11, 0.13, 0.15), 1.4, true)

	# Wing tactical stripes & vertical stabilizers
	for side: float in [-1.0, 1.0]:
		draw_line(pos - dir * 6.0 + perp * (side * 19.0), pos - dir * 12.0 + perp * (side * 19.0), Color(0.92, 0.68, 0.20, 0.85), 2.8, true)
		draw_line(pos - dir * 16.0 + perp * (side * 4.5), pos - dir * 26.0 + perp * (side * 6.5), Color(0.46, 0.52, 0.56), 2.4, true)
	# Cockpit canopy + glare
	draw_line(pos + dir * 20.0, pos + dir * 8.0, Color(0.24, 0.52, 0.64, 0.96), 4.6, true)
	draw_line(pos + dir * 18.0 - perp * 1.0, pos + dir * 10.0 - perp * 1.2, Color(0.80, 0.95, 1.0, 0.85), 1.6, true)

func _draw_airstrike_reticle() -> void:
	var p := airstrike_aim_pos
	var r := airstrike_radius
	var pulse := 0.5 + 0.5 * sin(_time * 8.0)
	var col := Color(1.0, 0.34, 0.18, 0.85)

	# Blast zone fill & pulsing border
	draw_circle(p, r, Color(1.0, 0.28, 0.12, 0.14 + pulse * 0.06))
	draw_arc(p, r, 0.0, TAU, 48, col, 2.4, true)
	draw_arc(p, r * 0.55, 0.0, TAU, 36, Color(1.0, 0.55, 0.25, 0.45), 1.4, true)

	# Bombing run corridor lines
	var run_dir := Vector2(1.0, -0.25).normalized()
	draw_line(p - run_dir * (r * 1.45), p + run_dir * (r * 1.45), Color(1.0, 0.42, 0.20, 0.5), 1.8, true)

	# Rotating tactical brackets
	var rot := _time * 1.4
	for i in range(4):
		var a := rot + float(i) * PI * 0.5
		draw_arc(p, r + 9.0, a - 0.22, a + 0.22, 8, Color(1.0, 0.80, 0.32, 0.9), 3.0, true)

	draw_string(ThemeDB.fallback_font, p + Vector2(-58.0, -r - 16.0), "HELLFIRE STRIKE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.82, 0.40, 0.95))

func _draw_drone_assign_reticle() -> void:
	var p: Vector2 = drone_assign_target_pos if drone_assign_has_target else drone_assign_pos
	var r: float = (drone_assign_target_radius + 10.0) if drone_assign_has_target else 22.0
	var col: Color = Color(0.56, 0.98, 0.34, 0.95) if drone_assign_has_target else Color(0.84, 0.92, 0.56, 0.65)
	var pulse: float = 0.5 + 0.5 * sin(_time * 10.0)

	draw_circle(p, r, Color(col.r, col.g, col.b, 0.14 if drone_assign_has_target else 0.06))
	draw_arc(p, r, 0.0, TAU, 36, col, 2.0, true)
	var rot: float = _time * 2.2
	for i in range(4):
		var a: float = rot + float(i) * PI * 0.5
		draw_arc(p, r + 5.0 + pulse * 2.5, a - 0.28, a + 0.28, 6, col, 2.4, true)
	var lbl: String = "LOCK TARGET [LMB]" if drone_assign_has_target else "CLICK HOSTILE TO HUNT"
	draw_string(ThemeDB.fallback_font, p + Vector2(-72.0, -r - 14.0), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
