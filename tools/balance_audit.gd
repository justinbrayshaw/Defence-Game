extends SceneTree

# ==============================================================================
# Defence Zone — Phase 2 Math & Simulation Survivability Audit
# ==============================================================================
# Repeatable headless Godot audit script reading live MapData, WaveData,
# TurretData, and EnemyData across all 17 sectors (16 campaign + north_pole)
# x 4 difficulties (EASY, NORMAL, HARD, HELL).
#
# Run from project root:
#   Godot_v4.7.2-stable_win64_console.exe --headless -s res://tools/balance_audit.gd
#
# Optional user flags (pass after `--`):
#   --save-baseline              Overwrite tools/audit_baseline.json
#   --diff <path_to_json>        Compare current run against a saved JSON baseline
#   --report <path_to_md>        Custom Markdown report path (default: tools/audit_report.md)
#   --json <path_to_json>        Custom JSON snapshot path (default: tools/audit_current.json)
# ==============================================================================

const MapDataScript = preload("res://scripts/data/map_data.gd")
const WaveDataScript = preload("res://scripts/data/wave_data.gd")
const TurretDataScript = preload("res://scripts/data/turret_data.gd")
const EnemyDataScript = preload("res://scripts/data/enemy_data.gd")

# Thresholds agreed in Phase 2 design review
const THRESH_IMPOSSIBLE: float = 1.0       # opt_ratio < 1.0
const THRESH_TIGHT: float = 1.0            # real_ratio < 1.0 (while opt >= 1.0)
const THRESH_SNOWBALL: float = 2.2         # real_ratio > 2.2
const THRESH_AIR_MIN_PADS: int = 4         # < 4 pads reaching air_path at SAM Lv1
const THRESH_AIR_MIN_COV_PCT: float = 50.0 # < 50% of air_path length covered at SAM Lv1
const THRESH_LANE_UNDERUSE_PCT: float = 15.0

# Mirror exact scaling constants from scripts/game_controller.gd
const WAVE_HP_STEP: float = 0.085

# Reference ranges from TurretData (read dynamically in _init, stored here for clarity)
var _vulcan_r1: float = 175.0
var _sam_r1: float = 285.0
var _sam_r4: float = 390.0
var _laser_r1: float = 235.0
var _cannon_r4: float = 290.0
var _mlrs_r4: float = 445.0

var _turret_cfgs: Dictionary = {}
var _enemy_cfgs: Dictionary = {}


func _init() -> void:
	var user_args := OS.get_cmdline_user_args()
	var save_baseline := false
	var diff_path := ""
	var report_path := "res://tools/audit_report.md"
	var json_path := "res://tools/audit_current.json"

	var i := 0
	while i < user_args.size():
		var arg := user_args[i]
		if arg == "--save-baseline":
			save_baseline = true
		elif arg == "--diff" and i + 1 < user_args.size():
			diff_path = user_args[i + 1]
			i += 1
		elif arg == "--report" and i + 1 < user_args.size():
			report_path = user_args[i + 1]
			i += 1
		elif arg == "--json" and i + 1 < user_args.size():
			json_path = user_args[i + 1]
			i += 1
		i += 1

	_cache_configs()
	var result := _run_full_audit()

	var baseline_data: Dictionary = {}
	if diff_path != "":
		baseline_data = _load_json(diff_path)

	# Persist JSON snapshots
	_save_json(json_path, result)
	if save_baseline or not FileAccess.file_exists("res://tools/audit_baseline.json"):
		_save_json("res://tools/audit_baseline.json", result)

	# Generate Markdown report
	var md := _build_markdown_report(result, baseline_data)
	_save_text(report_path, md)

	# Print concise CLI summary
	_print_cli_summary(result, baseline_data, report_path, json_path, save_baseline)
	quit(0)


func _cache_configs() -> void:
	for t in TurretDataScript.get_all_types():
		_turret_cfgs[t] = TurretDataScript.get_config(t)

	_vulcan_r1 = float(_turret_cfgs[TurretDataScript.TurretType.VULCAN]["levels"][0]["range"])
	_sam_r1 = float(_turret_cfgs[TurretDataScript.TurretType.MISSILE]["levels"][0]["range"])
	_sam_r4 = float(_turret_cfgs[TurretDataScript.TurretType.MISSILE]["levels"][3]["range"])
	_laser_r1 = float(_turret_cfgs[TurretDataScript.TurretType.LASER]["levels"][0]["range"])
	_cannon_r4 = float(_turret_cfgs[TurretDataScript.TurretType.CANNON]["levels"][3]["range"])
	_mlrs_r4 = float(_turret_cfgs[TurretDataScript.TurretType.MLRS]["levels"][3]["range"])

	var all_enemies := [
		EnemyDataScript.EnemyType.JEEP,
		EnemyDataScript.EnemyType.APC,
		EnemyDataScript.EnemyType.TANK,
		EnemyDataScript.EnemyType.CHOPPER,
		EnemyDataScript.EnemyType.BOMBER,
		EnemyDataScript.EnemyType.JUGGERNAUT,
		EnemyDataScript.EnemyType.APS_TANK,
		EnemyDataScript.EnemyType.UAV_CARRIER,
		EnemyDataScript.EnemyType.FPV_DRONE,
		EnemyDataScript.EnemyType.SKY_FORTRESS,
	]
	for e in all_enemies:
		_enemy_cfgs[e] = EnemyDataScript.get_config(e)


func _run_full_audit() -> Dictionary:
	var maps: Array[Dictionary] = MapDataScript.get_all_maps()
	maps.append(MapDataScript.get_north_pole())

	var diffs := [
		WaveDataScript.Difficulty.EASY,
		WaveDataScript.Difficulty.NORMAL,
		WaveDataScript.Difficulty.HARD,
		WaveDataScript.Difficulty.HELL,
	]

	var sector_results: Array = []
	var summary_counts := {
		"total_sector_diffs": 0,
		"total_waves_audited": 0,
		"impossible_waves": 0,
		"tight_waves": 0,
		"healthy_waves": 0,
		"snowball_waves": 0,
		"wave1_impossible": 0,
		"wave1_tight": 0,
		"air_impossible_waves": 0,
		"air_gap_maps": 0,
		"dead_lane_maps": 0,
		"orphan_pad_maps": 0,
		"cash_overflow_sector_diffs": 0,
	}

	for m in maps:
		var map_id: String = String(m["id"])
		var waves: Array[Dictionary] = WaveDataScript.get_waves_for_map(map_id)
		var geom := _analyze_map_geometry(m)
		var lanes := _analyze_lane_distribution(m, waves)

		if geom["air_gap_flag"]:
			summary_counts["air_gap_maps"] += 1
		if lanes["has_dead_lane_sector"] or lanes["dead_lane_wave_count"] > 0:
			summary_counts["dead_lane_maps"] += 1
		if geom["orphan_pads"].size() > 0:
			summary_counts["orphan_pad_maps"] += 1

		var diff_results: Dictionary = {}
		for d in diffs:
			var diff_cfg: Dictionary = WaveDataScript.get_difficulty_config(d)
			var diff_name: String = String(diff_cfg["name"])
			var dr := _audit_sector_difficulty(m, waves, diff_cfg, geom)
			diff_results[diff_name] = dr

			summary_counts["total_sector_diffs"] += 1
			summary_counts["total_waves_audited"] += waves.size()
			summary_counts["impossible_waves"] += dr["counts"]["impossible"]
			summary_counts["tight_waves"] += dr["counts"]["tight"]
			summary_counts["healthy_waves"] += dr["counts"]["healthy"]
			summary_counts["snowball_waves"] += dr["counts"]["snowball"]
			summary_counts["air_impossible_waves"] += dr["counts"]["air_impossible"]
			if dr["wave1"]["status"] == "IMPOSSIBLE":
				summary_counts["wave1_impossible"] += 1
			elif dr["wave1"]["status"] == "TIGHT":
				summary_counts["wave1_tight"] += 1
			if dr["cash_overflow_wave"] != -1:
				summary_counts["cash_overflow_sector_diffs"] += 1

		sector_results.append({
			"id": map_id,
			"index": int(m["index"]),
			"short_name": String(m["short_name"]),
			"is_secret": bool(m.get("is_secret", false)),
			"hp_scale": float(m.get("hp_scale", 1.0)),
			"cash_bonus": int(m.get("cash_bonus", 0)),
			"wave_count": waves.size(),
			"geometry": geom,
			"lanes": lanes,
			"difficulties": diff_results,
		})

	return {
		"meta": {
			"version": "1.0",
			"sector_count": maps.size(),
			"thresholds": {
				"impossible": THRESH_IMPOSSIBLE,
				"tight": THRESH_TIGHT,
				"snowball": THRESH_SNOWBALL,
				"air_min_pads": THRESH_AIR_MIN_PADS,
				"air_min_cov_pct": THRESH_AIR_MIN_COV_PCT,
			},
		},
		"summary": summary_counts,
		"sectors": sector_results,
	}


# ==============================================================================
# 1. GEOMETRY & PAD COVERAGE ANALYSIS
# ==============================================================================

