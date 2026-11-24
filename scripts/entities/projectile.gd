class_name Projectile
extends Node2D

var turret_type: TurretData.TurretType = TurretData.TurretType.VULCAN
var source_turret: Node = null
var target_enemy: Enemy = null
var target_pos: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var speed: float = 600.0
var damage: float = 20.0
var air_bonus: float = 1.0
var splash_radius: float = 0.0
var slow_amount: float = 0.0
var slow_duration: float = 0.0
var armor_pierce: float = 0.0
var can_hit_air: bool = false
var burn_dps: float = 0.0
var burn_duration: float = 0.0
var burn_radius: float = 0.0

var _fx: FxManager = null
var _decals: DecalLayer = null
var _sfx: SfxManager = null
var _enemies_container: Node = null
var _on_shake: Callable

var _trail_timer: float = 0.0
var _age: float = 0.0
var _max_life: float = 3.5
var _start_dist: float = 1.0

func setup(params: Dictionary) -> void:
	turret_type = params["turret_type"]
	source_turret = params["source_turret"]
	target_enemy = params["target_enemy"]
	position = params["start_pos"]
	target_pos = params["target_pos"]
	speed = float(params["speed"])
	damage = float(params["damage"])
	air_bonus = float(params.get("air_bonus", 1.0))
	splash_radius = float(params["splash_radius"])
	slow_amount = float(params["slow_amount"])
	slow_duration = float(params["slow_duration"])
	armor_pierce = float(params["armor_pierce"])
	can_hit_air = bool(params["can_hit_air"])
	burn_dps = float(params.get("burn_dps", 0.0))
	burn_duration = float(params.get("burn_dur", 0.0))
	burn_radius = float(params.get("burn_radius", 0.0))
	_fx = params["fx"]
	_decals = params["decals"]
	_sfx = params["sfx"]
	_enemies_container = params["enemies_container"]
	_on_shake = params.get("on_shake", Callable())

	var dir := (target_pos - position).normalized()
	if dir.length_squared() < 0.001:
		dir = Vector2.RIGHT
	velocity = dir * speed
	rotation = dir.angle()
	_start_dist = maxf(1.0, position.distance_to(target_pos))
	z_index = 40

func _process(delta: float) -> void:
	_age += delta
	if _age >= _max_life:
		queue_free()
		return

	# Track moving target for homing missiles & tracers
	if target_enemy != null and is_instance_valid(target_enemy) and target_enemy.alive:
		if turret_type == TurretData.TurretType.MISSILE:
			target_pos = target_enemy.position
			var desired := (target_pos - position).normalized()
			var cur_dir := velocity.normalized()
			var new_dir := cur_dir.lerp(desired, minf(1.0, delta * 9.5)).normalized()
			speed = minf(speed + 260.0 * delta, 760.0)
			velocity = new_dir * speed
			rotation = new_dir.angle()
		elif turret_type == TurretData.TurretType.VULCAN:
			target_pos = target_enemy.position
			var dir := (target_pos - position).normalized()
			velocity = dir * speed
			rotation = dir.angle()

	var step := velocity * delta
	var dist_to_target := position.distance_to(target_pos)
	if dist_to_target <= step.length() + 9.0:
		position = target_pos
		_detonate()
		return

	position += step

	# Trails
	if turret_type == TurretData.TurretType.MISSILE:
		_trail_timer += delta
		if _trail_timer >= 0.022 and _fx != null:
			_trail_timer = 0.0
			_fx.spawn_smoke(position - velocity.normalized() * 8.0, 4.2, 0.44, 0.72)
	elif turret_type == TurretData.TurretType.CANNON:
		_trail_timer += delta
		if _trail_timer >= 0.032 and _fx != null:
			_trail_timer = 0.0
			_fx.spawn_smoke(position, 3.0, 0.28, 0.45)
	elif turret_type == TurretData.TurretType.CRYO:
		_trail_timer += delta
		if _trail_timer >= 0.03 and _fx != null:
			_trail_timer = 0.0
			_fx.spawn_smoke(position, 3.2, 0.25, 0.85)
	elif turret_type == TurretData.TurretType.MLRS:
		_trail_timer += delta
		if _trail_timer >= 0.020 and _fx != null:
			_trail_timer = 0.0
			_fx.spawn_smoke(position - velocity.normalized() * 8.0, 4.4, 0.42, 0.56)

	queue_redraw()

