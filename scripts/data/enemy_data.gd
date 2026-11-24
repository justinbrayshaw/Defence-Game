class_name EnemyData
extends RefCounted

enum EnemyType {
	JEEP,
	APC,
	TANK,
	CHOPPER,
	BOMBER,
	JUGGERNAUT,
	APS_TANK,
	UAV_CARRIER,
	FPV_DRONE,
	SKY_FORTRESS,
}

static func get_config(type: EnemyType) -> Dictionary:
	match type:
		EnemyType.JEEP:
			return {
				"id": "jeep",
				"name": "Recon Humvee",
				"is_air": false,
				"hp": 58.0,
				"speed": 96.0,
				"armor": 0.05,
				"reward": 12,
				"lives_cost": 1,
				"radius": 11.0,
				"hull_color": Color(0.45, 0.48, 0.34),
				"trim_color": Color(0.28, 0.31, 0.22),
				"scale": 1.0,
			}
		EnemyType.APC:
			return {
				"id": "apc",
				"name": "BTR Armored APC",
				"is_air": false,
				"hp": 145.0,
				"speed": 68.0,
				"armor": 0.22,
				"reward": 20,
				"lives_cost": 1,
				"radius": 13.5,
				"hull_color": Color(0.38, 0.42, 0.34),
				"trim_color": Color(0.22, 0.25, 0.20),
				"scale": 1.12,
			}
		EnemyType.TANK:
			return {
				"id": "tank",
				"name": "Main Battle Tank",
				"is_air": false,
				"hp": 360.0,
				"speed": 46.0,
				"armor": 0.55,
				"reward": 36,
				"lives_cost": 2,
				"radius": 16.0,
				"hull_color": Color(0.34, 0.39, 0.30),
				"trim_color": Color(0.18, 0.21, 0.16),
				"scale": 1.25,
			}
		EnemyType.CHOPPER:
			return {
				"id": "chopper",
				"name": "Attack Gunship",
				"is_air": true,
				"hp": 190.0,
				"speed": 84.0,
				"armor": 0.12,
				"reward": 32,
				"lives_cost": 2,
				"radius": 15.0,
				"hull_color": Color(0.32, 0.36, 0.40),
				"trim_color": Color(0.18, 0.20, 0.24),
				"scale": 1.15,
			}
		EnemyType.BOMBER:
			return {
				"id": "bomber",
				"name": "Heavy Striker Jet",
				"is_air": true,
				"hp": 460.0,
				"speed": 72.0,
				"armor": 0.30,
				"reward": 58,
				"lives_cost": 3,
				"radius": 19.0,
				"hull_color": Color(0.28, 0.32, 0.36),
				"trim_color": Color(0.14, 0.17, 0.20),
				"scale": 1.35,
			}
		EnemyType.JUGGERNAUT:
			return {
				"id": "juggernaut",
				"name": "Siege Juggernaut",
				"is_air": false,
				"hp": 1650.0,
				"speed": 31.0,
				"armor": 0.66,
				"reward": 135,
				"lives_cost": 5,
				"radius": 22.0,
				"hull_color": Color(0.30, 0.30, 0.27),
				"trim_color": Color(0.58, 0.22, 0.16),
				"scale": 1.55,
			}
		EnemyType.APS_TANK:
			return {
				"id": "aps_tank",
				"name": "Trophy APS Tank",
				"is_air": false,
				"hp": 420.0,
				"shield": 240.0,
				"shield_regen": 40.0,
				"shield_regen_delay": 3.4,
				"speed": 44.0,
				"armor": 0.50,
				"reward": 56,
				"lives_cost": 2,
				"radius": 17.0,
				"hull_color": Color(0.28, 0.36, 0.38),
				"trim_color": Color(0.22, 0.78, 0.96),
				"scale": 1.30,
			}
		EnemyType.UAV_CARRIER:
			return {
				"id": "uav_carrier",
				"name": "Mobile UAV Carrier",
				"is_air": false,
				"hp": 290.0,
				"speed": 52.0,
				"armor": 0.28,
				"reward": 48,
				"lives_cost": 2,
				"radius": 16.5,
				"uav_spawn_interval": 4.6,
				"uav_first_delay": 2.2,
				"uav_max_spawns": 5,
				"hull_color": Color(0.36, 0.40, 0.33),
				"trim_color": Color(0.88, 0.58, 0.18),
				"scale": 1.24,
			}
		EnemyType.FPV_DRONE:
			return {
				"id": "fpv_drone",
				"name": "Shahed FPV Drone",
				"is_air": true,
				"hp": 46.0,
				"speed": 112.0,
				"armor": 0.0,
				"reward": 0,
				"lives_cost": 1,
				"radius": 9.0,
				"hull_color": Color(0.42, 0.44, 0.40),
				"trim_color": Color(0.94, 0.28, 0.20),
				"scale": 0.78,
			}
		EnemyType.SKY_FORTRESS:
			return {
				"id": "sky_fortress",
				"name": "Heavy Assault Gunship",
				"is_air": true,
				"hp": 1500.0,
				"speed": 42.0,
				"armor": 0.48,
				"reward": 145,
				"lives_cost": 4,
				"radius": 24.0,
				"hull_color": Color(0.25, 0.29, 0.34),
				"trim_color": Color(0.88, 0.30, 0.20),
				"scale": 1.55,
			}
	return {}
