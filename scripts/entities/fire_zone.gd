class_name FireZone
extends Node2D

const TICK_INTERVAL: float = 0.25

var source_turret: Node = null
var radius: float = 46.0
var dps: float = 16.0
var duration: float = 3.5
var armor_pierce: float = 0.65

var _age: float = 0.0
var _tick_timer: float = 0.08
var _smoke_timer: float = 0.0
var _redraw_timer: float = 0.0
var _phase: float = 0.0
var _enemies_container: Node = null
var _active_enemies: Array[Enemy] = []
var _has_active_enemies_ref: bool = false
var _fx: FxManager = null
var _blobs: Array[Dictionary] = []
var _is_mobile_perf: bool = false

func refresh_burn(new_radius: float, new_dps: float, new_duration: float, new_ap: float, new_src: Node) -> void:
	radius = maxf(radius, new_radius)
	dps = maxf(dps, new_dps)
	armor_pierce = maxf(armor_pierce, new_ap)
	duration = maxf(duration - _age, new_duration)
	_age = 0.0
	if new_src != null and is_instance_valid(new_src):
		source_turret = new_src

func setup(
	pos: Vector2,
	zone_radius: float,
	burn_dps: float,
	burn_duration: float,
	ap: float,
	src_turret: Node,
	enemies_container: Node,
	fx_manager: FxManager,
	active_enemies_ref: Variant = null
) -> void:
	_is_mobile_perf = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web")
	position = pos
	radius = zone_radius
	dps = burn_dps
	duration = burn_duration
	armor_pierce = ap
	source_turret = src_turret
	_enemies_container = enemies_container
	if active_enemies_ref is Array:
		_active_enemies = active_enemies_ref
		_has_active_enemies_ref = true
	_fx = fx_manager
	_phase = randf_range(0.0, TAU)
	z_as_relative = false
	z_index = 10

	_blobs.clear()
	var blob_count: int = 4 if _is_mobile_perf else 9
	for i in range(blob_count):
		var a: float = (float(i) / float(blob_count)) * TAU + randf_range(-0.32, 0.32)
		var d: float = randf_range(radius * 0.12, radius * 0.68)
		_blobs.append({
			"off": Vector2.from_angle(a) * d,
			"r": randf_range(radius * 0.22, radius * 0.38),
			"seed": randf_range(0.0, TAU),
			"spd": randf_range(8.0, 14.5),
		})
	queue_redraw()

func _process(delta: float) -> void:
	_age += delta
	if _age >= duration:
		queue_free()
		return

	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer += TICK_INTERVAL
		_apply_burn_tick()

	if _fx != null and not _is_mobile_perf:
		_smoke_timer += delta
		if _smoke_timer >= 0.22:
			_smoke_timer = 0.0
			var off := Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(0.0, radius * 0.65)
			_fx.spawn_smoke(position + off, randf_range(4.0, 6.5), 0.55, 0.16)

	_redraw_timer += delta
	var redraw_iv: float = 0.10 if _is_mobile_perf else 0.066
	if _redraw_timer >= redraw_iv:
		_redraw_timer = 0.0
		queue_redraw()

func _apply_burn_tick() -> void:
	if _enemies_container == null:
		return
	var killer: Node = source_turret if is_instance_valid(source_turret) else null
	var tick_dmg: float = dps * TICK_INTERVAL
	var enemy_list: Array = _active_enemies if _has_active_enemies_ref else _enemies_container.get_children()
	for i in range(enemy_list.size() - 1, -1, -1):
		if i >= enemy_list.size():
			continue
		var child: Variant = enemy_list[i]
		if not is_instance_valid(child):
			continue
		var e: Enemy = child as Enemy
		if e == null or not e.alive or e.is_air:
			continue
		var reach: float = radius + e.hit_radius
		if position.distance_squared_to(e.position) <= reach * reach:
			e.take_damage(tick_dmg, armor_pierce, killer, 1.0)

func _draw() -> void:
	var life_frac: float = clampf(1.0 - (_age / maxf(0.1, duration)), 0.0, 1.0)
	var fade: float = clampf(life_frac * 3.0, 0.0, 1.0) * minf(1.0, _age * 8.0)

	# Scorched incandescent base pool
	draw_circle(Vector2.ZERO, radius, Color(0.16, 0.06, 0.02, 0.28 * fade))
	draw_circle(Vector2.ZERO, radius * 0.78, Color(0.86, 0.24, 0.04, 0.24 * fade))
	if not _is_mobile_perf:
		draw_arc(Vector2.ZERO, radius * 0.92, 0.0, TAU, 32, Color(1.0, 0.48, 0.12, 0.34 * fade), 1.6, true)

	# Flickering thermobaric flame tongues
	for b in _blobs:
		var off: Vector2 = b["off"]
		var br: float = float(b["r"])
		var s: float = float(b["seed"])
		var spd: float = float(b["spd"])
		var flick: float = 0.72 + 0.28 * sin(_age * spd + s + _phase)
		var drift := Vector2(sin(_age * 5.0 + s) * 2.2, -3.5 * flick)
		var p: Vector2 = off + drift
		draw_circle(p, br * flick, Color(1.0, 0.36, 0.06, 0.56 * fade))
		draw_circle(p + Vector2(0.0, -1.6), br * 0.58 * flick, Color(1.0, 0.76, 0.18, 0.70 * fade))
		if not _is_mobile_perf:
			draw_circle(p + Vector2(0.0, -2.4), br * 0.26 * flick, Color(1.0, 0.96, 0.72, 0.74 * fade))
