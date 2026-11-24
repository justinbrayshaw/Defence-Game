shader_type canvas_item;

uniform sampler2D map_mask : filter_linear, repeat_disable;
uniform vec2 map_size = vec2(1600.0, 960.0);
uniform vec4 bridge_1 = vec4(-9999.0, -9999.0, 1.0, 0.0);
uniform vec4 bridge_2 = vec4(-9999.0, -9999.0, 1.0, 0.0);
uniform vec4 bridge_3 = vec4(-9999.0, -9999.0, 1.0, 0.0);
uniform int biome_type = 0; // 0=Alpine..8=Outback, 9=Tropical, 10=Volcanic, 11=Swamp, 12=Cyberpunk, 13=Moon, 14=Mars, 15=Europa, 16=Alien

float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

vec2 hash2(vec2 p) {
	return vec2(hash(p), hash(p + vec2(37.2, 17.9)));
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	for (int i = 0; i < 5; i++) {
		v += amp * noise(p);
		p = rot * p * 2.03 + vec2(19.3, 37.1);
		amp *= 0.5;
	}
	return v;
}

float ridged(vec2 p) {
	float v = 0.0;
	float amp = 0.55;
	mat2 rot = mat2(vec2(0.80, -0.60), vec2(0.60, 0.80));
	for (int i = 0; i < 4; i++) {
		float n = 1.0 - abs(noise(p) * 2.0 - 1.0);
		v += n * n * amp;
		p = rot * p * 2.12 + vec2(7.4, 13.9);
		amp *= 0.48;
	}
	return v;
}

float cobble_cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float min_d = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = hash2(i + g);
			vec2 r = g + o - f;
			float d = dot(r, r);
			min_d = min(min_d, d);
		}
	}
	return sqrt(min_d);
}

float caustics(vec2 p, float t) {
	vec2 p1 = p + vec2(sin(p.y * 1.4 + t * 1.3) * 0.35, -t * 0.75);
	vec2 p2 = p * 1.35 + vec2(cos(p.x * 1.2 - t * 1.1) * 0.3, -t * 1.05);
	float c1 = 1.0 - abs(noise(p1) * 2.0 - 1.0);
	float c2 = 1.0 - abs(noise(p2) * 2.0 - 1.0);
	return pow(clamp(c1 * c2 * 1.55, 0.0, 1.0), 2.4);
}

float water_wave_height(vec2 wp, float t) {
	vec2 flow1 = vec2(wp.x * 0.055, wp.y * 0.032 - t * 1.15);
	vec2 flow2 = vec2(wp.x * 0.11 + sin(wp.y * 0.035 - t) * 0.55, wp.y * 0.075 - t * 1.85);
	vec2 flow3 = vec2(wp.x * 0.24 - t * 0.35, wp.y * 0.19 - t * 2.6);
	float w1 = fbm(flow1) * 0.55;
	float w2 = noise(flow2) * 0.30;
	float w3 = noise(flow3) * 0.15;
	return w1 + w2 + w3;
}

float dune_ripples(vec2 wp) {
	float warp = fbm(wp * 0.012) * 4.5;
	float r1 = sin(wp.x * 0.17 + wp.y * 0.095 + warp);
	float r2 = sin(wp.x * 0.31 + wp.y * 0.16 - warp * 0.6) * 0.4;
	return (r1 + r2) * 0.018;
}

float snow_drifts(vec2 wp) {
	float warp = fbm(wp * 0.009) * 5.2;
	float s1 = sin(wp.x * 0.08 + wp.y * 0.13 + warp);
	float s2 = sin(wp.x * 0.19 + wp.y * 0.24 - warp * 0.5) * 0.35;
	return (s1 + s2) * 0.022;
}

float crater_layer(vec2 wp, float scale) {
	vec2 p = wp * scale;
	vec2 i = floor(p);
	vec2 f = fract(p);
	float delta_h = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 cell = i + g;
			vec2 o = hash2(cell);
			float r_cr = 0.22 + 0.24 * hash(cell + vec2(11.7, 29.3));
			float d = length(g + o - f) / r_cr;
			if (d < 1.35) {
				float bowl = -0.34 * max(0.0, 1.0 - d * d);
				float rim = 0.16 * exp(-pow((d - 0.96) / 0.16, 2.0));
				delta_h += bowl + rim;
			}
		}
	}
	return delta_h;
}

vec2 bridge_local(vec2 wp, vec4 b) {
	vec2 rel = wp - b.xy;
	vec2 dir = b.zw;
	vec2 perp = vec2(-dir.y, dir.x);
	return vec2(dot(rel, dir), dot(rel, perp));
}

float bridge_abutment_mask(vec2 wp, vec4 b) {
	vec2 loc = bridge_local(wp, b);
	return exp(-pow(loc.y / 40.0, 2.0)) * smoothstep(52.0, 74.0, abs(loc.x)) * (1.0 - smoothstep(82.0, 120.0, abs(loc.x)));
}

bool is_over_bridge(vec2 wp, vec4 b) {
	vec2 loc = bridge_local(wp, b);
	return abs(loc.x) < 66.0 && abs(loc.y) < 38.0;
}

float bridge_shadow_mask(vec2 wp, vec4 b) {
	vec2 loc = bridge_local(wp - vec2(12.0, 16.0), b);
	float bx = 1.0 - smoothstep(56.0, 74.0, abs(loc.x));
	float by = 1.0 - smoothstep(30.0, 48.0, abs(loc.y));
	return bx * by;
}

float bridge_pier_wake(vec2 wp, vec4 b, float t) {
	vec2 loc = bridge_local(wp, b);
	float dy_pier = loc.y - 30.0;
	if (dy_pier <= 0.0 || dy_pier >= 95.0) {
		return 0.0;
	}
	float wake_fade = smoothstep(0.0, 12.0, dy_pier) * (1.0 - smoothstep(25.0, 95.0, dy_pier));
	float spread = 5.0 + dy_pier * 0.18;
	float p1 = exp(-pow((loc.x - (-19.0)) / spread, 2.0));
	float p2 = exp(-pow((loc.x - 19.0) / spread, 2.0));
	float turb = smoothstep(0.36, 0.72, fbm(vec2(wp.x * 0.16, wp.y * 0.12 - t * 3.4)));
	return clamp(p1 + p2, 0.0, 1.0) * wake_fade * turb;
}

float scene_height(vec2 wp, vec4 m) {
	float d_road = m.r * 128.0;
	float d_river = m.g * 140.0;
	float d_pad = m.b * 96.0;

	vec2 uv_n = wp * 0.0036;
	float macro = fbm(uv_n) * 0.62 + ridged(uv_n * 2.05 + vec2(4.1, 2.7)) * 0.38;
	float micro_bump = (fbm(wp * 0.048) - 0.5) * 0.11;
	float h = 0.42 + macro * 0.55 + micro_bump;

	if (biome_type == 1) {
		float mesa = floor(h * 6.5) / 6.5;
		h = mix(h, mesa, 0.22) + dune_ripples(wp);
	} else if (biome_type == 2 || biome_type == 4) {
		h += snow_drifts(wp);
	} else if (biome_type == 3) {
		// Towering jagged mountain peaks rising steeply out of deep carved convoy valleys!
		float peaks = ridged(wp * 0.0052 + vec2(3.2, 6.8)) * 0.72 + ridged(wp * 0.0115 + vec2(-2.1, 4.4)) * 0.28;
		float valley_rise = smoothstep(38.0, 118.0, d_road) * smoothstep(46.0, 104.0, d_river);
		float pad_clear = smoothstep(26.0, 56.0, d_pad);
		float massif = valley_rise * mix(0.28, 1.0, pad_clear);
		h = 0.34 + macro * 0.24 + micro_bump * 1.15 + massif * (0.38 + peaks * 0.98);
	} else if (biome_type == 5) {
		// Flat engineered urban plateau with crisp canal embankment
		h = 0.62 + macro * 0.08 + micro_bump * 0.30;
	} else if (biome_type == 6) {
		// Soft rolling English countryside hills
		h = 0.48 + macro * 0.34 + micro_bump * 0.55;
	} else if (biome_type == 8) {
		// Flat sun-baked Outback plains with abrupt Uluru-style red sandstone mesas!
		float mesa_raw = smoothstep(0.60, 0.74, macro) * smoothstep(55.0, 115.0, d_road) * smoothstep(60.0, 110.0, d_river);
		h = 0.46 + macro * 0.18 + micro_bump * 0.70 + mesa_raw * 0.62;
	} else if (biome_type == 9) {
		// Tropical coral atoll: flat sandy coast rising gently to lush volcanic inland mounds
		h = 0.44 + macro * 0.40 + micro_bump * 0.60 + dune_ripples(wp) * 0.45;
	} else if (biome_type == 10) {
		// Obsidian Caldera: jagged fractured basalt ridges rising over cracked magma flats
		float jag = ridged(wp * 0.0065 + vec2(2.4, -5.1));
		h = 0.38 + macro * 0.28 + jag * 0.52 + micro_bump * 1.25;
	} else if (biome_type == 11) {
		// Cypress Bayou: low flat bog & muddy marsh hummocks
		h = 0.42 + macro * 0.22 + micro_bump * 0.50;
	} else if (biome_type == 12) {
		// Neo-Tokyo 2099: sleek flat concrete megacity deck with sharp canal walls
		h = 0.64 + macro * 0.06 + micro_bump * 0.22;
	} else if (biome_type == 13) {
		// The Moon: cratered lunar regolith with multi-scale 3D impact bowls & raised rims!
		float c_mask = smoothstep(38.0, 72.0, d_road) * smoothstep(46.0, 78.0, d_river) * smoothstep(26.0, 50.0, d_pad);
		float craters = crater_layer(wp, 0.0072) * 0.85 + crater_layer(wp + vec2(83.0, 41.0), 0.0175) * 0.42;
		h = 0.50 + macro * 0.26 + micro_bump * 0.85 + craters * c_mask;
	} else if (biome_type == 14) {
		// Mars Olympus Rift: dusty red dunes + stepped canyon terraces + impact craters
		float mesa_m = floor(h * 5.8) / 5.8;
		float c_mask = smoothstep(42.0, 80.0, d_road) * smoothstep(50.0, 84.0, d_river);
		h = mix(h, mesa_m, 0.28) + dune_ripples(wp) * 1.15 + crater_layer(wp, 0.0064) * 0.45 * c_mask;
	} else if (biome_type == 15) {
		// Europa Ice Shell: fractured tectonic ice plates with raised lineae ridges!
		float lin1 = abs(noise(wp * 0.014 + vec2(fbm(wp * 0.005) * 2.5, 0.0)) * 2.0 - 1.0);
		float ridge_ice = (1.0 - smoothstep(0.0, 0.14, lin1)) * 0.24;
		h = 0.48 + macro * 0.28 + ridge_ice + snow_drifts(wp) * 0.7;
	} else if (biome_type == 16) {
		// Xenon Prime: alien crystalline valley with faceted glowing mounds
		float xeno_r = ridged(wp * 0.0075 + vec2(-4.2, 3.8));
		h = 0.44 + macro * 0.30 + xeno_r * 0.46 + micro_bump * 0.90;
	}

	float pad_flat = 1.0 - smoothstep(22.0, 52.0, d_pad);
	float pad_mound = 1.0 - smoothstep(26.0, 44.0, d_pad);
	float pad_elev = (biome_type == 3) ? 0.76 : 0.72;
	h = mix(h, pad_elev + pad_mound * 0.10, pad_flat * 0.78);

	float road_zone = 1.0 - smoothstep(32.0, 56.0, d_road);
	float ditch = exp(-pow((d_road - 43.0) / 7.5, 2.0)) * 0.12;
	float road_crown = (1.0 - smoothstep(0.0, 34.0, d_road)) * 0.08;
	float road_elev = (biome_type == 3) ? 0.42 : 0.64;
	h = mix(h, road_elev + road_crown, road_zone * 0.88) - ditch;

	float bank_warp = (biome_type == 5 || biome_type == 12) ? 0.0 : ((fbm(wp * 0.026) - 0.5) * 18.0);
	float r_eff = d_river + bank_warp;
	float gorge = 1.0 - smoothstep(34.0, 102.0, r_eff);
	float cliff_step = (1.0 - smoothstep(42.0, 62.0, r_eff)) * 0.24;
	float abut = max(max(bridge_abutment_mask(wp, bridge_1), bridge_abutment_mask(wp, bridge_2)), bridge_abutment_mask(wp, bridge_3));
	h -= (gorge * 0.74 + cliff_step) * (1.0 - abut * 0.85);

	return h;
}

