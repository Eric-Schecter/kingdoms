# Kingdoms · The Last Stand

## Opening faction selection

Five compact town cards (330×285, arranged 3+2) select Castle, Necropolis, Rampart, Tower or Inferno. Click a card or press 1–5. Each has a dedicated town painting and seven troop icons. New battle / R returns here. Necropolis and Inferno face Castle; the other factions face Necropolis. Auto controls both sides. All five are playable; enemy selection is currently fixed.

Town illustrations were repainted for thumbnail readability: one dominant landmark, quiet background, broad faction colors, and distinct terrain (fortress / mausoleum / woodland hall / alpine wizard tower / lava citadel). Assets: `assets/storybook/*-town.png`. Built-in imagegen prompts: `art/storybook/town-rework/prompts.json`. Actual in-game preview: `output/five-factions.png`. Visual reference: Heroes III town screens, including https://heroes3wog.net/wp-content/uploads/2016/04/castle-town-screen.jpg and https://lutris.net/media/games/screenshots/homm3-city.png .

## Current roster: seven troops per faction

Castle: Pikemen, Marksmen, Crusaders, Griffins, Monks, Knights, Angels.
Necropolis: Skeletons, Zombies, Liches, Dread Knights, Ghosts, Vampires, Bone Dragons.

Rampart: Centaurs, Dwarves, Wood Elves, Pegasi, Dendroids, Unicorns, Green Dragons.
Tower: Gremlins, Gargoyles, Iron Golems, Mages, Genies, Nagas, Titans.
Inferno: Imps, Gogs, Hell Hounds, Demons, Pit Fiends, Efreet, Devils.

There are 35 creature sheets with nine separate painted frames each. The three new factions add 21 sheets and three towns, matching the storybook direction. New mechanics include elf double shots, centaur charges, dendroid roots (-2 speed until the target finishes acting), golem resistance to magical projectiles, naga/hell-hound/devil retaliation suppression, pit-fiend frenzy and efreet fire shields. Constructs resist disease, life drain and death clouds. These are prototype adaptations, not a complete reproduction of the original abilities or balance.

Validation: `factions_test.gd` checks all five deployments and 35 frame sets; `new_factions_match.gd -- --faction=2/3/4` runs each new army to a result. `new_factions_preview.gd` captures the picker and three starting armies under `output/`. Existing ability and expansion regressions also pass.

The original two factions contain fourteen troops. Monks fire holy bolts and retain full melee damage; Knights gain 30% charge damage after three straight movement steps; Angels occupy two hexes, fly and deal 25% bonus damage to Undead; Ghosts fly and resist 25% melee damage; Vampires prevent retaliation and restore 50% actual damage dealt to living targets, capped at their initial stack health; Bone Dragons occupy two hexes, fly, and reduce adjacent living enemy attack by two. The aura does not stack.

The initiative strip fits all fourteen stacks and retains completed turns. Deployment places all seven stacks along each back edge on rows 0, 2, 3, 5, 7, 8, 10. The board remains 15 by 11 hexes; vertical center spacing is 46 pixels with the top row at y=250 and single-hex actors render at 60% of their former size; Griffins and Angels at 90% and other two-hex actors at 84%. Large creatures retain two horizontal hexes. Starting counts: Castle 50/28/16/18/6/5/2; Necropolis 65/30/6/4/12/10/2. These are prototype balance values, not original-game statistics.

New sheets are in `assets/storybook/`, generated with built-in imagegen using the existing griffin sheet as the style reference. Movement/attack/hit use separate painted frames. Bone Dragon wing movement and Vampire airborne poses still need refinement; death uses hit-pose fading, not a dedicated animation.

Validation: `scripts/expansion_test.gd`, `scripts/rules_test.gd`, `scripts/abilities_test.gd`, `scripts/double_hex_test.gd`. Current recording: `output/seven-per-side.mp4`. The eight-troop notes below describe the previous iteration.

Godot 4 回合制战场原型，参考《魔法门之英雄无敌 III》的独立战斗部分。打开 `project.godot`，按 F6/F5 运行；macOS 也可双击 `运行战场.command`。

## 操作

