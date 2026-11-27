class_name MedalData
extends RefCounted

# 36 pompous military decorations awarded across campaign progression, combat milestones,
# turret specialization, tactical feats, economy, and time on duty.
# Displayed on the Sovereign General's increasingly overburdened dress uniform!

const GOLD := Color(0.98, 0.80, 0.24)
const SILVER := Color(0.82, 0.87, 0.91)
const BRONZE := Color(0.84, 0.54, 0.30)
const PLATINUM := Color(0.56, 0.92, 1.0)
const SOVEREIGN := Color(0.98, 0.36, 0.84)
const CRIMSON := Color(0.92, 0.22, 0.22)
const EMERALD := Color(0.24, 0.78, 0.42)
const ROYAL := Color(0.24, 0.44, 0.92)
const NAVY := Color(0.14, 0.22, 0.48)
const CREAM := Color(0.96, 0.94, 0.84)
const ORANGE := Color(0.96, 0.54, 0.16)
const PURPLE := Color(0.56, 0.24, 0.78)
const TEAL := Color(0.18, 0.74, 0.78)
const OLIVE := Color(0.32, 0.44, 0.24)

static var _cache: Array[Dictionary] = []

static func get_all_medals() -> Array[Dictionary]:
	if not _cache.is_empty():
		return _cache
	_cache = [
		# --- CAMPAIGN & PROGRESSION (8) ---
		{
			"id": "first_concrete",
			"name": "Order of the First Poured Concrete",
			"category": "CAMPAIGN",
			"desc": "Place your very first automated turret.",
			"citation": "Awarded for bravely authorizing the pouring of a single regulation concrete foundation.",
			"shape": "bar",
			"metal": BRONZE,
			"ribbon": [OLIVE, CREAM, OLIVE],
			"weight_g": 180,
		},
		{
			"id": "first_victory",
			"name": "Ribbon of Basic Perimeter Competence",
			"category": "CAMPAIGN",
			"desc": "Secure any 1 campaign sector.",
			"citation": "Proof that at least one sovereign road remained moderately un-invaded.",
			"shape": "circle",
			"metal": BRONZE,
			"ribbon": [EMERALD, GOLD, EMERALD],
			"weight_g": 240,
		},
		{
			"id": "earth_theater",
			"name": "Earth Theater Pacification Cross",
			"category": "CAMPAIGN",
			"desc": "Secure all 8 Earth Theater sectors (01–08).",
			"citation": "Every valley, desert, forest, and cul-de-sac on Earth is now aggressively zoned.",
			"shape": "cross",
			"metal": GOLD,
			"ribbon": [EMERALD, ROYAL, GOLD],
			"weight_g": 420,
		},
		{
			"id": "offworld_theater",
			"name": "Off-World Bastion Star",
			"category": "CAMPAIGN",
			"desc": "Secure all 8 Extreme & Off-World sectors (09–16).",
			"citation": "Successfully extended sovereign parking restrictions to Mars, Europa, and Xenon Prime.",
			"shape": "star",
			"metal": PLATINUM,
			"ribbon": [NAVY, PLATINUM, PURPLE],
			"weight_g": 480,
		},
		{
			"id": "full_campaign",
			"name": "Grand Sovereign Campaign Sunburst",
			"category": "CAMPAIGN",
			"desc": "Secure all 16 regular campaign sectors.",
			"citation": "Complete interplanetary prevention of unauthorized vehicular and aerial incursion.",
			"shape": "sunburst",
			"metal": SOVEREIGN,
			"ribbon": [CRIMSON, GOLD, ROYAL],
			"weight_g": 650,
		},
		{
			"id": "hard_clear",
			"name": "Order of Unreasonable Difficulty",
			"category": "CAMPAIGN",
			"desc": "Secure any sector on HARD difficulty or higher.",
			"citation": "Voluntarily accepted a reduced municipal defense budget and still prevailed.",
			"shape": "shield",
			"metal": GOLD,
			"ribbon": [ORANGE, CRIMSON, ORANGE],
			"weight_g": 360,
		},
		{
			"id": "hell_clear",
			"name": "Medal of Masochistic Sovereignty",
			"category": "CAMPAIGN",
			"desc": "Secure any sector on HELL difficulty.",
			"citation": "High Command assumed you would perish immediately and had already printed the condolence brochure.",
			"shape": "sunburst",
			"metal": SOVEREIGN,
			"ribbon": [CRIMSON, Color(0.14, 0.12, 0.12), GOLD],
			"weight_g": 540,
		},
		{
			"id": "north_pole_clear",
			"name": "Polar Toy-Pacification Snowflake",
			"category": "CAMPAIGN",
			"desc": "Secure the secret North Pole sector.",
			"citation": "Neutralized runaway holiday clockwork without formally indicting Santa Claus.",
			"shape": "star",
			"metal": PLATINUM,
			"ribbon": [CRIMSON, CREAM, EMERALD],
			"weight_g": 390,
		},

		# --- COMBAT & KILL MILESTONES (6) ---
		{
			"id": "kills_50",
			"name": "Bronze Fender-Bender Clasp",
			"category": "COMBAT",
			"desc": "Destroy 50 hostile units total.",
			"citation": "For enthusiastic early-career discouragement of unauthorized traffic.",
			"shape": "circle",
			"metal": BRONZE,
			"ribbon": [OLIVE, ORANGE, OLIVE],
			"weight_g": 210,
		},
		{
			"id": "kills_250",
			"name": "Silver Scrap-Metal Star",
			"category": "COMBAT",
			"desc": "Destroy 250 hostile units total.",
			"citation": "Local recycling contractors have named a barge after you.",
			"shape": "star",
			"metal": SILVER,
			"ribbon": [NAVY, SILVER, NAVY],
			"weight_g": 310,
		},
		{
			"id": "kills_1000",
			"name": "Gold Demolition Cross",
			"category": "COMBAT",
			"desc": "Destroy 1,000 hostile units total.",
			"citation": "One thousand unauthorized vehicles converted into sovereign roadside art.",
			"shape": "cross",
			"metal": GOLD,
			"ribbon": [CRIMSON, GOLD, CRIMSON],
			"weight_g": 450,
		},
		{
			"id": "kills_3000",
			"name": "Platinum Annihilation Medallion",
			"category": "COMBAT",
			"desc": "Destroy 3,000 hostile units total.",
			"citation": "The invading army's insurance premiums are now technically classified.",
			"shape": "sunburst",
			"metal": PLATINUM,
			"ribbon": [PURPLE, GOLD, CRIMSON],
			"weight_g": 580,
		},
		{
			"id": "air_kills_100",
			"name": "Anti-Air Sovereignty Wings",
			"category": "COMBAT",
			"desc": "Shoot down 100 hostile aircraft.",
			"citation": "Enforced strict airspace zoning with extreme vertical prejudice.",
			"shape": "wings",
			"metal": SILVER,
			"ribbon": [ROYAL, CREAM, ROYAL],
			"weight_g": 330,
		},
		{
			"id": "boss_kills_10",
			"name": "Giant-Slayer Rosette",
			"category": "COMBAT",
			"desc": "Destroy 10 Boss units (Juggernauts or Sky Fortresses).",
			"citation": "Demonstrated that absurdly expensive enemy superweapons still void their warranty under fire.",
			"shape": "diamond",
			"metal": GOLD,
			"ribbon": [CRIMSON, ORANGE, GOLD],
			"weight_g": 460,
		},

		# --- WEAPON SPECIALISTS (7) ---
		{
			"id": "spec_vulcan",
			"name": "Vulcan Brass-Casing Bar",
			"category": "SPECIALIST",
			"desc": "Score 150 kills with Vulcan MG turrets.",
			"citation": "Solved delicate geopolitical disputes at 600 rounds per minute.",
			"shape": "bar",
			"metal": GOLD,
			"ribbon": [ORANGE, GOLD, OLIVE],
			"weight_g": 280,
		},
		{
			"id": "spec_cryo",
			"name": "Order of Sub-Zero Bureaucracy",
			"category": "SPECIALIST",
			"desc": "Build or upgrade Cryo Emitters 15 times.",
			"citation": "Brought enemy columns to the exact pace of a municipal permit review.",
			"shape": "diamond",
			"metal": PLATINUM,
			"ribbon": [TEAL, CREAM, ROYAL],
			"weight_g": 320,
		},
		{
			"id": "spec_cannon",
			"name": "Artillery Noise-Complaint Cross",
			"category": "SPECIALIST",
			"desc": "Score 150 kills with Howitzer Cannons.",
			"citation": "Successfully rattled every teacup within fourteen sovereign kilometers.",
			"shape": "cross",
			"metal": BRONZE,
			"ribbon": [CRIMSON, OLIVE, ORANGE],
			"weight_g": 380,
		},
		{
			"id": "spec_missile",
			"name": "No-Fly-Zone Excellence Star",
			"category": "SPECIALIST",
			"desc": "Score 100 kills with SAM Batteries.",
			"citation": "Delivered polite homing reminders that the sky is closed until further notice.",
			"shape": "wings",
			"metal": GOLD,
			"ribbon": [EMERALD, CREAM, NAVY],
			"weight_g": 360,
		},
		{
			"id": "spec_drone",
			"name": "Autonomous Harassment Commendation",
			"category": "SPECIALIST",
			"desc": "Score 75 kills with Hunter Drone Pads.",
			"citation": "For relentless, map-wide robotic micromanagement of enemy armor.",
			"shape": "shield",
			"metal": SILVER,
			"ribbon": [EMERALD, OLIVE, GOLD],
			"weight_g": 340,
		},
		{
			"id": "spec_laser",
			"name": "Dragonfire Retinal-Safety Medal",
			"category": "SPECIALIST",
			"desc": "Score 100 kills with Dragonfire HEL Lasers.",
			"citation": "Certified Laser Specialist. Please do not look directly into the remaining beam.",
			"shape": "sunburst",
			"metal": SOVEREIGN,
			"ribbon": [SOVEREIGN, CRIMSON, CREAM],
			"weight_g": 410,
		},
		{
			"id": "spec_mlrs",
			"name": "Scorched-Asphalt Salvo Ribbon",
			"category": "SPECIALIST",
			"desc": "Score 125 kills with HIMARS MLRS.",
			"citation": "Public Works regrets to inform you that the highway is now legally magma.",
			"shape": "diamond",
			"metal": GOLD,
			"ribbon": [ORANGE, CRIMSON, GOLD],
			"weight_g": 430,
		},

		# --- TACTICAL & ECONOMY (9) ---
		{
			"id": "combined_arms",
			"name": "Combined-Arms Bureaucrat",
			"category": "TACTICAL",
			"desc": "Have all 7 turret types standing at once in a mission.",
			"citation": "Ensured every single defense contractor received an equal share of the budget.",
			"shape": "shield",
			"metal": GOLD,
			"ribbon": [ROYAL, EMERALD, ORANGE],
			"weight_g": 390,
		},
		{
			"id": "max_upgrade",
			"name": "Max-Spec Engineering Star",
			"category": "TACTICAL",
			"desc": "Upgrade any turret to Level 4.",
			"citation": "Spare no expense when bolting additional barrels onto a perfectly good turret.",
			"shape": "star",
			"metal": GOLD,
			"ribbon": [GOLD, NAVY, GOLD],
			"weight_g": 290,
		},
		{
			"id": "perfect_hq",
			"name": "Immaculate Headquarters Ribbon",
			"category": "TACTICAL",
			"desc": "Win any sector with 100% HQ Integrity (zero leaks).",
			"citation": "Not a single scuff mark on the General's marble reception foyer.",
			"shape": "circle",
			"metal": PLATINUM,
			"ribbon": [CREAM, GOLD, CREAM],
			"weight_g": 370,
		},
		{
			"id": "close_call",
			"name": "Skin-of-Your-Teeth Survival Clasp",
			"category": "TACTICAL",
			"desc": "Win any sector with 3 or fewer HQ lives left.",
			"citation": "Officially logged in the report as 'a calculated display of dramatic restraint.'",
			"shape": "cross",
			"metal": SILVER,
			"ribbon": [CRIMSON, CREAM, CRIMSON],
			"weight_g": 320,
		},
		{
			"id": "fiscal_restraint",
			"name": "Fiscal Restraint Order",
			"category": "TACTICAL",
			"desc": "Win any sector with at least $1,000 unspent cash in the bank.",
			"citation": "Treasury applauds your heroic refusal to buy unnecessary extra ammunition.",
			"shape": "circle",
			"metal": GOLD,
			"ribbon": [EMERALD, GOLD, CREAM],
			"weight_g": 350,
		},
		{
			"id": "early_caller",
			"name": "Impatient Commander's Spurs",
			"category": "TACTICAL",
			"desc": "Call 25 waves early ([N]) across your career.",
			"citation": "Found the enemy's scheduled arrival timetable intolerably leisurely.",
			"shape": "wings",
			"metal": BRONZE,
			"ribbon": [GOLD, ORANGE, GOLD],
			"weight_g": 260,
		},
		{
			"id": "airstrike_ace",
			"name": "Hellfire Close-Air-Support Crest",
			"category": "TACTICAL",
			"desc": "Call 15 Hellfire Air Strikes across your career.",
			"citation": "Kept the twin strike jets on speed-dial for minor roadside inconveniences.",
			"shape": "wings",
			"metal": GOLD,
			"ribbon": [CRIMSON, NAVY, ORANGE],
			"weight_g": 390,
		},
		{
			"id": "turret_flipper",
			"name": "Indecisive Contractor's Badge",
			"category": "TACTICAL",
			"desc": "Sell 25 turrets across your career.",
			"citation": "In recognition of bold, frequent, and financially questionable urban renewal.",
			"shape": "bar",
			"metal": SILVER,
			"ribbon": [OLIVE, CREAM, CRIMSON],
			"weight_g": 230,
		},
		{
			"id": "rank_35",
			"name": "Rank Inflation Commendation",
			"category": "TACTICAL",
			"desc": "Achieve Rank 35/50 or higher on any sector.",
			"citation": "Your official title now requires two business cards stapled end-to-end.",
			"shape": "sunburst",
			"metal": GOLD,
			"ribbon": [PURPLE, GOLD, PURPLE],
			"weight_g": 470,
		},

		# --- DUTY TIME & SPECIALTY (6) ---
		{
			"id": "time_5m",
			"name": "Five-Minute Desk Duty Ribbon",
			"category": "DUTY",
			"desc": "Spend 5 minutes on active sector duty.",
			"citation": "Successfully remained at your post long enough for the coffee to cool.",
			"shape": "bar",
			"metal": BRONZE,
			"ribbon": [ROYAL, CREAM, OLIVE],
			"weight_g": 160,
		},
		{
			"id": "time_30m",
			"name": "Half-Hour Perimeter Vigil Cross",
			"category": "DUTY",
			"desc": "Spend 30 minutes on active sector duty.",
			"citation": "Unwavering dedication to watching tiny vehicles explode from above.",
			"shape": "cross",
			"metal": SILVER,
			"ribbon": [NAVY, GOLD, ROYAL],
			"weight_g": 310,
		},
		{
			"id": "time_2h",
			"name": "Two-Hour Career Officer Sunburst",
			"category": "DUTY",
			"desc": "Spend 2 hours on active sector duty.",
			"citation": "High Command has formally upgraded your office chair to 'ceremonial.'",
			"shape": "sunburst",
			"metal": GOLD,
			"ribbon": [GOLD, CRIMSON, NAVY],
			"weight_g": 520,
		},
		{
			"id": "aps_breaker",
			"name": "Trophy-Shield Can-Opener",
			"category": "DUTY",
			"desc": "Destroy 25 Trophy APS Tanks.",
			"citation": "Proved that active protection systems are merely a polite suggestion.",
			"shape": "shield",
			"metal": PLATINUM,
			"ribbon": [TEAL, NAVY, PLATINUM],
			"weight_g": 350,
		},
		{
			"id": "fpv_swatter",
			"name": "FPV Flyswatter Pin",
			"category": "DUTY",
			"desc": "Destroy 50 Shahed FPV Drones.",
			"citation": "Maintained immaculate composure amid incessant hostile lawnmower noises.",
			"shape": "diamond",
			"metal": SILVER,
			"ribbon": [ORANGE, OLIVE, CREAM],
			"weight_g": 240,
		},
		{
			"id": "first_defeat",
			"name": "Participation & Attendance Rosette",
			"category": "DUTY",
			"desc": "Suffer your first Command HQ breach.",
			"citation": "Even catastrophic defeat warrants a shiny medal if the committee approves the paperwork.",
			"shape": "circle",
			"metal": BRONZE,
			"ribbon": [CRIMSON, OLIVE, CREAM],
			"weight_g": 220,
		},
	]
	return _cache

