# 2D griffin key-pose review

Generated with the built-in image_gen tool, using the approved eight-character soft-clay design sheet as visual reference. These are painted raster images, not Blender renders.

Files: master.png, 01-up.png, 02-out.png, 03-down.png, 04-recover.png.

These are design review assets, not a finished animation. Reviewed differences: body position and scale vary; leg tuck, tail curve, harness and shield details drift. The horizontal wings have very little margin. Before runtime integration, normalize anchors/scale, reconcile costume and anatomy, and add intermediate poses. Existing gameplay assets have not been replaced.

## Prompt set

Master: faithfully recreate only the top-right griffin from the approved character sheet, preserve cream layered feather mane, golden plump lion body, broad expressive eagle face, amber eyes, hooked beak, curled tail and blue/gold fleur-de-lis breast ornament. Transparent full-body 2D raster with finely textured soft clay appearance, warm upper-left light, fixed right-facing three-quarter view, no floor, base or UI.

All four pose prompts used master.png as the identity reference, asking for identical character proportions, costume, camera and lighting, gently tucked feet, upright airborne body, transparent square canvas and generous margins. The requested target anchors were body center x768/y900 and head center x820/y650 on a requested 1536-square canvas; generation did not fully honor these anchors, so they must not be treated as measured coordinates.

1. Top: both wings extended steeply upward above the head, primary feathers upward, tips separated.
2. Out: both wings fully outward nearly horizontal at shoulder height, broad feather fans, clear wide silhouette.
3. Down: wings at bottom of powerful downstroke, feather tips below belly near feet, head unobstructed.
4. Recovery: elbows bent, primary feathers folded backward, wrists at shoulder height, compact bent-wing silhouette.

## 运行接入（2026-11-07）

新增 `05-rise.png`：以平展姿势为参考，只改变双翼至斜上举；额外清除透明边缘光晕。原图保留，运行副本在 `assets/griffin_2d/`。

`scripts/unit_pose.gd` 中 PAINTED_REGISTRATION 记录每张图的眼睛坐标与等比缩放。固定眼睛位置 (14,-110)，不以透明包围框缩放。WING_SEQUENCE 记录八拍时间轴，五个真实姿势与停留帧，不把停留帧计作新素材。站姿用于待机，落地由收翼切换站姿。

仍需修整：尾巴位置、脚部形状、胸章比例帧间不同；攻击与受击专用帧缺失。该样板用于判断 2D 路线的游戏内效果，不代表整套兵种动画完工。