- 左键点击亮起的六角格移动；点击敌军执行近战或射击。
- 悬停兵团查看属性；悬停可攻击目标预览伤害。近战时移动鼠标到敌人的不同边缘，可在移动范围内选择接近方向，路线和最终双格占位会同时预览。
- W：等待，在本轮第二阶段行动；D：防御，防御力增加 20%。
- G：六角格开关；A：自动战斗开关；R：重新开始；S：1×/2× 动画速度。

## 实现

15×11 错列六角格，速度行动顺序与等待阶段、堆叠数量和残余生命、英雄攻防加成、距离减伤、贴身封锁远程、反击、弩手双射、十字军双击、皇家狮鹫飞行与无限反击、骑兵冲锋、恐怖骑士诅咒与致命一击、巫妖死亡之云、士气追加行动、幸运双倍伤害、AI 寻路与战斗、战报和胜负结算。

城堡：枪兵、神射手、十字军、皇家狮鹫；墓园：骷髅、僵尸、强力巫妖、恐怖骑士。兵种属性加英雄属性后显示，疫病与防御加成动态计入。城堡初始阵容 50/28/16/18，墓园 65/30/6/4。

## 当前绘本风样板

当前八个兵种与战场背景均已切换为绘本风：深棕描边、水彩色块、简化明暗。枪兵、神射手、十字军、骷髅、僵尸、巫妖、恐怖骑士各有九张独立姿势（待机、四张行走、攻击准备/出手/回收、受击）；狮鹫保留已认可的九张姿势。合计 72 张姿势，不含循环复用帧。

攻击与射击按既有命中时间轴播放；死亡暂复用受击姿势与倒下位移，并无专用死亡动作。四张步态和三张攻击关键帧仍有细节变化，不等同于完整流畅动画。UI 与地图障碍未重新绘制。狮鹫和恐怖骑士继续占双格。

运行素材位于 `assets/storybook/`，内置 imagegen 提示词见 `art/storybook/army-prompts.json`。阵容预览：`output/storybook-army.gif`；实战录像：`output/storybook-army-battle.mp4`。运行 `godot --path . --script scripts/army_preview.gd` 可重新录制八兵种动作检查。

以下软陶方案为历史归档，当前所有兵种优先使用绘本动作表。

## 2D 软陶风狮鹫样板

上一版狮鹫使用 AI 绘制的透明 2D PNG，已替换战场中的简化 3D 渲染版本。源图位于 `art/griffin_2d/`，运行素材位于 `assets/griffin_2d/`。一张站姿母版、五张独立振翅姿势，通过眼睛锚点与每帧统一缩放校准；飞行使用 12 fps 的八拍循环，包含下压停留和收翼恢复。没有贴图网格变形或混合淡入淡出来冒充新帧。

这是画风和飞行动画样板：尾巴、脚和徽章仍有帧间差异；攻击、受击尚未绘制专用的新 2D 动作，暂时使用站姿配合战斗位移与命中特效。其他兵种与背景仍为之前的画风。旧 Blender 模型保留在 `art/griffin/`，不再用于狮鹫当前表现。

```sh
godot --path . --script scripts/griffin_2d_preview.gd
```

此脚本使用与战场相同的角色播放器，输出放大和实际尺寸对照帧到 `/tmp/t17-2d-preview/`。预览：`output/griffin-2d-flight.gif`；实战录像：`output/griffin-2d-battle.mp4`。

## 逐帧动画与双格单位

当前已接入真正独立绘制的 PNG 帧：枪兵行走、枪兵刺击、十字军行走、十字军挥剑、狮鹫振翅。每组含参考首帧及 8 个生成动作帧，位于 `assets/animations/`。播放器已移除网格和顶点变形；旧狮鹫上/下翼帧保留归档，当前使用上述 2D 样板，近战动作含回收播放段。

素材由 PixelLab animate_image 根据已有角色生成，并非原版游戏提取素材。其余兵种动作生成时服务返回额度耗尽，因此暂使用静态角色随行动位移，尚未具备新的逐帧动作。旧版动画预览若未重新录制，不代表当前实现。

狮鹫和恐怖骑士仍占两格；双格寻路、转身、尾格接触、落点检查和范围伤害去重保持启用。S 切换 1×/2× 播放速度。

