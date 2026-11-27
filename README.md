# Stationary Automated Weapon Placement on Sovereign Tactical Bastions for the Prevention of Unauthorized Vehicular and Aerial Incursion Into Command Headquarters

A gritty, tactical military tower defense game built in **Godot 4 (GDScript)** with 100% procedural 3D-shaded terrain, animated water/lava/plasma rivers, detailed military units, combat VFX, and synthesized tactical audio—zero external asset packs required.

## Running the Project
1. Install **Godot 4.3+** (standard GDScript edition, e.g. via `winget install GodotEngine.GodotEngine` or [godotengine.org](https://godotengine.org/download/)).
2. Import `project.godot` in Godot and press **F5**, or run directly:
   ```powershell
   godot --path "."
   ```

## Campaign Sectors & Biomes
The campaign spans **16 sectors** across two theaters (plus **1 secret seasonal sector**), each with custom GPU-shaded 3D terrain, rivers, and biome props (`shaders/terrain.gdshader`):

### Page 1 — Earth Theater
1. **Sector 01 — Iron Valley** *(Alpine • 1 Lane • 15 Waves)*
2. **Sector 02 — Scorched Wadi** *(Desert • 2 Lanes • 16 Waves)*
3. **Sector 03 — Frostline Pass** *(Tundra • North→South • 17 Waves)*
4. **Sector 04 — Granite Gorge** *(Mountain • Switchback • 18 Waves)*
5. **Sector 05 — Town of Ironbourne** *(Town • Urban Grid • 19 Waves)*
6. **Sector 06 — Cotswold Vale** *(Countryside • Split • 20 Waves)*
7. **Sector 07 — Whisperwood Forest** *(Forest • X-Crossing • 21 Waves)*
8. **Sector 08 — The Australian Outback** *(Outback • 3 Lanes • 22 Waves)*

### Page 2 — Extreme & Off-World
9. **Sector 09 — Pacific Coral Atoll** *(Tropical • Atoll Ring • 23 Waves)*
10. **Sector 10 — Obsidian Caldera** *(Volcanic • East→West • 24 Waves)*
11. **Sector 11 — Cypress Bayou Delta** *(Swamp • 3 Crossings • 25 Waves)*
12. **Sector 12 — Neo-Tokyo 2099** *(Cyberpunk • 3-Corner • 26 Waves)*
13. **Sector 13 — Sea of Tranquility** *(The Moon • Spiral • 27 Waves)*
14. **Sector 14 — Mars: Olympus Rift** *(Mars • Canyon Fork • 28 Waves)*
15. **Sector 15 — Europa Ice Shell** *(Europa • South→North • 29 Waves)*
16. **Sector 16 — Xenon Prime** *(Alien Exoplanet • 3-Front Final • 30 Waves)*

### Secret Seasonal Mission (`Nov 20 – Jan 6`)
- **Operation Tinsel Storm — Santa's North Pole** *(Christmas Special • 12 Waves)*: Aurora Borealis snowscape, candy-cane cobblestone roads, Santa's Workshop, decorated trees, and festive clockwork toy skins for every enemy class *(rare random intercept on deploy, offered on defeat during season, or triggered anytime by typing `HOHOHO`, `XMAS`, or `SANTA` on the briefing screen)*.

## Core Gameplay
- **7 Modern Turrets (4 Upgrade Tiers each + Evolving Visuals + 4 Targeting Priorities):**
  - `[1]` **Vulcan MG** (`GND + AIR`) — High-ROF rotary cannon with ejecting brass casings.
  - `[2]` **Cryo Emitter** (`SLOW • AOE`) — Liquid-nitrogen frost projector chilling ground & air columns.
  - `[3]` **Howitzer Cannon** (`GND • AOE`) — Armor-piercing lead-aiming artillery shells with blast craters.
  - `[4]` **SAM Battery** (`AA + HEAVY`) — Long-range air-prioritizing homing missiles (`1.65×` air bonus).
  - `[5]` **Hunter Drone Pad** (`MAP HUNT`) — Launches a committed orbiting hunter-killer UAV that pursues its locked target map-wide until destroyed (`[H]` Hold/Auto mode, `[F]` Manual target assign).
  - `[6]` **Dragonfire HEL** (`BEAM • APS`) — Ramping directed-energy laser that ignores armor and deals `2×` damage to APS shields.
  - `[7]` **HIMARS MLRS** (`SALVO • FIRE`) — Long-range precision rocket salvo leaving lingering thermobaric burn pools.
- **Tactical Ability — `[Q]` Hellfire Air Strike:** Call twin strike jets for a staggered carpet-bombing run anywhere on the map.
- **9 Multi-Domain Hostiles (+ Carrier FPV Drones) & 4 Difficulties (`EASY / NORMAL / HARD / HELL`):**
  - Recon Humvee, BTR Armored APC, Main Battle Tank, Attack Gunship, Heavy Striker Jet, Siege Juggernaut, Trophy APS Tank (regenerating Active Protection shield), Mobile UAV Carrier (launches `$0`-bounty Shahed FPV Drones), and Heavy Assault Gunship (`Sky Fortress` air boss).
- **Procedural Combat Audio & Patriotic March (`SfxManager` + `MusicManager`):** Synthesized 16-bit PCM `AudioStreamWAV` weapons, explosions, jet flybys, drone rotors, UI feedback, holiday chimes, and an overtly pompous procedural military march soundtrack (with ceremonial menu fanfare, festive North Pole march, Victory/Defeat stingers, occasional unmotivated full-brass crescendos, and independent SFX/Music volume controls).
- **50-Rank Valuation, Badges of Shame & Persistent Save (`user://save.json`):** End-of-level Net Worth (unspent cash + standing turret value) and HQ Integrity are evaluated against each sector & difficulty's theoretical maximum to award 50 escalating military-to-farcical ranks and medals (plus 10 Defeat Badges of Shame), with campaign progress and audio settings saved locally.
- **Hall of Sovereign Decorations (`36` Career & Specialist Medals):** Earn decorations for campaign clears, kill milestones, all 7 weapon specialists, tactical feats, economy, and duty time — displayed live on a procedurally drawn Commanding General whose dress uniform becomes farcically overburdened with hardware spilling across both sides of his chest, onto his sash, sleeves, trousers, and peaked cap.
- **Next-Wave Intel Preview:** Live HUD strip above the build dock displaying upcoming wave threat badges (`AIR`, `HEAVY`, `SHIELD`, `UAV`, `BOSS`, `SWARM`) and unit counts.

## Controls
- **`1`–`7`**: Select turret to place (hold **`Shift`** to chain-place)
- **`Left Click`**: Place turret / Inspect turret / Drop Air Strike / Lock Drone target
- **`Right Click`**: Cancel placement or aiming / Deselect
- **`Esc`**: Cancel active placement/aiming/selection, or toggle the Pause Menu (Resume, Audio Sliders, Restart Sector, Briefing)
- **`Right/Middle Drag` or `WASD` / `Arrows`**: Pan battlefield camera
- **`Mouse Wheel`**: Cursor-anchored smooth zoom
- **`Q`**: Hellfire Air Strike
- **`F` / `H`**: Assign Hunter Drone target / Toggle Drone `AUTO` / `HOLD` mode
- **`N`**: Launch wave / call next wave early for bonus cash
- **`U` / `T` / `Del`**: Upgrade / Cycle Target Mode (`FIRST`, `STRONG`, `WEAK`, `NEAR`) / Sell selected turret
- **`Space`**: Tactical Freeze (pause simulation while keeping the map clickable for building/upgrading)
