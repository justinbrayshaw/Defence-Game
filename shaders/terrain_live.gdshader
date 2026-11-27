shader_type canvas_item;

uniform sampler2D baked_terrain : filter_linear, repeat_disable;
uniform sampler2D map_mask : filter_linear, repeat_disable;
uniform vec2 map_size = vec2(1600.0, 960.0);
uniform vec4 bridge_1 = vec4(-9999.0, -9999.0, 1.0, 0.0);
uniform vec4 bridge_2 = vec4(-9999.0, -9999.0, 1.0, 0.0);
uniform vec4 bridge_3 = vec4(-9999.0, -9999.0, 1.0, 0.0);
uniform int biome_type = 0;

float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
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

float fbm2(vec2 p) {
	mat2 rot = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	float v = 0.62 * noise(p);
	p = rot * p * 2.03 + vec2(19.3, 37.1);
	v += 0.38 * noise(p);
	return v;
}

float fbm3(vec2 p) {
	float v = 0.0;
	float amp = 0.52;
	mat2 rot = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	for (int i = 0; i < 3; i++) {
		v += amp * noise(p);
		p = rot * p * 2.03 + vec2(19.3, 37.1);
		amp *= 0.5;
	}
	return v;
}

// Matches terrain_bake's exact 5-octave shore_warp ONLY near shoreline pixels so water aligns sub-pixel with baked wet_rim
float fbm5(vec2 p) {
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
	return fbm2(flow1) * 0.65 + noise(flow2) * 0.35;
}

vec2 bridge_local(vec2 wp, vec4 b) {
	vec2 rel = wp - b.xy;
	vec2 dir = b.zw;
	vec2 perp = vec2(-dir.y, dir.x);
	return vec2(dot(rel, dir), dot(rel, perp));
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
	float turb = smoothstep(0.36, 0.72, fbm2(vec2(wp.x * 0.16, wp.y * 0.12 - t * 3.4)));
	return clamp(p1 + p2, 0.0, 1.0) * wake_fade * turb;
}