static func get_medal_by_id(medal_id: String) -> Dictionary:
	for m in get_all_medals():
		if String(m["id"]) == medal_id:
			return m
	return {}

static func get_progress(medal_id: String, stats: Dictionary, sector_records: Dictionary) -> Dictionary:
	# Returns { "current": int, "target": int, "unlocked": bool, "label": String }
	var tk: Dictionary = stats.get("turret_kills", {})
	var cur := 0
	var tgt := 1
	var label := ""

	match medal_id:
		"first_concrete":
			cur = int(stats.get("turrets_placed", 0)); tgt = 1
		"first_victory":
			cur = _count_regular_clears(sector_records); tgt = 1
		"earth_theater":
			cur = _count_theater_clears(sector_records, 1, 8); tgt = 8
		"offworld_theater":
			cur = _count_theater_clears(sector_records, 9, 16); tgt = 8
		"full_campaign":
			cur = _count_regular_clears(sector_records); tgt = 16
		"hard_clear":
			cur = 1 if _has_difficulty_clear(sector_records, int(WaveData.Difficulty.HARD)) else 0; tgt = 1
		"hell_clear":
			cur = 1 if _has_difficulty_clear(sector_records, int(WaveData.Difficulty.HELL)) else 0; tgt = 1
		"north_pole_clear":
			var np: Dictionary = sector_records.get("north_pole", {})
			cur = 1 if bool(np.get("cleared", false)) else 0; tgt = 1
		"kills_50":
			cur = int(stats.get("total_kills", 0)); tgt = 50
		"kills_250":
			cur = int(stats.get("total_kills", 0)); tgt = 250
		"kills_1000":
			cur = int(stats.get("total_kills", 0)); tgt = 1000
		"kills_3000":
			cur = int(stats.get("total_kills", 0)); tgt = 3000
		"air_kills_100":
			cur = int(stats.get("air_kills", 0)); tgt = 100
		"boss_kills_10":
			cur = int(stats.get("boss_kills", 0)); tgt = 10
		"spec_vulcan":
			cur = int(tk.get("vulcan", 0)); tgt = 150
		"spec_cryo":
			cur = int(stats.get("cryo_builds_upgrades", 0)); tgt = 15
		"spec_cannon":
			cur = int(tk.get("cannon", 0)); tgt = 150
		"spec_missile":
			cur = int(tk.get("missile", 0)); tgt = 100
		"spec_drone":
			cur = int(tk.get("drone", 0)); tgt = 75
		"spec_laser":
			cur = int(tk.get("laser", 0)); tgt = 100
		"spec_mlrs":
			cur = int(tk.get("mlrs", 0)); tgt = 125
		"combined_arms":
			cur = 1 if bool(stats.get("all_seven_turrets_achieved", false)) else 0; tgt = 1
		"max_upgrade":
			cur = int(stats.get("max_level_upgrades", 0)); tgt = 1
		"perfect_hq":
			cur = int(stats.get("perfect_hq_wins", 0)); tgt = 1
		"close_call":
			cur = int(stats.get("close_call_wins", 0)); tgt = 1
		"fiscal_restraint":
			cur = int(stats.get("rich_bank_wins", 0)); tgt = 1
		"early_caller":
			cur = int(stats.get("early_waves_called", 0)); tgt = 25
		"airstrike_ace":
			cur = int(stats.get("airstrikes_called", 0)); tgt = 15
		"turret_flipper":
			cur = int(stats.get("turrets_sold", 0)); tgt = 25
		"rank_35":
			cur = int(stats.get("best_rank_ever", 0)); tgt = 35
		"time_5m":
			var mins := int(floor(float(stats.get("play_time_sec", 0.0)) / 60.0))
			cur = mins; tgt = 5; label = "%d / %d min" % [mini(cur, tgt), tgt]
		"time_30m":
			var mins := int(floor(float(stats.get("play_time_sec", 0.0)) / 60.0))
			cur = mins; tgt = 30; label = "%d / %d min" % [mini(cur, tgt), tgt]
		"time_2h":
			var mins := int(floor(float(stats.get("play_time_sec", 0.0)) / 60.0))
			cur = mins; tgt = 120; label = "%d / %d min" % [mini(cur, tgt), tgt]
		"aps_breaker":
			cur = int(stats.get("aps_kills", 0)); tgt = 25
		"fpv_swatter":
			cur = int(stats.get("fpv_kills", 0)); tgt = 50
		"first_defeat":
			cur = int(stats.get("defeats", 0)); tgt = 1

	if label == "":
		label = "%d / %d" % [mini(cur, tgt), tgt]

	return {
		"current": cur,
		"target": tgt,
		"unlocked": cur >= tgt,
		"label": label,
	}

static func _count_regular_clears(sector_records: Dictionary) -> int:
	var count := 0
	for m in MapData.get_all_maps():
		var rec: Dictionary = sector_records.get(String(m["id"]), {})
		if bool(rec.get("cleared", false)):
			count += 1
	return count

static func _count_theater_clears(sector_records: Dictionary, min_idx: int, max_idx: int) -> int:
	var count := 0
	for m in MapData.get_all_maps():
		var idx: int = int(m["index"])
		if idx >= min_idx and idx <= max_idx:
			var rec: Dictionary = sector_records.get(String(m["id"]), {})
			if bool(rec.get("cleared", false)):
				count += 1
	return count

static func _has_difficulty_clear(sector_records: Dictionary, min_diff: int) -> bool:
	for rec in sector_records.values():
		if rec is Dictionary and bool(rec.get("cleared", false)) and int(rec.get("best_difficulty", -1)) >= min_diff:
			return true
	return false