func _analyze_map_geometry(m: Dictionary) -> Dictionary:
	var g_paths: Array = m["ground_paths"]
	var air_path: PackedVector2Array = m["air_path"]
	var pads: Array = m["pads"]
	var num_lanes: int = g_paths.size()
	var num_pads: int = pads.size()

	var lane_lengths: Array = []
	var min_lane_len: float = INF
	var max_lane_len: float = 0.0
	for l in range(num_lanes):
		var plen := _polyline_length(g_paths[l])
		lane_lengths.append(plen)
		min_lane_len = minf(min_lane_len, plen)
		max_lane_len = maxf(max_lane_len, plen)
	var air_len := _polyline_length(air_path)

	# Per-pad coverage metrics
	var pad_info: Array = []
	var air_pads_vulcan1 := 0
	var air_pads_sam1 := 0
	var air_pads_laser1 := 0
	var air_pads_sam4 := 0
	var orphan_pads: Array = []

	# Track per-lane best single-pad coverage at Lv1 Vulcan & Lv1 Cannon/Laser
	var pad_lane_cov_v1: Array = [] # [pad_idx][lane_idx] -> covered length
	var pad_lane_cov_mid: Array = [] # [pad_idx][lane_idx] -> covered length at 245px (mid turret range)
	var pad_lane_cov_max: Array = [] # [pad_idx][lane_idx] -> covered length at 315px (Lv4 avg range)
	var pad_air_cov_sam1: Array = []
	var pad_air_cov_sam4: Array = []

	var shared_lane_pads_mid := 0

	for pi in range(num_pads):
		var p: Vector2 = pads[pi]
		var d_air: float = MapDataScript.distance_to_polyline(p, air_path)
		if d_air <= _vulcan_r1:
			air_pads_vulcan1 += 1
		if d_air <= _sam_r1:
			air_pads_sam1 += 1
		if d_air <= _laser_r1:
			air_pads_laser1 += 1
		if d_air <= _sam_r4:
			air_pads_sam4 += 1

		var air_c1 := _covered_length_circle_polyline(p, _sam_r1, air_path)
		var air_c4 := _covered_length_circle_polyline(p, _sam_r4, air_path)
		pad_air_cov_sam1.append(air_c1)
		pad_air_cov_sam4.append(air_c4)

		var cov_v1: Array = []
		var cov_mid: Array = []
		var cov_max: Array = []
		var min_g_dist: float = INF
		var lanes_hit_mid := 0
		for l in range(num_lanes):
			var dg: float = MapDataScript.distance_to_polyline(p, g_paths[l])
			min_g_dist = minf(min_g_dist, dg)
			cov_v1.append(_covered_length_circle_polyline(p, _vulcan_r1, g_paths[l]))
			var cm := _covered_length_circle_polyline(p, 245.0, g_paths[l])
			cov_mid.append(cm)
			if cm > 40.0:
				lanes_hit_mid += 1
			cov_max.append(_covered_length_circle_polyline(p, 315.0, g_paths[l]))

		if lanes_hit_mid >= 2:
			shared_lane_pads_mid += 1

		if min_g_dist > _vulcan_r1 and d_air > _sam_r1:
			orphan_pads.append(pi)

		pad_lane_cov_v1.append(cov_v1)
		pad_lane_cov_mid.append(cov_mid)
		pad_lane_cov_max.append(cov_max)
		pad_info.append({
			"idx": pi,
			"min_ground_dist": snappedf(min_g_dist, 0.1),
			"air_dist": snappedf(d_air, 0.1),
			"lanes_hit_mid": lanes_hit_mid,
		})

	# Exact path union coverage % & average simultaneous pad overlap
	var air_cov1 := _union_coverage_stats(pads, _sam_r1, air_path)
	var air_cov4 := _union_coverage_stats(pads, _sam_r4, air_path)
	var air_cov_v1 := _union_coverage_stats(pads, _vulcan_r1, air_path)

	var lane_cov_v1: Array = []
	var lane_cov_max: Array = []
	var lane_overlap_mid: Array = []
	var lane_overlap_max: Array = []
	var lane_avg_pad_cov_mid: Array = []
	var lane_avg_pad_cov_max: Array = []
	for l in range(num_lanes):
		var c1 := _union_coverage_stats(pads, _vulcan_r1, g_paths[l])
		var cm := _union_coverage_stats(pads, 245.0, g_paths[l])
		var c4 := _union_coverage_stats(pads, 315.0, g_paths[l])
		lane_cov_v1.append(c1["cov_pct"])
		lane_cov_max.append(c4["cov_pct"])
		lane_overlap_mid.append(cm["avg_pads"])
		lane_overlap_max.append(c4["avg_pads"])
		# Average road length covered by a single pad that actually reaches this lane
		var sum_m := 0.0
		var cnt_m := 0
		var sum_4 := 0.0
		var cnt_4 := 0
		for pi in range(num_pads):
			var vm: float = float(pad_lane_cov_mid[pi][l])
			if vm > 40.0:
				sum_m += vm
				cnt_m += 1
			var v4: float = float(pad_lane_cov_max[pi][l])
			if v4 > 40.0:
				sum_4 += v4
				cnt_4 += 1
		lane_avg_pad_cov_mid.append(sum_m / maxf(1.0, float(cnt_m)))
		lane_avg_pad_cov_max.append(sum_4 / maxf(1.0, float(cnt_4)))

	var avg_air_pad_cov_sam1 := 0.0
	var cnt_air1 := 0
	var avg_air_pad_cov_sam4 := 0.0
	var cnt_air4 := 0
	for pi in range(num_pads):
		if float(pad_air_cov_sam1[pi]) > 40.0:
			avg_air_pad_cov_sam1 += float(pad_air_cov_sam1[pi])
			cnt_air1 += 1
		if float(pad_air_cov_sam4[pi]) > 40.0:
			avg_air_pad_cov_sam4 += float(pad_air_cov_sam4[pi])
			cnt_air4 += 1
	avg_air_pad_cov_sam1 /= maxf(1.0, float(cnt_air1))
	avg_air_pad_cov_sam4 /= maxf(1.0, float(cnt_air4))

	# Effective lane convergence factor:
	# Measures what fraction of total map pads can engage a given ground lane at mid/late range.
	# If all lanes merge at a central choke (e.g. Scorched Wadi), most pads hit both lanes (~0.75-0.95).
	# If 3 lanes stay totally split, each lane only sees ~1/3 of pads (~0.35-0.50).
	var avg_lane_pad_share: float = 0.0
	for l in range(num_lanes):
		var pads_reaching_l := 0
		for pi in range(num_pads):
			if float(pad_lane_cov_mid[pi][l]) > 40.0:
				pads_reaching_l += 1
		avg_lane_pad_share += float(pads_reaching_l) / maxf(1.0, float(num_pads))
	avg_lane_pad_share /= maxf(1.0, float(num_lanes))

	var air_gap_flag: bool = (air_pads_sam1 < THRESH_AIR_MIN_PADS) or (float(air_cov1["cov_pct"]) < THRESH_AIR_MIN_COV_PCT)

	return {
		"num_lanes": num_lanes,
		"num_pads": num_pads,
		"lane_lengths": lane_lengths,
		"min_lane_len": snappedf(min_lane_len, 0.1),
		"max_lane_len": snappedf(max_lane_len, 0.1),
		"air_len": snappedf(air_len, 0.1),
		"air_pads_vulcan1": air_pads_vulcan1,
		"air_pads_sam1": air_pads_sam1,
		"air_pads_laser1": air_pads_laser1,
		"air_pads_sam4": air_pads_sam4,
		"air_cov_vulcan1_pct": snappedf(float(air_cov_v1["cov_pct"]), 0.1),
		"air_cov_sam1_pct": snappedf(float(air_cov1["cov_pct"]), 0.1),
		"air_cov_sam4_pct": snappedf(float(air_cov4["cov_pct"]), 0.1),
		"air_avg_pads_sam1": snappedf(float(air_cov1["avg_pads"]), 0.01),
		"air_avg_pads_sam4": snappedf(float(air_cov4["avg_pads"]), 0.01),
		"air_gap_flag": air_gap_flag,
		"lane_cov_v1_pct": lane_cov_v1,
		"lane_cov_max_pct": lane_cov_max,
		"lane_overlap_mid": lane_overlap_mid,
		"lane_overlap_max": lane_overlap_max,
		"lane_avg_pad_cov_mid": lane_avg_pad_cov_mid,
		"lane_avg_pad_cov_max": lane_avg_pad_cov_max,
		"avg_air_pad_cov_sam1": snappedf(avg_air_pad_cov_sam1, 0.1),
		"avg_air_pad_cov_sam4": snappedf(avg_air_pad_cov_sam4, 0.1),
		"shared_lane_pads_mid": shared_lane_pads_mid,
		"avg_lane_pad_share": snappedf(avg_lane_pad_share, 0.01),
		"orphan_pads": orphan_pads,
		# Internal arrays kept for Wave 1 & per-wave calculations (stripped before JSON export)
		"_pad_lane_cov_v1": pad_lane_cov_v1,
		"_pad_lane_cov_mid": pad_lane_cov_mid,
		"_pad_lane_cov_max": pad_lane_cov_max,
		"_pad_air_cov_sam1": pad_air_cov_sam1,
		"_pad_air_cov_sam4": pad_air_cov_sam4,
	}


