class_name RankData
extends RefCounted

# 50 escalating Victory ranks — starts straight-faced like standard military ranks,
# then rapidly spirals into absurd bureaucratic-imperial pomp.
# Indexed 0..49 corresponding to 0%..100% of theoretical maximum valuation for that sector & difficulty.
const VICTORY_RANKS: Array[String] = [
	"Private",                                                                           # 01 (0-2%)
	"Private First Class",                                                               # 02 (2-4%)
	"Lance Corporal",                                                                    # 03 (4-6%)
	"Corporal",                                                                          # 04 (6-8%)
	"Sergeant",                                                                          # 05 (8-10%)
	"Staff Sergeant",                                                                    # 06 (10-12%)
	"Second Lieutenant",                                                                 # 07 (12-14%)
	"First Lieutenant",                                                                  # 08 (14-16%)
	"Captain",                                                                           # 09 (16-18%)
	"Major",                                                                             # 10 (18-20%)
	"Lieutenant Colonel",                                                                # 11 (20-22%)
	"Colonel",                                                                           # 12 (22-24%)
	"Brigadier General",                                                                 # 13 (24-26%)
	"Major General of Perimeter Paperwork",                                              # 14 (26-28%)
	"Lieutenant General of Stationary Ordnance",                                         # 15 (28-30%)
	"Four-Star Director of Vehicular Deterrence",                                        # 16 (30-32%)
	"Senior Undersecretary of Pre-Approved Kill Zones",                                  # 17 (32-34%)
	"Inspector-General of Unauthorized Incursions",                                      # 18 (34-36%)
	"High Quartermaster of Sovereign Concrete",                                          # 19 (36-38%)
	"Deputy Chief Marshal of Elevated Turret Pads",                                      # 20 (38-40%)
	"Supreme Comptroller of Munitions & Fiscal Restraint",                               # 21 (40-42%)
	"Commander-in-Chief of Automated Perimeter Bollards",                                # 22 (42-44%)
	"Grand Commissar of Anti-Aerial Disapproval",                                        # 23 (44-46%)
	"Field Marshal of the Fortified Cul-de-Sac",                                         # 24 (46-48%)
	"Lord Protector of Mildly Aggressive Turrets",                                       # 25 (48-50%)
	"Arch-Commandant of All Rotating Barrels",                                           # 26 (50-52%)
	"Viceroy of Unsolicited Artillery Salvos",                                           # 27 (52-54%)
	"First Sea Lord of Strictly Landlocked Bastions",                                    # 28 (54-56%)
	"Grand Duke of Suppressive Fire & Zoning Compliance",                                # 29 (56-58%)
	"Right Honorable Warden of the Sovereign Choke Point",                               # 30 (58-60%)
	"High Chancellor of Weaponized Civic Engineering",                                   # 31 (60-62%)
	"Supreme Plenipotentiary of Anti-Aircraft Munitions",                                # 32 (62-64%)
	"Exalted Generalissimo of Concrete-Mounted Deterrence",                              # 33 (64-66%)
	"Marquis of Directed-Energy Beam Administration",                                    # 34 (66-68%)
	"Imperial Prefect of Uninterrupted Headquarters Peace",                              # 35 (68-70%)
	"Sovereign Autocrat of Tactical Placement Geometry",                                 # 36 (70-72%)
	"Grand Marshal of the Imperium of Stationary Emplacements",                          # 37 (72-74%)
	"His Most Serene Excellency of High-Explosive Diplomacy",                            # 38 (74-76%)
	"Archduke of Zero-Tolerance Airspace Sovereignty",                                   # 39 (76-78%)
	"Supreme Sovereign Generalissimo of Tactical Bastions",                              # 40 (78-80%)
	"Emperor-Protector of Stationary Automated Weaponry",                                # 41 (80-82%)
	"Grand Imperator of Budget-Conscious Annihilation",                                  # 42 (82-84%)
	"Lord High Bastionkeeper of the Invincible Perimeter",                               # 43 (84-86%)
	"Celestial Field Marshal of Unspent Defense Appropriations",                         # 44 (86-88%)
	"Magnificent Potentate of Total Vehicular & Aerial Rejection",                       # 45 (88-90%)
	"All-Highest Sovereign Strategist of the Known Hemisphere",                          # 46 (90-92%)
	"Eternal Hyper-Generalissimo of Immaculate Kill Corridors",                          # 47 (92-94%)
	"Transcendent Architect of Sovereign Territorial Inviolability",                     # 48 (94-96%)
	"Living Monument to Authorized Stationary Automated Weaponry",                       # 49 (96-98.9%)
	"THE ABSOLUTE PLATONIC IDEAL OF SOVEREIGN TACTICAL BASTION PLACEMENT",               # 50 (>= 99.0% — nigh impossible!)
]

# 10 Defeat Badges of Shame — indexed from earliest collapse (0) to heartbreak final-wave defeat (9)
const DEFEAT_RANKS: Array[String] = [
	"Dishonorably Demoted to Sandbag",
	"Court-Martialed Latrine Strategist",
	"Chief Architect of an Unplanned Open-Door Policy",
	"Suspended Indefinitely Without Munitions",
	"Reassigned to Perimeter Clipboard Inventory",
	"Honorary Welcoming Committee Chairman",
	"Relieved of Command for Excessive Incursion",
	"Deputy Liaison to the Invading Convoy",
	"Almost Competent Enough for a Stern Memo",
	"Snatched Catastrophic Defeat From the Jaws of Paperwork",
]

