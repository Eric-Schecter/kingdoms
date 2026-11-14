# 绘本风样板 · 2026-11-07

使用内置 imagegen，参考用户提供的第二张绘本战场图；未使用旧软陶图滤镜。运行素材：`assets/storybook/griffin-sheet.png`、`assets/storybook/battlefield.png`。

## 素材与播放

狮鹫 3×3 透明动作表：站立、上举、斜上、平展、下压、收翼、攻击蓄力、扑击、受击。AtlasTexture 按等分区域读取，无贴图变形。飞行按头部锚点校准，攻击保持脚底基线以保留头部前探。五张飞行姿势以 12 fps 八拍播放；停留和复用帧不计为新姿势。死亡暂复用受击姿势并沿用战斗死亡运动。

背景及全部八兵种已经替换；UI 和障碍仍是原样。此版本是风格小样，尚非完整换肤。攻击只有两张专用关键帧，落地使用收翼到站立的切换，后续需要补中间姿势。

## 生成提示词

Sprite: Create a production 2D sprite sheet based on the GRIFFIN at upper left of the reference. Storybook ink and watercolor, warm dark brown outlines, flat ochre lion body, cream eagle head, gold beak, simplified large feather shapes, TWO flat shadow tones only. Absolutely no clay, no 3D rendering, no realistic feathers. One identical cute griffin facing RIGHT in every frame, profile with slight three quarter view. Transparent background. EXACT 3 columns x 3 rows, equal square cells, generous clear gutters, no labels, no grid. Each cell same character scale and torso center; all feathers fully inside its cell. Row1: grounded idle wings folded; airborne wings raised vertically; airborne wings extended diagonally up. Row2: airborne wings horizontal; airborne wings fully down; airborne wings folded for upward recovery. Row3: attack anticipation crouching back; attack forward beak strike with front claws reaching right; recoil/hit with eyes shut and head withdrawn. Nine full body drawings. Maintain identical eye, beak, head, tail and body design across all nine. Sprite sheet square 1536x1536. No scenery, no bases, no oval shadows, no numbers, no ornaments.

Background: Empty tactical battlefield background in the reference's flat ink and watercolor storybook style. Wide landscape. Ivory castle green hills upper left, stone bridge distant horizon, lavender haunted woods upper right, sparse flowers at extreme edges. Horizon top 20%. Middle and lower 75% open pale olive meadow, low contrast for sprites. Paper grain, warm colors, delicate brown contours. NO characters, portraits, borders, UI, hexagons, numbers, letters, foreground obstacles or cast shadows. Full bleed landscape illustration, no 3D.

## 预览

`godot --path . --script scripts/storybook_preview.gd` 输出 72 帧到 `/tmp/t17-storybook-preview/`。战斗使用现有 `scripts/animation_demo.gd -- --record`。输出：`output/storybook-griffin.gif` 和 `output/storybook-battle.mp4`。

## 全兵种接入

七个新增动作表见 `assets/storybook/*-sheet.png`，每张九格，排列统一为：待机、行走1、行走2、行走3、行走4、蓄力、出手、回收、受击。完整生成提示词见 `army-prompts.json`，均使用内置 imagegen，参考已认可的狮鹫动作表。神射手额外使用内置编辑清除棋盘格背景，保持人物、位置与3×3布局。

播放器按 alpha > 0.5 的有效区域校准脚底，角色缩放在各自整套动作内保持一致；透明微弱噪点不参与尺寸计算。十字军和巫妖出手帧使用右侧空白边距的额外5.5%区域，以容纳剑尖和火焰。每种角色注册结果缓存，避免重开战斗时重复扫描。

新增 `scripts/army_preview.gd` 检查全部八种角色的待机、移动、攻击/射击和受击。死亡仍无独立素材，远程兵近战暂共用攻击姿势。部分步态轮廓与装备细节存在帧间差异，后续可增加过渡帧。

## UI 图标

内置 imagegen 生成 `assets/storybook/ui-icons.png`，3×3 等分读取；其余面板为 Godot StyleBoxFlat 绘制，头像复用兵种待机素材。提示词：Transparent 3x3 game icon sprite sheet, nine isolated symbols, no text, no backgrounds, no frames. Flat storybook watercolor dark brown ink outlines, cream antique gold muted blue purple. Equal square cells 20% margins. Row1 hourglass, blue shield, magic purple arrow. Row2 winged boot, purple snail, two rightward gold chevrons. Row3 three connected hexagon outlines, crossed swords, circular curved gold restart arrow. Clear simple silhouettes readable at 48px, no 3D. Square sheet.
