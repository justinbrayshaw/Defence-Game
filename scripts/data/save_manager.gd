class_name SaveManager
extends RefCounted

const SAVE_PATH: String = "user://save.json"
const SAVE_VERSION: int = 1

var data: Dictionary = {}

func _init() -> void:
	load_save()

func _default_stats() -> Dictionary:
	return {
		"play_time_sec": 0.0,
		"total_kills": 0,
		"air_kills": 0,
		"boss_kills": 0,
		"aps_kills": 0,
		"fpv_kills": 0,
		"turrets_placed": 0,
		"turrets_sold": 0,
		"max_level_upgrades": 0,
		"airstrikes_called": 0,
		"early_waves_called": 0,
		"cryo_builds_upgrades": 0,
		"turret_kills": {
			"vulcan": 0,
			"cannon": 0,
			"missile": 0,
			"cryo": 0,
			"laser": 0,
			"mlrs": 0,
			"drone": 0,
		},
		"perfect_hq_wins": 0,
		"close_call_wins": 0,
		"rich_bank_wins": 0,
		"all_seven_turrets_achieved": false,
		"best_rank_ever": 0,
		"defeats": 0,
	}

func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"audio": {
			"master_muted": false,
			"sfx_volume": 0.85,
			"sfx_muted": false,
			"music_volume": 0.50,
			"music_muted": false,
		},
		"sectors": {},
		"stats": _default_stats(),
		"medals": [],
		"profile": {
			"general_avatar": "male",
		},
	}

func load_save() -> void:
	data = _default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if not (parsed is Dictionary):
		return
	var loaded: Dictionary = parsed
	if loaded.has("audio") and loaded["audio"] is Dictionary:
		var a: Dictionary = loaded["audio"]
		data["audio"]["master_muted"] = bool(a.get("master_muted", false))
		data["audio"]["sfx_volume"] = clampf(float(a.get("sfx_volume", 0.85)), 0.0, 1.0)
		data["audio"]["sfx_muted"] = bool(a.get("sfx_muted", false))
		data["audio"]["music_volume"] = clampf(float(a.get("music_volume", 0.50)), 0.0, 1.10)
		data["audio"]["music_muted"] = bool(a.get("music_muted", false))
	if loaded.has("sectors") and loaded["sectors"] is Dictionary:
		data["sectors"] = (loaded["sectors"] as Dictionary).duplicate(true)
	if loaded.has("stats") and loaded["stats"] is Dictionary:
		var st_loaded: Dictionary = loaded["stats"]
		var st_def: Dictionary = data["stats"]
		for k in st_def.keys():
			if st_loaded.has(k):
				if k == "turret_kills" and st_loaded[k] is Dictionary:
					var tk_def: Dictionary = st_def["turret_kills"]
					var tk_ld: Dictionary = st_loaded["turret_kills"]
					for tk_k in tk_def.keys():
						if tk_ld.has(tk_k):
							tk_def[tk_k] = int(tk_ld[tk_k])
				else:
					st_def[k] = st_loaded[k]
	if loaded.has("medals") and loaded["medals"] is Array:
		var m_arr: Array[String] = []
		for item in loaded["medals"]:
			var s_id := String(item)
			if s_id != "" and not m_arr.has(s_id):
				m_arr.append(s_id)
		data["medals"] = m_arr
	if loaded.has("profile") and loaded["profile"] is Dictionary:
		var av := String((loaded["profile"] as Dictionary).get("general_avatar", "male"))
		data["profile"]["general_avatar"] = "female" if av == "female" else "male"

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func get_audio_settings() -> Dictionary:
	return (data["audio"] as Dictionary).duplicate()

func set_audio_settings(master_muted: bool, sfx_volume: float, sfx_muted: bool, music_volume: float, music_muted: bool) -> void:
	data["audio"] = {
		"master_muted": master_muted,
		"sfx_volume": clampf(sfx_volume, 0.0, 1.0),
		"sfx_muted": sfx_muted,
		"music_volume": clampf(music_volume, 0.0, 1.10),
		"music_muted": music_muted,
	}
	save()

func get_sector_record(map_id: String) -> Dictionary:
	var sectors: Dictionary = data["sectors"]
	if sectors.has(map_id) and sectors[map_id] is Dictionary:
		return sectors[map_id]
	return {}

func get_all_sector_records() -> Dictionary:
	return data["sectors"]

# Records a victory and returns true if this run set a new best difficulty or best rank/efficiency!
func record_sector_victory(map_id: String, diff_idx: int, eval_res: Dictionary) -> bool:
	var sectors: Dictionary = data["sectors"]
	var prev: Dictionary = sectors.get(map_id, {})
	var is_new_best: bool = false

	var new_rank_num: int = int(eval_res.get("rank_num", 1))
	var new_pct: float = float(eval_res.get("efficiency_pct", 0.0))
	var new_worth: int = int(eval_res.get("net_worth", 0))
	var new_title: String = String(eval_res.get("rank_title", "Private"))
	var new_medal: String = String(eval_res.get("medal_id", "BRONZE"))

	if prev.is_empty():
		is_new_best = true
		sectors[map_id] = {
			"cleared": true,
			"best_difficulty": diff_idx,
			"best_rank_num": new_rank_num,
			"best_rank_title": new_title,
			"best_medal": new_medal,
			"best_pct": snappedf(new_pct, 0.1),
			"best_net_worth": new_worth,
		}
	else:
		var rec: Dictionary = prev.duplicate()
		rec["cleared"] = true
		if diff_idx > int(rec.get("best_difficulty", -1)):
			rec["best_difficulty"] = diff_idx
			is_new_best = true
		if new_pct > float(rec.get("best_pct", -1.0)):
			rec["best_pct"] = snappedf(new_pct, 0.1)
			rec["best_rank_num"] = new_rank_num
			rec["best_rank_title"] = new_title
			rec["best_medal"] = new_medal
			is_new_best = true
		if new_worth > int(rec.get("best_net_worth", 0)):
			rec["best_net_worth"] = new_worth
		sectors[map_id] = rec

	save()
	return is_new_best

func get_stats() -> Dictionary:
	return data["stats"]

func get_unlocked_medals() -> Array[String]:
	var out: Array[String] = []
	for item in data.get("medals", []):
		out.append(String(item))
	return out

func evaluate_and_unlock_medals() -> Array[String]:
	var unlocked: Array[String] = get_unlocked_medals()
	var newly_unlocked: Array[String] = []
	var st: Dictionary = data["stats"]
	var secs: Dictionary = data["sectors"]

	for m in MedalData.get_all_medals():
		var mid: String = String(m["id"])
		if unlocked.has(mid):
			continue
		var prog := MedalData.get_progress(mid, st, secs)
		if bool(prog["unlocked"]):
			unlocked.append(mid)
			newly_unlocked.append(mid)

	if not newly_unlocked.is_empty():
		data["medals"] = unlocked
		save()
	return newly_unlocked

func get_general_avatar() -> String:
	var prof: Dictionary = data.get("profile", {})
	return "female" if String(prof.get("general_avatar", "male")) == "female" else "male"

func set_general_avatar(style: String) -> void:
	if not data.has("profile") or not (data["profile"] is Dictionary):
		data["profile"] = {}
	data["profile"]["general_avatar"] = "female" if style == "female" else "male"
	save()

func reset_campaign_progress() -> void:
	data["sectors"] = {}
	data["stats"] = _default_stats()
	data["medals"] = []
	save()