static func compute_max_possible_cash(map_data: Dictionary, waves: Array[Dictionary], diff_cfg: Dictionary, inter_wave_time: float) -> int:
	var total: int = int(diff_cfg["start_cash"]) + int(map_data.get("cash_bonus", 0))
	var base_rew_mult: float = float(diff_cfg["reward_mult"])
	var total_waves: int = waves.size()

	for w_idx in range(total_waves):
		var wave_def: Dictionary = waves[w_idx]
		total += int(wave_def.get("bonus", 0))
		var rew_mult: float = base_rew_mult * WaveData.get_wave_reward_scale(w_idx, total_waves)
		var groups: Array = wave_def.get("groups", [])
		for g in groups:
			var cfg := EnemyData.get_config(g["type"])
			var unit_rew: int = int(round(float(cfg.get("reward", 0)) * rew_mult))
			total += int(g.get("count", 0)) * unit_rew

	# Theoretical early-call bonus if every single wave after Wave 1 is called immediately
	if total_waves > 1:
		var max_early_per_wave: int = int(round(inter_wave_time * 2.2))
		total += (total_waves - 1) * max_early_per_wave

	return maxi(1, total)

static func get_medal_info(rank_num: int) -> Dictionary:
	# rank_num is 1..50
	if rank_num >= 47:
		return {"id": "SOVEREIGN", "stars": "★★★★★", "short": "★★★★★", "color": Color(1.0, 0.36, 0.88)}
	elif rank_num >= 39:
		return {"id": "PLATINUM", "stars": "★★★★", "short": "★★★★", "color": Color(0.46, 0.92, 1.0)}
	elif rank_num >= 28:
		return {"id": "GOLD", "stars": "★★★", "short": "★★★", "color": Color(1.0, 0.82, 0.24)}
	elif rank_num >= 15:
		return {"id": "SILVER", "stars": "★★", "short": "★★", "color": Color(0.78, 0.84, 0.88)}
	else:
		return {"id": "BRONZE", "stars": "★", "short": "★", "color": Color(0.84, 0.56, 0.32)}

static func evaluate_victory(
	cash: int,
	turrets_sell_value: int,
	lives: int,
	max_lives: int,
	map_data: Dictionary,
	waves: Array[Dictionary],
	diff_cfg: Dictionary,
	inter_wave_time: float
) -> Dictionary:
	var max_cash: int = compute_max_possible_cash(map_data, waves, diff_cfg, inter_wave_time)
	var net_worth: int = cash + turrets_sell_value
	var net_worth_ratio: float = clampf(float(net_worth) / float(max_cash), 0.0, 1.0)
	var lives_ratio: float = clampf(float(lives) / float(maxi(1, max_lives)), 0.0, 1.0)

	# Net Worth is invariant to panic-selling turrets right before the last enemy dies.
	# At 100% lives and 100% max_cash (literally zero turret depreciation + every wave called instantly),
	# efficiency reaches 100.0% (Rank 50 — nigh impossible).
	var efficiency: float = clampf(net_worth_ratio * (0.25 + 0.75 * lives_ratio), 0.0, 1.0)
	var pct: float = efficiency * 100.0

	var rank_idx: int
	if pct >= 99.0:
		rank_idx = VICTORY_RANKS.size() - 1
	else:
		# Map 0.0..99.0 across indices 0..48 smoothly
		rank_idx = clampi(int(floor((pct / 99.0) * float(VICTORY_RANKS.size() - 1))), 0, VICTORY_RANKS.size() - 2)

	var rank_num: int = rank_idx + 1
	var medal := get_medal_info(rank_num)

	return {
		"victory": true,
		"cash": cash,
		"turrets_sell_value": turrets_sell_value,
		"net_worth": net_worth,
		"max_cash": max_cash,
		"lives": lives,
		"max_lives": max_lives,
		"efficiency_pct": pct,
		"rank_num": rank_num,
		"rank_total": VICTORY_RANKS.size(),
		"rank_title": VICTORY_RANKS[rank_idx],
		"medal_id": String(medal["id"]),
		"medal_stars": String(medal["stars"]),
		"medal_color": medal["color"],
	}

static func evaluate_defeat(
	waves_cleared: int,
	total_waves: int,
	cash: int,
	turrets_sell_value: int
) -> Dictionary:
	var progress: float = clampf(float(waves_cleared) / float(maxi(1, total_waves)), 0.0, 0.999)
	var idx: int = clampi(int(floor(progress * float(DEFEAT_RANKS.size()))), 0, DEFEAT_RANKS.size() - 1)
	return {
		"victory": false,
		"cash": cash,
		"turrets_sell_value": turrets_sell_value,
		"net_worth": cash + turrets_sell_value,
		"shame_num": idx + 1,
		"shame_total": DEFEAT_RANKS.size(),
		"shame_title": DEFEAT_RANKS[idx],
	}