## 当前范围

这是独立战场的近似复刻，并非完整原作移植。目前实现四张场地、五阵营共 35 个兵种和本地人机对战，不含英雄施法。美术为 AI 生成的全新素材，动画由独立 PNG 帧、动作状态与命中特效驱动；未使用原版数据包、逐帧素材或音乐。已实现大型单位双格占位与转身，尚无攻城、原版逐帧动作、完整法术持续时间/抗性系统和全部技能。战斗音效为程序合成。

## 验证

```sh
godot --headless --path . --script scripts/rules_test.gd
godot --headless --path . --script scripts/double_hex_test.gd
godot --headless --path . -- --self-test
```

第一项检查原有规则；第二项检查双格占位、两侧边界、狭道、飞行落点、零消耗转身、尾格近战、命中时间、范围伤害去重和死亡动作；第三项自动战斗到胜负结算，并在每次换手时校验占位。实际窗口截图位于 `output/battle-preview.png`。

规则参考：[原版 1999 英文手册（Steam 官方托管）](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/297000/manuals/BONUS_Heroes_of_Might_and_Magic_III_HDEdition_OldManual1999_EN.pdf)。伤害和特殊能力为原型实现，未承诺全部边界情况与原作一致。

素材生成方式、最终提示词见 `assets/GENERATION.md`。

### 可重现动画演示

```sh
godot --path . --script scripts/animation_demo.gd -- --record
```

演示会播放真实战斗调用并将渲染帧写入 `/tmp/t17-animation-frames/`。交付的预览为 `output/battle-animation.mp4` 和 `output/battle-animation.gif`。演示中的移动与正常对战共用双格寻路和动作时间轴。

## 绘本图标界面

行动顺序以兵种图片与堆叠数量呈现，金边表示当前行动者。下方沙漏/盾牌对应等待、防御，英雄施法按钮已删除；右侧箭头/六角/双剑/回转箭头对应速度、网格、自动战斗、重新开始。悬停显示英文说明和快捷键，不可用操作降低图标亮度。原快捷键继续有效。状态区以头像、生命条、剑/盾/翼靴数值展示单位，战报默认保留最近一条。

界面截图 `output/storybook-ui.png`。`scripts/ui_preview.gd` 验证图标资源、命中区域以及网格/速度按钮的点击路径。

## English UI and battle audio

All in-game interface labels and tooltips are English. B toggles the looping background music; M mutes/unmutes all audio. The header Music button also pauses/resumes the music without restarting it.

`assets/audio/` contains an original 36.9-second, 104 BPM synthesized battle loop (plucked accompaniment, reed-like melody, bass and percussion), plus seven layered combat sounds. `scripts/build_audio.py` rebuilds these deterministic WAV assets without external dependencies. Music plays quietly under eight overlapping SFX voices. Attack release and impact sounds are tied to actual combat timing; animation speed does not change music pitch.

Impact effects use ink-outlined starbursts, radiating sparks and creature claw marks, alongside the existing weapon trails and magic cloud. Preview with real engine audio: `output/storybook-battle-audio.mp4`. Audio is original procedural synthesis, not recorded orchestral instruments.

## Compact dock and auto-battle previews

The bottom dock is a single row: unit portrait/HP/count, five combat actions, then four utility controls. Hover the unit summary for attack, defense, damage and speed; action hints and keyboard shortcuts remain available. The repeated battle log and always-visible attribute row have been removed from the dock.

Both enemy AI and Auto Battle show SELECT UNIT, PLAN MOVE and SELECT ATTACK/AIM SHOT before execution. Gold paths show the planned route and final footprint; purple target hexes and an aim marker identify the defender. No unit selection circle was added. Preview pacing follows 1×/2× animation speed. `scripts/auto_preview.gd` captures and validates the preview stages; `output/auto-preview.mp4` is the recorded example.

### Round roster and grid visibility

Initiative cards now retain the complete speed-sorted roster for the current round. The current actor has a gold border, finished stacks are dimmed with a check, waiting stacks have an hourglass, and eliminated stacks remain marked until the next round. The underlying waiting/morale action queue is unchanged. At the next round the roster refreshes from living stacks.