void fragment() {
	vec2 wp = UV * map_size;
	vec2 texel = vec2(2.6) / map_size;

	vec4 m = texture(map_mask, UV);
	vec4 mx = texture(map_mask, UV + vec2(texel.x, 0.0));
	vec4 my = texture(map_mask, UV + vec2(0.0, texel.y));

	float d_road = m.r * 128.0;
	float d_river = m.g * 140.0;
	float d_pad = m.b * 96.0;
	float river_side = (m.a - 0.5) * 2.0;

	float h = scene_height(wp, m);
	float hx = scene_height(wp + vec2(2.6, 0.0), mx);
	float hy = scene_height(wp + vec2(0.0, 2.6), my);

	float micro_h = fbm(wp * 0.14);
	float micro_hx = fbm((wp + vec2(1.4, 0.0)) * 0.14);
	float micro_hy = fbm((wp + vec2(0.0, 1.4)) * 0.14);

	vec3 normal = normalize(vec3(
		(h - hx) * 10.5 + (micro_h - micro_hx) * 1.8,
		(h - hy) * 10.5 + (micro_h - micro_hy) * 1.8,
		1.0
	));
	float slope = clamp(1.0 - normal.z, 0.0, 1.0);

	vec3 sun_dir = normalize(vec3(-0.68, -0.58, 0.66));
	vec3 view_dir = vec3(0.0, 0.0, 1.0);
	float ndotl = clamp(dot(normal, sun_dir), 0.0, 1.0);

	vec3 shadow_tint = vec3(0.46, 0.52, 0.58);
	vec3 sun_tint = vec3(1.24, 1.18, 1.04);
	if (biome_type == 1) {
		shadow_tint = vec3(0.50, 0.44, 0.48);
		sun_tint = vec3(1.26, 1.15, 0.94);
	} else if (biome_type == 2) {
		shadow_tint = vec3(0.45, 0.56, 0.72);
		sun_tint = vec3(1.10, 1.14, 1.18);
	} else if (biome_type == 3) {
		shadow_tint = vec3(0.36, 0.42, 0.52);
		sun_tint = vec3(1.26, 1.22, 1.14);
	} else if (biome_type == 4) {
		// Cozy starlit North Pole twilight with warm golden workshop bounce
		shadow_tint = vec3(0.34, 0.46, 0.66);
		sun_tint = vec3(1.08, 1.12, 1.20);
	} else if (biome_type == 5) {
		shadow_tint = vec3(0.46, 0.50, 0.56);
		sun_tint = vec3(1.18, 1.16, 1.10);
	} else if (biome_type == 6) {
		// Pleasant golden-afternoon English countryside sun
		shadow_tint = vec3(0.48, 0.55, 0.56);
		sun_tint = vec3(1.26, 1.22, 1.02);
	} else if (biome_type == 7) {
		// Rich cool-dappled deep woodland shade
		shadow_tint = vec3(0.34, 0.42, 0.40);
		sun_tint = vec3(1.16, 1.12, 0.96);
	} else if (biome_type == 8) {
		// Blistering warm Australian Outback sun + terracotta bounce
		shadow_tint = vec3(0.48, 0.38, 0.42);
		sun_tint = vec3(1.30, 1.14, 0.92);
	} else if (biome_type == 9) {
		// Tropical Pacific bright turquoise sky bounce + dazzling tropical sun
		shadow_tint = vec3(0.42, 0.56, 0.62);
		sun_tint = vec3(1.28, 1.24, 1.06);
	} else if (biome_type == 10) {
		// Volcanic caldera: dark ash ambient + fiery orange lava under-glow!
		shadow_tint = vec3(0.32, 0.22, 0.20);
		sun_tint = vec3(1.26, 0.92, 0.72);
	} else if (biome_type == 11) {
		// Cypress Bayou: eerie misty blue-green twilight
		shadow_tint = vec3(0.30, 0.38, 0.36);
		sun_tint = vec3(0.98, 1.06, 0.92);
	} else if (biome_type == 12) {
		// Neo-Tokyo 2099: rain-slick midnight indigo ambient + electric cyan/magenta sheen
		shadow_tint = vec3(0.24, 0.28, 0.42);
		sun_tint = vec3(0.86, 0.92, 1.14);
	} else if (biome_type == 13) {
		// The Moon: razor-sharp airless vacuum contrast! Deep pitch shadow + stark solar white
		shadow_tint = vec3(0.14, 0.15, 0.18);
		sun_tint = vec3(1.32, 1.32, 1.34);
	} else if (biome_type == 14) {
		// Mars Olympus Rift: dusty salmon-amber Martian atmosphere
		shadow_tint = vec3(0.38, 0.24, 0.22);
		sun_tint = vec3(1.28, 1.02, 0.84);
	} else if (biome_type == 15) {
		// Europa Ice Shell: distant pale Jovian sunlight + icy sapphire shadow
		shadow_tint = vec3(0.28, 0.40, 0.58);
		sun_tint = vec3(1.16, 1.24, 1.34);
	} else if (biome_type == 16) {
		// Xenon Prime: exotic deep-space indigo nebula light + iridescent cyan/violet shine
		shadow_tint = vec3(0.24, 0.20, 0.42);
		sun_tint = vec3(1.10, 0.96, 1.34);
	}
	vec3 sun_lit = mix(shadow_tint, sun_tint, smoothstep(0.12, 0.92, ndotl));

	float moisture = fbm(wp * 0.0052 + vec2(14.2, -9.8));
	float turf_var = fbm(wp * 0.022);
	float grain = noise(wp * 0.38) * 0.65 + noise(wp * 0.92) * 0.35;
	float cobbles = cobble_cells(wp * 0.16);
	float strata = fbm(wp * 0.065 + vec2(h * 3.5, 0.0));

	vec3 ground = vec3(0.0);
	if (biome_type == 1) {
		// DESERT SCORCHED WADI
		vec3 warm_sand = vec3(0.56, 0.44, 0.27);
		vec3 golden_dune = vec3(0.66, 0.53, 0.33);
		vec3 ochre_dust = vec3(0.47, 0.34, 0.21);
		vec3 red_sandstone = vec3(0.46, 0.26, 0.17);
		vec3 dark_mesa = vec3(0.32, 0.20, 0.14);
		vec3 oasis_grass = vec3(0.24, 0.31, 0.15);

		ground = mix(ochre_dust, warm_sand, smoothstep(0.24, 0.60, turf_var));
		ground = mix(ground, golden_dune, smoothstep(0.50, 0.84, h));
		ground *= mix(0.88, 1.12, grain);

		float rock_mask = smoothstep(0.13, 0.40, slope) + smoothstep(0.82, 0.96, h) * 0.62;
		float band = 0.5 + 0.5 * sin(h * 34.0 + strata * 3.0);
		vec3 cliff_col = mix(dark_mesa, red_sandstone, band);
		cliff_col *= mix(0.78, 1.16, smoothstep(0.18, 0.62, cobbles));
		ground = mix(ground, cliff_col, clamp(rock_mask, 0.0, 1.0));

		float oasis_belt = (1.0 - smoothstep(42.0, 92.0, d_river + (turf_var - 0.5) * 24.0)) * smoothstep(38.0, 50.0, d_river);
		ground = mix(ground, oasis_grass * mix(0.82, 1.16, grain), oasis_belt * 0.72 * (1.0 - rock_mask * 0.6));

		float pad_dirt = 1.0 - smoothstep(24.0, 42.0, d_pad + (turf_var - 0.5) * 9.0);
		ground = mix(ground, vec3(0.40, 0.32, 0.22) * mix(0.85, 1.12, cobbles), pad_dirt * 0.65);
	} else if (biome_type == 2) {
		// ARCTIC TUNDRA: Wind-sculpted snowdrifts, glacial ice-blue recesses, wind-scoured slate rock & permafrost
		vec3 packed_snow = vec3(0.68, 0.74, 0.80);
		vec3 fresh_snow = vec3(0.82, 0.86, 0.90);
		vec3 ice_crust = vec3(0.54, 0.65, 0.74);
		vec3 frozen_moss = vec3(0.26, 0.29, 0.24);
		vec3 dark_slate = vec3(0.22, 0.25, 0.29);
		vec3 frosty_granite = vec3(0.38, 0.42, 0.46);

		ground = mix(ice_crust, packed_snow, smoothstep(0.22, 0.58, turf_var));
		ground = mix(ground, fresh_snow, smoothstep(0.46, 0.82, h));

		// Wind-scoured patches of frozen dark tundra lichen/permafrost
		float scoured = smoothstep(0.64, 0.84, moisture) * (1.0 - smoothstep(0.55, 0.80, h));
		ground = mix(ground, frozen_moss * mix(0.84, 1.14, grain), scoured * 0.68);

		// Steep canyon walls & rocky outcrops expose craggy dark slate & frost-crusted granite
		float rock_mask = smoothstep(0.14, 0.40, slope) + smoothstep(0.85, 0.98, h) * 0.50;
		vec3 rock_col = mix(dark_slate, frosty_granite, smoothstep(0.28, 0.76, strata));
		rock_col *= mix(0.76, 1.18, smoothstep(0.18, 0.62, cobbles));
		ground = mix(ground, rock_col, clamp(rock_mask, 0.0, 1.0));

		// Fine snow powder micro-grain & subtle frost sparkle on sunlit snow
		ground *= mix(0.92, 1.08, grain);
		float sparkle = smoothstep(0.92, 0.99, noise(wp * 0.95)) * ndotl * (1.0 - rock_mask);
		ground += vec3(0.24, 0.28, 0.32) * sparkle;

		// Cleared frozen gravel/slush ring around turret hardpoints
		float pad_dirt = 1.0 - smoothstep(24.0, 40.0, d_pad + (turf_var - 0.5) * 9.0);
		ground = mix(ground, vec3(0.34, 0.37, 0.40) * mix(0.85, 1.12, cobbles), pad_dirt * 0.62);
	} else if (biome_type == 3) {
		// HIGH-ALTITUDE MOUNTAIN VALLEYS: Deep pine valley floors -> craggy granite cliffs -> snow-capped peaks!
		vec3 valley_moss = vec3(0.14, 0.20, 0.12);
		vec3 scree_earth = vec3(0.27, 0.25, 0.21);
		vec3 dark_granite = vec3(0.24, 0.25, 0.26);
		vec3 pale_granite = vec3(0.45, 0.44, 0.42);
		vec3 warm_quartz = vec3(0.42, 0.37, 0.31);
		vec3 peak_snow = vec3(0.86, 0.90, 0.94);

		// Deep valley floor greenery & talus scree
		ground = mix(valley_moss, scree_earth, smoothstep(0.36, 0.68, turf_var));
		ground *= mix(0.84, 1.14, grain);

		// Craggy alpine granite cliffs rising out of the valleys
		float cliff_band = 0.5 + 0.5 * sin(h * 28.0 + strata * 3.4);
		vec3 granite = mix(dark_granite, mix(pale_granite, warm_quartz, 0.32), cliff_band);
		granite *= mix(0.74, 1.20, smoothstep(0.16, 0.64, cobbles));

		float rock_mask = smoothstep(0.11, 0.36, slope) + smoothstep(0.56, 0.84, h);
		ground = mix(ground, granite, clamp(rock_mask, 0.0, 1.0));

		// High-altitude snowcaps clinging to mountain summits & ledges (shedding off ultra-sheer rock faces)
		float snow_line = smoothstep(0.94, 1.22, h + (turf_var - 0.5) * 0.14);
		float sheer_shed = 1.0 - smoothstep(0.48, 0.74, slope);
		float summit_snow = clamp(snow_line * sheer_shed, 0.0, 1.0);
		ground = mix(ground, peak_snow * mix(0.92, 1.08, grain), summit_snow);

		// Subtle deep-valley atmospheric depth & cliff-base ambient occlusion
		float valley_depth_ao = smoothstep(0.32, 0.62, h);
		ground *= mix(0.80, 1.0, valley_depth_ao);

		// Compacted rocky gravel shelf on mountain turret ledges
		float pad_dirt = 1.0 - smoothstep(24.0, 42.0, d_pad + (turf_var - 0.5) * 8.0);
		ground = mix(ground, vec3(0.33, 0.33, 0.31) * mix(0.84, 1.14, cobbles), pad_dirt * 0.72);
	} else if (biome_type == 4) {
		// SANTA'S NORTH POLE: Plush sparkling snow + shimmering Northern Lights (Aurora Borealis!)
		vec3 snow_shadow = vec3(0.56, 0.68, 0.82);
		vec3 snow_plush = vec3(0.82, 0.88, 0.94);
		vec3 snow_bright = vec3(0.92, 0.96, 1.00);
		vec3 frost_slate = vec3(0.30, 0.38, 0.48);

		ground = mix(snow_shadow, snow_plush, smoothstep(0.22, 0.60, turf_var));
		ground = mix(ground, snow_bright, smoothstep(0.50, 0.85, h));

		float rock_mask = smoothstep(0.18, 0.46, slope);
		ground = mix(ground, frost_slate * mix(0.82, 1.16, cobbles), rock_mask * 0.75);
		ground *= mix(0.94, 1.06, grain);

		// Magical Northern Lights aurora waves drifting softly across the snow
		float a_wave1 = sin(wp.x * 0.0045 + wp.y * 0.0025 + TIME * 0.45 + fbm(wp * 0.003) * 3.5);
		float a_wave2 = sin(wp.x * 0.0032 - wp.y * 0.0042 - TIME * 0.32 + fbm(wp * 0.004) * 3.0);
		float aurora_green = smoothstep(0.35, 0.95, a_wave1) * 0.14;
		float aurora_violet = smoothstep(0.45, 0.98, a_wave2) * 0.10;
		ground += vec3(0.08, 0.55, 0.42) * aurora_green + vec3(0.46, 0.16, 0.62) * aurora_violet;

		// Glistening diamond snow sparkles
		float sparkle = smoothstep(0.91, 0.99, noise(wp * 0.88 + vec2(sin(TIME * 0.6) * 0.05, 0.0)));
		ground += vec3(0.45, 0.52, 0.60) * sparkle;

		// Warm golden glow radiating around Santa's Workshop on the eastern courtyard
		float workshop_dist = length(wp - vec2(1515.0, 480.0));
		float warm_glow = exp(-workshop_dist * 0.0055);
		ground += vec3(0.42, 0.28, 0.08) * warm_glow * 0.55;

		// Festive cobblestone clearing under wreath turret pads
		float pad_clear = 1.0 - smoothstep(23.0, 38.0, d_pad + (turf_var - 0.5) * 6.0);
		ground = mix(ground, vec3(0.44, 0.34, 0.30) * mix(0.84, 1.14, cobbles), pad_clear * 0.58);
	} else if (biome_type == 5) {
		// TOWN OF IRONBOURNE: Concrete city blocks, tiled plazas, manicured park lawns, canal quay!
		vec3 concrete_a = vec3(0.35, 0.36, 0.35);
		vec3 concrete_b = vec3(0.45, 0.45, 0.43);
		vec3 park_grass = vec3(0.20, 0.30, 0.16);
		vec3 plaza_tile = vec3(0.41, 0.39, 0.35);

		// Urban paving slab grid lines
		vec2 tile_f = abs(fract(wp / 32.0) - 0.5);
		float seam = 1.0 - smoothstep(0.45, 0.495, max(tile_f.x, tile_f.y));
		ground = mix(concrete_a, concrete_b, turf_var) * mix(0.84, 1.04, seam);
		ground = mix(ground, plaza_tile, smoothstep(0.54, 0.72, moisture) * 0.55);

		// Manicured city park lawn patches in residential blocks
		float park_mask = smoothstep(0.56, 0.70, fbm(wp * 0.0065 + vec2(3.1, 7.2))) * smoothstep(46.0, 62.0, d_road) * smoothstep(52.0, 68.0, d_river);
		ground = mix(ground, park_grass * mix(0.88, 1.12, grain), park_mask * 0.92);
		ground *= mix(0.92, 1.08, grain);

		// Concrete canal quay stone wall border
		float quay = (1.0 - smoothstep(40.0, 56.0, d_river)) * smoothstep(38.0, 42.0, d_river);
		ground = mix(ground, vec3(0.48, 0.48, 0.46), quay * 0.9);
	} else if (biome_type == 6) {
		// PLEASANT ENGLISH COUNTRYSIDE: Patchwork emerald pastures, golden plowed wheat fields & hedgerows!
		vec2 field_uv = wp / 210.0 + (vec2(fbm(wp * 0.004), fbm(wp * 0.004 + vec2(7.3, 4.1))) - 0.5) * 0.45;
		vec2 f_cell = floor(field_uv);
		vec2 f_frac = fract(field_uv);
		float field_id = hash(f_cell);

		// Plowed tractor crop furrows rotated per field!
		float furrow_ang = (field_id > 0.5) ? 0.0 : 1.5708;
		float f_coord = wp.x * cos(furrow_ang) + wp.y * sin(furrow_ang);
		float furrows = 0.5 + 0.5 * sin(f_coord * 0.48);

		vec3 lush_pasture = vec3(0.20, 0.36, 0.14);
		vec3 clover_meadow = vec3(0.28, 0.42, 0.17);
		vec3 golden_wheat = vec3(0.58, 0.49, 0.20);
		vec3 plowed_loam = vec3(0.36, 0.27, 0.16);

		if (field_id < 0.34) {
			ground = mix(lush_pasture, clover_meadow, turf_var);
		} else if (field_id < 0.64) {
			ground = mix(clover_meadow, lush_pasture, turf_var) * mix(0.92, 1.08, furrows);
		} else if (field_id < 0.86) {
			ground = mix(golden_wheat * 0.88, golden_wheat * 1.10, furrows);
		} else {
			ground = mix(plowed_loam * 0.86, plowed_loam * 1.12, furrows);
		}
		ground *= mix(0.88, 1.12, grain);

		// Dark green English hedgerow / stone-wall field boundaries!
		float edge_d = min(min(f_frac.x, 1.0 - f_frac.x), min(f_frac.y, 1.0 - f_frac.y));
		float hedge = (1.0 - smoothstep(0.015, 0.048, edge_d)) * smoothstep(42.0, 56.0, d_road) * smoothstep(48.0, 62.0, d_river) * smoothstep(32.0, 46.0, d_pad);
		ground = mix(ground, vec3(0.11, 0.20, 0.09) * mix(0.8, 1.15, cobbles), hedge * 0.85);

		float pad_dirt = 1.0 - smoothstep(24.0, 40.0, d_pad + (turf_var - 0.5) * 8.0);
		ground = mix(ground, vec3(0.38, 0.34, 0.26) * mix(0.88, 1.12, cobbles), pad_dirt * 0.62);
	} else if (biome_type == 7) {
		// WHISPERWOOD DEEP FOREST: Velvet forest moss, amber leaf litter, dark humus & dappled sunlight!
		vec3 deep_moss = vec3(0.10, 0.19, 0.09);
		vec3 fern_green = vec3(0.16, 0.27, 0.12);
		vec3 leaf_litter = vec3(0.28, 0.21, 0.11);
		vec3 dark_humus = vec3(0.14, 0.12, 0.08);

		ground = mix(deep_moss, fern_green, smoothstep(0.24, 0.64, turf_var));
		ground = mix(ground, leaf_litter, smoothstep(0.56, 0.82, moisture) * 0.72);
		ground = mix(ground, dark_humus, smoothstep(0.18, 0.44, slope) * 0.70);
		ground *= mix(0.80, 1.18, grain);

		// Dappled golden sunlight beams piercing the forest canopy!
		float dapple = smoothstep(0.56, 0.82, fbm(wp * 0.018 + vec2(4.2, -3.1)));
		ground += vec3(0.12, 0.13, 0.05) * dapple;

		float pad_dirt = 1.0 - smoothstep(24.0, 40.0, d_pad + (turf_var - 0.5) * 8.0);
		ground = mix(ground, vec3(0.24, 0.19, 0.13) * mix(0.84, 1.14, cobbles), pad_dirt * 0.72);
	} else if (biome_type == 8) {
		// THE AUSTRALIAN OUTBACK: Iconic Uluru iron-oxide crimson red earth, claypans & red mesas!
		vec3 red_earth = vec3(0.58, 0.23, 0.12);
		vec3 bright_ochre = vec3(0.70, 0.33, 0.16);
		vec3 claypan = vec3(0.64, 0.48, 0.34);
		vec3 uluru_rock = vec3(0.48, 0.17, 0.10);
		vec3 mesa_crest = vec3(0.62, 0.24, 0.13);

		ground = mix(red_earth, bright_ochre, smoothstep(0.26, 0.68, turf_var));
		// Sun-baked cracked claypan flats
		float pan_mask = smoothstep(0.68, 0.86, moisture) * (1.0 - smoothstep(0.55, 0.72, h));
		ground = mix(ground, claypan, pan_mask * 0.65);
		ground *= mix(0.86, 1.14, grain);

		// Stratified Uluru red sandstone mesas rising from the red plains
		float rock_mask = smoothstep(0.12, 0.38, slope) + smoothstep(0.76, 0.94, h) * 0.72;
		float band = 0.5 + 0.5 * sin(h * 30.0 + strata * 3.0);
		vec3 mesa_col = mix(uluru_rock, mesa_crest, band) * mix(0.76, 1.18, smoothstep(0.18, 0.62, cobbles));
		ground = mix(ground, mesa_col, clamp(rock_mask, 0.0, 1.0));

		// Dusty pale-olive eucalyptus river gum verge near billabong creek
		float creek_verge = (1.0 - smoothstep(42.0, 78.0, d_river + (turf_var - 0.5) * 18.0)) * smoothstep(38.0, 48.0, d_river);
		ground = mix(ground, vec3(0.32, 0.34, 0.20) * mix(0.85, 1.15, grain), creek_verge * 0.55);

		float pad_dirt = 1.0 - smoothstep(24.0, 42.0, d_pad + (turf_var - 0.5) * 9.0);
		ground = mix(ground, vec3(0.46, 0.20, 0.12) * mix(0.85, 1.14, cobbles), pad_dirt * 0.65);
	} else if (biome_type == 9) {
		// PACIFIC CORAL ATOLL: Dazzling cream-white coral sand ring islets + lush emerald palm-island cores!
		vec3 white_sand = vec3(0.92, 0.86, 0.70);
		vec3 warm_sand = vec3(0.82, 0.73, 0.52);
		vec3 jungle_moss = vec3(0.14, 0.36, 0.16);
		vec3 palm_turf = vec3(0.24, 0.48, 0.20);

		float outer_e = length((wp - vec2(800.0, 480.0)) / vec2(770.0, 452.0));
		float inner_beach = 1.0 - smoothstep(54.0, 126.0, d_river + (turf_var - 0.5) * 28.0);
		float outer_beach = smoothstep(0.78, 0.96, outer_e + (turf_var - 0.5) * 0.08);
		float sand_mask = clamp(max(inner_beach, outer_beach), 0.0, 1.0);
		vec3 inland = mix(jungle_moss, palm_turf, smoothstep(0.28, 0.68, turf_var));
		vec3 beach = mix(warm_sand, white_sand, smoothstep(0.28, 0.72, h));
		ground = mix(inland, beach, sand_mask);
		ground *= mix(0.90, 1.10, grain);

		float pad_sand = 1.0 - smoothstep(24.0, 44.0, d_pad + (turf_var - 0.5) * 8.0);
		ground = mix(ground, vec3(0.84, 0.77, 0.58) * mix(0.90, 1.10, cobbles), pad_sand * 0.78);
	} else if (biome_type == 10) {
		// OBSIDIAN CALDERA: Jagged black basalt, charred volcanic ash & incandescent glowing magma fissures!
		vec3 charred_ash = vec3(0.12, 0.11, 0.11);
		vec3 dark_basalt = vec3(0.19, 0.18, 0.19);
		vec3 warm_slate = vec3(0.28, 0.23, 0.21);

		ground = mix(charred_ash, dark_basalt, smoothstep(0.25, 0.68, turf_var));
		ground = mix(ground, warm_slate, smoothstep(0.55, 0.85, h) * 0.65);
		ground *= mix(0.80, 1.18, cobbles);
		ground *= mix(0.86, 1.14, grain);

		// Glowing molten magma cracks pulsing in volcanic crevices!
		float crack_f = abs(noise(wp * 0.018 + vec2(fbm(wp * 0.008) * 2.2, 0.0)) * 2.0 - 1.0);
		float lava_vein = (1.0 - smoothstep(0.0, 0.065, crack_f)) * (1.0 - smoothstep(0.52, 0.76, h)) * smoothstep(38.0, 56.0, d_road) * smoothstep(26.0, 42.0, d_pad);
		float pulse_v = 0.78 + 0.22 * sin(TIME * 2.6 + wp.x * 0.02 + wp.y * 0.015);
		ground += vec3(1.15, 0.36, 0.04) * lava_vein * pulse_v * 1.45;
		// Fiery heat reflection near the molten lava riverbanks
		float heat_glow = (1.0 - smoothstep(38.0, 96.0, d_river)) * smoothstep(36.0, 44.0, d_river);
		ground += vec3(0.55, 0.16, 0.02) * heat_glow * 0.62;
	} else if (biome_type == 11) {
		// CYPRESS BAYOU: Damp mossy marshland, dark peat bog, duckweed puddles & eerie twilight mist!
		vec3 peat_mud = vec3(0.14, 0.15, 0.10);
		vec3 bog_moss = vec3(0.16, 0.24, 0.12);
		vec3 swamp_fern = vec3(0.22, 0.30, 0.14);
		vec3 duckweed = vec3(0.30, 0.44, 0.16);

		ground = mix(peat_mud, bog_moss, smoothstep(0.26, 0.64, turf_var));
		ground = mix(ground, swamp_fern, smoothstep(0.52, 0.80, h) * 0.75);
		float puddle = smoothstep(0.64, 0.82, moisture) * (1.0 - smoothstep(0.46, 0.64, h));
		ground = mix(ground, duckweed * 0.75, puddle * 0.58);
		ground *= mix(0.84, 1.16, grain);

		// Drifting pale twilight swamp fog wisps
		float mist = smoothstep(0.45, 0.85, fbm(wp * 0.0045 + vec2(TIME * 0.025, -TIME * 0.012)));
		ground = mix(ground, vec3(0.28, 0.38, 0.36), mist * 0.24);
	} else if (biome_type == 12) {
		// NEO-TOKYO 2099: Wet midnight carbon-deck plazas, circuit seams & ambient cyan/magenta neon glow!
		vec3 deck_a = vec3(0.11, 0.13, 0.17);
		vec3 deck_b = vec3(0.18, 0.20, 0.26);
		vec2 tile_f = abs(fract(wp / 36.0) - 0.5);
		float seam = 1.0 - smoothstep(0.46, 0.495, max(tile_f.x, tile_f.y));
		ground = mix(deck_a, deck_b, turf_var) * mix(0.78, 1.06, seam);
		ground *= mix(0.90, 1.10, grain);

		// Subtle glowing cyan circuit traces along city deck seams
		float circuit = (1.0 - seam) * smoothstep(0.62, 0.86, fbm(wp * 0.012));
		ground += vec3(0.06, 0.42, 0.58) * circuit * 0.45;
		// Wet neon reflection pools scattered over the rain-slick plazas
		float neon_pool = smoothstep(0.60, 0.82, moisture);
		vec3 neon_bounce = mix(vec3(0.45, 0.08, 0.38), vec3(0.06, 0.38, 0.48), smoothstep(0.35, 0.65, sin(wp.x * 0.009 + wp.y * 0.006)));
		ground += neon_bounce * neon_pool * 0.24;
	} else if (biome_type == 13) {
		// THE MOON (SEA OF TRANQUILITY): Silver-grey cratered lunar regolith & bright ejecta rays!
		vec3 mare_dark = vec3(0.30, 0.31, 0.33);
		vec3 regolith = vec3(0.48, 0.49, 0.51);
		vec3 bright_ejecta = vec3(0.68, 0.70, 0.72);

		ground = mix(mare_dark, regolith, smoothstep(0.24, 0.68, turf_var));
		ground = mix(ground, bright_ejecta, smoothstep(0.64, 0.90, h) * 0.72);
		ground *= mix(0.84, 1.16, grain);

		// Sharp rocky crater walls & rim highlights
		float rock_mask = smoothstep(0.14, 0.40, slope);
		ground = mix(ground, vec3(0.58, 0.59, 0.61) * mix(0.76, 1.18, cobbles), rock_mask * 0.75);

		float pad_deck = 1.0 - smoothstep(23.0, 40.0, d_pad + (turf_var - 0.5) * 6.0);
		ground = mix(ground, vec3(0.38, 0.40, 0.43) * mix(0.88, 1.12, cobbles), pad_deck * 0.65);
	} else if (biome_type == 14) {
		// MARS: OLYMPUS RIFT: Rusty vermilion dust plains, layered salmon canyon rock & dark iron-sand!
		vec3 dark_iron = vec3(0.36, 0.16, 0.10);
		vec3 mars_rust = vec3(0.60, 0.26, 0.15);
		vec3 salmon_dust = vec3(0.74, 0.38, 0.22);
		vec3 canyon_band = vec3(0.46, 0.18, 0.11);

		ground = mix(mars_rust, salmon_dust, smoothstep(0.28, 0.70, turf_var));
		ground = mix(ground, dark_iron, smoothstep(0.62, 0.84, moisture) * 0.58);
		ground *= mix(0.86, 1.14, grain);

		float rock_mask = smoothstep(0.12, 0.38, slope) + smoothstep(0.78, 0.96, h) * 0.55;
		float band = 0.5 + 0.5 * sin(h * 32.0 + strata * 3.2);
		ground = mix(ground, mix(dark_iron, canyon_band * 1.35, band) * mix(0.78, 1.16, cobbles), clamp(rock_mask, 0.0, 1.0));

		float pad_deck = 1.0 - smoothstep(24.0, 42.0, d_pad + (turf_var - 0.5) * 8.0);
		ground = mix(ground, vec3(0.42, 0.22, 0.14) * mix(0.86, 1.14, cobbles), pad_deck * 0.65);
	} else if (biome_type == 15) {
		// EUROPA ICE SHELL: Translucent sapphire-white glacial ice crisscrossed with reddish-rust tectonic lineae!
		vec3 deep_ice = vec3(0.48, 0.64, 0.80);
		vec3 bright_ice = vec3(0.80, 0.88, 0.96);
		vec3 rust_lineae = vec3(0.56, 0.34, 0.26);

		ground = mix(deep_ice, bright_ice, smoothstep(0.24, 0.72, h));
		// Intersecting planetary tectonic salt-rust lineae fractures!
		float l1 = abs(noise(wp * 0.014 + vec2(fbm(wp * 0.005) * 2.5, 0.0)) * 2.0 - 1.0);
		float l2 = abs(noise(wp * 0.019 + vec2(0.0, fbm(wp * 0.006) * 2.2)) * 2.0 - 1.0);
		float lineae = clamp((1.0 - smoothstep(0.0, 0.11, l1)) + (1.0 - smoothstep(0.0, 0.09, l2)) * 0.75, 0.0, 1.0);
		ground = mix(ground, rust_lineae * mix(0.82, 1.16, cobbles), lineae * 0.74);
		ground *= mix(0.92, 1.08, grain);

		// Sub-surface cyan glow bleeding through ice near the Abyssal Fissure!
		float abyss_glow = (1.0 - smoothstep(38.0, 92.0, d_river)) * smoothstep(36.0, 44.0, d_river);
		ground += vec3(0.08, 0.56, 0.72) * abyss_glow * 0.52;
		float sparkle = smoothstep(0.90, 0.99, noise(wp * 0.92)) * ndotl;
		ground += vec3(0.35, 0.48, 0.62) * sparkle;
	} else if (biome_type == 16) {
		// XENON PRIME (EXOPLANET): Deep velvet indigo-violet alien soil with pulsing glowing cyan/magenta crystal veins!
		vec3 void_soil = vec3(0.13, 0.09, 0.22);
		vec3 violet_turf = vec3(0.24, 0.14, 0.36);
		vec3 indigo_ridge = vec3(0.18, 0.24, 0.42);

		ground = mix(void_soil, violet_turf, smoothstep(0.24, 0.68, turf_var));
		ground = mix(ground, indigo_ridge, smoothstep(0.56, 0.88, h) * 0.75);
		ground *= mix(0.84, 1.16, grain);

		// Glowing bioluminescent ley-line crystal fissures across the alien crust!
		float ley = abs(noise(wp * 0.016 + vec2(fbm(wp * 0.006) * 2.4, -TIME * 0.04)) * 2.0 - 1.0);
		float vein = (1.0 - smoothstep(0.0, 0.075, ley)) * smoothstep(36.0, 52.0, d_road);
		float p_vein = 0.72 + 0.28 * sin(TIME * 2.2 + wp.x * 0.015);
		vec3 vein_col = mix(vec3(0.14, 0.92, 0.96), vec3(0.94, 0.24, 0.82), smoothstep(0.3, 0.7, moisture));
		ground += vein_col * vein * p_vein * 0.78;
	} else {
		// ALPINE IRON VALLEY
		vec3 rich_moss = vec3(0.15, 0.21, 0.12);
		vec3 olive_grass = vec3(0.22, 0.28, 0.16);
		vec3 dry_meadow = vec3(0.32, 0.30, 0.19);
		vec3 packed_earth = vec3(0.28, 0.23, 0.17);
		vec3 cliff_rock = vec3(0.35, 0.34, 0.30);
		vec3 wet_shale = vec3(0.21, 0.20, 0.17);

		ground = mix(rich_moss, olive_grass, smoothstep(0.28, 0.62, turf_var));
		ground = mix(ground, dry_meadow, smoothstep(0.50, 0.80, turf_var) * (1.0 - moisture * 0.55));
		ground *= mix(0.84, 1.15, grain);

		float rock_mask = smoothstep(0.14, 0.42, slope) + smoothstep(0.84, 0.98, h) * 0.55;
		vec3 rock_col = mix(wet_shale, cliff_rock, smoothstep(0.25, 0.78, strata));
		rock_col *= mix(0.76, 1.16, smoothstep(0.18, 0.62, cobbles));
		ground = mix(ground, rock_col, clamp(rock_mask, 0.0, 1.0));

		float pad_dirt = 1.0 - smoothstep(24.0, 40.0, d_pad + (turf_var - 0.5) * 9.0);
		ground = mix(ground, packed_earth * mix(0.85, 1.12, cobbles), pad_dirt * 0.68);
	}

	vec3 col = ground * sun_lit;

	// === TEXTURED 3D MILITARY ROAD ===
	float road_edge_noise = (fbm(wp * 0.08) - 0.5) * 4.5;
	float r_dist = d_road + road_edge_noise;
	float in_shoulder = 1.0 - smoothstep(32.0, 45.0, r_dist);
	float in_asphalt = 1.0 - smoothstep(28.5, 32.5, r_dist);

	bool over_bridge_span = is_over_bridge(wp, bridge_1) || is_over_bridge(wp, bridge_2) || is_over_bridge(wp, bridge_3);

	if (in_shoulder > 0.001 && !over_bridge_span) {
		float gravel_grain = noise(wp * 0.45) * 0.5 + cobbles * 0.5;
		vec3 sh_dark = vec3(0.24, 0.22, 0.18);
		vec3 sh_light = vec3(0.38, 0.35, 0.29);
		if (biome_type == 1) {
			sh_dark = vec3(0.42, 0.32, 0.20);
			sh_light = vec3(0.60, 0.48, 0.31);
		} else if (biome_type == 2) {
			sh_dark = vec3(0.38, 0.43, 0.48);
			sh_light = vec3(0.76, 0.81, 0.86);
		} else if (biome_type == 4) {
			// Candy-cane striped snowy cobblestone curb!
			float stripe = step(0.5, fract((wp.x + wp.y) * 0.032));
			sh_dark = mix(vec3(0.78, 0.14, 0.16), vec3(0.92, 0.94, 0.96), stripe);
			sh_light = mix(vec3(0.92, 0.24, 0.24), vec3(0.98, 0.98, 1.00), stripe);
		} else if (biome_type == 5) {
			// Crisp urban concrete sidewalks
			sh_dark = vec3(0.44, 0.45, 0.44);
			sh_light = vec3(0.56, 0.56, 0.54);
		} else if (biome_type == 6) {
			// Mossy English country grass verge
			sh_dark = vec3(0.20, 0.32, 0.14);
			sh_light = vec3(0.34, 0.42, 0.20);
		} else if (biome_type == 7) {
			// Muddy woodland trail berm
			sh_dark = vec3(0.18, 0.14, 0.09);
			sh_light = vec3(0.30, 0.23, 0.14);
		} else if (biome_type == 8) {
			// Red-ochre outback dust shoulder
			sh_dark = vec3(0.48, 0.19, 0.10);
			sh_light = vec3(0.68, 0.31, 0.15);
		} else if (biome_type == 9) {
			// Bright coral-sand beach shoulder
			sh_dark = vec3(0.68, 0.60, 0.44);
			sh_light = vec3(0.88, 0.82, 0.66);
		} else if (biome_type == 10) {
			// Scorched volcanic basalt gravel shoulder
			sh_dark = vec3(0.14, 0.11, 0.11);
			sh_light = vec3(0.28, 0.20, 0.17);
		} else if (biome_type == 11) {
			// Muddy cypress marsh berm
			sh_dark = vec3(0.15, 0.17, 0.10);
			sh_light = vec3(0.26, 0.30, 0.16);
		} else if (biome_type == 12) {
			// Neo-Tokyo illuminated cyber-curb sidewalk
			sh_dark = vec3(0.14, 0.17, 0.24);
			sh_light = vec3(0.24, 0.28, 0.38);
		} else if (biome_type == 13) {
			// Moon regolith compacted rover berm
			sh_dark = vec3(0.32, 0.33, 0.36);
			sh_light = vec3(0.56, 0.57, 0.60);
		} else if (biome_type == 14) {
			// Mars vermilion dust shoulder
			sh_dark = vec3(0.44, 0.19, 0.11);
			sh_light = vec3(0.66, 0.32, 0.18);
		} else if (biome_type == 15) {
			// Europa packed cryogenic ice shoulder
			sh_dark = vec3(0.42, 0.56, 0.72);
			sh_light = vec3(0.76, 0.86, 0.96);
		} else if (biome_type == 16) {
			// Xenon Prime crystalline violet berm
			sh_dark = vec3(0.20, 0.12, 0.34);
			sh_light = vec3(0.38, 0.22, 0.54);
		}
		vec3 shoulder_col = mix(sh_dark, sh_light, gravel_grain) * sun_lit;
		col = mix(col, shoulder_col, in_shoulder * 0.94);

		if (in_asphalt > 0.001) {
			float agg = noise(wp * 0.72) * 0.55 + noise(wp * 1.55) * 0.45;
			float wear = fbm(wp * 0.042);
			float crack_n = abs(noise(wp * 0.075 + vec2(wear * 2.0, 0.0)) * 2.0 - 1.0);
			float crack = 1.0 - smoothstep(0.0, 0.045, crack_n);

			vec3 asp_a = vec3(0.17, 0.175, 0.17);
			vec3 asp_b = vec3(0.26, 0.26, 0.25);
			if (biome_type == 1) {
				asp_a = vec3(0.23, 0.21, 0.19);
				asp_b = vec3(0.34, 0.30, 0.25);
			} else if (biome_type == 2) {
				asp_a = vec3(0.16, 0.18, 0.21);
				asp_b = vec3(0.27, 0.30, 0.34);
			} else if (biome_type == 4) {
				// Cozy frosted red-brown Workshop cobblestone highway
				asp_a = vec3(0.30, 0.22, 0.20);
				asp_b = vec3(0.46, 0.34, 0.30);
			} else if (biome_type == 5) {
				// Dark urban tarmac avenue
				asp_a = vec3(0.14, 0.15, 0.16);
				asp_b = vec3(0.22, 0.23, 0.24);
			} else if (biome_type == 6) {
				// Weathered English country lane tarmac
				asp_a = vec3(0.20, 0.21, 0.19);
				asp_b = vec3(0.30, 0.30, 0.27);
			} else if (biome_type == 7) {
				// Muddy packed-earth forest logging track
				asp_a = vec3(0.24, 0.18, 0.12);
				asp_b = vec3(0.35, 0.27, 0.18);
			} else if (biome_type == 8) {
				// Corrugated red-dirt Australian outback track!
				asp_a = vec3(0.46, 0.20, 0.11);
				asp_b = vec3(0.60, 0.28, 0.15);
			} else if (biome_type == 9) {
				// Sun-bleached tropical coral-concrete causeway
				asp_a = vec3(0.34, 0.33, 0.29);
				asp_b = vec3(0.48, 0.45, 0.38);
			} else if (biome_type == 10) {
				// Reinforced charcoal blast-plate volcanic highway
				asp_a = vec3(0.13, 0.13, 0.14);
				asp_b = vec3(0.22, 0.20, 0.20);
			} else if (biome_type == 11) {
				// Damp peat-mud & timber-plank bayou road
				asp_a = vec3(0.20, 0.18, 0.13);
				asp_b = vec3(0.31, 0.28, 0.20);
			} else if (biome_type == 12) {
				// Rain-slick midnight carbon-fiber cyber-expressway
				asp_a = vec3(0.08, 0.09, 0.13);
				asp_b = vec3(0.15, 0.17, 0.23);
			} else if (biome_type == 13) {
				// Compacted silver lunar regolith rover highway
				asp_a = vec3(0.26, 0.27, 0.30);
				asp_b = vec3(0.38, 0.39, 0.42);
			} else if (biome_type == 14) {
				// Sintered Martian basalt-composite colony freightway
				asp_a = vec3(0.30, 0.20, 0.16);
				asp_b = vec3(0.44, 0.28, 0.21);
			} else if (biome_type == 15) {
				// Frost-plated cryogenic alloy research road
				asp_a = vec3(0.24, 0.32, 0.42);
				asp_b = vec3(0.38, 0.48, 0.60);
			} else if (biome_type == 16) {
				// Obsidian-violet Xenon Prime energy highway
				asp_a = vec3(0.14, 0.10, 0.24);
				asp_b = vec3(0.24, 0.16, 0.38);
			}
			vec3 asphalt = mix(asp_a, asp_b, wear);
			if (biome_type == 4) {
				asphalt *= mix(0.76, 1.18, smoothstep(0.16, 0.65, cobbles));
				float snow_dust = smoothstep(16.0, 30.0, d_road) * smoothstep(0.34, 0.72, fbm(wp * 0.055));
				asphalt = mix(asphalt, vec3(0.86, 0.91, 0.96), snow_dust * 0.74);
			} else {
				asphalt *= mix(0.84, 1.14, agg);
				asphalt = mix(asphalt, vec3(0.09, 0.10, 0.11), crack * 0.55);
			}

			if (biome_type == 1) {
				float sand_drift = smoothstep(16.0, 31.0, d_road) * smoothstep(0.36, 0.72, fbm(wp * 0.055));
				asphalt = mix(asphalt, vec3(0.56, 0.44, 0.28), sand_drift * 0.62);
			} else if (biome_type == 2) {
				// Wind-blown snowdrifts & frosty rime creeping over the edges of the winter highway
				float snow_drift = smoothstep(15.0, 30.5, d_road) * smoothstep(0.32, 0.70, fbm(wp * 0.052));
				asphalt = mix(asphalt, vec3(0.74, 0.80, 0.86), snow_drift * 0.72);
			} else if (biome_type == 14) {
				// Red Martian dust drifting across freightway edges
				float mars_drift = smoothstep(15.0, 30.5, d_road) * smoothstep(0.36, 0.72, fbm(wp * 0.055));
				asphalt = mix(asphalt, vec3(0.64, 0.30, 0.17), mars_drift * 0.58);
			}

			// Dual darkened tank/convoy tire ruts (extra wet-slush dark on tundra!)
			float rut = exp(-pow((abs(d_road - 13.5)) / 4.2, 2.0));
			asphalt *= mix(1.0, (biome_type == 2 || biome_type == 12) ? 0.62 : 0.72, rut * 0.82);

			float white_edge = exp(-pow((d_road - 25.5) / 1.15, 2.0));
			float paint_chip = smoothstep(0.28, 0.70, noise(wp * 0.25));
			if (biome_type == 12) {
				// Glowing electric cyan & neon magenta highway edge rails!
				vec3 neon_rail = mix(vec3(0.10, 0.95, 1.0), vec3(1.0, 0.16, 0.74), 0.5 + 0.5 * sin(wp.x * 0.015 + TIME * 2.0));
				asphalt += neon_rail * white_edge * 0.95;
			} else if (biome_type == 16) {
				// Glowing alien bioluminescent violet-cyan road guide rails!
				vec3 xeno_rail = mix(vec3(0.22, 0.98, 0.92), vec3(0.92, 0.24, 0.98), 0.5 + 0.5 * sin(wp.y * 0.02 - TIME * 2.4));
				asphalt += xeno_rail * white_edge * 0.88;
			} else if (biome_type == 10) {
				// Heat-warning amber hazard strips
				asphalt += vec3(1.0, 0.45, 0.08) * white_edge * paint_chip * 0.42;
			} else {
				asphalt = mix(asphalt, vec3(0.74, 0.74, 0.70), white_edge * paint_chip * 0.32);
			}

			float curb_ao = smoothstep(26.0, 31.0, r_dist) * 0.24;
			asphalt *= (1.0 - curb_ao);

			vec3 road_n = normalize(vec3((agg - 0.5) * 0.35, (agg - 0.5) * 0.35, 1.0));
			vec3 half_v = normalize(sun_dir + view_dir);
			float spec_gain = (biome_type == 12) ? (0.16 + rut * 0.24) : ((biome_type == 2 || biome_type == 15) ? (0.06 + rut * 0.14) : (0.04 + rut * 0.07));
			float road_spec = pow(max(dot(road_n, half_v), 0.0), 24.0) * spec_gain;
			vec3 road_lit = asphalt * mix(vec3(0.80, 0.84, 0.88), sun_tint * 0.94, ndotl) + vec3(road_spec);

			col = mix(col, road_lit, in_asphalt);
		}
	}

	// === PHOTOREALISTIC 3D RIVER / LAVA / CHASM / PLASMA ===
	float shore_warp = (biome_type == 5 || biome_type == 12) ? 0.0 : ((fbm(wp * 0.032) - 0.5) * 16.0 + (noise(wp * 0.12) - 0.5) * 4.5);
	float river_r = d_river + shore_warp;
	float water_edge = (biome_type == 9) ? 50.0 : 41.0;

	float wet_rim = (1.0 - smoothstep(water_edge - 1.0, water_edge + 14.0, river_r)) * smoothstep(water_edge - 3.0, water_edge + 2.0, river_r);
	if (wet_rim > 0.001 && !over_bridge_span) {
		float wet_cob = smoothstep(0.15, 0.65, cobbles);
		vec3 wet_a = vec3(0.10, 0.10, 0.08);
		vec3 wet_b = vec3(0.22, 0.21, 0.18);
		if (biome_type == 1) {
			wet_a = vec3(0.22, 0.15, 0.10);
			wet_b = vec3(0.36, 0.26, 0.17);
		} else if (biome_type == 2) {
			wet_a = vec3(0.18, 0.23, 0.28);
			wet_b = vec3(0.58, 0.68, 0.76);
		}
		vec3 wet_bank = mix(wet_a, wet_b, wet_cob) * sun_lit;
		vec3 half_w = normalize(sun_dir + view_dir);
		float damp_spec = pow(max(dot(normal, half_w), 0.0), 28.0) * 0.26 * wet_rim;
		col = mix(col, wet_bank + vec3(damp_spec), wet_rim * 0.85);
	}

	float in_water = 1.0 - smoothstep(water_edge - 2.4, water_edge + 1.2, river_r);
	if (in_water > 0.001) {
		float depth = clamp((water_edge - river_r) / 34.0, 0.0, 1.0);
		float depth_smooth = smoothstep(0.0, 1.0, depth);

		float wh = water_wave_height(wp, TIME);
		float whx = water_wave_height(wp + vec2(1.8, 0.0), TIME);
		float why = water_wave_height(wp + vec2(0.0, 1.8), TIME);
		vec3 water_n = normalize(vec3((wh - whx) * 4.6, (wh - why) * 4.6, 1.0));

		vec2 refracted_wp = wp + water_n.xy * (8.0 + depth_smooth * 14.0);
		float bed_stones = cobble_cells(refracted_wp * 0.15);
		float bed_grit = fbm(refracted_wp * 0.06);

		vec3 bed_a = vec3(0.16, 0.15, 0.11);
		vec3 bed_b = vec3(0.32, 0.29, 0.22);
		vec3 caust_col = vec3(0.42, 0.56, 0.48);
		vec3 abs_coeff = vec3(3.1, 1.55, 1.15);
		vec3 deep_water = vec3(0.035, 0.105, 0.145);
		vec3 mid_col = vec3(0.07, 0.21, 0.23);
		vec3 sky_a = vec3(0.24, 0.36, 0.44);
		vec3 sky_b = vec3(0.58, 0.64, 0.66);

		if (biome_type == 1) {
			bed_a = vec3(0.32, 0.24, 0.14);
			bed_b = vec3(0.52, 0.40, 0.24);
			caust_col = vec3(0.62, 0.72, 0.56);
			abs_coeff = vec3(2.8, 1.15, 0.95);
			deep_water = vec3(0.03, 0.16, 0.20);
			mid_col = vec3(0.06, 0.30, 0.30);
			sky_a = vec3(0.32, 0.48, 0.54);
			sky_b = vec3(0.72, 0.70, 0.62);
		} else if (biome_type == 2) {
			bed_a = vec3(0.10, 0.15, 0.20);
			bed_b = vec3(0.28, 0.36, 0.44);
			caust_col = vec3(0.52, 0.78, 0.92);
			abs_coeff = vec3(3.4, 1.50, 0.92);
			deep_water = vec3(0.02, 0.075, 0.145);
			mid_col = vec3(0.07, 0.24, 0.34);
			sky_a = vec3(0.36, 0.50, 0.64);
			sky_b = vec3(0.76, 0.84, 0.90);
		} else if (biome_type == 3) {
			// Crisp glacial-snowmelt alpine rapids cutting through the granite gorge
			bed_a = vec3(0.14, 0.16, 0.18);
			bed_b = vec3(0.34, 0.36, 0.38);
			caust_col = vec3(0.50, 0.76, 0.78);
			abs_coeff = vec3(3.0, 1.35, 1.02);
			deep_water = vec3(0.025, 0.115, 0.165);
			mid_col = vec3(0.07, 0.28, 0.32);
			sky_a = vec3(0.30, 0.44, 0.56);
			sky_b = vec3(0.74, 0.78, 0.82);
		} else if (biome_type == 4) {
			// Enchanted Aurora Borealis Ice Canal!
			bed_a = vec3(0.10, 0.18, 0.30);
			bed_b = vec3(0.30, 0.52, 0.64);
			caust_col = vec3(0.38, 0.92, 0.76);
			abs_coeff = vec3(3.2, 1.35, 0.85);
			deep_water = vec3(0.03, 0.08, 0.22);
			mid_col = vec3(0.10, 0.44, 0.48);
			sky_a = vec3(0.18, 0.56, 0.54);
			sky_b = vec3(0.68, 0.44, 0.86);
		} else if (biome_type == 5) {
			// Industrial urban canal water
			bed_a = vec3(0.08, 0.11, 0.12);
			bed_b = vec3(0.18, 0.21, 0.22);
			caust_col = vec3(0.28, 0.42, 0.46);
			abs_coeff = vec3(3.6, 2.0, 1.5);
			deep_water = vec3(0.04, 0.09, 0.12);
			mid_col = vec3(0.08, 0.18, 0.20);
			sky_a = vec3(0.30, 0.38, 0.44);
			sky_b = vec3(0.60, 0.64, 0.66);
		} else if (biome_type == 6) {
			// Sparkling clear English chalk stream!
			bed_a = vec3(0.24, 0.23, 0.16);
			bed_b = vec3(0.46, 0.44, 0.32);
			caust_col = vec3(0.60, 0.74, 0.52);
			abs_coeff = vec3(2.6, 1.25, 0.98);
			deep_water = vec3(0.04, 0.15, 0.18);
			mid_col = vec3(0.10, 0.28, 0.28);
			sky_a = vec3(0.34, 0.52, 0.64);
			sky_b = vec3(0.78, 0.82, 0.84);
		} else if (biome_type == 7) {
			// Deep mossy emerald woodland creek
			bed_a = vec3(0.10, 0.14, 0.08);
			bed_b = vec3(0.24, 0.28, 0.18);
			caust_col = vec3(0.38, 0.56, 0.34);
			abs_coeff = vec3(3.4, 1.70, 1.45);
			deep_water = vec3(0.03, 0.09, 0.08);
			mid_col = vec3(0.06, 0.20, 0.16);
			sky_a = vec3(0.20, 0.34, 0.30);
			sky_b = vec3(0.52, 0.60, 0.52);
		} else if (biome_type == 8) {
			// Outback Billabong creek — warm ochre-muddy banks & teal waterhole!
			bed_a = vec3(0.34, 0.18, 0.10);
			bed_b = vec3(0.54, 0.32, 0.18);
			caust_col = vec3(0.66, 0.58, 0.36);
			abs_coeff = vec3(2.4, 1.45, 1.35);
			deep_water = vec3(0.08, 0.16, 0.16);
			mid_col = vec3(0.18, 0.28, 0.22);
			sky_a = vec3(0.38, 0.50, 0.56);
			sky_b = vec3(0.78, 0.68, 0.56);
		} else if (biome_type == 9) {
			// Pacific Coral Atoll — dazzling tropical turquoise reef water & bright white coral sandbed!
			bed_a = vec3(0.58, 0.52, 0.38);
			bed_b = vec3(0.84, 0.78, 0.62);
			caust_col = vec3(0.55, 0.96, 0.94);
			abs_coeff = vec3(3.2, 0.85, 0.72);
			deep_water = vec3(0.02, 0.28, 0.42);
			mid_col = vec3(0.06, 0.66, 0.68);
			sky_a = vec3(0.34, 0.74, 0.88);
			sky_b = vec3(0.82, 0.92, 0.96);
		} else if (biome_type == 11) {
			// Cypress Bayou — murky emerald-brown swamp water with duckweed highlights!
			bed_a = vec3(0.09, 0.12, 0.06);
			bed_b = vec3(0.18, 0.22, 0.11);
			caust_col = vec3(0.34, 0.48, 0.22);
			abs_coeff = vec3(3.8, 2.2, 2.6);
			deep_water = vec3(0.04, 0.09, 0.06);
			mid_col = vec3(0.10, 0.20, 0.11);
			sky_a = vec3(0.20, 0.32, 0.28);
			sky_b = vec3(0.46, 0.54, 0.44);
		} else if (biome_type == 12) {
			// Neo-Tokyo 2099 — dark cyber-canal reflecting pulsing neon magenta & electric cyan!
			bed_a = vec3(0.04, 0.05, 0.10);
			bed_b = vec3(0.10, 0.14, 0.24);
			caust_col = vec3(0.14, 0.86, 1.0);
			abs_coeff = vec3(3.8, 1.8, 1.2);
			deep_water = vec3(0.03, 0.04, 0.10);
			mid_col = vec3(0.10, 0.24, 0.36);
			sky_a = vec3(0.76, 0.14, 0.62);
			sky_b = vec3(0.12, 0.86, 0.98);
		} else if (biome_type == 15) {
			// Europa Abyssal Fissure — glowing bioluminescent sub-surface cyan ocean beneath cracked ice!
			bed_a = vec3(0.04, 0.24, 0.40);
			bed_b = vec3(0.12, 0.64, 0.84);
			caust_col = vec3(0.38, 0.98, 1.0);
			abs_coeff = vec3(3.8, 1.15, 0.72);
			deep_water = vec3(0.02, 0.14, 0.34);
			mid_col = vec3(0.08, 0.58, 0.82);
			sky_a = vec3(0.22, 0.68, 0.92);
			sky_b = vec3(0.76, 0.94, 1.0);
		}

		vec3 water_col = vec3(0.0);
		float bridge_shadow = max(max(bridge_shadow_mask(wp, bridge_1), bridge_shadow_mask(wp, bridge_2)), bridge_shadow_mask(wp, bridge_3));

		if (biome_type == 10) {
			// VOLCANIC MOLTEN LAVA RIVER: Churning incandescent magma with dark cooling basalt crust plates!
			vec2 l_uv = vec2(wp.x * 0.045, wp.y * 0.030 - TIME * 0.55);
			float lava_flow = fbm(l_uv + vec2(fbm(l_uv * 1.8) * 1.6, -TIME * 0.22));
			float crust = smoothstep(0.54, 0.76, lava_flow) * (0.45 + 0.55 * (1.0 - depth_smooth));
			vec3 hot_core = vec3(1.0, 0.92, 0.38);
			vec3 bright_magma = vec3(1.0, 0.42, 0.05);
			vec3 deep_red = vec3(0.58, 0.09, 0.02);
			vec3 cooled_crust = vec3(0.11, 0.09, 0.10);
			water_col = mix(deep_red, bright_magma, smoothstep(0.20, 0.62, lava_flow + depth_smooth * 0.28));
			water_col = mix(water_col, hot_core, smoothstep(0.68, 0.92, lava_flow + depth_smooth * 0.32));
			water_col = mix(water_col, cooled_crust, crust * 0.86);
			water_col *= (1.0 - bridge_shadow * 0.50);
		} else if (biome_type == 13) {
			// LUNAR RILLE CHASM: Bottomless pitch-black airless canyon glittering with distant stars!
			float wall = 1.0 - smoothstep(0.0, 0.45, depth_smooth);
			vec3 chasm_wall = vec3(0.22, 0.23, 0.25) * mix(0.6, 1.2, cobbles) * smoothstep(-0.3, 0.5, river_side);
			vec3 void_col = vec3(0.015, 0.018, 0.030);
			float star = smoothstep(0.972, 0.996, noise(wp * 0.55));
			float twinkle = 0.65 + 0.35 * sin(TIME * 3.2 + wp.x * 0.3 + wp.y * 0.2);
			void_col += vec3(0.85, 0.92, 1.0) * star * twinkle * smoothstep(0.35, 0.75, depth_smooth);
			water_col = mix(void_col, chasm_wall, wall * 0.85) * (1.0 - bridge_shadow * 0.70);
		} else if (biome_type == 14) {
			// MARS CANYON CHASM: Deep vermilion-shadowed gorge with sparkling CO2 dry-ice frost floor!
			float strata_c = 0.5 + 0.5 * sin(depth_smooth * 24.0 + fbm(wp * 0.04) * 3.0);
			vec3 canyon_deep = vec3(0.14, 0.05, 0.04);
			vec3 canyon_wall = mix(vec3(0.32, 0.12, 0.08), vec3(0.54, 0.24, 0.14), strata_c);
			water_col = mix(canyon_wall, canyon_deep, smoothstep(0.05, 0.78, depth_smooth));
			float dry_ice = smoothstep(0.58, 0.84, fbm(wp * 0.06)) * smoothstep(0.55, 0.95, depth_smooth);
			water_col = mix(water_col, vec3(0.84, 0.78, 0.76), dry_ice * 0.55);
			float west_sh = smoothstep(0.10, -0.50, river_side) * smoothstep(8.0, 38.0, river_r);
			water_col *= (1.0 - west_sh * 0.58) * (1.0 - bridge_shadow * 0.65);
		} else if (biome_type == 16) {
			// XENON PRIME IRIDESCENT PLASMA RIVER: Swirling neon magenta, violet & electric cyan energy!
			vec2 p_uv = vec2(wp.x * 0.05, wp.y * 0.036 - TIME * 0.95);
			float sw1 = fbm(p_uv + vec2(sin(wp.y * 0.03 - TIME) * 0.6, 0.0));
			float sw2 = fbm(p_uv * 1.9 - vec2(TIME * 0.35, TIME * 0.65));
			vec3 deep_p = vec3(0.14, 0.04, 0.30);
			vec3 mag_p = vec3(0.88, 0.18, 0.86);
			vec3 cyan_p = vec3(0.18, 0.96, 0.98);
			water_col = mix(deep_p, mag_p, smoothstep(0.25, 0.72, sw1));
			water_col = mix(water_col, cyan_p, smoothstep(0.56, 0.88, sw2) * (0.45 + 0.55 * depth_smooth));
			water_col += vec3(0.42, 0.95, 1.0) * smoothstep(0.78, 0.95, sw1 * sw2 * 2.1) * 0.65;
			water_col *= (1.0 - bridge_shadow * 0.55);
		} else {
			vec3 riverbed = mix(bed_a, bed_b, smoothstep(0.18, 0.68, bed_stones)) * mix(0.75, 1.15, bed_grit);
			if (biome_type == 9) {
				// Colorful submerged coral reef heads glowing beneath the crystal-clear turquoise lagoon!
				float coral_n = fbm(refracted_wp * 0.048 + vec2(5.2, -3.7));
				float coral_patch = smoothstep(0.56, 0.76, coral_n) * smoothstep(0.12, 0.55, depth_smooth) * smoothstep(0.16, 0.58, bed_stones);
				vec3 c_pink = vec3(0.95, 0.36, 0.46);
				vec3 c_gold = vec3(0.92, 0.66, 0.22);
				vec3 c_plum = vec3(0.66, 0.30, 0.70);
				float c_sel = noise(refracted_wp * 0.025);
				vec3 coral_col = mix(c_pink, mix(c_gold, c_plum, smoothstep(0.55, 0.85, c_sel)), smoothstep(0.25, 0.65, c_sel));
				riverbed = mix(riverbed, coral_col, coral_patch * 0.78);
			}
			float caust = caustics(refracted_wp * 0.055, TIME);
			riverbed += caust_col * caust * (1.0 - depth_smooth * 0.60) * ((biome_type == 9 || biome_type == 15) ? 0.95 : 0.72);

			vec3 absorption = exp(-depth_smooth * abs_coeff);
			vec3 mid_scatter = mid_col * (0.55 + 0.45 * wh);
			vec3 water_body = mix(deep_water, riverbed * absorption + mid_scatter * 0.38, clamp(absorption.b * 0.92, 0.18, 1.0));

			float fresnel = 0.06 + 0.58 * pow(1.0 - clamp(water_n.z, 0.0, 1.0), 2.4);
			float sky_cloud = fbm(wp * 0.004 + water_n.xy * 0.45 + vec2(TIME * 0.015, TIME * 0.008));
			vec3 sky_refl = mix(sky_a, sky_b, smoothstep(0.42, 0.78, sky_cloud));
			water_col = mix(water_body, sky_refl, fresnel * (0.45 + depth_smooth * 0.55));

			if (biome_type == 12) {
				// Shimmering horizontal neon skyline reflections on Neo-Tokyo canal!
				float neon_band = sin(wp.y * 0.065 + water_n.x * 5.0 + TIME * 1.4);
				vec3 nc = mix(vec3(0.95, 0.14, 0.68), vec3(0.08, 0.92, 1.0), 0.5 + 0.5 * neon_band);
				water_col += nc * smoothstep(0.45, 0.95, abs(neon_band)) * 0.24;
			} else if (biome_type == 11) {
				// Floating lime-green duckweed mats along calm bayou edges!
				float dw = smoothstep(0.62, 0.82, fbm(wp * 0.055)) * smoothstep(water_edge - 22.0, water_edge - 3.0, river_r);
				water_col = mix(water_col, vec3(0.28, 0.46, 0.16), dw * 0.72);
			}

			vec3 half_vec = normalize(sun_dir + view_dir);
			float spec_sharp = pow(max(dot(water_n, half_vec), 0.0), 96.0);
			float spec_broad = pow(max(dot(water_n, half_vec), 0.0), 18.0);
			water_col += vec3(1.0, 0.97, 0.90) * spec_sharp * ((biome_type == 1 || biome_type == 9) ? 1.15 : 0.98);
			water_col += vec3(0.55, 0.76, 0.84) * spec_broad * 0.22;

			// Steep western canyon wall casts shadow onto western river edge
			float west_shadow = smoothstep(0.08, -0.55, river_side) * smoothstep(10.0, 40.0, river_r);
			float bank_ao = 1.0 - smoothstep(water_edge - 9.0, water_edge + 1.0, river_r) * 0.30;
			water_col *= (1.0 - west_shadow * 0.52) * bank_ao;

			// Dual-bridge cast shadows onto the flowing water
			water_col *= (1.0 - bridge_shadow * 0.62);

			// Organic shoreline foam (plus jagged glacial shelf-ice on tundra/Europa & extra mountain rapids!)
			float foam_wave = fbm(vec2(wp.x * 0.14, wp.y * 0.11 - TIME * 1.45));
			float shore_foam = smoothstep(water_edge - 9.5, water_edge - 1.0, river_r) * smoothstep(0.44, 0.74, foam_wave);
			water_col = mix(water_col, vec3(0.84, 0.90, 0.94), shore_foam * ((biome_type == 3 || biome_type == 9) ? 0.68 : 0.54));

			if (biome_type == 3) {
				float rapids = smoothstep(0.58, 0.84, fbm(vec2(wp.x * 0.16, wp.y * 0.08 - TIME * 2.5)));
				water_col = mix(water_col, vec3(0.86, 0.92, 0.94), rapids * 0.34 * (1.0 - bridge_shadow * 0.75));
			}

			if (biome_type == 2 || biome_type == 4 || biome_type == 15) {
				float ice_n = fbm(wp * 0.075);
				float shelf_ice = smoothstep(water_edge - 13.0 + ice_n * 8.0, water_edge - 2.5, river_r) * (1.0 - bridge_shadow * 0.7);
				vec3 ice_col = mix(vec3(0.62, 0.78, 0.88), vec3(0.88, 0.94, 0.98), cobbles) * sun_lit;
				water_col = mix(water_col, ice_col, shelf_ice * 0.82);
			}

			// Turbulent whitewater wakes behind bridges' piers
			float wake_foam = max(max(bridge_pier_wake(wp, bridge_1, TIME), bridge_pier_wake(wp, bridge_2, TIME)), bridge_pier_wake(wp, bridge_3, TIME));
			water_col = mix(water_col, vec3(0.88, 0.94, 0.96), wake_foam * 0.72);

			float flow_streak = smoothstep(0.68, 0.88, fbm(vec2(wp.x * 0.18, wp.y * 0.035 - TIME * 1.65)));
			water_col += vec3(0.36, 0.54, 0.62) * flow_streak * depth_smooth * 0.20 * (1.0 - bridge_shadow * 0.8);
		}

		col = mix(col, water_col, in_water);
	}

	// === OUTER DEEP PACIFIC OCEAN + FOAMING REEF BREAKERS FOR CORAL ATOLL (biome_type == 9) ===
	if (biome_type == 9) {
		float o_warp = (fbm(wp * 0.018) - 0.5) * 0.095;
		float atoll_e = length((wp - vec2(800.0, 480.0)) / vec2(745.0, 442.0)) + o_warp;
		// Keep dry coral sand spits around roads and turret pads!
		float land_keep = max(1.0 - smoothstep(38.0, 62.0, d_road), 1.0 - smoothstep(34.0, 56.0, d_pad));
		float ocean_depth = clamp((atoll_e - 0.96) / 0.28, 0.0, 1.0) * (1.0 - land_keep);
		float in_ocean = smoothstep(0.01, 0.14, ocean_depth);
		if (in_ocean > 0.001) {
			float o_wh = water_wave_height(wp * 0.75, TIME * 0.85);
			float o_whx = water_wave_height((wp + vec2(2.0, 0.0)) * 0.75, TIME * 0.85);
			float o_why = water_wave_height((wp + vec2(0.0, 2.0)) * 0.75, TIME * 0.85);
			vec3 o_n = normalize(vec3((o_wh - o_whx) * 4.2, (o_wh - o_why) * 4.2, 1.0));
			vec3 shallow_reef = vec3(0.08, 0.64, 0.70);
			vec3 deep_pacific = vec3(0.02, 0.16, 0.38);
			vec3 o_col = mix(shallow_reef, deep_pacific, smoothstep(0.08, 0.72, ocean_depth));
			float o_caust = caustics(wp * 0.045, TIME);
			o_col += vec3(0.32, 0.86, 0.90) * o_caust * (1.0 - ocean_depth) * 0.42;
			vec3 half_o = normalize(sun_dir + view_dir);
			float o_spec = pow(max(dot(o_n, half_o), 0.0), 72.0);
			o_col += vec3(1.0, 0.98, 0.92) * o_spec * 0.85;
			// Animated foaming white Pacific surf waves breaking against the outer coral reef!
			float surf_band = sin(ocean_depth * 24.0 - TIME * 2.4 + fbm(wp * 0.04) * 3.0);
			float breaker = smoothstep(0.55, 0.95, surf_band) * smoothstep(0.02, 0.14, ocean_depth) * (1.0 - smoothstep(0.18, 0.46, ocean_depth));
			float shore_line = (1.0 - smoothstep(0.02, 0.12, ocean_depth)) * smoothstep(0.38, 0.72, fbm(wp * 0.09 - vec2(0.0, TIME * 0.8)));
			o_col = mix(o_col, vec3(0.92, 0.96, 0.98), clamp(breaker * 0.82 + shore_line * 0.65, 0.0, 1.0));
			col = mix(col, o_col, in_ocean);
		}
	}

	// Drifting soft cloud shadows (none on airless Moon / Europa!)
	vec2 cloud_uv = wp * 0.0013 + vec2(TIME * 0.014, TIME * 0.007);
	float cloud = smoothstep(0.50, 0.80, fbm(cloud_uv));
	float cloud_str = (biome_type == 13 || biome_type == 15) ? 0.0 : ((biome_type == 1 || biome_type == 14) ? 0.36 : ((biome_type == 2 || biome_type == 10) ? 0.42 : 0.60));
	col *= mix(1.0, 0.80, cloud * cloud_str);

	// Soft battlefield edge vignette
	vec2 edge = min(UV, 1.0 - UV);
	float vig = smoothstep(0.0, 0.08, min(edge.x, edge.y));
	col *= mix(0.72, 1.0, vig);

	COLOR = vec4(col, 1.0);
}
