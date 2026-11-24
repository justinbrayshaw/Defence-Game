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
var _phase: float = 0.0
var _enemies_container: Node = null
var _fx: FxManager = null
var _blobs: Array[Dictionary] = []

func setup(
	pos: Vector2,
	zone_radius: float,
	burn_dps: float,
	burn_duration: float,
	ap: float,
	src_turret: Node,
	enemies_container: Node,
	fx_manager: FxManager
) -> void:
	position = pos
	radius = zone_radius
	dps = burn_dps
	duration = burn_duration
	armor_pierce = ap
	source_turret = src_turret
	_enemies_container = enemies_container
	_fx = fx_manager
	_phase = randf_range(0.0, TAU)
	z_as_relative = false
	z_index = 10

	_blobs.clear()
	for i in range(9):
		var a: float = (float(i) / 9.0) * TAU + randf_range(-0.32, 0.32)
		var d: float = randf_range(radius * 0.12, radius * 0.68)
		_blobs.append({
			"off": Vector2.from_angle(a) * d,
			"r": randf_range(radius * 0.20, radius * 0.36),
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

	if _fx != null:
		_smoke_timer += delta
		if _smoke_timer >= 0.22:
			_smoke_timer = 0.0
			var off := Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(0.0, radius * 0.65)
			_fx.spawn_smoke(position + off, randf_range(4.0, 6.5), 0.55, 0.16)

	queue_redraw()

func _apply_burn_tick() -> void:
	if _enemies_container == null:
		return
	var killer: Node = source_turret if is_instance_valid(source_turret) else null
	var tick_dmg: float = dps * TICK_INTERVAL
	for child in _enemies_container.get_children():
		if not (child is Enemy) or not is_instance_valid(child):
			continue
		var e: Enemy = child
		if not e.alive or e.is_air:
			continue
		if position.distance_to(e.position) <= radius + e.hit_radius:
			e.take_damage(tick_dmg, armor_pierce, killer, 1.0)

func _draw() -> void:
	var life_frac: float = clampf(1.0 - (_age / maxf(0.1, duration)), 0.0, 1.0)
	var fade: float = clampf(life_frac * 3.0, 0.0, 1.0) * minf(1.0, _age * 8.0)

	# Scorched incandescent base pool
	draw_circle(Vector2.ZERO, radius, Color(0.16, 0.06, 0.02, 0.28 * fade))
	draw_circle(Vector2.ZERO, radius * 0.78, Color(0.86, 0.24, 0.04, 0.24 * fade))
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
		draw_circle(p + Vector2(0.0, -2.4), br * 0.26 * flick, Color(1.0, 0.96, 0.72, 0.74 * fade))