Walking, flying and landing units do not render their ground oval or selected footprint. Planning routes remain visible before motion. Hexes use a pale under-stroke plus a dark outline for contrast against grass. `scripts/auto_preview.gd` asserts the roster remains unchanged throughout round one and captures `output/moving-no-marker.png`. The latest movie capture had timing problems and is not an acceptance artifact. `scripts/roster_check.gd` separately verifies eight cards remain after a completed action; screenshot: `output/fixed-roster.png`.

The bottom dock is now centered at 960×100 logical pixels with tighter 60px icon buttons. Routine turn/AI-phase labels (ENEMY TURN, YOUR TURN, IN ACTION) are hidden; targeting, damage and movement previews remain available when the player can act. Auto-battle continues to show its selection/path/target visually on the battlefield.

The game viewport is now 1440×872, with a 10px gap between the battlefield and dock and an 8px bottom margin. Contextual action hints appear above the dock instead of reserving an empty footer. Video-frame export preserves the viewport aspect ratio.

## Creature attributes and abilities

Combat stats and starting stacks remain prototype-balanced. Current creature mechanics and their limitations are documented in **HOMM III abilities and interaction revision** below. The earlier experimental flank, preemptive bracing and Dread Knight charge rules have been replaced.

Current regression suites: `scripts/rules_test.gd`, `scripts/new_faction_abilities_test.gd`, `scripts/h3_feedback_test.gd` and `scripts/h3_area_test.gd`.

## Full-width dock and settings

The bottom parchment dock spans the battlefield width. Decorative hero portraits on both sides are removed; hero stat bonuses remain part of combat rules. The header gear icon opens settings with a music-note toggle (B) and speaker mute toggle (M); no Music ON text button remains. Click outside or press Escape to close settings.

`scripts/record_match.gd` starts a new auto battle, verifies music toggling, validates footprints during play, and stops after the outcome. Final recording: `output/full-match.mp4`; screenshot: `output/full-width-ui.png`.

## Combat presentation revision

Movement is shown as a continuous chain of highlighted footprint hexes, with distinct origin/destination cells. It stays visible while moving. The old arrow/line route and overhead selection triangle are removed. Direction changes switch directly between left/right sprite views: no horizontal squeeze animation, no automatic flip back after attacking. Defeated sprites fade rather than rotate like cardboard; dedicated death frames are still absent.

Melee swings now draw a tapered luminous ribbon. Crossbow bolts show a shaft and arrowhead; lich projectiles have a bright core, undulating particle tail and orbiting sparks, preceded by a gathering effect. Eight rebuilt stereo SFX layer air movement, attack transient, low impact body, material resonance and short spatial echoes, with a separate magic impact burst. These remain original synthesized effects, not recorded instrument/foley samples. Demo: `output/combat-polish.mp4`.

The current background is `assets/storybook/battlefield-valley.png`: distant scenery is confined above the playable grass, so the top deployment row no longer overlaps castle/tree terrain. The previous background is retained as an art reference.

Stack counts use compact 16-pixel-high dark labels near the feet, mirrored towards the battlefield by faction. Candidate positions avoid approximate creature bounds and other labels. This is an adaptation of the original Heroes III side-mounted count plates; crowded formations are covered by `scripts/count_labels_preview.gd`.

## Creature movement audio

All 35 creatures map to 14 material families. Runtime movement now uses 42 sample-based Foley mixes: Fantozzi ground footsteps, HaelDB equipment/cloth/leather, AntumDeluge wing flaps and StephenSaldanha horse gallop (adapted by congusbongus). Runtime source selections use CC0. Full authors, URLs, selected files and edits are documented in `assets/audio/sources/CREDITS.md`; original source files are preserved beside it.

Rebuild with `python3 scripts/build_foley_movement.py` (ffmpeg required). The old `build_movement_audio.py` is the historical synthesized version and overwrites the current mixes if run; rerun the Foley builder afterward to restore the current sound.

Ground cadence continues across hex boundaries; flight sounds repeat during flight and physical flyers have landing impacts. Three takes per family use nonconsecutive selection with restrained pitch variation. Four dedicated movement voices do not steal attack voices. Existing music and master mute settings apply. Fantasy movement is designed from recorded material layers, not literal creature recordings.

