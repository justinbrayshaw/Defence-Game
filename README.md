# Defence Zone (Godot 4)

A gritty, tactical military tower defense game inspired by **Defense Zone 3 HD**, built in **Godot 4 (GDScript)** with 100% procedural 3D-shaded terrain, animated water, detailed military units, combat VFX, and synthesized tactical audio—zero external asset packs required.

## Running the Project
1. Install **Godot 4.3+** (standard GDScript edition, e.g. via `winget install GodotEngine.GodotEngine` or [godotengine.org](https://godotengine.org/download/)).
2. Import `project.godot` in Godot and press **F5**, or run directly:
   ```powershell
   godot --path "."
   ```

## Sectors & Biomes
Each sector steps up the tactical challenge and features its own custom GPU-shaded 3D terrain, water, and biome props (`shaders/terrain.gdshader`):
1. **Sector 01 — Iron Valley (Alpine):** Winding convoy highway, carved river gorge, steel-truss bridge, volumetric pines — 15 waves.
2. **Sector 02 — Scorched Wadi (Desert):** Wind-rippled golden dunes, sandstone mesas, turquoise oasis river & palm groves, twin converging lanes — 16 waves.
3. **Sector 03 — Frostline Pass (Arctic Tundra):** Snowdrifts, freezing sapphire glacial river with shelf-ice & floating floes, twin independent bridges, snowfall — 17 waves.
4. **Sector 04 — Granite Gorge (Mountain Valleys):** Towering snow-capped 3D granite peaks rising out of deep carved switchback valleys and roaring mountain rapids — 18 waves.
5. **Secret Seasonal Mission (Nov 20 – Jan 6):** **Operation Tinsel Storm — Santa's North Pole**, complete with Aurora Borealis snowscape, candy-cane cobblestone roads, Santa's Workshop, decorated Christmas trees, and 6 runaway clockwork Christmas toy enemies across 12 waves *(intercepted randomly on deploy, on defeat, or by typing `HOHOHO` / `XMAS` on the briefing screen)*.

## Core Gameplay
- **4 Turrets (4 Upgrade Tiers each + Evolving Visuals + 4 Targeting Priorities):**
  - `[1]` **Vulcan MG** (`GND + AIR`) — High-ROF rotary cannon with ejecting brass casings.
  - `[2]` **Howitzer Cannon** (`GND • AOE`) — Armor-piercing lead-aiming artillery shells with blast craters.
  - `[3]` **SAM Battery** (`AA + HEAVY`) — Long-range homing missiles with smoke trails and `1.65×` air bonus.
  - `[4]` **Cryo Emitter** (`SLOW • AOE`) — Liquid-nitrogen frost projector chilling ground & air columns.
- **Tactical Ability — `[Q]` Hellfire Air Strike:** Call twin strike jets for a staggered carpet-bombing run anywhere on the map.
- **6 Multi-Domain Hostiles & 4 Difficulties (`EASY / NORMAL / HARD / HELL`):** Recon Humvee, BTR APC, Main Battle Tank, Attack Gunship, Heavy Striker Jet, and Siege Juggernaut (plus 6 bespoke runaway clockwork Christmas toys on the secret North Pole map).
- **Procedural Combat Audio (`SfxManager`):** Synthesized 16-bit PCM `AudioStreamWAV` weapons, explosions, jet flybys, UI feedback, and holiday chimes.

## Controls
- **`1`–`4`**: Select turret to place (hold **`Shift`** to chain-place)
- **`Left Click`**: Place turret / Inspect turret / Drop Air Strike
- **`Right Click` / `Esc`**: Cancel placement or aiming / Deselect
- **`Right/Middle Drag` or `WASD` / `Arrows`**: Pan battlefield camera
- **`Mouse Wheel`**: Cursor-anchored smooth zoom
- **`Q`**: Hellfire Air Strike
- **`N`**: Launch wave / call next wave early for bonus cash
- **`U` / `T` / `Del`**: Upgrade / Cycle Target Mode (`FIRST`, `STRONG`, `WEAK`, `NEAR`) / Sell selected turret
- **`Space`**: Pause / Resume