void fragment() {
	vec2 wp = UV * map_size;
	vec3 col = texture(baked_terrain, UV).rgb;
	vec4 m = texture(map_mask, UV);

	float d_road = m.r * 128.0;
	float d_river = m.g * 140.0;
	float river_side = (m.a - 0.5) * 2.0;

	vec3 sun_dir = normalize(vec3(-0.68, -0.58, 0.66));
	vec3 view_dir = vec3(0.0, 0.0, 1.0);
	vec3 half_vec = normalize(sun_dir + view_dir);

	// === BIOME-SPECIFIC LIGHTWEIGHT LAND ANIMATIONS ===
	if (biome_type == 4) {
		// North Pole: drifting Northern Lights Aurora Borealis + glistening diamond snow sparkles
		float a_wave1 = sin(wp.x * 0.0045 + wp.y * 0.0025 + TIME * 0.45 + fbm2(wp * 0.003) * 3.5);
		float a_wave2 = sin(wp.x * 0.0032 - wp.y * 0.0042 - TIME * 0.32 + fbm2(wp * 0.004) * 3.0);
		float aurora_green = smoothstep(0.35, 0.95, a_wave1) * 0.12;
		float aurora_violet = smoothstep(0.45, 0.98, a_wave2) * 0.09;
		col += vec3(0.08, 0.55, 0.42) * aurora_green + vec3(0.46, 0.16, 0.62) * aurora_violet;
		float sparkle = smoothstep(0.91, 0.99, noise(wp * 0.88 + vec2(sin(TIME * 0.6) * 0.05, 0.0)));
		col += vec3(0.38, 0.45, 0.54) * sparkle * step(42.0, d_river);
	} else if (biome_type == 10) {
		// Volcanic: zero-noise pulse on baked glowing magma fissures
		float hot = clamp((col.r - col.b * 2.2) * 1.4, 0.0, 1.0);
		if (hot > 0.01) {
			float pulse_v = 0.78 + 0.22 * sin(TIME * 2.6 + wp.x * 0.02 + wp.y * 0.015);
			col *= mix(1.0, pulse_v, hot);
		}
	} else if (biome_type == 11) {
		// Cypress Bayou: drifting pale twilight swamp fog wisps
		float mist = smoothstep(0.45, 0.85, fbm2(wp * 0.0045 + vec2(TIME * 0.025, -TIME * 0.012)));
		col = mix(col, vec3(0.24, 0.34, 0.32), mist * 0.24);
	} else if (biome_type == 12) {
		// Neo-Tokyo: animated neon highway edge rails (only evaluated on road edges)
		if (d_road > 21.0 && d_road < 31.0) {
			bool over_b = is_over_bridge(wp, bridge_1) || is_over_bridge(wp, bridge_2) || is_over_bridge(wp, bridge_3);
			if (!over_b) {
				float white_edge = exp(-pow((d_road - 25.5) / 1.15, 2.0));
				vec3 neon_rail = mix(vec3(0.10, 0.95, 1.0), vec3(1.0, 0.16, 0.74), 0.5 + 0.5 * sin(wp.x * 0.015 + TIME * 2.0));
				col += neon_rail * white_edge * 0.95;
			}
		}
	} else if (biome_type == 16) {
		// Xenon Prime: zero-noise bioluminescent pulse + animated road guide rails
		float bio = clamp((max(col.r, col.g) - 0.34) * 2.0, 0.0, 1.0);
		if (bio > 0.01) {
			float p_vein = 0.76 + 0.24 * sin(TIME * 2.2 + wp.x * 0.015);
			col *= mix(1.0, p_vein, bio);
		}
		if (d_road > 21.0 && d_road < 31.0) {
			bool over_b = is_over_bridge(wp, bridge_1) || is_over_bridge(wp, bridge_2) || is_over_bridge(wp, bridge_3);
			if (!over_b) {
				float white_edge = exp(-pow((d_road - 25.5) / 1.15, 2.0));
				vec3 xeno_rail = mix(vec3(0.22, 0.98, 0.92), vec3(0.92, 0.24, 0.98), 0.5 + 0.5 * sin(wp.y * 0.02 - TIME * 2.4));
				col += xeno_rail * white_edge * 0.88;
			}
		}
	}

	// === ANIMATED WATER / LAVA / PLASMA / LUNAR STARS (EARLY-OUT FOR ALL DRY LAND!) ===
	float water_edge = (biome_type == 9) ? 50.0 : 41.0;
	if (biome_type != 14 && d_river < water_edge + 13.0) {
		float shore_warp = (biome_type == 5 || biome_type == 12) ? 0.0 : ((fbm5(wp * 0.032) - 0.5) * 16.0 + (noise(wp * 0.12) - 0.5) * 4.5);
		float river_r = d_river + shore_warp;
		float in_water = 1.0 - smoothstep(water_edge - 2.4, water_edge + 1.2, river_r);

		if (in_water > 0.001) {
			float depth = clamp((water_edge - river_r) / 34.0, 0.0, 1.0);
			float depth_smooth = smoothstep(0.0, 1.0, depth);
			float bridge_shadow = max(max(bridge_shadow_mask(wp, bridge_1), bridge_shadow_mask(wp, bridge_2)), bridge_shadow_mask(wp, bridge_3));

			if (biome_type == 13) {
				// Moon: chasm walls are already baked — only layer twinkling stars in the pitch void
				float star = smoothstep(0.972, 0.996, noise(wp * 0.55));
				float twinkle = 0.65 + 0.35 * sin(TIME * 3.2 + wp.x * 0.3 + wp.y * 0.2);
				col += vec3(0.85, 0.92, 1.0) * star * twinkle * smoothstep(0.35, 0.75, depth_smooth) * (1.0 - bridge_shadow * 0.70) * in_water;
			} else if (biome_type == 10) {
				// Volcanic molten lava river
				vec2 l_uv = vec2(wp.x * 0.045, wp.y * 0.030 - TIME * 0.55);
				float lava_flow = fbm3(l_uv + vec2(fbm2(l_uv * 1.8) * 1.6, -TIME * 0.22));
				float crust = smoothstep(0.54, 0.76, lava_flow) * (0.45 + 0.55 * (1.0 - depth_smooth));
				vec3 hot_core = vec3(1.0, 0.92, 0.38);
				vec3 bright_magma = vec3(1.0, 0.42, 0.05);
				vec3 deep_red = vec3(0.58, 0.09, 0.02);
				vec3 cooled_crust = vec3(0.11, 0.09, 0.10);
				vec3 water_col = mix(deep_red, bright_magma, smoothstep(0.20, 0.62, lava_flow + depth_smooth * 0.28));
				water_col = mix(water_col, hot_core, smoothstep(0.68, 0.92, lava_flow + depth_smooth * 0.32));
				water_col = mix(water_col, cooled_crust, crust * 0.86);
				water_col *= (1.0 - bridge_shadow * 0.50);
				col = mix(col, water_col, in_water);
			} else if (biome_type == 16) {
				// Xenon Prime iridescent plasma river
				vec2 p_uv = vec2(wp.x * 0.05, wp.y * 0.036 - TIME * 0.95);
				float sw1 = fbm3(p_uv + vec2(sin(wp.y * 0.03 - TIME) * 0.6, 0.0));
				float sw2 = fbm2(p_uv * 1.9 - vec2(TIME * 0.35, TIME * 0.65));
				vec3 deep_p = vec3(0.14, 0.04, 0.30);
				vec3 mag_p = vec3(0.88, 0.18, 0.86);
				vec3 cyan_p = vec3(0.18, 0.96, 0.98);
				vec3 water_col = mix(deep_p, mag_p, smoothstep(0.25, 0.72, sw1));
				water_col = mix(water_col, cyan_p, smoothstep(0.56, 0.88, sw2) * (0.45 + 0.55 * depth_smooth));
				water_col += vec3(0.42, 0.95, 1.0) * smoothstep(0.78, 0.95, sw1 * sw2 * 2.1) * 0.65;
				water_col *= (1.0 - bridge_shadow * 0.55);
				col = mix(col, water_col, in_water);
			} else {
				float wh = water_wave_height(wp, TIME);
				float whx = water_wave_height(wp + vec2(1.8, 0.0), TIME);
				float why = water_wave_height(wp + vec2(0.0, 1.8), TIME);
				vec3 water_n = normalize(vec3((wh - whx) * 4.6, (wh - why) * 4.6, 1.0));

				vec2 refracted_wp = wp + water_n.xy * (8.0 + depth_smooth * 14.0);
				float bed_stones = noise(refracted_wp * 0.18) * 0.65 + noise(refracted_wp * 0.36) * 0.35;
				float bed_grit = fbm2(refracted_wp * 0.06);

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
					bed_a = vec3(0.14, 0.16, 0.18);
					bed_b = vec3(0.34, 0.36, 0.38);
					caust_col = vec3(0.50, 0.76, 0.78);
					abs_coeff = vec3(3.0, 1.35, 1.02);
					deep_water = vec3(0.025, 0.115, 0.165);
					mid_col = vec3(0.07, 0.28, 0.32);
					sky_a = vec3(0.30, 0.44, 0.56);
					sky_b = vec3(0.74, 0.78, 0.82);
				} else if (biome_type == 4) {
					bed_a = vec3(0.10, 0.18, 0.30);
					bed_b = vec3(0.30, 0.52, 0.64);
					caust_col = vec3(0.38, 0.92, 0.76);
					abs_coeff = vec3(3.2, 1.35, 0.85);
					deep_water = vec3(0.03, 0.08, 0.22);
					mid_col = vec3(0.10, 0.44, 0.48);
					sky_a = vec3(0.18, 0.56, 0.54);
					sky_b = vec3(0.68, 0.44, 0.86);
				} else if (biome_type == 5) {
					bed_a = vec3(0.08, 0.11, 0.12);
					bed_b = vec3(0.18, 0.21, 0.22);
					caust_col = vec3(0.28, 0.42, 0.46);
					abs_coeff = vec3(3.6, 2.0, 1.5);
					deep_water = vec3(0.04, 0.09, 0.12);
					mid_col = vec3(0.08, 0.18, 0.20);
					sky_a = vec3(0.30, 0.38, 0.44);
					sky_b = vec3(0.60, 0.64, 0.66);
				} else if (biome_type == 6) {
					bed_a = vec3(0.24, 0.23, 0.16);
					bed_b = vec3(0.46, 0.44, 0.32);
					caust_col = vec3(0.60, 0.74, 0.52);
					abs_coeff = vec3(2.6, 1.25, 0.98);
					deep_water = vec3(0.04, 0.15, 0.18);
					mid_col = vec3(0.10, 0.28, 0.28);
					sky_a = vec3(0.34, 0.52, 0.64);
					sky_b = vec3(0.78, 0.82, 0.84);
				} else if (biome_type == 7) {
					bed_a = vec3(0.10, 0.14, 0.08);
					bed_b = vec3(0.24, 0.28, 0.18);
					caust_col = vec3(0.38, 0.56, 0.34);
					abs_coeff = vec3(3.4, 1.70, 1.45);
					deep_water = vec3(0.03, 0.09, 0.08);
					mid_col = vec3(0.06, 0.20, 0.16);
					sky_a = vec3(0.20, 0.34, 0.30);
					sky_b = vec3(0.52, 0.60, 0.52);
				} else if (biome_type == 8) {
					bed_a = vec3(0.34, 0.18, 0.10);
					bed_b = vec3(0.54, 0.32, 0.18);
					caust_col = vec3(0.66, 0.58, 0.36);
					abs_coeff = vec3(2.4, 1.45, 1.35);
					deep_water = vec3(0.08, 0.16, 0.16);
					mid_col = vec3(0.18, 0.28, 0.22);
					sky_a = vec3(0.38, 0.50, 0.56);
					sky_b = vec3(0.78, 0.68, 0.56);
				} else if (biome_type == 9) {
					bed_a = vec3(0.58, 0.52, 0.38);
					bed_b = vec3(0.84, 0.78, 0.62);
					caust_col = vec3(0.55, 0.96, 0.94);
					abs_coeff = vec3(3.2, 0.85, 0.72);
					deep_water = vec3(0.02, 0.28, 0.42);
					mid_col = vec3(0.06, 0.66, 0.68);
					sky_a = vec3(0.34, 0.74, 0.88);
					sky_b = vec3(0.82, 0.92, 0.96);
				} else if (biome_type == 11) {
					bed_a = vec3(0.09, 0.12, 0.06);
					bed_b = vec3(0.18, 0.22, 0.11);
					caust_col = vec3(0.34, 0.48, 0.22);
					abs_coeff = vec3(3.8, 2.2, 2.6);
					deep_water = vec3(0.04, 0.09, 0.06);
					mid_col = vec3(0.10, 0.20, 0.11);
					sky_a = vec3(0.20, 0.32, 0.28);
					sky_b = vec3(0.46, 0.54, 0.44);
				} else if (biome_type == 12) {
					bed_a = vec3(0.04, 0.05, 0.10);
					bed_b = vec3(0.10, 0.14, 0.24);
					caust_col = vec3(0.14, 0.86, 1.0);
					abs_coeff = vec3(3.8, 1.8, 1.2);
					deep_water = vec3(0.03, 0.04, 0.10);
					mid_col = vec3(0.10, 0.24, 0.36);
					sky_a = vec3(0.76, 0.14, 0.62);
					sky_b = vec3(0.12, 0.86, 0.98);
				} else if (biome_type == 15) {
					bed_a = vec3(0.04, 0.24, 0.40);
					bed_b = vec3(0.12, 0.64, 0.84);
					caust_col = vec3(0.38, 0.98, 1.0);
					abs_coeff = vec3(3.8, 1.15, 0.72);
					deep_water = vec3(0.02, 0.14, 0.34);
					mid_col = vec3(0.08, 0.58, 0.82);
					sky_a = vec3(0.22, 0.68, 0.92);
					sky_b = vec3(0.76, 0.94, 1.0);
				}

				vec3 riverbed = mix(bed_a, bed_b, smoothstep(0.18, 0.68, bed_stones)) * mix(0.75, 1.15, bed_grit);
				if (biome_type == 9) {
					float coral_n = fbm2(refracted_wp * 0.048 + vec2(5.2, -3.7));
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
				float sky_cloud = fbm2(wp * 0.004 + water_n.xy * 0.45 + vec2(TIME * 0.015, TIME * 0.008));
				vec3 sky_refl = mix(sky_a, sky_b, smoothstep(0.42, 0.78, sky_cloud));
				vec3 water_col = mix(water_body, sky_refl, fresnel * (0.45 + depth_smooth * 0.55));

				if (biome_type == 12) {
					float neon_band = sin(wp.y * 0.065 + water_n.x * 5.0 + TIME * 1.4);
					vec3 nc = mix(vec3(0.95, 0.14, 0.68), vec3(0.08, 0.92, 1.0), 0.5 + 0.5 * neon_band);
					water_col += nc * smoothstep(0.45, 0.95, abs(neon_band)) * 0.24;
				} else if (biome_type == 11) {
					float dw = smoothstep(0.62, 0.82, fbm2(wp * 0.055)) * smoothstep(water_edge - 22.0, water_edge - 3.0, river_r);
					water_col = mix(water_col, vec3(0.28, 0.46, 0.16), dw * 0.72);
				}

				float spec_sharp = pow(max(dot(water_n, half_vec), 0.0), 96.0);
				float spec_broad = pow(max(dot(water_n, half_vec), 0.0), 18.0);
				water_col += vec3(1.0, 0.97, 0.90) * spec_sharp * ((biome_type == 1 || biome_type == 9) ? 1.15 : 0.98);
				water_col += vec3(0.55, 0.76, 0.84) * spec_broad * 0.22;

				float west_shadow = smoothstep(0.08, -0.55, river_side) * smoothstep(10.0, 40.0, river_r);
				float bank_ao = 1.0 - smoothstep(water_edge - 9.0, water_edge + 1.0, river_r) * 0.30;
				water_col *= (1.0 - west_shadow * 0.52) * bank_ao;
				water_col *= (1.0 - bridge_shadow * 0.62);

				float foam_wave = fbm2(vec2(wp.x * 0.14, wp.y * 0.11 - TIME * 1.45));
				float shore_foam = smoothstep(water_edge - 9.5, water_edge - 1.0, river_r) * smoothstep(0.44, 0.74, foam_wave);
				water_col = mix(water_col, vec3(0.84, 0.90, 0.94), shore_foam * ((biome_type == 3 || biome_type == 9) ? 0.68 : 0.54));

				if (biome_type == 3) {
					float rapids = smoothstep(0.58, 0.84, fbm2(vec2(wp.x * 0.16, wp.y * 0.08 - TIME * 2.5)));
					water_col = mix(water_col, vec3(0.86, 0.92, 0.94), rapids * 0.34 * (1.0 - bridge_shadow * 0.75));
				}

				if (biome_type == 2 || biome_type == 4 || biome_type == 15) {
					float ice_n = fbm2(wp * 0.075);
					float shelf_ice = smoothstep(water_edge - 13.0 + ice_n * 8.0, water_edge - 2.5, river_r) * (1.0 - bridge_shadow * 0.7);
					vec3 ice_col = mix(vec3(0.58, 0.74, 0.86), vec3(0.88, 0.94, 0.98), bed_stones);
					water_col = mix(water_col, ice_col, shelf_ice * 0.82);
				}

				float wake_foam = max(max(bridge_pier_wake(wp, bridge_1, TIME), bridge_pier_wake(wp, bridge_2, TIME)), bridge_pier_wake(wp, bridge_3, TIME));
				water_col = mix(water_col, vec3(0.88, 0.94, 0.96), wake_foam * 0.72);

				float flow_streak = smoothstep(0.68, 0.88, fbm2(vec2(wp.x * 0.18, wp.y * 0.035 - TIME * 1.65)));
				water_col += vec3(0.36, 0.54, 0.62) * flow_streak * depth_smooth * 0.20 * (1.0 - bridge_shadow * 0.8);

				col = mix(col, water_col, in_water);
			}
		}
	}

	// === OUTER DEEP PACIFIC OCEAN FOR CORAL ATOLL (biome_type == 9) ===
	if (biome_type == 9) {
		vec2 e_rel = (wp - vec2(800.0, 480.0)) / vec2(745.0, 442.0);
		if (dot(e_rel, e_rel) > 0.78) {
			float d_pad = m.b * 96.0;
			float o_warp = (fbm2(wp * 0.018) - 0.5) * 0.095;
			float atoll_e = length(e_rel) + o_warp;
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
				float o_spec = pow(max(dot(o_n, half_vec), 0.0), 72.0);
				o_col += vec3(1.0, 0.98, 0.92) * o_spec * 0.85;
				float surf_band = sin(ocean_depth * 24.0 - TIME * 2.4 + fbm2(wp * 0.04) * 3.0);
				float breaker = smoothstep(0.55, 0.95, surf_band) * smoothstep(0.02, 0.14, ocean_depth) * (1.0 - smoothstep(0.18, 0.46, ocean_depth));
				float shore_line = (1.0 - smoothstep(0.02, 0.12, ocean_depth)) * smoothstep(0.38, 0.72, fbm2(wp * 0.09 - vec2(0.0, TIME * 0.8)));
				o_col = mix(o_col, vec3(0.92, 0.96, 0.98), clamp(breaker * 0.82 + shore_line * 0.65, 0.0, 1.0));
				col = mix(col, o_col, in_ocean);
			}
		}
	}

	// Drifting soft cloud shadows (2-octave lightweight pass; skipped on airless Moon / Europa)
	if (biome_type != 13 && biome_type != 15) {
		vec2 cloud_uv = wp * 0.0013 + vec2(TIME * 0.014, TIME * 0.007);
		float cloud = smoothstep(0.50, 0.80, fbm2(cloud_uv));
		float cloud_str = (biome_type == 1 || biome_type == 14) ? 0.36 : ((biome_type == 2 || biome_type == 10) ? 0.42 : 0.60);
		col *= mix(1.0, 0.80, cloud * cloud_str);
	}

	// Soft battlefield edge vignette
	vec2 edge = min(UV, 1.0 - UV);
	float vig = smoothstep(0.0, 0.08, min(edge.x, edge.y));
	col *= mix(0.72, 1.0, vig);

	COLOR = vec4(col, 1.0);
}