`movement_audio_demo.gd` verifies all 14 profiles through actual movement. Current preview: `output/movement-foley.mp4`, with BGM disabled only for the demonstration. Previous synth comparison: `output/movement-audio.mp4`.

## Attack sound and targeting revision

`combat-*.wav` replaces generic attack cues with CC0-derived layered releases and impacts. Eleven attack families distinguish blade, thrust, claw, heavy melee, bow, crossbow, holy, arcane, death, fire and lightning. Physical impacts select flesh, metal, bone or stone by defender; magic impacts retain spell identity with a stronger low layer. Three variants avoid consecutive repetition. Sources and changes: `assets/audio/sources/CREDITS.md`; builder: `scripts/build_combat_foley.py`.

AI aiming keeps the target footprint highlight but no longer draws a source-to-target line or crosshair. Arrows are short physical projectiles; magic uses compact traveling particles, with a short jagged traveling bolt for Titans. Damage and impact sound occur after projectile arrival. Reference direction: Heroes III's target/action indication and actual projectiles, not a persistent aiming beam (https://heroes.thelazy.net/index.php/Cursors).

`combat_foley_demo.gd` checks eleven attack families on actual attacks; preview `output/combat-foley.mp4` has music off for clarity. Normal battles retain BGM.

## Creature inspection

The redundant KINGDOMS header is removed; a compact hourglass and number show the current round, and the initiative strip starts beside it. Click a living creature's body/hex or an initiative portrait to open an English detail panel for either side. It shows faction/allegiance, count, total and top-creature HP, effective attack/defense, per-creature damage, effective speed, shots, abilities and active statuses. Inspection itself never issues an attack. If the inspected enemy is a valid target on the player's turn, the panel offers explicit Attack/Shoot with estimated damage. Close with ×, Esc, right-click or outside click. Empty-hex movement retains direct click behavior; hero spell targeting, hotkeys and mana have been removed. AI battles continue while inspecting; displayed values stay live.

Validation: `scripts/creature_details_test.gd` covers friendly/enemy body clicks, dismissal, no damage on inspect and damage on explicit Shoot. Screenshot: `output/creature-details.png`.

Inspection refinement: left-clicking the active friendly creature refreshes its legal movement range without opening a modal; right-click or its initiative/bottom portrait opens details. Movement destinations use a contrasting blue-green fill. Details show icons and values, town artwork, ability/status badges and an icon-only confirmation action. Hover icons for English explanations and full ability text. Other creatures are inspection-only until their own turn.

## Four battlefields and matching music

Before choosing a faction, click one of four landscape thumbnails along the bottom (or use Left/Right). The battlefield background and its music preview switch immediately; then click a faction to deploy. Sunlit Valley, Frostwatch Ruins, Twilight Necropolis and Ashen Caldera each have their own central obstacle layout. All preserve the same 15×11 grid, seven-stack edges and clear deployment ground; scenery remains outside the playable area. Terrain currently changes presentation and obstacle placement, not creature statistics.

New backgrounds: `assets/storybook/battlefield-{snow,graveyard,volcano}.png`, generated with built-in imagegen using the valley composition as reference. Prompt set: `art/storybook/map-prompts.json`. Music sources/CC0 credits: `assets/audio/music/CREDITS.md`. The valley retains its original project composition; the new three use licensed music with looping, a short fade-in and preserved music-off preference.

Validation: `maps_preview.gd` verifies all four map/music selections, music mute, deployment and movement. `new_factions_match.gd -- --faction=3 --map=1/2/3` completes battles on the three new layouts. Still gameplay screenshots with matching music preview: `output/battlefields-preview.mp4`; picker: `output/map-selection.png`.

## Combat readability and deployment

