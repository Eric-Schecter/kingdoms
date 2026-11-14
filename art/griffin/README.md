# Soft-clay griffin prototype

Editable source: `griffin_clay.blend`. Rebuild with Blender's background runner and `build_griffin.py`.

The model is an original procedural sculpt assembled from smooth clay forms, with individually modelled wing feathers, eyes, beak, paws, harness and tail. All mesh parts have armature modifiers and vertex groups. Named actions: Griffin_idle, Griffin_fly, Griffin_attack, Griffin_hit, Griffin_land.

48 transparent 320×320 frames are rendered with a fixed orthographic camera and area lights into assets/griffin_clay. Godot consumes these frames directly, without image-warp animation. Flight loops use 12 frames, other clips 9.

This validates the consistent-model-to-rendered-sprite workflow. It is an early simplified sculpt, not the finished concept-art quality: feather detailing, wing articulation, clay surface detail and facial sculpting still need art iteration.

## V2 static sculpt study

`build_griffin_v2.py` creates `griffin_clay_v2.blend` and `output/griffin-v2-sculpt.png`. The wider head, shorter hooked bill, full haunches, larger paws, curved tail and layered custom feather meshes replace the V1 silhouette. The feather blades use tapered closed sections with raised quills; the shoulder has overlapping coverts. Subtle procedural bump adds clay grain. V2 is a separate static review model and is not yet the live animated unit. The studio render is produced by Blender, not an image-generation mockup.