func _polyline_length(poly: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(poly.size() - 1):
		total += poly[i].distance_to(poly[i + 1])
	return total


# Exact length of polyline segments lying inside circle(center, radius)
func _covered_length_circle_polyline(center: Vector2, radius: float, poly: PackedVector2Array) -> float:
	var r_sq := radius * radius
	var covered := 0.0
	for i in range(poly.size() - 1):
		covered += _segment_length_in_circle(poly[i], poly[i + 1], center, r_sq)
	return covered


func _segment_length_in_circle(a: Vector2, b: Vector2, c: Vector2, r_sq: float) -> float:
	var d := b - a
	var f := a - c
	var qa := d.dot(d)
	if qa < 0.00001:
		return 0.0
	var qb := 2.0 * f.dot(d)
	var qc := f.dot(f) - r_sq
	var disc := qb * qb - 4.0 * qa * qc
	if disc <= 0.0:
		return 0.0
	var sqrt_d := sqrt(disc)
	var t1 := (-qb - sqrt_d) / (2.0 * qa)
	var t2 := (-qb + sqrt_d) / (2.0 * qa)
	var lo := clampf(t1, 0.0, 1.0)
	var hi := clampf(t2, 0.0, 1.0)
	if hi <= lo:
		return 0.0
	return (hi - lo) * sqrt(qa)


func _union_coverage_stats(pads: Array, radius: float, poly: PackedVector2Array) -> Dictionary:
	var total_len := 0.0
	var covered_len := 0.0
	var overlap_weighted := 0.0
	var r_sq := radius * radius

	for i in range(poly.size() - 1):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[i + 1]
		var seg_len := a.distance_to(b)
		if seg_len < 0.01:
			continue
		# Subdivide segment to ~8px samples for exact union coverage
		var steps := maxi(1, int(ceil(seg_len / 8.0)))
		var dl := seg_len / float(steps)
		for s in range(steps):
			var u := (float(s) + 0.5) / float(steps)
			var pt := a.lerp(b, u)
			var cnt := 0
			for p in pads:
				if pt.distance_squared_to(p) <= r_sq:
					cnt += 1
			total_len += dl
			if cnt > 0:
				covered_len += dl
				overlap_weighted += float(cnt) * dl

	var cov_pct := (covered_len / maxf(1.0, total_len)) * 100.0
	var avg_pads := overlap_weighted / maxf(1.0, total_len)
	return {"cov_pct": cov_pct, "avg_pads": avg_pads}


# ==============================================================================
# 2. LANE DISTRIBUTION & DEAD-LANE AUDIT
# ==============================================================================

func _analyze_lane_distribution(m: Dictionary, waves: Array[Dictionary]) -> Dictionary:
	var num_lanes: int = (m["ground_paths"] as Array).size()
	var total_per_lane: Array = []
	for _l in range(num_lanes):
		total_per_lane.append(0)

	var dead_lane_waves: Array = []
	var total_ground := 0

	for wi in range(waves.size()):
		var w_counts: Array = []
		for _l in range(num_lanes):
			w_counts.append(0)
		var w_ground := 0

		for g in waves[wi]["groups"]:
			var etype: EnemyDataScript.EnemyType = g["type"]
			var ecfg: Dictionary = _enemy_cfgs[etype]
			if bool(ecfg["is_air"]):
				continue
			var cnt: int = int(g["count"])
			var lane_cfg: int = int(g.get("lane", 0))
			for k in range(cnt):
				var l_idx: int = (k if lane_cfg < 0 else lane_cfg) % num_lanes
				w_counts[l_idx] = int(w_counts[l_idx]) + 1
				total_per_lane[l_idx] = int(total_per_lane[l_idx]) + 1
				w_ground += 1
				total_ground += 1

		if num_lanes > 1 and w_ground > 0:
			var empty_lanes: Array = []
			for l in range(num_lanes):
				if int(w_counts[l]) == 0:
					empty_lanes.append(l)
			if empty_lanes.size() > 0:
				dead_lane_waves.append({
					"wave": wi + 1,
					"title": String(waves[wi]["title"]),
					"empty_lanes": empty_lanes,
					"counts": w_counts,
				})

	var lane_shares_pct: Array = []
	var has_dead_lane_sector := false
	var underused_lanes: Array = []
	for l in range(num_lanes):
		var pct := (float(total_per_lane[l]) / maxf(1.0, float(total_ground))) * 100.0
		lane_shares_pct.append(snappedf(pct, 0.1))
		if num_lanes > 1 and int(total_per_lane[l]) == 0:
			has_dead_lane_sector = true
		if num_lanes > 1 and pct < THRESH_LANE_UNDERUSE_PCT:
			underused_lanes.append(l)

	return {
		"num_lanes": num_lanes,
		"total_ground_enemies": total_ground,
		"total_per_lane": total_per_lane,
		"lane_shares_pct": lane_shares_pct,
		"has_dead_lane_sector": has_dead_lane_sector,
		"underused_lanes": underused_lanes,
		"dead_lane_wave_count": dead_lane_waves.size(),
		"dead_lane_waves": dead_lane_waves,
	}


# ==============================================================================
# 3. SECTOR x DIFFICULTY SURVIVABILITY & ECONOMY MODEL
# ==============================================================================

func _audit_sector_difficulty(
	m: Dictionary,
	waves: Array[Dictionary],
	diff_cfg: Dictionary,
	geom: Dictionary
) -> Dictionary:
	var start_cash: int = int(diff_cfg["start_cash"]) + int(m.get("cash_bonus", 0))
	var hp_mult_diff: float = float(diff_cfg["hp_mult"])
	var spd_mult: float = float(diff_cfg["speed_mult"])
	var rew_mult: float = float(diff_cfg["reward_mult"])
	var sector_hp_scale: float = float(m.get("hp_scale", 1.0))
	var num_pads: int = int(geom["num_pads"])

	# Realistic cost to max every pad on the map (~$840 avg Lv1->Lv4 across mixed roster)
	var avg_max_pad_cost := _compute_avg_max_pad_cost()
	var max_map_budget: float = float(num_pads) * avg_max_pad_cost

	var cum_cash: float = float(start_cash)
	var cum_ehp_real: float = 0.0
	var wave_reports: Array = []

	var counts := {
		"impossible": 0,
		"tight": 0,
		"healthy": 0,
		"snowball": 0,
		"air_impossible": 0,
	}

	var worst_real_ratio := INF
	var worst_real_wave := 1
	var worst_opt_ratio := INF
	var worst_opt_wave := 1
	var peak_real_ratio := 0.0
	var peak_real_wave := 1
	var cash_overflow_wave := -1
	var first_snowball_wave := -1
	var first_impossible_wave := -1
	var wave1_detail: Dictionary = {}

	for wi in range(waves.size()):
		var w_num := wi + 1
		var wave_def: Dictionary = waves[wi]
		var wave_scale: float = 1.0 + float(wi) * WAVE_HP_STEP
		var hp_mult: float = hp_mult_diff * wave_scale * sector_hp_scale

		# Analyze wave enemy demand & exact 0.5s timeline peak DPS
		var demand := _compute_wave_demand(wave_def, hp_mult, spd_mult, rew_mult, geom)

		# Dedicated Wave 1 geometric survivability audit
		var w_real_ratio := 0.0
		var w_opt_ratio := 0.0
		var air_ratio_real := 99.0
		var air_ratio_opt := 99.0
		var real_dps_cap := 0.0
		var opt_dps_cap := 0.0

		if wi == 0:
			wave1_detail = _audit_wave1_exact(wave_def, start_cash, hp_mult, spd_mult, rew_mult, geom, demand)
			w_real_ratio = float(wave1_detail["real_ratio"])
			w_opt_ratio = float(wave1_detail["opt_ratio"])
			real_dps_cap = float(wave1_detail["real_dps"])
			opt_dps_cap = float(wave1_detail["opt_dps"])
		else:
			# Dual-envelope budget & DPS model for Waves 2..N
			var env := _evaluate_dual_envelope(cum_cash, demand, geom, num_pads)
			w_real_ratio = float(env["real_ratio"])
			w_opt_ratio = float(env["opt_ratio"])
			air_ratio_real = float(env["air_ratio_real"])
			air_ratio_opt = float(env["air_ratio_opt"])
			real_dps_cap = float(env["real_dps"])
			opt_dps_cap = float(env["opt_dps"])

		var cash_overflow := (cum_cash > max_map_budget)
		if cash_overflow and cash_overflow_wave == -1:
			cash_overflow_wave = w_num

		var status := "HEALTHY"
		if w_opt_ratio < THRESH_IMPOSSIBLE or (bool(demand["has_air"]) and air_ratio_opt < THRESH_IMPOSSIBLE):
			status = "IMPOSSIBLE"
			counts["impossible"] += 1
			if first_impossible_wave == -1:
				first_impossible_wave = w_num
		elif w_real_ratio < THRESH_TIGHT or (bool(demand["has_air"]) and air_ratio_real < THRESH_TIGHT):
			status = "TIGHT"
			counts["tight"] += 1
		elif w_real_ratio > THRESH_SNOWBALL or cash_overflow:
			status = "SNOWBALL"
			counts["snowball"] += 1
			if first_snowball_wave == -1:
				first_snowball_wave = w_num
		else:
			counts["healthy"] += 1

		if bool(demand["has_air"]) and air_ratio_opt < THRESH_IMPOSSIBLE:
			counts["air_impossible"] += 1

		if w_real_ratio < worst_real_ratio:
			worst_real_ratio = w_real_ratio
			worst_real_wave = w_num
		if w_opt_ratio < worst_opt_ratio:
			worst_opt_ratio = w_opt_ratio
			worst_opt_wave = w_num
		if w_real_ratio > peak_real_ratio:
			peak_real_ratio = w_real_ratio
			peak_real_wave = w_num

		cum_ehp_real += float(demand["total_ehp_real"])

		wave_reports.append({
			"wave": w_num,
			"title": String(wave_def["title"]),
			"hp_mult": snappedf(hp_mult, 0.01),
			"cash_before": int(round(cum_cash)),
			"cash_pct_of_max_map": snappedf((cum_cash / maxf(1.0, max_map_budget)) * 100.0, 0.1),
			"enemy_count": int(demand["total_units"]),
			"raw_hp": int(round(float(demand["total_raw_hp"]))),
			"ehp_real": int(round(float(demand["total_ehp_real"]))),
			"ehp_opt": int(round(float(demand["total_ehp_opt"]))),
			"air_ehp_real": int(round(float(demand["air_ehp_real"]))),
			"peak_req_dps_real": snappedf(float(demand["peak_req_dps_real"]), 0.1),
			"peak_req_dps_opt": snappedf(float(demand["peak_req_dps_opt"]), 0.1),
			"peak_air_req_dps": snappedf(float(demand["peak_air_req_dps_real"]), 0.1),
			"real_dps": snappedf(real_dps_cap, 0.1),
			"opt_dps": snappedf(opt_dps_cap, 0.1),
			"real_ratio": snappedf(w_real_ratio, 0.01),
			"opt_ratio": snappedf(w_opt_ratio, 0.01),
			"air_ratio_real": snappedf(minf(99.0, air_ratio_real), 0.01),
			"air_ratio_opt": snappedf(minf(99.0, air_ratio_opt), 0.01),
			"kill_cash": int(demand["kill_cash"]),
			"wave_bonus": int(wave_def["bonus"]),
			"status": status,
			"has_air": bool(demand["has_air"]),
		})

		# Update cumulative cash for next wave (strictly no early-call bonus!)
		cum_cash += float(demand["kill_cash"]) + float(wave_def["bonus"])

	return {
		"start_cash": start_cash,
		"end_cash": int(round(cum_cash)),
		"max_map_budget": int(round(max_map_budget)),
		"cash_to_max_ratio": snappedf(cum_cash / maxf(1.0, max_map_budget), 0.01),
		"total_cum_ehp": int(round(cum_ehp_real)),
		"counts": counts,
		"wave1": wave1_detail,
		"worst_real_ratio": snappedf(worst_real_ratio, 0.01),
		"worst_real_wave": worst_real_wave,
		"worst_opt_ratio": snappedf(worst_opt_ratio, 0.01),
		"worst_opt_wave": worst_opt_wave,
		"peak_real_ratio": snappedf(peak_real_ratio, 0.01),
		"peak_real_wave": peak_real_wave,
		"first_impossible_wave": first_impossible_wave,
		"first_snowball_wave": first_snowball_wave,
		"cash_overflow_wave": cash_overflow_wave,
		"waves": wave_reports,
	}


# ==============================================================================
# 4. WAVE DEMAND & TIMELINE PEAK DPS MODEL
# ==============================================================================

func _compute_wave_demand(
	wave_def: Dictionary,
	hp_mult: float,
	spd_mult: float,
	rew_mult: float,
	geom: Dictionary
) -> Dictionary:
	var lane_lengths: Array = geom["lane_lengths"]
	var num_lanes: int = int(geom["num_lanes"])
	var air_len: float = float(geom["air_len"])

	var total_units := 0
	var ground_units := 0
	var air_units := 0
	var total_raw_hp := 0.0
	var total_ehp_real := 0.0
	var total_ehp_opt := 0.0
	var ground_ehp_real := 0.0
	var ground_ehp_opt := 0.0
	var air_ehp_real := 0.0
	var air_ehp_opt := 0.0
	var aps_shield_total := 0.0
	var kill_cash := 0

	# Track weighted armor & spacing for AOE splash modeling
	var armor_weighted_sum := 0.0
	var heavy_ehp_sum := 0.0
	var swarm_density_sum := 0.0
	var swarm_weight_sum := 0.0
	var gnd_speed_weighted := 0.0
	var air_speed_weighted := 0.0

	# Active intervals for exact 0.5s peak concurrent DPS timeline
	# Each entry: {t0, t1, dps_real, dps_opt, is_air}
	var intervals: Array = []
	var max_t_end := 1.0
	var max_t_spawn := 0.0

	# Track per-lane EHP & unit count for Wave 1 / split-lane analysis
	var lane_ehp_real: Array = []
	var lane_unit_counts: Array = []
	for _l in range(num_lanes):
		lane_ehp_real.append(0.0)
		lane_unit_counts.append(0)

	# Average armor-pierce of realistic mixed defense (~0.68) vs optimized counter defense (~0.94)
	const AP_REAL := 0.68
	const AP_OPT := 0.94

	var fpv_cfg: Dictionary = _enemy_cfgs[EnemyDataScript.EnemyType.FPV_DRONE]
	var fpv_hp: float = float(fpv_cfg["hp"]) * hp_mult
	var fpv_spd: float = float(fpv_cfg["speed"]) * spd_mult

	for g in wave_def["groups"]:
		var etype: EnemyDataScript.EnemyType = g["type"]
		var ecfg: Dictionary = _enemy_cfgs[etype]
		var cnt: int = int(g["count"])
		var interval: float = maxf(0.05, float(g["interval"]))
		var delay: float = float(g["delay"])
		var lane_cfg: int = int(g.get("lane", 0))
		var is_air: bool = bool(ecfg["is_air"])

		var hp: float = float(ecfg["hp"]) * hp_mult
		var shield: float = float(ecfg.get("shield", 0.0)) * hp_mult
		var spd: float = float(ecfg["speed"]) * spd_mult
		var armor: float = float(ecfg["armor"])
		var base_rew: int = int(ecfg["reward"])
		var rew: int = 0 if base_rew <= 0 else maxi(1, int(round(float(base_rew) * rew_mult)))

		# Armor-adjusted EHP (how much raw turret damage is required to kill 1 unit)
		var eff_arm_real: float = maxf(0.0, armor * (1.0 - AP_REAL))
		var eff_arm_opt: float = maxf(0.0, armor * (1.0 - AP_OPT))
		var hull_ehp_real: float = hp / maxf(0.15, 1.0 - eff_arm_real)
		var hull_ehp_opt: float = hp / maxf(0.15, 1.0 - eff_arm_opt)

		# APS shield EHP: realistic takes 1.15x (partial regen), optimized (Laser 2x vs shield) takes 0.50x
		var shield_ehp_real: float = shield * 1.15
		var shield_ehp_opt: float = shield * 0.50

		var unit_ehp_r: float = hull_ehp_real + shield_ehp_real
		var unit_ehp_o: float = hull_ehp_opt + shield_ehp_opt

		# Spacing between consecutive units in this group (px) — drives realistic AOE overlap
		var spacing_px: float = interval * spd
		var splash_hits_est: float = clampf(95.0 / maxf(18.0, spacing_px), 1.0, 4.0)

		for k in range(cnt):
			var l_idx: int = 0 if is_air else ((k if lane_cfg < 0 else lane_cfg) % num_lanes)
			var plen: float = air_len if is_air else float(lane_lengths[l_idx])
			var t_travel: float = plen / maxf(10.0, spd)
			var t0: float = delay + float(k) * interval
			var t1: float = t0 + t_travel
			max_t_spawn = maxf(max_t_spawn, t0)
			max_t_end = maxf(max_t_end, t1)

			# Path engagement fraction (portion of path actually under fire)
			var engage_frac: float = 0.72
			if is_air:
				engage_frac = clampf(float(geom["air_cov_sam1_pct"]) / 100.0, 0.15, 0.92)
			else:
				var lcov: float = float(geom["lane_cov_max_pct"][l_idx]) / 100.0
				engage_frac = clampf(lcov * 0.85, 0.25, 0.92)

			var active_dur := maxf(1.5, t_travel * engage_frac)
			intervals.append({
				"t0": t0,
				"t1": t1,
				"dps_real": unit_ehp_r / active_dur,
				"dps_opt": unit_ehp_o / active_dur,
				"is_air": is_air,
			})

			total_units += 1
			total_raw_hp += hp + shield
			total_ehp_real += unit_ehp_r
			total_ehp_opt += unit_ehp_o
			aps_shield_total += shield
			kill_cash += rew
			armor_weighted_sum += armor * unit_ehp_r
			if armor >= 0.45 or hp >= 300.0 * hp_mult:
				heavy_ehp_sum += unit_ehp_r

			if is_air:
				air_units += 1
				air_ehp_real += unit_ehp_r
				air_ehp_opt += unit_ehp_o
				air_speed_weighted += spd * unit_ehp_r
			else:
				ground_units += 1
				ground_ehp_real += unit_ehp_r
				ground_ehp_opt += unit_ehp_o
				gnd_speed_weighted += spd * unit_ehp_r
				lane_ehp_real[l_idx] = float(lane_ehp_real[l_idx]) + unit_ehp_r
				lane_unit_counts[l_idx] = int(lane_unit_counts[l_idx]) + 1
				swarm_density_sum += splash_hits_est * unit_ehp_r
				swarm_weight_sum += unit_ehp_r

			# Account for FPV Drones launched by UAV_CARRIER!
			if etype == EnemyDataScript.EnemyType.UAV_CARRIER:
				var max_spawns := int(ecfg.get("uav_max_spawns", 5))
				var first_d := float(ecfg.get("uav_first_delay", 2.2))
				var sp_int := float(ecfg.get("uav_spawn_interval", 4.6))
				var max_by_time := int(floor(maxf(0.0, t_travel - first_d) / sp_int)) + 1
				var launches_real := mini(max_spawns, mini(max_by_time, 3))
				var launches_opt := mini(max_spawns, mini(max_by_time, 2))
				var fpv_travel := (air_len * 0.65) / maxf(10.0, fpv_spd)
				var air_eng := clampf(float(geom["air_cov_sam1_pct"]) / 100.0, 0.15, 0.90)
				for s_idx in range(launches_real):
					var st0 := t0 + first_d + float(s_idx) * sp_int
					var st1 := st0 + fpv_travel
					max_t_end = maxf(max_t_end, st1)
					var d_r := fpv_hp / maxf(1.2, fpv_travel * air_eng)
					var d_o := d_r if s_idx < launches_opt else 0.0
					intervals.append({
						"t0": st0,
						"t1": st1,
						"dps_real": d_r,
						"dps_opt": d_o,
						"is_air": true,
					})
					total_raw_hp += fpv_hp
					total_ehp_real += fpv_hp
					air_ehp_real += fpv_hp
					air_units += 1
					if s_idx < launches_opt:
						total_ehp_opt += fpv_hp
						air_ehp_opt += fpv_hp

	# Sample timeline at 0.5s steps to find exact peak simultaneous DPS demand
	var peak_req_real := 0.0
	var peak_req_opt := 0.0
	var peak_gnd_real := 0.0
	var peak_gnd_opt := 0.0
	var peak_air_real := 0.0
	var peak_air_opt := 0.0

	var t := 0.0
	while t <= max_t_end:
		var cur_r := 0.0
		var cur_o := 0.0
		var cur_gr := 0.0
		var cur_go := 0.0
		var cur_ar := 0.0
		var cur_ao := 0.0
		for iv in intervals:
			if t >= float(iv["t0"]) and t <= float(iv["t1"]):
				var dr: float = float(iv["dps_real"])
				var do_val: float = float(iv["dps_opt"])
				cur_r += dr
				cur_o += do_val
				if bool(iv["is_air"]):
					cur_ar += dr
					cur_ao += do_val
				else:
					cur_gr += dr
					cur_go += do_val
		peak_req_real = maxf(peak_req_real, cur_r)
		peak_req_opt = maxf(peak_req_opt, cur_o)
		peak_gnd_real = maxf(peak_gnd_real, cur_gr)
		peak_gnd_opt = maxf(peak_gnd_opt, cur_go)
		peak_air_real = maxf(peak_air_real, cur_ar)
		peak_air_opt = maxf(peak_air_opt, cur_ao)
		t += 0.5

	var avg_armor := armor_weighted_sum / maxf(1.0, total_ehp_real)
	var heavy_frac := heavy_ehp_sum / maxf(1.0, total_ehp_real)
	var air_frac := air_ehp_real / maxf(1.0, total_ehp_real)
	var avg_splash_density := swarm_density_sum / maxf(1.0, swarm_weight_sum) if swarm_weight_sum > 0.0 else 1.0
	var avg_gnd_speed := gnd_speed_weighted / maxf(1.0, ground_ehp_real) if ground_ehp_real > 0.0 else 60.0
	var avg_air_speed := air_speed_weighted / maxf(1.0, air_ehp_real) if air_ehp_real > 0.0 else 80.0

	return {
		"total_units": total_units,
		"ground_units": ground_units,
		"air_units": air_units,
		"has_air": air_units > 0,
		"total_raw_hp": total_raw_hp,
		"total_ehp_real": total_ehp_real,
		"total_ehp_opt": total_ehp_opt,
		"ground_ehp_real": ground_ehp_real,
		"ground_ehp_opt": ground_ehp_opt,
		"air_ehp_real": air_ehp_real,
		"air_ehp_opt": air_ehp_opt,
		"aps_shield_total": aps_shield_total,
		"kill_cash": kill_cash,
		"avg_armor": avg_armor,
		"heavy_frac": heavy_frac,
		"air_frac": air_frac,
		"avg_splash_density": avg_splash_density,
		"avg_gnd_speed": avg_gnd_speed,
		"avg_air_speed": avg_air_speed,
		"wave_duration": max_t_end,
		"spawn_duration": max_t_spawn,
		"peak_req_dps_real": peak_req_real,
		"peak_req_dps_opt": peak_req_opt,
		"peak_gnd_req_dps_real": peak_gnd_real,
		"peak_gnd_req_dps_opt": peak_gnd_opt,
		"peak_air_req_dps_real": peak_air_real,
		"peak_air_req_dps_opt": peak_air_opt,
		"lane_ehp_real": lane_ehp_real,
		"lane_unit_counts": lane_unit_counts,
	}


# ==============================================================================
# 5. DEDICATED WAVE 1 EXACT GEOMETRIC SURVIVABILITY AUDIT
# ==============================================================================

func _audit_wave1_exact(
	wave_def: Dictionary,
	start_cash: int,
	hp_mult: float,
	spd_mult: float,
	rew_mult: float,
	geom: Dictionary,
	demand: Dictionary
) -> Dictionary:
	var pad_lane_v1: Array = geom["_pad_lane_cov_v1"]
	var lane_lengths: Array = geom["lane_lengths"]
	var num_lanes: int = int(geom["num_lanes"])
	var num_pads: int = int(geom["num_pads"])

	var v_lv0: Dictionary = _turret_cfgs[TurretDataScript.TurretType.VULCAN]["levels"][0]
	var c_lv0: Dictionary = _turret_cfgs[TurretDataScript.TurretType.CANNON]["levels"][0]
	var cryo_lv0: Dictionary = _turret_cfgs[TurretDataScript.TurretType.CRYO]["levels"][0]
	var v_cost: int = int(v_lv0["cost"])       # $70
	var cryo_cost: int = int(cryo_lv0["cost"]) # $100

	var v_raw_dps: float = float(v_lv0["damage"]) * float(v_lv0["fire_rate"]) # 68.2
	var v_ap: float = float(v_lv0["armor_pierce"]) # 0.15

	# Wave 1 is Recon Jeeps (armor 0.05, speed 96 * spd_mult, hp 58 * hp_mult)
	var first_group: Dictionary = wave_def["groups"][0]
	var ecfg: Dictionary = _enemy_cfgs[first_group["type"]]
	var unit_hp: float = float(ecfg["hp"]) * hp_mult
	var unit_spd: float = float(ecfg["speed"]) * spd_mult
	var unit_arm: float = float(ecfg["armor"])
	var eff_arm_v: float = maxf(0.0, unit_arm * (1.0 - v_ap))
	var v_eff_dps: float = v_raw_dps * (1.0 - eff_arm_v)

	# Determine which lanes are active in Wave 1
	var active_lanes: Array = []
	for l in range(num_lanes):
		if float(demand["lane_ehp_real"][l]) > 0.0:
			active_lanes.append(l)
	if active_lanes.is_empty():
		active_lanes.append(0)

	# Pre-wave starting budget + 40% of Wave 1 kill cash realistically reinvestable mid-wave
	var pre_vulcans: int = mini(num_pads, int(floor(float(start_cash) / float(v_cost))))
	var mid_cash: float = float(start_cash) + float(demand["kill_cash"]) * 0.40
	var mid_vulcans: int = mini(num_pads, int(floor(mid_cash / float(v_cost))))

	# Greedily pick best pads covering active lanes (prioritizing shared choke pads first!)
	var chosen_pads: Array = []
	var lane_cov_sum: Array = []
	for _l in range(num_lanes):
		lane_cov_sum.append(0.0)

	for _slot in range(mid_vulcans):
		var best_pad := -1
		var best_score := -1.0
		for pi in range(num_pads):
			if pi in chosen_pads:
				continue
			# Score favors covering the least-covered active lane + total active lane coverage
			var score := 0.0
			for l in active_lanes:
				var c: float = float(pad_lane_v1[pi][l])
				if c <= 1.0:
					continue
				var need_weight := 1.0 / (1.0 + float(lane_cov_sum[l]) / 250.0)
				score += c * need_weight
			if score > best_score:
				best_score = score
				best_pad = pi
		if best_pad == -1:
			break
		chosen_pads.append(best_pad)
		for l in active_lanes:
			lane_cov_sum[l] = float(lane_cov_sum[l]) + float(pad_lane_v1[best_pad][l])

	# Compute total deliverable damage on Wave 1 across active lanes:
	# 1. Pre-wave Vulcan-only single-unit kill check on the weakest active lane
	# 2. Full-wave realistic capacity (pre_vulcans active 100%, extra mid_vulcans active 50% of wave)
	var pre_lane_cov: Array = []
	for _l in range(num_lanes):
		pre_lane_cov.append(0.0)
	for idx in range(mini(pre_vulcans, chosen_pads.size())):
		var pi: int = chosen_pads[idx]
		for l in active_lanes:
			pre_lane_cov[l] = float(pre_lane_cov[l]) + float(pad_lane_v1[pi][l])

	var min_lane_single_kill_ratio := INF
	var min_lane_wave_ratio := INF
	var total_real_dps_effective := 0.0
	var total_real_damage_cap := 0.0
	var shortest_active_travel := INF
	var wave_spawn_dur: float = float(demand["spawn_duration"])
	var lane_unit_counts: Array = demand["lane_unit_counts"]

	for l in active_lanes:
		var llen: float = float(lane_lengths[l])
		var t_travel: float = llen / maxf(10.0, unit_spd)
		shortest_active_travel = minf(shortest_active_travel, t_travel)
		var n_lane: int = maxi(1, int(lane_unit_counts[l]))

		# Time first enemy spends under fire from pre-wave turrets on this lane
		var pre_time_in_range: float = float(pre_lane_cov[l]) / maxf(10.0, unit_spd)
		var single_dmg: float = pre_time_in_range * v_eff_dps
		min_lane_single_kill_ratio = minf(min_lane_single_kill_ratio, single_dmg / maxf(1.0, unit_hp))

		# Exact per-pad deliverable damage on lane `l`:
		# Each turret `pi` covers length `c_l` -> single-unit dwell time `t_pass = c_l / unit_spd`.
		# Over the wave, pad `pi` can fire at lane `l` for at most min(n_lane * t_pass, wave_spawn_dur + t_pass).
		var lane_dmg_cap := 0.0
		var lane_eff_turrets := 0.0
		for idx in range(chosen_pads.size()):
			var pi: int = chosen_pads[idx]
			var c_l: float = float(pad_lane_v1[pi][l])
			if c_l <= 35.0:
				continue
			var c_all := 0.0
			for al in active_lanes:
				c_all += float(pad_lane_cov_safe(pad_lane_v1, pi, al))
			var share := c_l / maxf(1.0, c_all)
			var w_time := 1.0 if idx < pre_vulcans else 0.45
			var t_pass := c_l / maxf(10.0, unit_spd)
			var pad_fire_s := minf(float(n_lane) * t_pass, wave_spawn_dur + t_pass)
			lane_dmg_cap += share * w_time * v_eff_dps * pad_fire_s
			lane_eff_turrets += share * w_time

		var lane_ehp: float = float(demand["lane_ehp_real"][l])
		min_lane_wave_ratio = minf(min_lane_wave_ratio, lane_dmg_cap / maxf(1.0, lane_ehp))
		total_real_damage_cap += lane_dmg_cap
		total_real_dps_effective += lane_eff_turrets * v_eff_dps

	# Realistic ratio: bounded by total wave capacity, weakest lane capacity, and single-unit kill ability
	var w1_total_ehp_r: float = float(demand["total_ehp_real"])
	var cap_ratio_real := total_real_damage_cap / maxf(1.0, w1_total_ehp_r)
	var real_ratio := minf(cap_ratio_real, minf(min_lane_wave_ratio * 1.05, min_lane_single_kill_ratio * 1.10))

	# Optimized Wave 1: considers Cryo + Vulcan/Cannon combo (Cryo slows Jeeps 34% -> 1.51x dwell time,
	# plus Cannon splash on tight groups, plus full mid-wave reinvestment of 65% kill cash)
	var opt_mult := 1.0
	if start_cash >= v_cost + cryo_cost:
		# Cryo + Vulcans gives ~1.30x effective damage window on tight Wave 1 streams
		opt_mult = 1.32
	if float(demand["avg_splash_density"]) > 1.3 and start_cash >= int(c_lv0["cost"]) + v_cost:
		opt_mult = maxf(opt_mult, 1.38)
	var opt_dps := total_real_dps_effective * opt_mult
	var opt_ratio := real_ratio * opt_mult

	var status := "HEALTHY"
	if opt_ratio < THRESH_IMPOSSIBLE:
		status = "IMPOSSIBLE"
	elif real_ratio < THRESH_TIGHT:
		status = "TIGHT"
	elif real_ratio > THRESH_SNOWBALL:
		status = "SNOWBALL"

	return {
		"start_cash": start_cash,
		"pre_vulcans": pre_vulcans,
		"mid_vulcans": mid_vulcans,
		"active_lanes": active_lanes.size(),
		"shortest_travel_s": snappedf(shortest_active_travel, 0.1),
		"unit_hp": snappedf(unit_hp, 0.1),
		"wave1_units": int(demand["total_units"]),
		"wave1_ehp": int(round(w1_total_ehp_r)),
		"single_kill_ratio": snappedf(min_lane_single_kill_ratio, 0.01),
		"real_dps": snappedf(total_real_dps_effective, 0.1),
		"opt_dps": snappedf(opt_dps, 0.1),
		"real_ratio": snappedf(real_ratio, 0.01),
		"opt_ratio": snappedf(opt_ratio, 0.01),
		"status": status,
	}


func pad_lane_cov_safe(arr: Array, pi: int, l: int) -> float:
	return float(arr[pi][l])


# ==============================================================================
# 6. DUAL-ENVELOPE DEFENSE MODEL (WAVES 2..N)
# ==============================================================================

func _compute_avg_max_pad_cost() -> float:
	var weights := {
		TurretDataScript.TurretType.VULCAN: 0.22,
		TurretDataScript.TurretType.CRYO: 0.12,
		TurretDataScript.TurretType.CANNON: 0.18,
		TurretDataScript.TurretType.MISSILE: 0.18,
		TurretDataScript.TurretType.LASER: 0.12,
		TurretDataScript.TurretType.MLRS: 0.10,
		TurretDataScript.TurretType.DRONE: 0.08,
	}
	var avg := 0.0
	for t in weights.keys():
		var lvls: Array = _turret_cfgs[t]["levels"]
		var tot := 0.0
		for lv in lvls:
			tot += float(lv["cost"])
		avg += tot * float(weights[t])
	return avg


# Compute sustained effective DPS and total cumulative cost of a turret at level `lv` (0..3)
func _turret_tier_metrics(
	t: TurretDataScript.TurretType,
	lv: int,
	splash_density: float,
	is_optimized: bool,
	against_air: bool
) -> Dictionary:
	var cfg: Dictionary = _turret_cfgs[t]
	var lvls: Array = cfg["levels"]
	var st: Dictionary = lvls[lv]

	var cum_cost := 0.0
	for i in range(lv + 1):
		cum_cost += float(lvls[i]["cost"])

	var dmg := float(st["damage"])
	var fr := float(st["fire_rate"])
	var raw_dps := dmg * fr

	match t:
		TurretDataScript.TurretType.VULCAN:
			pass
		TurretDataScript.TurretType.CRYO:
			var splash_f := clampf(splash_density, 1.0, 2.2 if is_optimized else 1.5)
			raw_dps *= splash_f
		TurretDataScript.TurretType.CANNON:
			if against_air:
				raw_dps = 0.0
			else:
				var splash_f := clampf(1.0 + (splash_density - 1.0) * 0.72, 1.0, 2.4 if is_optimized else 1.6)
				raw_dps *= splash_f
		TurretDataScript.TurretType.MISSILE:
			var splash_f := clampf(1.0 + (splash_density - 1.0) * 0.42, 1.0, 1.65 if is_optimized else 1.25)
			raw_dps *= splash_f
			if against_air:
				raw_dps *= float(cfg.get("air_bonus", 1.65))
		TurretDataScript.TurretType.LASER:
			var max_r := float(st.get("max_ramp", 2.2))
			# Average ramp depends on target durability & focus fire
			var ramp_frac := 0.62 if is_optimized else 0.36
			raw_dps = dmg * lerpf(1.0, max_r, ramp_frac)
		TurretDataScript.TurretType.MLRS:
			if against_air:
				raw_dps = 0.0
			else:
				var salvo := float(st.get("salvo_count", 3))
				var impact_dps := dmg * salvo * fr
				var burn_dps := float(st.get("burn_dps", 14.0))
				var burn_dur := float(st.get("burn_dur", 3.4))
				# Each salvo lays `salvo` overlapping burn pools; average enemy crosses ~1.6-2.4s of fire
				var burn_contact := (2.2 if is_optimized else 1.45) * minf(burn_dur, 4.0) / maxf(1.0, burn_dur)
				var pool_dps := burn_dps * burn_contact * (1.8 if is_optimized else 1.15)
				var splash_f := clampf(1.0 + (splash_density - 1.0) * 0.65, 1.0, 2.3 if is_optimized else 1.55)
				raw_dps = (impact_dps * splash_f) + (pool_dps * splash_f)
		TurretDataScript.TurretType.DRONE:
			# Map-wide pursuit, but loses time to flight + rearm between kills
			var uptime := 0.80 if is_optimized else 0.66
			raw_dps = dmg * fr * uptime

	return {
		"cost": cum_cost,
		"dps": raw_dps,
		"ap": float(st["armor_pierce"]),
		"can_air": bool(cfg["can_hit_air"]),
		"can_ground": bool(cfg["can_hit_ground"]),
	}


func _evaluate_dual_envelope(
	cash_budget: float,
	demand: Dictionary,
	geom: Dictionary,
	num_pads: int
) -> Dictionary:
	var splash_d: float = float(demand["avg_splash_density"])
	var air_frac: float = float(demand["air_frac"])
	var heavy_frac: float = float(demand["heavy_frac"])
	var has_aps: bool = float(demand["aps_shield_total"]) > 0.0
	var num_lanes: int = int(geom["num_lanes"])
	var lane_share: float = float(geom["avg_lane_pad_share"]) # 1.0 on 1-lane, ~0.45-0.85 on multi-lane

	# Determine average turret upgrade tier achievable with current cash & pad count
	# Realistic players build ~60% of pads before pushing everything to Lv4;
	# Optimized players prioritize upgrading choke pads to Lv3/Lv4 earlier (much higher DPS/$!).
	var real_dps := _simulate_roster_dps(cash_budget, num_pads, splash_d, air_frac, heavy_frac, has_aps, false, geom)
	var opt_dps := _simulate_roster_dps(cash_budget, num_pads, splash_d, air_frac, heavy_frac, has_aps, true, geom)

	# Multi-lane split penalty:
	# When a map has 2 or 3 separated lanes, a turret on Lane A cannot simultaneously shoot Lane B.
	# However, enemies also split across lanes (unless a wave dumps everything on 1 lane!).
	# Effective engagement factor blends pad-lane share with active utilization:
	var lane_efficiency := 1.0
	if num_lanes == 2:
		lane_efficiency = clampf(0.66 + 0.34 * lane_share, 0.68, 0.96)
	elif num_lanes >= 3:
		lane_efficiency = clampf(0.54 + 0.46 * lane_share, 0.56, 0.92)

	# Cryo kill-zone slow multiplier (active once player has enough economy for Cryo emitters)
	var cryo_mult_real := 1.0
	var cryo_mult_opt := 1.0
	if cash_budget >= 420.0:
		var cryo_progress := clampf((cash_budget - 420.0) / 3500.0, 0.0, 1.0)
		cryo_mult_real = lerpf(1.12, 1.38, cryo_progress)
		cryo_mult_opt = lerpf(1.22, 1.72, cryo_progress)

	var eff_real_total_dps: float = float(real_dps["total_dps"]) * lane_efficiency * cryo_mult_real
	var eff_opt_total_dps: float = float(opt_dps["total_dps"]) * clampf(lane_efficiency + 0.08, 0.62, 1.0) * cryo_mult_opt

	# Geometry-accurate turret firing window!
	# A stationary turret only fires while enemies pass through its range footprint:
	#   pad_window = min(wave_dur, spawn_dur + avg_pad_cov_len / avg_enemy_speed)
	# (Hunter Drones pursue map-wide so their fire window is full wave_dur.)
	var wave_dur: float = maxf(6.0, float(demand["wave_duration"]))
	var spawn_dur: float = float(demand["spawn_duration"])
	var avg_gnd_spd: float = maxf(20.0, float(demand["avg_gnd_speed"]))
	var avg_air_spd: float = maxf(30.0, float(demand["avg_air_speed"]))

	var avg_pad_cov_mid := 0.0
	var avg_pad_cov_max := 0.0
	var avg_lane_len := 0.0
	for l in range(num_lanes):
		avg_pad_cov_mid += float(geom["lane_avg_pad_cov_mid"][l])
		avg_pad_cov_max += float(geom["lane_avg_pad_cov_max"][l])
		avg_lane_len += float(geom["lane_lengths"][l])
	avg_pad_cov_mid /= maxf(1.0, float(num_lanes))
	avg_pad_cov_max /= maxf(1.0, float(num_lanes))
	avg_lane_len /= maxf(1.0, float(num_lanes))

	var t_pass_real := avg_pad_cov_mid / avg_gnd_spd
	var t_pass_opt := avg_pad_cov_max / avg_gnd_spd
	var pad_window_real := minf(wave_dur, spawn_dur + t_pass_real)
	var pad_window_opt := minf(wave_dur, spawn_dur + t_pass_opt)

	var drone_r: float = float(real_dps["drone_dps"]) * cryo_mult_real
	var drone_o: float = float(opt_dps["drone_dps"]) * cryo_mult_opt
	var stat_r: float = maxf(0.0, eff_real_total_dps - drone_r)
	var stat_o: float = maxf(0.0, eff_opt_total_dps - drone_o)

	var total_dmg_real := stat_r * pad_window_real + drone_r * wave_dur
	var total_dmg_opt := stat_o * pad_window_opt + drone_o * wave_dur
	var total_cap_ratio_real := total_dmg_real / maxf(1.0, float(demand["total_ehp_real"]))
	var total_cap_ratio_opt := total_dmg_opt / maxf(1.0, float(demand["total_ehp_opt"]))

	# Peak concurrent DPS ratio: stationary turrets spread along a road have concurrent
	# engagement fraction bounded by how much of the active enemy stream overlaps turret ranges.
	var stream_len_est := spawn_dur * avg_gnd_spd
	var active_frac_real := clampf((stream_len_est + avg_pad_cov_mid) / maxf(1.0, avg_lane_len), 0.30, 1.0)
	var active_frac_opt := clampf((stream_len_est + avg_pad_cov_max) / maxf(1.0, avg_lane_len), 0.38, 1.0)
	var conc_dps_real := stat_r * active_frac_real + drone_r
	var conc_dps_opt := stat_o * active_frac_opt + drone_o
	var peak_ratio_real := conc_dps_real / maxf(1.0, float(demand["peak_req_dps_real"]))
	var peak_ratio_opt := conc_dps_opt / maxf(1.0, float(demand["peak_req_dps_opt"]))

	# Binding survivability ratio (must handle BOTH sustained HP and peak push!)
	var real_ratio := minf(total_cap_ratio_real, peak_ratio_real)
	var opt_ratio := minf(total_cap_ratio_opt, peak_ratio_opt)

	# Dedicated Air-Domain Check (AA pads covering air_path vs Air EHP & Peak Air DPS)
	var air_ratio_real := 99.0
	var air_ratio_opt := 99.0
	if bool(demand["has_air"]):
		var air_pads_1 := int(geom["air_pads_sam1"])
		var air_pads_4 := int(geom["air_pads_sam4"])
		var air_len := maxf(100.0, float(geom["air_len"]))
		var air_pad_cov1 := float(geom["avg_air_pad_cov_sam1"])
		var air_pad_cov4 := float(geom["avg_air_pad_cov_sam4"])
		var aa_real_stat := float(real_dps["air_dps"]) * clampf(float(air_pads_1) / maxf(1.0, float(num_pads) * 0.35), 0.20, 1.0) * cryo_mult_real
		var aa_opt_stat := float(opt_dps["air_dps"]) * clampf(float(air_pads_4) / maxf(1.0, float(num_pads) * 0.30), 0.25, 1.0) * cryo_mult_opt
		var air_win_r := minf(wave_dur, spawn_dur + air_pad_cov1 / avg_air_spd)
		var air_win_o := minf(wave_dur, spawn_dur + air_pad_cov4 / avg_air_spd)
		var air_active_r := clampf((spawn_dur * avg_air_spd + air_pad_cov1) / air_len, 0.32, 1.0)
		var air_active_o := clampf((spawn_dur * avg_air_spd + air_pad_cov4) / air_len, 0.40, 1.0)

		var air_conc_r := aa_real_stat * air_active_r + drone_r
		var air_conc_o := aa_opt_stat * air_active_o + drone_o
		var air_dmg_r := aa_real_stat * air_win_r + drone_r * wave_dur
		var air_dmg_o := aa_opt_stat * air_win_o + drone_o * wave_dur

		var air_peak_r := air_conc_r / maxf(1.0, float(demand["peak_air_req_dps_real"]))
		var air_peak_o := air_conc_o / maxf(1.0, float(demand["peak_air_req_dps_opt"]))
		var air_tot_r := air_dmg_r / maxf(1.0, float(demand["air_ehp_real"]))
		var air_tot_o := air_dmg_o / maxf(1.0, float(demand["air_ehp_opt"]))
		air_ratio_real = minf(air_peak_r, air_tot_r)
		air_ratio_opt = minf(air_peak_o, air_tot_o)

	return {
		"real_dps": eff_real_total_dps,
		"opt_dps": eff_opt_total_dps,
		"real_ratio": real_ratio,
		"opt_ratio": opt_ratio,
		"air_ratio_real": air_ratio_real,
		"air_ratio_opt": air_ratio_opt,
	}


# Allocate `cash_budget` across up to `num_pads` pads using either Realistic Mixed or Optimized Counter weights
func _simulate_roster_dps(
	cash_budget: float,
	num_pads: int,
	splash_d: float,
	air_frac: float,
	heavy_frac: float,
	has_aps: bool,
	is_optimized: bool,
	geom: Dictionary
) -> Dictionary:
	var T := TurretDataScript.TurretType
	var weights: Dictionary = {}

	if not is_optimized:
		# Realistic generalist player mix (adapts modestly when air is heavy)
		var air_shift := clampf(air_frac * 0.25, 0.0, 0.14)
		weights = {
			T.VULCAN: 0.24 - air_shift * 0.3,
			T.CRYO: 0.12,
			T.CANNON: 0.20 - air_shift * 0.5,
			T.MISSILE: 0.16 + air_shift,
			T.LASER: 0.11 + (0.04 if has_aps else 0.0),
			T.MLRS: 0.10 - (0.02 if has_aps else 0.0) - air_shift * 0.2,
			T.DRONE: 0.07,
		}
	else:
		# Optimized counter-play mix tailored to wave threats
		var w_sam := clampf(0.14 + air_frac * 0.55, 0.12, 0.52)
		var w_laser := clampf(0.16 + heavy_frac * 0.22 + (0.12 if has_aps else 0.0), 0.14, 0.38)
		var w_cryo := 0.11
		var w_drone := 0.10
		var rem := maxf(0.10, 1.0 - w_sam - w_laser - w_cryo - w_drone)
		var w_mlrs := rem * (0.52 if splash_d >= 1.5 else 0.38)
		var w_cannon := rem * 0.24
		var w_vulcan := rem - w_mlrs - w_cannon
		weights = {
			T.VULCAN: w_vulcan,
			T.CRYO: w_cryo,
			T.CANNON: w_cannon,
			T.MISSILE: w_sam,
			T.LASER: w_laser,
			T.MLRS: w_mlrs,
			T.DRONE: w_drone,
		}

	# Normalize weights
	var w_sum := 0.0
	for k in weights.keys():
		w_sum += float(weights[k])
	for k in weights.keys():
		weights[k] = float(weights[k]) / maxf(0.001, w_sum)

	# Decide effective average turret level based on budget vs pad count
	# Realistic: fills pads gradually (Lv1 -> Lv2 -> Lv3 -> Lv4)
	# Optimized: concentrates cash into higher-tier Lv3/Lv4 powerhouses on choke pads first
	var avg_lv4_cost := _compute_avg_max_pad_cost()
	var budget_fill := cash_budget / maxf(1.0, float(num_pads) * avg_lv4_cost)

	var lv_lo := 0
	var lv_hi := 0
	var lv_t := 0.0
	if not is_optimized:
		if budget_fill < 0.12:
			lv_lo = 0; lv_hi = 1; lv_t = clampf(budget_fill / 0.12, 0.0, 1.0)
		elif budget_fill < 0.35:
			lv_lo = 1; lv_hi = 2; lv_t = clampf((budget_fill - 0.12) / 0.23, 0.0, 1.0)
		elif budget_fill < 0.72:
			lv_lo = 2; lv_hi = 3; lv_t = clampf((budget_fill - 0.35) / 0.37, 0.0, 1.0)
		else:
			lv_lo = 3; lv_hi = 3; lv_t = 1.0
	else:
		if budget_fill < 0.07:
			lv_lo = 0; lv_hi = 1; lv_t = clampf(budget_fill / 0.07, 0.0, 1.0)
		elif budget_fill < 0.22:
			lv_lo = 1; lv_hi = 2; lv_t = clampf((budget_fill - 0.07) / 0.15, 0.0, 1.0)
		elif budget_fill < 0.48:
			lv_lo = 2; lv_hi = 3; lv_t = clampf((budget_fill - 0.22) / 0.26, 0.0, 1.0)
		else:
			lv_lo = 3; lv_hi = 3; lv_t = 1.0

	var total_dps := 0.0
	var air_dps := 0.0
	var drone_dps := 0.0

	# Cap spend at filling all `num_pads` pads at Lv4
	var spendable := minf(cash_budget, float(num_pads) * avg_lv4_cost)
	var air_pad_limit := int(geom["air_pads_sam4"]) if is_optimized else int(geom["air_pads_sam1"])
	var max_aa_spend := float(maxi(1, air_pad_limit)) * 870.0

	for t in weights.keys():
		var alloc_cash: float = spendable * float(weights[t])
		var m_lo := _turret_tier_metrics(t, lv_lo, splash_d, is_optimized, false)
		var m_hi := _turret_tier_metrics(t, lv_hi, splash_d, is_optimized, false)
		var unit_cost := lerpf(float(m_lo["cost"]), float(m_hi["cost"]), lv_t)
		var unit_dps := lerpf(float(m_lo["dps"]), float(m_hi["dps"]), lv_t)
		var count_est := alloc_cash / maxf(1.0, unit_cost)
		var t_dps := count_est * unit_dps
		total_dps += t_dps

		if t == T.DRONE:
			drone_dps += t_dps
		elif bool(m_lo["can_air"]):
			var m_lo_a := _turret_tier_metrics(t, lv_lo, splash_d, is_optimized, true)
			var m_hi_a := _turret_tier_metrics(t, lv_hi, splash_d, is_optimized, true)
			var unit_dps_a := lerpf(float(m_lo_a["dps"]), float(m_hi_a["dps"]), lv_t)
			var aa_count := minf(count_est, max_aa_spend / maxf(1.0, unit_cost))
			air_dps += aa_count * unit_dps_a

	return {
		"total_dps": total_dps,
		"air_dps": air_dps,
		"drone_dps": drone_dps,
	}


# ==============================================================================
# 7. SERIALIZATION, DIFFING & REPORT GENERATION
# ==============================================================================

func _strip_internal_fields(data: Dictionary) -> Dictionary:
	var clean: Dictionary = data.duplicate(true)
	for sec in clean["sectors"]:
		var g: Dictionary = sec["geometry"]
		for key in g.keys():
			if String(key).begins_with("_"):
				g.erase(key)
	return clean


func _save_json(path: String, data: Dictionary) -> void:
	var clean := _strip_internal_fields(data)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Failed to write JSON: " + path)
		return
	f.store_string(JSON.stringify(clean, "\t"))
	f.close()


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Baseline JSON not found: " + path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}


func _save_text(path: String, content: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Failed to write text: " + path)
		return
	f.store_string(content)
	f.close()


func _print_cli_summary(
	res: Dictionary,
	baseline: Dictionary,
	report_path: String,
	json_path: String,
	saved_baseline: bool
) -> void:
	var s: Dictionary = res["summary"]
	print("================================================================================")
	print("  DEFENCE ZONE — PHASE 2 SURVIVABILITY & ECONOMY AUDIT (17 SECTORS x 4 DIFFS)")
	print("================================================================================")
	print("  Waves audited   : %d (%d sector-difficulty runs)" % [s["total_waves_audited"], s["total_sector_diffs"]])
	print("  IMPOSSIBLE waves: %d   |  TIGHT: %d   |  HEALTHY: %d   |  SNOWBALL: %d" % [
		s["impossible_waves"], s["tight_waves"], s["healthy_waves"], s["snowball_waves"]
	])
	print("  Wave 1 flags    : %d IMPOSSIBLE, %d TIGHT (out of %d runs)" % [
		s["wave1_impossible"], s["wave1_tight"], s["total_sector_diffs"]
	])
	print("  Air-domain flags: %d IMPOSSIBLE air waves  |  %d maps with AIR_GAP" % [
		s["air_impossible_waves"], s["air_gap_maps"]
	])
	print("  Geometry/Lanes  : %d maps with DEAD_LANE waves  |  %d maps with orphan pads" % [
		s["dead_lane_maps"], s["orphan_pad_maps"]
	])
	print("  Economy overflow: %d / %d runs exceed 100%% max-map pad budget" % [
		s["cash_overflow_sector_diffs"], s["total_sector_diffs"]
	])
	print("--------------------------------------------------------------------------------")
	print("  SEC  NAME                HPx   WVS  LNS  AIR(pads/cov)  NRM[W1 / Min / Snow]   HELL[W1 / Min / Imp]")
	print("--------------------------------------------------------------------------------")

	for sec in res["sectors"]:
		var g: Dictionary = sec["geometry"]
		var linfo: Dictionary = sec["lanes"]
		var nrm: Dictionary = sec["difficulties"]["NORMAL"]
		var hel: Dictionary = sec["difficulties"]["HELL"]
		var idx_str := "SP" if bool(sec["is_secret"]) else ("%02d" % int(sec["index"]))
		var air_flag := "!" if bool(g["air_gap_flag"]) else " "
		var lane_flag := "*" if int(linfo["dead_lane_wave_count"]) > 0 else " "
		var nrm_w1: float = float(nrm["wave1"]["real_ratio"])
		var hel_w1: float = float(hel["wave1"]["real_ratio"])
		print("  %-3s  %-18s  %4.2f  %2d   %d%s   %2dp/%4.0f%%%s      %4.2f / %4.2f(W%02d) / %2d  | %4.2f / %4.2f(W%02d) / %2d" % [
			idx_str,
			String(sec["short_name"]).left(18),
			float(sec["hp_scale"]),
			int(sec["wave_count"]),
			int(g["num_lanes"]),
			lane_flag,
			int(g["air_pads_sam1"]),
			float(g["air_cov_sam1_pct"]),
			air_flag,
			nrm_w1,
			float(nrm["worst_real_ratio"]),
			int(nrm["worst_real_wave"]),
			int(nrm["counts"]["snowball"]),
			hel_w1,
			float(hel["worst_opt_ratio"]),
			int(hel["worst_opt_wave"]),
			int(hel["counts"]["impossible"]),
		])

	print("--------------------------------------------------------------------------------")
	print("  Legend: * = dead-lane wave(s) detected   ! = AIR_GAP (<4 SAM Lv1 pads or <50% air path)")
	print("  NRM cols: Wave1 real_ratio / Worst real_ratio(Wave) / Snowball wave count")
	print("  HELL cols: Wave1 real_ratio / Worst opt_ratio(Wave) / Impossible wave count")

	if not baseline.is_empty():
		var bs: Dictionary = baseline["summary"]
		print("--------------------------------------------------------------------------------")
		print("  DIFF vs BASELINE:")
		print("    IMPOSSIBLE waves : %d -> %d (%+d)" % [bs["impossible_waves"], s["impossible_waves"], int(s["impossible_waves"]) - int(bs["impossible_waves"])])
		print("    TIGHT waves      : %d -> %d (%+d)" % [bs["tight_waves"], s["tight_waves"], int(s["tight_waves"]) - int(bs["tight_waves"])])
		print("    HEALTHY waves    : %d -> %d (%+d)" % [bs["healthy_waves"], s["healthy_waves"], int(s["healthy_waves"]) - int(bs["healthy_waves"])])
		print("    SNOWBALL waves   : %d -> %d (%+d)" % [bs["snowball_waves"], s["snowball_waves"], int(s["snowball_waves"]) - int(bs["snowball_waves"])])
		print("    Wave 1 IMPOSSIBLE: %d -> %d (%+d)" % [bs["wave1_impossible"], s["wave1_impossible"], int(s["wave1_impossible"]) - int(bs["wave1_impossible"])])

	print("--------------------------------------------------------------------------------")
	print("  Report written : %s" % ProjectSettings.globalize_path(report_path))
	print("  JSON snapshot  : %s" % ProjectSettings.globalize_path(json_path))
	if saved_baseline:
		print("  Baseline saved : %s" % ProjectSettings.globalize_path("res://tools/audit_baseline.json"))
	print("================================================================================")


func _build_markdown_report(res: Dictionary, baseline: Dictionary) -> String:
	var lines: PackedStringArray = []
	var s: Dictionary = res["summary"]

	lines.append("# Defence Zone — Phase 2 Math & Survivability Audit Report")
	lines.append("")
	lines.append("Generated directly from live `MapData`, `WaveData`, `TurretData`, and `EnemyData` via headless Godot (`tools/balance_audit.gd`).")
	lines.append("")
	lines.append("## Methodology & Thresholds")
	lines.append("- **Turrets-only baseline**: Hellfire Air Strike and early-wave call bonuses are excluded from pass/fail checks across all 4 difficulties (including `HELL`).")
	lines.append("- **Dual-envelope model**:")
	lines.append("  - **Realistic Mixed (`real_ratio`)**: Balanced combined-arms build, armor/AP mitigation (`0.68` avg AP), APS shield regen (`1.15×`), UAV-spawned `FPV_DRONE`s (up to 3/carrier), conservative spacing-based AOE splash (`<=1.6×`), modest Cryo uptime (`1.12×–1.38×`), and map lane-split penalty.")
	lines.append("  - **Optimized Counter-Play (`opt_ratio`)**: Counter-tailored build (Laser vs APS/heavies with `2×` shield dmg & higher ramp, SAM vs air with `1.65×` air bonus, MLRS/Cannon/Cryo on dense swarms, Drone sniping carriers), bounded strictly by available cash, pad count, and exact map geometry.")
	lines.append("- **Flags**:")
	lines.append("  - `IMPOSSIBLE`: `opt_ratio < 1.0` (or air-only `air_opt_ratio < 1.0`)")
	lines.append("  - `TIGHT`: `real_ratio < 1.0` while `opt_ratio >= 1.0`")
	lines.append("  - `HEALTHY`: `1.0 <= real_ratio <= 2.2` and cash `<= 100%` max-map pad budget")
	lines.append("  - `SNOWBALL`: `real_ratio > 2.2` or cumulative cash `> 100%` of cost to Lv4-max every pad")
	lines.append("  - `AIR_GAP`: `< 4` pads reaching `air_path` at SAM Lv1 (`285px`) or `< 50%` of `air_path` length covered")
	lines.append("  - `DEAD_LANE`: Multi-lane map with waves spawning `0` ground units on a lane, or `< 15%` sector-wide lane share")
	lines.append("")

	lines.append("## Executive Summary")
	lines.append("| Metric | Value |")
	lines.append("|---|---:|")
	lines.append("| Sectors Audited | %d (16 campaign + `north_pole`) |" % int(res["meta"]["sector_count"]))
	lines.append("| Total Waves Audited (× 4 diffs) | %d |" % int(s["total_waves_audited"]))
	lines.append("| `IMPOSSIBLE` Waves | **%d** |" % int(s["impossible_waves"]))
	lines.append("| `TIGHT` Waves | **%d** |" % int(s["tight_waves"]))
	lines.append("| `HEALTHY` Waves | %d |" % int(s["healthy_waves"]))
	lines.append("| `SNOWBALL` Waves | **%d** |" % int(s["snowball_waves"]))
	lines.append("| Wave 1 `IMPOSSIBLE` / `TIGHT` (of 68 runs) | **%d** / **%d** |" % [int(s["wave1_impossible"]), int(s["wave1_tight"])])
	lines.append("| Air-Domain `IMPOSSIBLE` Waves | **%d** |" % int(s["air_impossible_waves"]))
	lines.append("| Maps with `AIR_GAP` | **%d** |" % int(s["air_gap_maps"]))
	lines.append("| Maps with `DEAD_LANE` Waves | **%d** |" % int(s["dead_lane_maps"]))
	lines.append("| Maps with Orphan Pads | **%d** |" % int(s["orphan_pad_maps"]))
	lines.append("| Runs Exceeding 100%% Max-Map Cash Budget | **%d / %d** |" % [int(s["cash_overflow_sector_diffs"]), int(s["total_sector_diffs"])])
	lines.append("")

	if not baseline.is_empty():
		var bs: Dictionary = baseline["summary"]
		lines.append("## Delta vs Baseline")
		lines.append("| Metric | Baseline | Current | Delta |")
		lines.append("|---|---:|---:|---:|")
		for k in ["impossible_waves", "tight_waves", "healthy_waves", "snowball_waves", "wave1_impossible", "wave1_tight", "air_impossible_waves", "cash_overflow_sector_diffs"]:
			var bval := int(bs[k])
			var cval := int(s[k])
			lines.append("| `%s` | %d | %d | %+d |" % [k, bval, cval, cval - bval])
		lines.append("")

	# Table 1: Map Geometry, Air Coverage & Dead Lanes
	lines.append("## 1. Map Geometry, Air-Path Coverage & Lane Utilization")
	lines.append("| Sec | Map | Lanes | Pads | Shortest Lane (px) | Air Len (px) | Air Pads (V1/L1/S1/S4) | Air Cov (S1/S4) | Avg Air Overlap (S1) | Lane Share (%) | Dead-Lane Waves | Flags |")
	lines.append("|---|---|---:|---:|---:|---:|---|---|---:|---|---:|---|")
	for sec in res["sectors"]:
		var g: Dictionary = sec["geometry"]
		var li: Dictionary = sec["lanes"]
		var idx_str := "SP" if bool(sec["is_secret"]) else ("%02d" % int(sec["index"]))
		var shares := PackedStringArray()
		for sh in li["lane_shares_pct"]:
			shares.append("%.0f%%" % float(sh))
		var flags := PackedStringArray()
		if bool(g["air_gap_flag"]):
			flags.append("`AIR_GAP`")
		if bool(li["has_dead_lane_sector"]):
			flags.append("`DEAD_SECTOR_LANE`")
		elif int(li["dead_lane_wave_count"]) > 0:
			flags.append("`DEAD_LANE`")
		if (li["underused_lanes"] as Array).size() > 0:
			flags.append("`UNDERUSED_LANE`")
		if (g["orphan_pads"] as Array).size() > 0:
			flags.append("`ORPHAN_PAD(%d)`" % (g["orphan_pads"] as Array).size())
		var flag_str := ", ".join(flags) if flags.size() > 0 else "OK"
		lines.append("| %s | %s | %d | %d | %.0f | %.0f | %d / %d / %d / %d | %.0f%% / %.0f%% | %.2f | %s | %d | %s |" % [
			idx_str,
			String(sec["short_name"]),
			int(g["num_lanes"]),
			int(g["num_pads"]),
			float(g["min_lane_len"]),
			float(g["air_len"]),
			int(g["air_pads_vulcan1"]),
			int(g["air_pads_laser1"]),
			int(g["air_pads_sam1"]),
			int(g["air_pads_sam4"]),
			float(g["air_cov_sam1_pct"]),
			float(g["air_cov_sam4_pct"]),
			float(g["air_avg_pads_sam1"]),
			" / ".join(shares),
			int(li["dead_lane_wave_count"]),
			flag_str,
		])
	lines.append("")

	# Table 2: Wave 1 Survivability Across All 17 Sectors x 4 Difficulties
	lines.append("## 2. Wave 1 Survivability Matrix (Start Cash vs. Wave 1 HP, Lanes & Shortest Path)")
	lines.append("| Sec | Map | `hp_scale` | `+cash` | EASY (Cash / EHP / Real / Opt) | NORMAL (Cash / EHP / Real / Opt) | HARD (Cash / EHP / Real / Opt) | HELL (Cash / EHP / Real / Opt) |")
	lines.append("|---|---|---:|---:|---|---|---|---|")
	for sec in res["sectors"]:
		var idx_str := "SP" if bool(sec["is_secret"]) else ("%02d" % int(sec["index"]))
		var cells := PackedStringArray()
		for dname in ["EASY", "NORMAL", "HARD", "HELL"]:
			var w1: Dictionary = sec["difficulties"][dname]["wave1"]
			var tag := _status_badge(String(w1["status"]))
			cells.append("$%d / %d / %.2f / %.2f %s" % [
				int(w1["start_cash"]),
				int(w1["wave1_ehp"]),
				float(w1["real_ratio"]),
				float(w1["opt_ratio"]),
				tag,
			])
		lines.append("| %s | %s | %.2f | +$%d | %s | %s | %s | %s |" % [
			idx_str,
			String(sec["short_name"]),
			float(sec["hp_scale"]),
			int(sec["cash_bonus"]),
			cells[0], cells[1], cells[2], cells[3],
		])
	lines.append("")

	# Table 3: Economy & Full-Campaign Survivability Matrix
	lines.append("## 3. Full-Campaign Economy & Peak Pressure Matrix")
	lines.append("Format per difficulty: `Imp / Tight / Hlth / Snow | WorstOpt(W#) | EndCash / MaxMap`")
	lines.append("")
	lines.append("| Sec | Map | Waves | EASY | NORMAL | HARD | HELL |")
	lines.append("|---|---|---:|---|---|---|---|")
	for sec in res["sectors"]:
		var idx_str := "SP" if bool(sec["is_secret"]) else ("%02d" % int(sec["index"]))
		var cells := PackedStringArray()
		for dname in ["EASY", "NORMAL", "HARD", "HELL"]:
			var dr: Dictionary = sec["difficulties"][dname]
			var c: Dictionary = dr["counts"]
			cells.append("%dI/%dT/%dH/%dS · min %.2f(W%d) · %.1f×" % [
				int(c["impossible"]),
				int(c["tight"]),
				int(c["healthy"]),
				int(c["snowball"]),
				float(dr["worst_opt_ratio"]),
				int(dr["worst_opt_wave"]),
				float(dr["cash_to_max_ratio"]),
			])
		lines.append("| %s | %s | %d | %s | %s | %s | %s |" % [
			idx_str,
			String(sec["short_name"]),
			int(sec["wave_count"]),
			cells[0], cells[1], cells[2], cells[3],
		])
	lines.append("")

	# Section 4: Critical Anomalies & Detailed Wave Flags
	lines.append("## 4. Flagged Anomalies & Worst Waves by Sector")
	for sec in res["sectors"]:
		var idx_str := "SECRET" if bool(sec["is_secret"]) else ("SECTOR %02d" % int(sec["index"]))
		var g: Dictionary = sec["geometry"]
		var li: Dictionary = sec["lanes"]

		var notable := PackedStringArray()
		if bool(g["air_gap_flag"]):
			notable.append("- **AIR_GAP**: Only %d pads reach `air_path` at SAM Lv1 (`%.1f%%` air-path coverage)." % [int(g["air_pads_sam1"]), float(g["air_cov_sam1_pct"])])
		if (g["orphan_pads"] as Array).size() > 0:
			notable.append("- **ORPHAN_PADS**: Pad indices `%s` are out of Vulcan Lv1 ground range AND SAM Lv1 air range." % [str(g["orphan_pads"])])
		if int(li["dead_lane_wave_count"]) > 0:
			var sample_w := PackedStringArray()
			var dlw: Array = li["dead_lane_waves"]
			for j in range(mini(8, dlw.size())):
				sample_w.append("W%d(empty=%s)" % [int(dlw[j]["wave"]), str(dlw[j]["empty_lanes"])])
			if dlw.size() > 8:
				sample_w.append("+%d more" % (dlw.size() - 8))
			notable.append("- **DEAD_LANES**: %d waves skip >=1 lane; overall lane split `%s%%`. Examples: %s." % [
				dlw.size(), str(li["lane_shares_pct"]), ", ".join(sample_w)
			])

		for dname in ["NORMAL", "HARD", "HELL", "EASY"]:
			var dr: Dictionary = sec["difficulties"][dname]
			var imp_list := PackedStringArray()
			var snow_first := int(dr["first_snowball_wave"])
			var over_first := int(dr["cash_overflow_wave"])
			for w in dr["waves"]:
				if String(w["status"]) == "IMPOSSIBLE":
					var air_note := ""
					if bool(w["has_air"]) and float(w["air_ratio_opt"]) < THRESH_IMPOSSIBLE:
						air_note = " [AIR=%.2f]" % float(w["air_ratio_opt"])
					imp_list.append("W%d(opt=%.2f%s)" % [int(w["wave"]), float(w["opt_ratio"]), air_note])
			if imp_list.size() > 0:
				var shown := PackedStringArray()
				for j in range(mini(10, imp_list.size())):
					shown.append(imp_list[j])
				if imp_list.size() > 10:
					shown.append("... (%d total)" % imp_list.size())
				notable.append("- **%s IMPOSSIBLE (%d waves)**: %s" % [dname, imp_list.size(), ", ".join(shown)])
			if snow_first != -1 or over_first != -1:
				var parts := PackedStringArray()
				if snow_first != -1:
					parts.append("first `SNOWBALL` at W%d (%d total)" % [snow_first, int(dr["counts"]["snowball"])])
				if over_first != -1:
					parts.append("cash > 100%% max-map at W%d (ends at %.1f×)" % [over_first, float(dr["cash_to_max_ratio"])])
				notable.append("- **%s ECONOMY**: %s" % [dname, "; ".join(parts)])

		if notable.size() > 0:
			lines.append("### %s — %s (`hp_scale=%.2f`, `+%d cash`, `%d waves`)" % [
				idx_str, String(sec["short_name"]), float(sec["hp_scale"]), int(sec["cash_bonus"]), int(sec["wave_count"])
			])
			for n in notable:
				lines.append(n)
			lines.append("")

	return "\n".join(lines) + "\n"


func _status_badge(status: String) -> String:
	match status:
		"IMPOSSIBLE":
			return "**[IMP]**"
		"TIGHT":
			return "[TIGHT]"
		"SNOWBALL":
			return "[SNOW]"
		_:
			return "[OK]"