Combat feedback uses compact dark, gold-bordered badges with line-art icons and numbers. Numbers use the engine-bundled sans font with lining figures; icon centers and the font-metric baseline align within each badge, and negative values use a mathematical minus sign. Sword + number means actual HP lost (capped at remaining HP); skull + number means creatures killed by that hit, including zero. Direct attacks, death-cloud splash and fire-shield reflection share this accounting. Special effects use dedicated icons: heart for healing/drain, curled arrow for retaliation, paired arrows for double shot, pathogen for disease, roots for rooting, flame for fire shield, and distinct icons for the remaining ability cues. Buffs use sky blue, healing mint green, adverse effects lavender and luck/morale gold. Compound cues split into separate lanes; nearby messages avoid overlapping. Badges hold full opacity before fading and last 2 seconds independently of animation speed. English descriptions remain in creature details and the battle log. `scripts/combat_icons_test.gd` validates real attack damage/casualties, wounded stacks, overkill and all 21 ability labels; `output/combat-icons-preview.png` is a staged UI example. Every initial stack footprint touches its army edge: single-hex stacks occupy the outside column, large stacks extend one cell inward.

Music uses per-track gain matching (valley −11, snow +5, graveyard +10, volcano −17 dB) because source recording levels differ substantially. `combat_text_preview.gd` checks all five faction deployments on all four maps and music playback/gain; its isolated BGM recording measures approximately −30 dBFS average per map. `record_faction_series.gd` supports `--left`, `--right`, `--map`, and optional `--preview-seconds` for real battle recordings.

## Airborne animation

Winged creatures use a separate flight cycle, never their ground walking cycle. Angel and bone dragon use `airborne-angel-bone-dragon.png`: four independent painted wing poses per creature with tucked, steady legs. Griffin, pegasus, green dragon and gargoyle reuse their actual airborne drawings with eye-based registration instead of changing silhouette bounds. Vampire levitation holds the spread-cloak pose; devil travel holds a stable body pose, so neither runs in midair. Ghost, genie and efreet retain their legless drifting animation. Flight rises briefly, cruises at steady altitude and descends before landing. `flight_preview.gd` captures the six wing cycles and two stable levitation poses; it is an animation showcase, not a battle. Recording harnesses force drawing every captured frame to avoid macOS occlusion freezes.

Battle results play distinct original musical cues: an ascending major victory fanfare and a descending minor defeat cue. Result playback is one-shot, keyed to the player's side; BGM fades down 12 dB at the result screen. Restart stops the cue and restores map music level. Sources: `scripts/build_result_audio.py` (original synthesis, no third-party samples). Validation: `scripts/result_audio_test.gd` covers both sides, both outcomes, repeated result checks and restart.

Result cues now use sampled orchestral instruments rendered by `scripts/render_result_orchestra.swift` through macOS AVAudioUnitSampler: strings, French horn, trumpet, timpani and percussion, with large-hall reverb. Original D-major victory and C-minor defeat arrangements; 8-second stereo WAVs are normalized to −18 LUFS with −2 dBTP ceiling. Only rendered audio is included; the system instrument bank is not copied or redistributed. `build_result_audio.py` is the older synthesized prototype and should not overwrite these assets.

Faction selection rolls an enemy uniformly from the other four factions. Opponent randomness is separately seeded from battle-damage RNG, so restarting the app does not force the same opponent. Each new faction selection rolls once; the chosen matchup remains fixed throughout the battle. The picker shows “RANDOM OPPONENT”. The Necropolis player still deploys on the right; other player factions deploy on the left. `factions_test.gd` checks exclusion, coverage of all four opponents and player roster/deployment correctness.

## HOMM III abilities and interaction revision

Hovering a creature highlights its actual silhouette and footprint (cyan ally, warm enemy). Context icons show inspect, movement, melee or ranged attack. Clicking another creature still opens details; the sword/arrow confirmation issues the attack. Attack and retaliation animations show the corresponding action icon. Only Wait/Defend remain as bottom combat actions; hero spell input, mana and spell implementations are removed.

Rosters now name the intended upgrade where the existing art/ability already represented one: Cavaliers, Wights, Vampire Lords, Grand Elves, Master Gremlins, Cerberi and Efreet Sultans. Original-style creature abilities replace invented flank, armor, frenzy and ranged-resistance bonuses. New executable rules include jousting +5% per moved hex and pikeman immunity; death blow/curse; disease; full vampire life drain; Wight top-unit regeneration; persistent binding; blinding; dragon breath with friendly fire; three-headed attack; hate bonuses; angel/bone-dragon morale; and devil teleportation. Attack data and army counts remain prototype-balanced, not an exact original-stat port.

