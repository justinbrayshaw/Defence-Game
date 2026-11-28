class_name DecalLayer
extends Node2D

const MAX_DECALS: int = 160
const MAX_DECALS_MOBILE: int = 72

var _decals: Array[Dictionary] = []
var _max_decals: int = MAX_DECALS
var _redraw_accum: float = 0.0

func _ready() -> void:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web"):
		_max_decals = MAX_DECALS_MOBILE

func clear_all() -> void:
	_decals.clear()
	queue_redraw()

func add_crater(pos: Vector2, radius: float) -> void:
	_push_decal({
		"kind": "crater",
		"pos": pos,
		"radius": radius,
		"angle": randf_range(0.0, TAU),
		"age": 0.0,
		"max_age": 95.0,
	})

func add_scorch(pos: Vector2, radius: float) -> void:
	_push_decal({
		"kind": "scorch",
		"pos": pos,
		"radius": radius,
		"angle": randf_range(0.0, TAU),
		"age": 0.0,
		"max_age": 70.0,
	})

func add_wreck(pos: Vector2, angle: float, scale_factor: float) -> void:
	_push_decal({
		"kind": "wreck",
		"pos": pos,
		"radius": 14.0 * scale_factor,
		"angle": angle,
		"age": 0.0,
		"max_age": 48.0,
	})

func add_gift_box(pos: Vector2, angle: float, scale_factor: float) -> void:
	var palette: Array[Color] = [
		Color(0.88, 0.16, 0.20),
		Color(0.14, 0.64, 0.28),
		Color(0.18, 0.44, 0.86),
		Color(0.76, 0.22, 0.72),
		Color(0.92, 0.66, 0.14),
	]
	_push_decal({
		"kind": "gift",
		"pos": pos,
		"radius": 10.5 * clampf(scale_factor, 0.9, 1.45),
		"angle": angle,
		"color": palette[randi() % palette.size()],
		"age": 0.0,
		"max_age": 42.0,
	})

func add_frost(pos: Vector2, radius: float) -> void:
	_push_decal({
		"kind": "frost",
		"pos": pos,
		"radius": radius,
		"angle": randf_range(0.0, TAU),
		"age": 0.0,
		"max_age": 6.5,
	})

func _push_decal(d: Dictionary) -> void:
	# Avoid stacking dozens of identical dark blast marks on the exact same pixel
	var pos: Vector2 = d["pos"]
	var kind: String = String(d["kind"])
	if kind != "frost":
		for existing in _decals:
			if String(existing["kind"]) == kind and Vector2(existing["pos"]).distance_squared_to(pos) < 100.0:
				existing["age"] = 0.0
				queue_redraw()
				return
	_decals.append(d)
	if _decals.size() > _max_decals:
		_decals.remove_at(0)
	queue_redraw()

func _process(delta: float) -> void:
	if _decals.is_empty():
		return
	_redraw_accum += delta
	if _redraw_accum < 0.125:
		return
	var step: float = _redraw_accum
	_redraw_accum = 0.0
	var dirty := false
	for i in range(_decals.size() - 1, -1, -1):
		var d := _decals[i]
		d["age"] = float(d["age"]) + step
		var age: float = d["age"]
		var max_age: float = d["max_age"]
		if age >= max_age:
			_decals.remove_at(i)
			dirty = true
		elif age > max_age - 8.0 or d["kind"] == "frost":
			dirty = true
	if dirty:
		queue_redraw()

func _draw() -> void:
	for d in _decals:
		var pos: Vector2 = d["pos"]
		var r: float = d["radius"]
		var age: float = d["age"]
		var max_age: float = d["max_age"]
		var fade := clampf((max_age - age) / minf(8.0, max_age * 0.45), 0.0, 1.0)
		var kind: String = d["kind"]

		if kind == "crater":
			draw_circle(pos, r * 1.15, Color(0.05, 0.04, 0.03, 0.34 * fade))
			draw_circle(pos, r * 0.72, Color(0.11, 0.09, 0.07, 0.52 * fade))
			draw_circle(pos + Vector2(1.5, 1.5), r * 0.42, Color(0.04, 0.04, 0.03, 0.62 * fade))
			draw_arc(pos, r * 0.78, 0.0, TAU, 20, Color(0.28, 0.24, 0.19, 0.32 * fade), 1.6, true)
		elif kind == "scorch":
			draw_circle(pos, r, Color(0.06, 0.05, 0.04, 0.32 * fade))
			draw_circle(pos, r * 0.52, Color(0.03, 0.03, 0.02, 0.45 * fade))
		elif kind == "frost":
			draw_circle(pos, r, Color(0.52, 0.86, 0.98, 0.18 * fade))
			draw_arc(pos, r * 0.75, 0.0, TAU, 20, Color(0.75, 0.94, 1.0, 0.28 * fade), 1.4, true)
		elif kind == "wreck":
			var ang: float = d["angle"]
			draw_circle(pos, r * 1.1, Color(0.05, 0.04, 0.03, 0.45 * fade))
			var dir := Vector2.from_angle(ang)
			var perp := Vector2(-dir.y, dir.x)
			var half_l := r * 0.85
			var half_w := r * 0.52
			var hull := PackedVector2Array([
				pos + dir * half_l + perp * half_w,
				pos + dir * half_l - perp * half_w,
				pos - dir * half_l - perp * half_w,
				pos - dir * half_l + perp * half_w,
			])
			draw_colored_polygon(hull, Color(0.13, 0.12, 0.11, 0.78 * fade))
			# Glowing embers fading out over first 6 seconds
			if age < 6.0:
				var ember := (1.0 - age / 6.0) * 0.85
				draw_circle(pos + dir * 2.0, r * 0.28, Color(1.0, 0.42, 0.10, ember))
		elif kind == "gift":
			var ang: float = float(d["angle"])
			var box_col: Color = d["color"]
			box_col.a = 0.95 * fade
			var rib_col := Color(0.98, 0.86, 0.30, 0.95 * fade)
			var dir := Vector2.from_angle(ang)
			var perp := Vector2(-dir.y, dir.x)
			var half_s: float = r * 0.62
			var sh_off := Vector2(2.4, 2.8)
			var sh_poly := PackedVector2Array([
				pos + sh_off + dir * half_s + perp * half_s,
				pos + sh_off + dir * half_s - perp * half_s,
				pos + sh_off - dir * half_s - perp * half_s,
				pos + sh_off - dir * half_s + perp * half_s,
			])
			var poly := PackedVector2Array([
				pos + dir * half_s + perp * half_s,
				pos + dir * half_s - perp * half_s,
				pos - dir * half_s - perp * half_s,
				pos - dir * half_s + perp * half_s,
			])
			draw_colored_polygon(sh_poly, Color(0.06, 0.12, 0.24, 0.32 * fade))
			draw_colored_polygon(poly, box_col)
			draw_line(pos - dir * half_s, pos + dir * half_s, rib_col, 2.4, true)
			draw_line(pos - perp * half_s, pos + perp * half_s, rib_col, 2.4, true)
			draw_circle(pos, 2.5, rib_col)
