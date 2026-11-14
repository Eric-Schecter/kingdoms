# Movement sound sources

Downloaded 2026-11-08. Final mixes are `assets/audio/move-*.wav`, rebuilt by `scripts/build_foley_movement.py`. Edits include trimming, EQ, resampling/pitch, layering, fades and peak normalization. Fantasy movements are designed from Foley, not recordings of mythical creatures.

- **Fantozzi's Footsteps (Grass/Sand & Stone)** — Fantozzi; submitted by qubodup. CC0 1.0. https://opengameart.org/content/fantozzis-footsteps-grasssand-stone . Original pack https://www.freesound.org/people/Fantozzi/packs/10338/ . Uses SandL1–3 and StoneL1–3. Basis for footsteps, bodies, scraping, stone and fantasy layers.
- **Footsteps Leather, Cloth, Armor** — HaelDB. Page offers CC0 and OGA-BY 3.0; this project uses the CC0 option. https://opengameart.org/node/6197 . Uses three leather, cloth and metal takes as equipment and material layers.
- **Large Wings Flap** — AntumDeluge, based on “fast simple chop 5” by dave.des (https://freesound.org/s/127197/). CC0. https://opengameart.org/content/large-wings-flap . Uses three flap segments. Original README retained.
- **Horse gallop on different surfaces** — adapted by congusbongus. https://opengameart.org/content/horse-gallop-on-different-surfaces . Uses **only grass.mp3**, derived from **SRS_Foley_Horse_Galloping.wav**, StephenSaldanha, https://freesound.org/people/StephenSaldanha/sounds/165532/ , **CC0** according to included credits.txt. Other archive files have mixed CC0/CC-BY 4.0 licenses; none are used in the runtime mixes. Attribution for all downloaded originals is retained in horse/credits.txt.

CC0: https://creativecommons.org/publicdomain/zero/1.0/
CC-BY 4.0 (unused horse originals): https://creativecommons.org/licenses/by/4.0/

Kenney Impact Sounds was considered but its download returned HTTP 403; no Kenney samples are used.

## Attack sounds (2026-11-08)

**RPG Sound Pack** — artisticdude, CC0. https://opengameart.org/content/rpg-sound-pack . The source page explicitly labels CC0 and the author confirms it in comments. Selected originals under `rpg/RPG Sound Pack/`: battle/magic1.wav, battle/swing.wav, swing2.wav, swing3.wav; inventory/metal-ringing.wav, metal-small1.wav, metal-small2.wav, metal-small3.wav, wood-small.wav; NPC/beetle/bite-small.wav, bite-small2.wav, bite-small3.wav.

`build_combat_foley.py` trims, normalizes, pitches, filters and layers these with the credited Fantozzi StoneL1–3 recordings. It generates `combat-*.wav` with 3 variations each, including separate spell releases and impacts. Bow and crossbow are designed from wooden/metallic transients and swishes, not claimed to be recordings of real bows. Fantasy spell identities are sound design adaptations. The original pack is unchanged in the source directory.