No hero casting is available. Spell-cost modifiers, hero-spell resistance/reduction and spell immunity are listed in creature descriptions for reference but do not fabricate an effect on ordinary ranged attacks. No positive luck source exists in these armies, so Devil's enemy-luck penalty cannot reduce damage below neutral luck in the original rules. No summoning is assigned to Pit Fiends (it belongs to Pit Lords), nor spellcasting to base Genies. Flying and occupancy remain the project's existing footprint convention.

References: https://heroes.thelazy.net/index.php/Castle_creatures , https://heroes.thelazy.net/index.php/Necropolis , https://heroes.thelazy.net/index.php/Rampart , https://heroes.thelazy.net/index.php/Tower_creatures , https://heroes.thelazy.net/index.php/Inferno . Verification: `rules_test.gd`, `new_faction_abilities_test.gd`, `h3_feedback_test.gd`, full AI match checks.

## Creature ability audiovisual feedback

Creature procs now dispatch impact-synchronized accents through `ability_feedback.gd`: death-blow skull/slash, curse skull, blinding eye flash, disease motes, growing binding vines, reflected flames, life-drain particles returning to the attacker, dragon breath and per-target Cerberus claw marks. Blind, curse, disease and binding also retain compact status badges until the actual state expires. These do not add hero casting or distort creature sprites.

Nine audio profiles layer the existing credited Foley library (`assets/audio/sources/CREDITS.md`) with separate pitches and gains. Normal attack/material impact sounds remain underneath. This is an original lightweight interpretation, not extracted HOMM III effects or recordings. Existing death-cloud and ranged-attack effects remain in place.

Validation: `scripts/ability_feedback_test.gd` executes a real binding attack, verifies the skill audio event, checks all nine visual branches and imported audio layers in a native window, and saves `output/ability-feedback.png` as a simultaneous effect contact sheet (not normal battle placement). `scripts/h3_area_test.gd` covers multi-target geometry and status procs.

## Battle-opening fanfare

Choosing a faction starts a five-second original orchestral fanfare: sampled trumpet/horns, marching strings, timpani and cymbal, rendered with `scripts/render_start_orchestra.swift` using the macOS system instrument bank. It evokes classic fantasy strategy openings without copying the original game's melody or recording. Map music ducks by 22 dB and returns over 1.6 seconds after the initial 2.8-second call. The music toggle also pauses the fanfare; results interrupt it and scene restart resets playback. Validation: `scripts/start_audio_test.gd` checks actual faction entry, duplicate suppression, music toggle, BGM recovery and result interruption.

## Rolling initiative, morale and luck

The top strip now scrolls forward with the active stack, displays remaining normal actions then waiting stacks (slowest first), and continues into a dimmed next-round preview separated by a gold line. Mouse wheel browses the queue; selecting a portrait inspects the displayed stack. Death removes entries, and morale inserts the same stack immediately again.

Morale includes single-faction +1, mixed-faction penalties, undead companions, Angel +1 and opposing Bone Dragon -1, clamped to -3..3; undead and golems are immune. Positive morale rolls after a move/attack (level/24, at most one extra action each round); negative morale rolls once per round before acting (absolute level/12), with visible pause and feedback. Waiting cannot reroll negative morale. No bonus roll for defending/waiting.

Both battle-scenario heroes have Basic Luck (+1), explicitly shown in creature detail hints; enemy Devils reduce it by 1. Positive luck chance is level/24, capped at 3. Lucky strikes add 100% base damage to the offensive multiplier, before defensive/range penalties, rather than doubling final damage. Classic negative luck has no unlucky half-damage proc (that is a HotA rule). Creature details expose both values with icons; triggers use icon feedback, rainbow accents and audio. This remains a battle-only scenario, not a hero progression or artifact system.

References: https://heroes.thelazy.net/index.php/Morale and https://heroes.thelazy.net/index.php/Luck . Regression: `scripts/initiative_fortune_test.gd` (queue changes, waiting, deaths, morale immunity and bounds, lucky damage and Devil modifier).

## Distinct morale and luck cues