func _detonate() -> void:
	var hit_air_or_ground := false
	var killer: Node = source_turret if is_instance_valid(source_turret) else null
	if splash_radius > 0.0 and _enemies_container != null:
		for child in _enemies_container.get_children():
			if child is Enemy and is_instance_valid(child) and child.alive:
				var e: Enemy = child
				if e.is_air and not can_hit_air:
					continue
				var dist := position.distance_to(e.position)
				if dist <= splash_radius + e.hit_radius:
					var falloff := lerpf(1.0, 0.45, clampf(dist / maxf(1.0, splash_radius), 0.0, 1.0))
					var dmg := damage * falloff
					if e.is_air:
						dmg *= air_bonus
					e.take_damage(dmg, armor_pierce, killer)
					if slow_amount > 0.0:
						e.apply_slow(slow_amount, slow_duration)
					hit_air_or_ground = true
	else:
		if target_enemy != null and is_instance_valid(target_enemy) and target_enemy.alive:
			var dmg := damage * (air_bonus if target_enemy.is_air else 1.0)
			target_enemy.take_damage(dmg, armor_pierce, killer)
			if slow_amount > 0.0:
				target_enemy.apply_slow(slow_amount, slow_duration)
			hit_air_or_ground = true

	# Visual & Audio impact effects
	match turret_type:
		TurretData.TurretType.VULCAN:
			if _fx != null:
				_fx.spawn_spark_hit(position, Color(1.0, 0.84, 0.35), 4)
		TurretData.TurretType.CANNON:
			if _fx != null:
				_fx.spawn_explosion(position, maxf(36.0, splash_radius * 0.72), true)
			if _decals != null:
				_decals.add_crater(position, clampf(splash_radius * 0.28, 12.0, 26.0))
			if _sfx != null:
				_sfx.play("explosion_small", -2.5, 0.12, 0.05)
			if _on_shake.is_valid():
				_on_shake.call(3.8)
		TurretData.TurretType.MISSILE:
			if _fx != null:
				_fx.spawn_explosion(position, maxf(32.0, splash_radius * 0.85), false)
			if _decals != null and not (target_enemy != null and is_instance_valid(target_enemy) and target_enemy.is_air):
				_decals.add_scorch(position, 16.0)
			if _sfx != null:
				_sfx.play("explosion_small", -3.0, 0.12, 0.05)
			if _on_shake.is_valid():
				_on_shake.call(2.4)
		TurretData.TurretType.CRYO:
			if _fx != null:
				_fx.spawn_cryo_burst(position, splash_radius)
			if _decals != null:
				_decals.add_frost(position, splash_radius * 0.75)
		TurretData.TurretType.MLRS:
			if _fx != null:
				_fx.spawn_explosion(position, maxf(34.0, splash_radius * 0.78), false)
			if _decals != null:
				_decals.add_scorch(position, clampf(burn_radius * 0.55, 16.0, 30.0))
			if _sfx != null:
				_sfx.play("explosion_small", -3.0, 0.14, 0.05)
			if _on_shake.is_valid():
				_on_shake.call(2.2)
			if burn_dps > 0.0 and burn_duration > 0.0 and get_parent() != null:
				var fz := FireZone.new()
				fz.setup(position, burn_radius, burn_dps, burn_duration, armor_pierce, killer, _enemies_container, _fx)
				get_parent().add_child(fz)

	if hit_air_or_ground:
		pass
	queue_free()

func _draw() -> void:
	match turret_type:
		TurretData.TurretType.VULCAN:
			draw_line(Vector2(-14, 0), Vector2(3, 0), Color(1.0, 0.76, 0.25, 0.75), 2.4, true)
			draw_line(Vector2(-4, 0), Vector2(4, 0), Color(1.0, 0.96, 0.80, 1.0), 1.8, true)
		TurretData.TurretType.CANNON:
			# Parabolic altitude visual scale
			var frac := clampf(1.0 - (position.distance_to(target_pos) / _start_dist), 0.0, 1.0)
			var arc_scale := 1.0 + sin(frac * PI) * 0.55
			draw_circle(Vector2(6, 7) * arc_scale, 3.6, Color(0.0, 0.0, 0.0, 0.25))
			draw_line(Vector2(-10, 0), Vector2(4, 0), Color(1.0, 0.55, 0.18, 0.85), 3.6 * arc_scale, true)
			draw_circle(Vector2(2, 0), 3.2 * arc_scale, Color(1.0, 0.92, 0.65))
		TurretData.TurretType.MISSILE:
			# Sleek rocket body + glowing motor exhaust
			draw_line(Vector2(-8, 0), Vector2(7, 0), Color(0.84, 0.86, 0.82), 3.2, true)
			draw_line(Vector2(4, 0), Vector2(8, 0), Color(0.88, 0.26, 0.20), 2.8, true)
			draw_line(Vector2(-7, -3.5), Vector2(-4, 0), Color(0.45, 0.48, 0.44), 1.6, true)
			draw_line(Vector2(-7, 3.5), Vector2(-4, 0), Color(0.45, 0.48, 0.44), 1.6, true)
			draw_circle(Vector2(-9, 0), 3.2, Color(1.0, 0.72, 0.24, 0.92))
		TurretData.TurretType.CRYO:
			draw_circle(Vector2.ZERO, 6.2, Color(0.32, 0.82, 1.0, 0.35))
			draw_circle(Vector2.ZERO, 3.6, Color(0.75, 0.96, 1.0, 0.95))
			draw_line(Vector2(-9, 0), Vector2(3, 0), Color(0.45, 0.88, 1.0, 0.7), 2.4, true)
		TurretData.TurretType.MLRS:
			var frac := clampf(1.0 - (position.distance_to(target_pos) / _start_dist), 0.0, 1.0)
			var arc_scale := 1.0 + sin(frac * PI) * 0.45
			draw_circle(Vector2(5, 6) * arc_scale, 3.0, Color(0.0, 0.0, 0.0, 0.22))
			draw_line(Vector2(-9, 0), Vector2(6, 0), Color(0.72, 0.74, 0.70), 3.0 * arc_scale, true)
			draw_line(Vector2(3, 0), Vector2(8, 0), Color(0.98, 0.56, 0.14), 2.8 * arc_scale, true)
			draw_circle(Vector2(-10, 0), 3.6 * arc_scale, Color(1.0, 0.62, 0.16, 0.94))
			draw_circle(Vector2(-9, 0), 1.8 * arc_scale, Color(1.0, 0.96, 0.72, 0.98))