Morale now shows a large gold flag with EXTRA TURN / HIGH MORALE and a sampled ascending horn phrase; a 0.65-second pause separates the earned action. Luck uses a green clover with LUCKY STRIKE / +100% BASE DAMAGE and a high bell arpeggio. Negative morale uses TURN LOST and descending horns. Cards last two real-time seconds regardless of combat speed. Dedicated proc audio avoids stealing ordinary impact voices. Original cues are rendered by `scripts/render_proc_audio.swift`. Settings and its dropdown align with the right edge. `scripts/proc_feedback_test.gd` validates distinct streams, real-time duration and button positions; `output/proc-feedback-clear.png` is a staged comparison of both indicators.

Proc feedback refinement: the large text cards are replaced by 52px outlined flag/clover icons that prefer free space above the creature bounds, remain visible for two real-time seconds and retain distinct audio. Lucky impact adds a short hollow gold/white radial burst at the target, plus heavy and metallic impact layers under the bell cue. This changes presentation only; the original lucky damage calculation is unchanged. `proc_feedback_test.gd` also renders the critical burst.

Lucky-hit punch refinement: a 0.13-second white/gold core flash leads into a 0.6-second expanding shock ring and outward sparks. A short 0.10-second action pause follows impact. `lucky-impact.wav` layers the existing credited heavy, metallic and stone recordings with slowed bass, crisp high frequencies and peak limiting; a dedicated player prevents normal attack voices from replacing it. Flag/clover icon rendering and the damage rules are unchanged.

## Opening phase and direct targeting

Faction selection now starts a five-second opening phase: the fanfare plays, action advancement/AI stays locked and no reachable hexes are available. The normal turn and movement range begin after the opening. Hovered creatures have a colored silhouette outline plus a subtle tint. The move cursor is a boot icon. Left-clicking an attackable enemy on a manual player turn attacks immediately; right-click and initiative portraits retain optional inspection. This supersedes the older inspect-before-attack workflow above. `scripts/opening_interaction_test.gd` verifies opening lock/unlock, actual damage from direct clicking, right-click inspection and the hover shader.

Opening input lock now rejects mouse buttons, wheel, shortcuts and direct detail/settings commands; hover outlines and tooltips are suppressed until opening completion. Movement-distance text is removed. Inspect, boot, melee and ranged cursor images now replace the native arrow with a dark-outlined 38px custom cursor (center hotspot), restoring the arrow over UI, during opening and on exit. No cursor-following action panel is drawn. Opening interaction regression covers locked inspection/settings/auto plus custom-cursor creation after unlocking.

macOS cursor compatibility: use a software replacement centered exactly at the pointer, hiding the native arrow only over contextual battlefield targets. UI, focus loss, window exit and scene exit restore the native arrow. This works in the standard non-fullscreen window and is captured by game recordings. Removed the remaining attack/range information strip. `opening_interaction_test.gd` verifies native-arrow hiding and captures move/attack cursors in window mode.

## Active-stack and result UX

Initiative cards are now 90×80 with 96px spacing and 12 visible entries; drawing, hitboxes, scrolling and transition spacing share the enlarged layout. The active creature has a persistent gold outline/tint, distinct from friendly/enemy hover colors. Left-click, cursor selection and hover share `pick_action_target`: an occupied hex resolves to its stack; a legal empty movement destination takes precedence over overlapping artwork. Right-click retains body-based inspection.

Results retain the undimmed battlefield and surviving creatures. Input is locked to the result's restart button / R; inspection, board clicks, scrolling and hover highlights are disabled. `battle_ux_test.gd` verifies overlap targeting, active highlight and result locks, with native-window screenshots.

Ranged distance cursor: targets farther than 10 hexes use an amber broken-arrow cursor with a small half-damage badge; targets at 10 hexes or closer retain the normal ranged cursor. The active shooting icon uses the same rule. `ranged_distance_penalty` is shared by damage, labels and cursor selection; `ranged_cursor_test.gd` checks 10/11-hex boundary damage and visible window-mode cursor.

Result controls: ordinary corner/dock buttons are no longer rendered or registered after battle ends. Button dispatch also rejects all non-restart commands in the result state. The sole remaining hitbox is the central Fight Again button. Regression checks unchanged grid/speed/auto/music/mute state even when commands are invoked directly.
