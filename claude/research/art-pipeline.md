# Solaria AI art pipeline: the Art Director playbook

Written 2026-10-23 by the research loop (10 rounds; log at the bottom). Reader: the Art Director
expert agent. Goal: shippable, consistent pixel art at $0 on Juzo's PC (RTX 4060 8 GB, 16 GB RAM),
made by one AI agent, every step scripted.

Inputs read: `claude/experts.md`, `claude/art-plan-2.1.md`, `claude/art-audit.md`,
`claude/research-2.1.md`, `claude/research/art-critique.md` (Fable critique + **Juzo's round-2
verdict**), `art_style.gd`, `art_info.gd`, `sprites.gd`, `lpc.gd`, `project.godot`, `C:\ai\README.md`,
the art helper's scripts and results (`C:\ai\scripts`, `C:\ai\art_work`,
`C:\gamedev\solaria_wt_newart\claude\art_test\` incl. `v2/README.md`, the A/B/C sheet, mockups and town sheets).

Confidence marks:
- **[V]** verified this session against a primary source (model card, repo/source code, official docs,
  ComfyUI source on disk, Solaria's own code/files).
- **[L]** local evidence from the art helper's real runs (small sample, but on this exact stack).
- **[U]** unverified: secondary source or craft knowledge. Test before relying on it.

---

## 0. Juzo's round-2 verdict and what this playbook does about it

| Juzo said (Oct 23) | Meaning for the pipeline | Section |
|---|---|---|
| Hero: **head from look C, armour from look B** (slimmer); **dark chibi, three-quarter from behind** | new mannequin v3 = C head on the B body; the layer system makes the mix possible (head = race body layer, armour = outfit layer) | 7 |
| Current **dungeon** backgrounds/tiles "don't look good" | full replacement, not cleanup: layered depth backgrounds + new tile/texture sets | 10 |
| Current **monsters** "don't look good" | full redraw of all 144 in one new style matching the approved heroes (not only the HIGH list) | 8 |
| Town concept is "**hella flat**" | rebuild around depth cues: 3/4 buildings with visible front walls + receding roofs, foundations, cast shadows on their own layer, elevation tiers with cliff faces, overlapping trees/props, y-sorting | 9 |
| (art helper) OpenPose ignored poses at 32 px | explained: one art pixel = one latent cell; control through the guide image, 2x-guide test, canny/lineart, IP-Adapter for style only | 4 |

### 0.1 Juzo's art direction (latest, overrides older style notes)
- **TOWN = "dark fantasy Stardew Valley"**: 3/4 top-down depth and richness (cliffs and terraces,
  layered trees, detailed varied buildings, fences, crops, paths, small lively villagers) in a dark
  palette (dusk, stone, old wood, lanterns, walled prison town). Recipe: section 9 + 0.3.
- **DUNGEON + MONSTERS = Gen 2-3 handheld monster-battle sprites, heavily fantasy**: bold dark
  outlines, few colours per sprite, dithering for texture, dynamic expressive poses, strong silhouettes,
  big personality; mythic creatures, not cute pocket animals. Recipe: sections 8, 10 + 0.2.
- **Style only.** Never copy Pokemon or Stardew designs, characters, layouts or tiles (Nintendo /
  ConcernedApe IP). Prompts never name those games or their creatures (it pulls the model toward their
  designs); use descriptive words. Never use LoRAs or references trained on their sprites.

### 0.2 Look recipe: "handheld battle sprite" (monsters, dungeon)
What defines the look (from the platform's limits, which artists still imitate):
- Gen 3 (GBA) battle sprites: 64x64, 4 bits per pixel = a 16-colour palette whose first entry is
  transparent, so **15 visible colours** [V ROM-hacking guide on PokeCommunity; U as a general rule].
  Gen 2 (GBC) sprites had about 4 colours [U]. So the look = **8-15 colours incl. outline**, not 20+.
- Bold dark outline all around; inner contour lines in the darkest step of the local ramp (not black);
  2-4 step ramps per material; **ordered/checker dithering** only in transition bands (fur, stone,
  shading of big flat areas); a dynamic pose (leaning toward the viewer, limbs out, mouth open) and a
  clear silhouette at thumbnail size; one strong accent colour.
- Our size rule stays: 32x32 art px body at 2x (68x68 file) so heroes and monsters share one pixel
  density (the audit's #1 problem). This is chunkier than Gen 3's 64 px at 1x, close to Gen 2 density.
  If Juzo wants Gen 3 detail, the alternative is a 48x48 art px body (100x100 file at 2x): see Q5.

Settings:
- Palette budget per monster **10-14 colours + outline** (QC enforces); per dungeon background layer
  6-10.
- Prompt words (no IP names): `retro handheld JRPG battle sprite, 16-color GBA-era pixel art, bold black
  outline, limited palette, dithered shading, dynamic action pose, facing the viewer, mythic creature`
  (+ the creature description). Negative add: `cute, chibi animal, pastel, soft shading, gradient`.
- Cleanup adds `*dither_bands` (6.5) after `ramp_snap`; QC allows checker cells only inside dither bands.
- LoRA: keep pixel-art-xl; IP-Adapter = our own approved anchors (8.2). Optional later: train our own
  LoRA on 30-50 approved Solaria monsters (kohya sd-scripts says SDXL LoRA training fits 8 GB with
  U-Net-only training, gradient checkpointing, cached latents/text outputs, 8-bit optimizer or
  Adafactor, dim 4-8 (10 GB recommended) [V via the sd-scripts SDXL doc summary]; one user calls 8 GB
  "pretty tricky" [U]).

### 0.3 Look recipe: "dark fantasy farm-town" (town)
What defines the look [U craft + SLYNYRD/blakecrosley V where marked in 9]:
- 16x16 art px tiles (Stardew's world tiles are mostly 16x16, NPCs 16x32 [V forum posts of modders]);
  our town at 2x display -> 32x32 file tiles. Villagers ~16x24-32 art px (the chibi hero walkers fit).
- Depth from **cliffs/terraces** (tall stratified faces, grass/stone lip on top, shadow at the base),
  **big tree canopies** (3x3-tile crowns over 1-tile trunks, overlapping in rows), **buildings** with
  detailed roofs over short front walls, **fences, crops, paths** with clean edges, props everywhere.
- Colour: rich but dark: dusk blue-violet shadows, desaturated greens, warm lantern and window light as
  the only bright accents; no outline on ground tiles, dark (not black) outlines on objects [U].
- Prompt words: `cozy farming RPG town tile art, top-down three-quarter view, 16x16 tiles, dark fantasy,
  dusk, stone and old wood, lanterns, detailed roofs` (no game names).

### 0.4 LoRA options (commercial use)
| LoRA | License | Use |
|---|---|---|
| nerijs pixel-art-xl | OpenRAIL-M [V] | default |
| artificialguybr PixelArtRedmond (SDXL; prompt "Pixel Art, PixArFK") | OpenRAIL-M [V] | A/B test for monsters |
| lizozom pixel-icon-lora-sdxl | Apache-2.0 but trained on undisclosed "third party's artwork" [V] | avoid (provenance) |
| any LoRA trained on Pokemon/Stardew sprites (e.g. SD1.5 trainer-sprite LoRAs) | various | never (IP) |
| our own LoRA on approved Solaria sprites | ours | after ~30-50 approved assets |

---

## 1. The twelve things to know first

1. **Battle camera = behind the hero.** [V] `sprites.gd hero_back()` ("the hero seen from behind (0.13
   back-to-front fights)", `dir = "up"`); screenshots `shots/room3d/fight.png`, `shots/boss/boss_1.png`.
   Juzo asked for "three-quarter from behind". Hero priority: **back-3/4**, then front portrait (menus),
   then side (only if the gear page keeps a full figure). Monsters face the camera.
2. **Stack: SDXL base + pixel-art-xl + fp16-fix VAE, IP-Adapter plus ViT-H, xinsir ControlNets.** All
   allow selling the game [V, section 2.3] and fit 8 GB [V README]. Nothing newer is ready to replace it
   here: Z-Image-Turbo is Apache-2.0 [V] but img2img pixel conversion failed in a public test and its
   LoRA loading needs a custom loader [V lilting.ch]; FLUX-dev is non-commercial [U].
3. **The pixel LoRA's ~8 px cell equals SDXL's latent cell.** pixel-art-xl: "Downscale 8 times ...
   Nearest Neighbors" [V card]; SDXL's VAE downsamples 8x [U, standard]. So **one art pixel = one latent
   cell.** A 32 px hero is a 32x32 latent: OpenPose limbs are 1-2 cells wide, which is why ControlNet
   ignored the arm [L v2 README]. At this scale the guide image is the control.
4. **Draw at final density with a "miniature" subject; don't shrink big renders.** Big figures shrunk
   3x "turn to mush: faces disappear"; small figures at true density keep "real 1-pixel eyes" [L].
   pixie.haus advises the same: tiny subject on a larger canvas, then trim (not downscale) [V]. Test a
   **2x guide with 2:1 downscale** only when a pose needs ControlNet (4.2).
5. **Consistency = code-drawn guides + img2img.** One mannequin per build/view puts every race and outfit
   in the same box [L `f_o2.json`, boxes within +/-2 px]. Denoise 0.5 races, 0.55 outfits [L v2].
6. **Heroes animate as a part-cut puppet** (arm+weapon rotate at the shoulder with RotSprite, rows shift
   for breathing) [L v2 `hero_anim.gif`]. AI per frame cannot keep recolourable layers aligned; video
   models need 24 GB (Wan 2.2 TI2V-5B [V card]).
7. **Monsters need one still each**: the game already animates monsters by row shifts (idle, windup,
   strike, hit, kneel) [V `sprites.gd POSES/poses_for`]. 144 redraws = 144 stills (+ optional boss frames).
8. **Make 3 anchor monsters, get Juzo's yes, then use them as the IP-Adapter reference for all others.**
   The old Zone 1 DCSS sprites stop being the bar (Juzo rejected the current monsters).
9. **Depth is built by code layers around AI sprites.** The town concept was flat because AI buildings sat
   on a noisy flat ground with no shadows, foundations, elevation or overlap [L `town_concept_dusk.png`].
10. **Backgrounds fit SDXL exactly:** 1344x768 / 8 = ~168x96 art px; target 160x90 art px (320x180 at
    2x) [V audit]. Make them as **separate depth layers** from a code-drawn label/value sketch.
11. **Tiles, icon sets and FX are code-first**; AI supplies details (decals, references).
12. **Automated QC on every asset** (palette, outline, hard alpha, size, 2x flatness, colour budget,
    contrast vs zone, frame jitter) before Juzo or Fable sees a contact sheet.

---

## 2. Tools, models and licenses

### 2.1 Installed [V README + model folders]
SDXL base 1.0; pixel-art-xl; sdxl-vae-fp16-fix; xinsir openpose SDXL; xinsir canny SDXL v2;
ip-adapter_sdxl_vit-h + ip-adapter-plus_sdxl_vit-h; CLIP-ViT-H-14-laion2B. The IP-Adapter node pack was
used in the v2 run (style transfer 0.3/0.6) [L]; a copy also sits in `C:\ai\staging\ComfyUI_IPAdapter_plus`.
ComfyUI has a native BiRefNet `LoadBackgroundRemovalModel` / `RemoveBackground` node [V
`comfy_extras/nodes_bg_removal.py`] (weights not downloaded; flood fill works on white backgrounds [L]).

### 2.2 Worth adding (free)
| Add | Why | Size | When |
|---|---|---|---|
| xinsir controlnet-union-sdxl-1.0, promax file | depth, lineart, anime lineart, scribble, tile, inpaint in one model; native `SetUnionControlNetType` exists [V] | 2.51 GB [V repo] | week 1 (backgrounds, buildings) |
| lcm-lora-sdxl | 4-8 steps, CFG 1-2 [V card]; pixel-art-xl card: "8 steps and guidance scale of 1.5, 1.2 Lora strength" [V] | ~400 MB [U] | optional, big candidate batches |
| spinagon ComfyUI-seamless-tiling | circular padding for tileable textures [V README]; SDXL not stated; open issue "Not working at all" [V title] | small | optional, test first |

Avoid: BRIA RMBG-2.0 (paid commercial agreement [V rembg page]); FLUX.1-dev; unlicensed Civitai models.

### 2.3 License table (copy into `claude/licenses-audit.md`)
| Item | License | Outputs in a sold game | Mark |
|---|---|---|---|
| SDXL base 1.0 | CreativeML Open RAIL++-M: "Licensor claims no rights in the Output"; Attachment A use restrictions (minors, harassment, discrimination, misinformation, ...) don't touch a fantasy game | yes | [V] |
| pixel-art-xl | CreativeML Open RAIL-M | yes | [V] |
| sdxl-vae-fp16-fix | MIT | yes | [V] |
| xinsir openpose / canny / union | Apache-2.0 | yes | [V] |
| h94 IP-Adapter | Apache-2.0 | yes | [V] |
| CLIP-ViT-H-14 laion2B | MIT | yes | [V] |
| lcm-lora-sdxl | openrail++ | yes | [V] |
| ComfyUI, IPAdapter_plus, seamless-tiling | GPL-3.0 tools on the PC, not shipped | GPL binds the tool code, not the pictures [U reading] | [V licenses] |
| proper-pixel-art, spritefusion-pixel-snapper, unfake, rembg | MIT | tools | [V] |
| Z-Image-Turbo, tarn59 pixel LoRA | Apache-2.0 | yes | [V] |

Legal notes:
- US Copyright Office, *Part 2: Copyrightability* (29 Jan 2025): prompts alone don't give enough human
  control to make the user the author; protection needs "sufficient human control over the expressive
  elements"; assistive AI use doesn't remove protection from human-authored parts [V via IPWatchdog and
  Sidley summaries]. Raw AI sprites may be copyable; the edits and the game are Juzo's. Low risk.
- Apple: no AI-art rule in the 16 Oct 2026 guidelines [V in research-2.1].
- Keep `art/AI_SOURCES.md`: per file model, LoRA, seed, prompt, workflow JSON, cleanup settings (raws are
  already logged in `C:\ai\art_raw\log.jsonl` [L]).

---

## 3. Fixed targets (from the game)

| Asset | File size | Grid | Count | Source |
|---|---|---|---|---|
| Monster / pet | 68x68 (32x32 body + outline ring, 2x) | 2x | 144 + 20 | `art_style.gd` [V] |
| Giant boss | 68x132 | 2x | 5 | [V] |
| Hero | 2x; v2 window 40x42 art px [L] | 2x | 12 races, 13 hair, gear | D4 [V] |
| Props / consumables | 32x32 | 1x | 28 + 13 | PROP_SIZE [V] |
| 2D dungeon tiles | 32x32 | 1x | ~80 | critique [V] |
| 3D hall textures | 32x32 (doors 32x48) | 1x | 32 | audit [V] |
| Zone backgrounds | 320x180 | 2x (160x90 art px) | 10 zones x 3+ | critique [V] |
| Gear icons | 32x32 art in the 44x44 frame | 1x | ~35 | ICON_FRAME, critique [V] |
| FX | ~48 px footprint, alpha 0/64/128/192/255 | 2x | 20 | critique, FX_ALPHA [V] |
| Town | top-down 3/4, dusk; helper's layout 880x440 art px [L] | 2x | 12 buildings x 3 levels + plots | brief [V] |

Rules [V `art_style.gd`]: 74-colour palette (`art/palette.gpl`), outline `#0e0812` (outside the palette),
OKLab nearest. Recolour keys [V `art_info.gd` "keys"]: skin (255,0,0)..(195,0,0), hair (0,255,0)..(0,195,0),
material (255,255,0)..(195,195,0), trim (255,0,255)..(195,0,195), eye (0,0,255); 5 steps light->dark.
Battle animation names [V `lpc.gd`]: `combat_idle`, `slash`, `thrust`, `spellcast`, `shoot`, `walk`.

---

## 4. Small sprites: the 32 px problem

### 4.1 Facts
- pixel-art-xl cells are ~8 canvas px; period/phase drift a little per image (8.0 px, phase 7 on every
  image of one run) [L].
- SDXL denoises a latent 8x smaller than the image [U standard] -> one art pixel per latent cell.
- ControlNet features act at latent resolution; a 32-cell figure gives a skeleton almost no area, and
  OpenPose cannot tell front from back [U craft]. xinsir's card warns the default pose drawer is
  unstable and supplies a replacement [V]. Pose estimators fail on sprite proportions (big heads) [V
  Sprite Sheet Diffusion paper].
- Shrinking a big render 3x destroys faces [L]; density-correct generation keeps 1 px eyes [L].
- A commercial pixel tool (PixelLab) does per-frame AI animation with skeleton keypoints + init image +
  inpainting at <= 128 px canvases [V docs page], i.e. the same "guide image + inpaint" control, with a
  model trained on sprites. Generic SDXL needs the guide even more.

### 4.2 What to do, best first
1. **Guide image at density (current method).** The guide's values, pose and proportions are the
   control. Paint clear value separation (skin mid, cloth dark, hair darkest, metal light), exact pose,
   exact proportions. Denoise 0.45-0.6.
2. **2x guide + 2:1 downscale** for poses method 1 can't carry: guide at 64 px (512 canvas px = 64 latent
   cells), img2img + canny/lineart ControlNet with edges drawn from the guide (strength 0.5-0.6, end
   0.6), prompt `thick outline, big simple shapes`, then `shrink_mode` 2:1 with ink preservation and rule
   pixels for faces. A/B on 3 heroes before adopting [U].
3. **IP-Adapter for style only**: `style transfer` "only works with SDXL ... transfer only the style of an
   image but not its content" [V NODES.md]. 0.3 kept the pose; 0.6 darkened look C [L]. Use 0.3-0.5.
4. **Inpaint one bad part** (G5) at density rather than re-rolling.
5. **Rule pixels** (eyes, ear tips, tusks, glints) per race/monster, 3-5 px, after palette mapping [L
   `FACE` table].

---

## 5. ComfyUI API graphs

POST `{"prompt": graph}` to `http://127.0.0.1:8188/prompt`; upload with `POST /upload/image` (multipart
field `image`); poll `/history/{id}`; fetch with `/view` [V `server.py` routes]. Node names exist in
ComfyUI core [V grep]; `IPAdapter*` come from ComfyUI_IPAdapter_plus [V source]. The helper's
`artjob_gen2.py` already runs img2img + IP-Adapter jobs from JSON [L].

### G1 txt2img (`C:\ai\workflows\pixel_sdxl.json`)
`4 CheckpointLoaderSimple -> 10 LoraLoader(pixel-art-xl 1.0/1.0) -> 6/7 CLIPTextEncode -> 5
EmptyLatentImage 1024 -> 3 KSampler -> 8 VAEDecode (11 VAELoader fp16-fix) -> 9 SaveImage`. Ideas only.

### G2 img2img from a guide (workhorse)
```json
"20": {"class_type": "LoadImage", "inputs": {"image": "guide_sheet.png"}},
"21": {"class_type": "VAEEncode", "inputs": {"pixels": ["20", 0], "vae": ["11", 0]}},
"3":  {"class_type": "KSampler", "inputs": {"seed": 731, "steps": 24, "cfg": 7.0,
       "sampler_name": "euler_ancestral", "scheduler": "normal", "denoise": 0.5,
       "model": ["18", 0], "positive": ["6", 0], "negative": ["7", 0], "latent_image": ["21", 0]}}
```
(The helper's working values [L]; `model` = 18 with IP-Adapter, else 10.)

### G3 = G2 + IP-Adapter + ControlNet
```json
"16": {"class_type": "IPAdapterModelLoader", "inputs": {"ipadapter_file": "ip-adapter-plus_sdxl_vit-h.safetensors"}},
"17": {"class_type": "CLIPVisionLoader", "inputs": {"clip_name": "CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"}},
"12": {"class_type": "LoadImage", "inputs": {"image": "style_ref.png"}},
"15": {"class_type": "ImageScale", "inputs": {"image": ["12", 0], "upscale_method": "nearest-exact", "width": 448, "height": 448, "crop": "center"}},
"18": {"class_type": "IPAdapterAdvanced", "inputs": {"model": ["10", 0], "ipadapter": ["16", 0], "image": ["15", 0], "clip_vision": ["17", 0],
       "weight": 0.4, "weight_type": "style transfer", "combine_embeds": "concat", "start_at": 0.0, "end_at": 1.0, "embeds_scaling": "V only"}},
"13": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": "xinsir-canny-sdxl-1.0-v2.safetensors"}},
"22": {"class_type": "LoadImage", "inputs": {"image": "guide_edges.png"}},
"14": {"class_type": "ControlNetApplyAdvanced", "inputs": {"positive": ["6", 0], "negative": ["7", 0], "control_net": ["13", 0],
       "image": ["22", 0], "strength": 0.6, "start_percent": 0.0, "end_percent": 0.6, "vae": ["11", 0]}},
"3":  {"class_type": "KSampler", "inputs": {"...": "as G2", "model": ["18", 0], "positive": ["14", 0], "negative": ["14", 1]}}
```
Weight types [V source]: `linear, ease in, ease out, ease in-out, reverse in-out, weak input, weak output,
weak middle, strong middle, style transfer, composition, strong style transfer, style and composition,
style transfer precise, composition precise`. The pack is "maintenance only" since 2025-04-14 [V]: pin
ComfyUI once it works. Union ControlNet: `ControlNetLoader(promax) -> SetUnionControlNetType(type) ->
ControlNetApplyAdvanced` [V node; read the node's type list for exact strings, U]. Draw edge/depth
images in code from masks (1 art px = 8 canvas px lines on black); no detector needed.

### G4 tileable texture
Preferred: procedural (10.3). AI option: `Seamless Tile -> KSampler -> Make Circular VAE -> VAEDecode ->
Offset Image` (spinagon) [V names; SDXL untested]. Fallback: generate, wrap-offset by half, inpaint the
cross seam with G5.

### G5 inpaint one region
`LoadImage(+mask) -> VAEEncodeForInpaint(grow_mask_by 8) -> KSampler(denoise 0.8-1.0) -> VAEDecode ->
ImageCompositeMasked` [V names]. Re-clean the whole sprite afterwards.

### 5.1 Defaults
euler_ancestral / normal, 24 steps, CFG 7, LoRA 1.0/1.0, 1024x1024 (backgrounds 1344x768), batch 1 [L].
~12-13 s per warm 1024 image [V README]; budget ~20 s with IP-Adapter + one ControlNet [U].
`--lowvram` "doesn't do anything if dynamic vram is enabled" in this ComfyUI [V `cli_args.py`]; 16 GB
system RAM is the real limit: one ControlNet at a time, close Godot while generating.

### 5.2 Prompts
Prefix: `pixel art, dark fantasy, muted cold desaturated colors, thick dark outline, crisp pixels,`
| Asset | Template ([L] = the helper's working one) |
|---|---|
| Hero back-3/4 | `tiny pixel art battle sprite, chibi {X}, seen from behind, three-quarter rear view turned up and to the right, side of the face and ear visible, full body, ..., plain white background, 32x32 sprite` [L] |
| Hero portrait | `... chibi {X}, front view, head and shoulders, ...` |
| Monster | `tiny pixel art battle sprite, retro handheld JRPG battle sprite, 16-color GBA-era pixel art, {creature}, mythic, dynamic action pose, facing the viewer, bold black outline, dithered shading, plain white background, 32x32 sprite` (never game or creature names from existing IP) |
| Building | `top-down three-quarter view rpg game building sprite, {building}, dark fantasy village at dusk, warm glowing windows, single building isolated on a plain white background, whole building visible` [L] + `visible front wall, roof seen from above, stone foundation` |
| Background | `dungeon interior, {zone}, {far wall / pillars / foreground arch}, dark, atmospheric, no characters` |
| Icons / decals | `pixel art game item icons sheet, {items}, each drawn diagonally, low resolution, few colors, thick dark outline, plain white background, dark fantasy rpg inventory` [L] |

Negative [L]: `3d render, realistic, photo, blurry, text, watermark, signature, multiple characters,
cropped, cut off, frame, border, scenery, landscape, ground shadow, gradient background` (+ `face, front
view` for backs; + `characters, person` and minus `scenery, landscape` for backgrounds).

---

## 6. Cleanup (extends `C:\ai\scripts\pixlib.py` [L]; * = new)

```
def clean(png, kind, window=None):
    im   = remove_bg(load(png))                 # flood fill white bg + grey drop shadow from the border
    grid = find_grid(im)                        # periods 5-14 step 1/8; largest within 3% of best
    if not (7 <= grid.px <= 9 and abs(grid.px - grid.py) < 0.4): return REJECT    # see 6.1
    nat  = grid_sample(im, grid)                # median of each cell's centre half -> ~128x128 true px
    parts = [nat.crop(window)] if window else figures(nat)   # heroes: fixed window keeps layers aligned
    for f in parts:
        f = keep_largest(f, 0.05); f = strip_shadow(f)
        f = drop_lone_pixels(f); f = smooth_noise(f)          # [L] stray px; px unlike all 4 nbrs -> their colour
        if f.h > target_h(kind): f = shrink_mode(f, height=target_h(kind))   # palette first, per-cell mode, ink >= 30% wins
        f = cool_grade(f)                                     # [L] slight cold shift
        f = quantize(f, BUDGET[kind])                         # OKLab nearest in the 74 colours, cap count
        f = *ramp_snap(f, kind)                               # 6.2
        f = *fix_jaggies(f)                                   # 6.3
        f = *apply_rule_pixels(f, table)                      # eyes/ears/glints [L FACE]
        f = outline(f); f = rim(f)                            # #0e0812 ring, top-left rim
        if not *qc(f, kind): continue                         # section 12; reject, don't patch
        yield place(f, canvas, feet_row, scale=2)
```
Colour budgets (outline excluded) [U start values; pixie.haus suggests 8 for sprites <= 64 px [V]]: hero
composite <= 20 [L], each layer <= 6, monster 10-14 (handheld look, 0.2), building 16-24, background
layer 6-10 (whole <= 32), tile 6-10, icon 8-12, FX 4-6.

### 6.1 Grid failures
Signs: period ~4 or ~16, x/y mismatch, low score. Then: (1) `proper-pixel-art` (Canny + probabilistic
Hough + autocorrelation, validated by in-cell variance) [V repo]; (2) unfake runs-based GCD [V]; (3) force
8.0, search phase only; (4) reject.

### 6.2 *ramp_snap
Nearest-colour mapping mixes hues inside one material (banding, speckle). Instead:
```
for each 4-connected region of similar OKLab hue (~25 deg; greys grouped by L only):
    ramp = palette/material ramp with the nearest hue (art_info "materials", palette.gpl)
    map the region's L quantiles onto 3-5 ramp steps, dark -> light, keeping order
hero layers: same, but onto the KEY ramps (skin/hair/mat/trim/eye) so Sprites._recolor works;
    straps/rivets stay fixed palette colours (tools/art_gear.py letters x, k [V])
```
OKLab is the usual space in current quantizers [V zenquant/quantette docs]; no sprite-specific evidence
favours CIEDE2000 (none found).

### 6.3 *fix_jaggies
On silhouettes and long internal lines: runs along an edge should change monotonically (1,1,2,2,3, not
1,3,1,2); fill or clear single-pixel notches; unfake's `jaggy` cleanup removes isolated diagonal pixels [V].

### 6.5 *dither_bands (handheld look; monsters and dungeon only)
Dithering must look deliberate: regular patterns, only between two neighbouring ramp steps.
```
for each region already snapped to a ramp:
    for each pair of adjacent steps (a darker, b lighter) that touch along a long boundary:
        band = pixels within 1-2 px of the boundary (wider on big flat areas >= 64 px)
        in the band, use the pre-snap OKLab L: t = (L - L_a) / (L_b - L_a)
        if 0.35 < t < 0.65: pixel = b if (x + y) % 2 == 0 else a          # 50% checker
        elif 0.2 < t <= 0.35 and (x % 2 == 0 and y % 2 == 0): pixel = b   # 25% pattern (sparse)
never dither: outlines, faces/eyes, regions smaller than 12 px, 1-px lines, the hero (heroes stay clean)
```
QC: checker cells allowed only inside recorded bands; outside them the old <5% rule applies.

### 6.4 Second opinions
spritefusion-pixel-snapper (`--palette hex,...`; no Windows release, `cargo install`) [V]; ppa (`ppa in.png
-o out -c 16 -t`) [V]; unfake (`--palette file --cleanup morph,jaggy`) [V].

---

## 7. Heroes: dark chibi, back three-quarter (MOST DEPTH)

### 7.1 Target look
- **Head of look C, armour of look B** [V critique]. From `v2/01_variants_ABC.png` [L]: C has the
  darker, larger chibi head and draugr-tinted shading; B has the slimmer, taller body with readable steel
  plates. Head ~40% of total height [U estimate from the sheet].
- Dark, desaturated skin; muted cloth; each race its own head (not hue swaps); weapons 2 px minimum with a
  highlight; same outline/light on wings, tails, horns [V critique].
- Back-3/4 turned up-right with a sliver of cheek, ear and nose [L]. Race identity lives in that sliver
  (ear shape, tusk, beard edge) and in hair/helmet silhouettes: give it rule pixels.

### 7.2 Guides (mannequin v3)
1. In code, cut C's head (above the neck line) and B's body (below), align at the neck, keep B's hand
   pixel. Repaint as flat value regions (skin mid-grey, cloth dark grey, hair darkest, metal light grey).
2. Builds: `tall` (human, elf, orc, angel, demon, undead, dragonkin, beastkin), `short` (dwarf, goblin)
   as squashed copies (80% height, 108% width worked [L]); check fairy and golem separately (maybe their
   own build).
3. Views: `back34` (battle) and `front` (portraits). Side only if needed (Q3).
4. Animation key poses = the same guide with parts moved by the rig (7.5), rendered grey.
5. Guides at 8x on a white 1024 canvas, 3x3 copies per sheet = 9 candidates per run.

### 7.3 Layers (bottom -> top, back view)
`back_addon` (wings, tail, back part of long hair, cape) -> `body` (race head + skin + underclothes) ->
`legs` -> `feet` -> `chest` -> `hair` -> `helmet` -> `offhand` -> `weapon_arm` (arm + weapon, own layer,
rotates at the shoulder) [L v2 L1-L4]. Layer outline pixels carry alpha 201 and only fill empty space
(current `_stack` convention [V `sprites.gd`]); the composite gets the final outline.

### 7.4 Production
1. **Race bodies** (12): G3, denoise 0.5 [L], IP-Adapter = approved look sheet at 0.3-0.4, seeds 731-733 +
   3 more; prompt names only head features (`elf with long pointed ears, pale grey skin, long silver hair
   tied back`).
2. **Outfits** per class family (warrior plate, mage robe, ranger leather, + rogue/cleric...): on the bald
   human guide, denoise 0.55 [L]; outfit layer = outfit minus head rows minus guide-skin pixels; body
   clipped to the outfit silhouette [L].
3. **Hair** (13) on each bald race body; layer = difference; long styles also feed `back_addon` [V
   `hair_back`: Long, Ponytail, Bun, Braid].
4. **Helmets** (cap, helm, hood, crown); `hides_hair` [V art_info]; fix the helm/hood clipping the
   critique noted by drawing helmets on the guide head, not floating.
5. **Weapons**: icon-sheet prompt [L], diagonal, cleaned; grip pixel + rest angle recorded.
6. **Key ramps** (6.2) on every layer; runtime recolour + stacking stay unchanged.
7. **Rule pixels** per race (ear tip, tusk, beard edge, eye glint) [L].
8. Sheets: races x outfits back view + portraits, next to the 3 anchor monsters on a new dungeon
   background, at game scale and 3x. After Juzo's yes, lock seeds and settings in `AI_SOURCES.md`.

### 7.5 Animation (puppet)
Parts: head(+hair/helmet), torso, weapon_arm(+weapon), other arm, pelvis, left leg, right leg; cuts and
pivots fixed per guide in `rig_<build>_<view>.json`, so every race/outfit animates identically. Torso and
head never rotate (1 px shifts only); arms/weapons rotate with RotSprite; joints gap-filled, then the
composite is re-outlined [L `anim.finish`]. RotSprite (Xenowhirl): 8x upscale with a Scale2x variant that
treats similar colours as equal, optional rotation offset, nearest rotate+downscale, optional restore of
lost single-pixel details [V Wikipedia]. The helper's version is plain 8x nearest + mode downsample [L];
add the Scale2x step if edges look ragged.

| Anim | Frames | ms | Motion (back-3/4) |
|---|---|---|---|
| combat_idle | 4 | 250 (4 fps [L]) | rows above waist 0/1/1/0 px; arm 0/-3/-5/-2 deg [L] |
| slash | 4 | 180/70/110/200 [L] | wind-up +55 deg, body back 1 px; strike -40 deg + lunge up-right + 3-colour smear; follow-through -75 deg; recover [L] |
| thrust | 4 | 150/60/120/180 | pull back 2 px; lunge 3 px up-right with a 1-frame streak; hold; recover |
| spellcast | 5 | 100 | arms rise 2 frames, hold 2 (FX spawns), drop |
| shoot | 4 | 80 | draw, hold, release, recover |
| walk | 6 | 100 | legs alternate 1-2 px, 1 px bob (town/menus) |
| hit | 2 | 80/120 | lean back 2 px + 1-frame white/red additive flash (critique) |
| death | 5 | 120, last held | stagger, kneel, lower, fall (squash rows), lie; then code dissolve |

Craft basis [U tutorial summaries]: longer anticipation and recovery than strike; smears sparingly;
ease in/out; ~12 fps common. Store one PNG strip per layer per animation + JSON (fps, relative
durations, pivot, hand pixel).

---

## 8. Monsters: full redraw of all 144 (MOST DEPTH)

### 8.1 Style bible (write first): handheld battle sprite, mythic (0.2)
- 2x, palette, bold `#0e0812` outline, inner lines in the darkest local ramp step, top-left rim,
  **10-14 colours + outline**, dither bands for fur/stone/scales (6.5).
- **Dynamic, expressive pose**: lunging or rearing toward the viewer (3/4 front, slightly from below
  for bosses), limbs and wings spread to fill the box, mouth/claws open; personality first.
- Feet (or lowest point) on the foot row; body fills >= 24x24 of the 32x32 (no tiny wisps); giants 32x64.
- One silhouette idea per monster, readable as a black shape at 1x; 1 accent colour (eyes, flame,
  gem); flames and glows get a dark core (critique). Mythic, menacing, not cute.
- Original designs from myth (the names are already mythic: draugr, garmr, kelpie...); never base a
  guide on a known Pokemon.
- Per-zone material ramps (Catacombs bone/teal-grey, Hushwood moss/bark, Gilded Spire tarnished
  gold/dark bronze, Cinder Abyss ember/black, ...).

### 8.2 Anchor monsters (first)
Three body types: humanoid (draugr), beast (garmr), spirit (banshee). G3: guide = a **new dynamic-pose
silhouette** painted in code (4 values; the old sprite only as an idea reference, since Juzo wants new
poses), 8x, 3x3 sheet; prompt with the 0.2 words;
IP-Adapter = approved hero sheet at 0.3 (monsters share the heroes' rendering); denoise 0.6-0.7; 6 sheets
each (54 candidates). After Juzo's yes they become `ref/monster_anchor.png`, the IP-Adapter reference for
every later monster (0.35-0.5).

### 8.3 Per-monster recipe
| Case | Guide | Denoise | ControlNet |
|---|---|---|---|
| Good idea, bad pixels (most) | old sprite posterised, re-posed in code (lean, limbs out) for a dynamic pose, 8x | 0.62-0.7 | none |
| Off-genre / unreadable (Grendel, Forge Sentry, Stoneguard, Sun Golem, Gilded Lion, calamity_3/5/6, Owlwraith, wisps, Pixie Swarm, Kelpie) | new grey silhouette blob drawn in code from a short description | 0.72-0.8 | canny from the blob at 0.4 if the shape drifts |
| LPC-built humanoids (Cinder Miner, Black Annis, Mirror Nymph, Fairy Queen, Treasure Goblin) | the hero mannequin in front view + monster prompt | 0.6 | none |
| Giants 68x132 | tall 32x64 guide on 768x1344 | 0.65 | none |
| Zone 8 set | redraw with tarnished gold/dark bronze; stopgap recolour (8.5) | | |

Per monster: one-line description in `monsters.csv` (id, zone, body type, silhouette words, accent) ->
4 sheets (36 candidates, ~1.5 min) -> auto clean + QC -> top 6 on a sheet with anchors and hero at game
scale -> pick -> rule pixels (eyes) -> bake rules (`tools/bake_art.gd`: size, outline, hard alpha) -> feet
row measured by `Sprites.enemy_by_key` [V audit].

### 8.4 Order and time
Zone by zone, bosses first, so Juzo reviews a whole zone at once; ship zones behind an old/new setting
(art plan rule). ~12-15 min per monster [U] -> ~30-36 h. Pets (20) next: one creature per line growing
through 4 stages (critique), same guide scaled per stage.

### 8.5 Zone 8 stopgap recolour (1 h)
```
for each non-outline pixel p (choir_sentinel, cherub, boss_archon_valeth, boss_seraphiel, eye_of_judgement):
    if chroma(p) < 0.06 or p is pastel: p = GOLD_BRONZE[index_by_oklab_L(p)]   # c8a060, 9a7040, 6a4a28 + darkest
    else: darken accents one ramp step
```
`c8a060`, `9a7040`, `6a4a28` are in the palette [V].

---

## 9. Town: depth in top-down 3/4 (MOST DEPTH)

### 9.1 Why the concept looked flat, and the fix for each cause
Seen in `town_concept_dusk.png` and `v2/13_town_phone_market_dusk.png` [L]; compared with Juzo's
reference `art_refs/town_ref.png` (timber-framed front walls under big receding roofs, clean road edges,
fenced plots, dense props, overlapping tree clusters, a castle wall with top and front faces) [L].

| Flat because | Depth cue | How |
|---|---|---|
| buildings read as front elevations on a map | **3/4 projection**: ~45 deg from above, ~3/4 of roof and facade visible; facade foreshortened, roof angles kept; roof slab tilted toward the viewer takes the upper half or more of the footprint; eaves overhang a few px [V SLYNYRD via blakecrosley summary] | block-out guides with separate roof (top) and wall (bottom) value bands + prompt |
| no ground contact | **foundation + contact line**: 1-2 px darker plinth, 1 px dark line at wall/ground | code from the building mask |
| no cast shadows | **one light, short shadows on their own layer**: subtle and short so they don't clash; separate layer so a sprite works on any ground [V SLYNYRD]; at most one tile, to the right and 1-2 px down (blakecrosley's rule after Emerald [V]) | code: mask offset away from the light, filled with the ground's ramp 1-2 steps darker, not black |
| noisy uniform ground | **calm ground, value hierarchy**: 2-3 value patterns, paths lighter than grass, buildings carry the detail; clean 1 px path borders | procedural ground tiles (10.3 method), not AI noise |
| everything at one height | **elevation tiers**: raised plaza/terraces with a darker vertical **cliff or retaining-wall front face**, lighter top surface, 1 px lit lip, cast shadow below; "the lighter surface is necessary and not sufficient" (all three cues together) [V Tiny Swords tilemap guide summary] | code height map 0/1/2; faces where a higher tier meets a lower one toward the viewer; stairs where roads cross |
| props and trees float | **overlap + y-sort**: trees in staggered overlapping rows [V SLYNYRD]; sprite tops may overlap what is behind, foundations stay intact [V blakecrosley]; walkers pass behind | Godot `y_sort_enabled`: "higher Y position rendered in front" [V docs]; origins at feet |
| sparse | **clutter around buildings**: crates, barrels, fences, lamps, signs, carts, gardens, wells; empty lots fenced | 3x3 prop sheets (G2) placed by the layout script |
| one flat light | **dusk light**: warm windows and lamps with hard-edged light pools 2-3 ramp steps lighter, cool shadows | baked light-pool layer + a few PointLight2D torches |
| equal heights | **height variety**: two-storey guild, church spire, low stalls, towers | block-out sizes per building |

### 9.1b Farm-town richness (Juzo: "dark fantasy Stardew Valley", 0.3)
Grid: 16x16 art px tiles (32x32 files at 2x). Recipes for the pieces that carry that look:
- **Cliffs/terraces (procedural autotile)**: a tier edge facing the viewer gets a face 1-2 tiles tall:
  2-3 horizontal strata bands (stone ramp, darkest at the bottom), vertical cracks every 5-9 px, a 2-3 px
  grass/stone **lip** overhanging the top edge with a 1 px lit rim, a 1-2 px dark **base shadow** on the
  lower ground; side edges get a narrow face; inner/outer corners as autotile pieces (a 47-tile blob set
  or a simpler 16-tile set, generated from the same rules) [U craft; elevation cues V Tiny Swords].
  Stairs cut into faces where paths cross tiers.
- **Trees**: AI sprite sheets of 3-4 species (dead oak, black pine, willow, gnarled apple) at 48x64 art px
  (3x3-tile crown + trunk); canopy split into a top layer drawn above walkers and a trunk layer
  y-sorted, so villagers walk behind crowns; place in staggered overlapping rows; colour-swap variants;
  baked contact shadow ellipse on the ground layer.
- **Buildings**: as 9.3, but richer: shingle/slate roofs with 2-3 tone rows, chimneys, dormers, porches,
  hanging signs, flower boxes with dead flowers, stone footings; every building a different footprint.
- **Fences, crops, paths**: procedural autotiles: wooden/iron fences (posts every 16 px, 2 rails),
  crop rows (pumpkins, cabbages, nightshade) as small 16x16 sprites, paths with 1 px darker borders and
  scattered pebbles; garden plots fenced.
- **Props**: lanterns, barrels, crates, carts, wells, gravestones, scarecrows, laundry lines, noticeboard:
  3x3 G2 sheets at 16-32 art px.
- **Villagers**: the hero puppet system with townsfolk outfits (front/back/side walk cycles, 4-6 frames),
  idle chatter loops, a few with tasks (sweeping, drawing water).
- **Dark palette**: ground ramps desaturated and dark (grass `566a56`/`7f9478`-type greens, stone greys
  `545d70`..`a8a8ba`, wood browns), sky/shadow tint blue-violet; warm accents only for lights.

### 9.2 Projection contract (put in the art bible)
- Light from the top-left (matches the sprite rim) [U choice; SLYNYRD: usually a top corner [V]].
- No visible side walls unless a building is turned; every building obeys one projection (inconsistent
  perspective is very visible on man-made objects [V SLYNYRD]).
- Storey = 16 art px of front wall; roof depth >= wall height; eaves 2 px each side; 3 px dark band under
  the eave. (Emerald at 16 px tiles: storey 32 px, roof 2-3 rows; blakecrosley's forge rules: 2 px eaves,
  3 px band [V]; scaling to our grid is [U].)
- One shadow length for every object [V blakecrosley summary of SLYNYRD].

### 9.3 Building recipe
1. **Block-out guide** (code): footprint; front-wall band (mid value) with door/window rectangles (dark /
   lit); roof band (ridge line, material value); chimney; foundation strip; size by importance. 8x on white.
2. G3: denoise 0.6-0.65; prompt [L] + projection words; IP-Adapter = first approved building at 0.4;
   union `lineart` from the block-out edges at 0.5 if the roof drifts.
3. Clean (`clean_building` [L]), budget 16-24; outline: test full `#0e0812` vs selective (dark only
   against empty ground, darker neighbour shade inside; blakecrosley rule [V]); Juzo picks.
4. **Upgrades L2/L3**: img2img from approved L1, denoise 0.35-0.45, prompt additions (`second floor,
   banners, iron lanterns, slate roof`), IP-Adapter = L1 at 0.6; palette locked to L1 + 2 accents.
5. Shadow, light-pool and window-glow layers come from masks (code), never from AI.

### 9.4 Terrain and layout
1. Layout script: road graph, plaza, river + bridge, wall ring, building slots, 2-3 fenced empty lots
   (brief [V]); keep the helper's ~880x440 art px swipe town [L].
2. Height map 0/1/2 (plaza +1, church/keep +2); cliff faces, lips and shadows per tier; stairs/ramps.
3. Procedural ground tiles (cobble, dirt, grass 2-3 values, water) with autotile edges.
4. Trees: 3-4 AI tree sprites [L pine/oak] in staggered overlapping clusters; colour-swap variants.
5. Draw order: ground -> water -> cliff faces -> shadow layer -> y-sorted buildings/props/trees/walkers ->
   roof-overhang layer (if walkers pass behind) -> light pools -> fog/particles.
6. QC on a 430x932 crop at game scale: go down the 9.1 table item by item.

### 9.5 Animated layers (procedural)
Torches/braziers (4-6 frame flame from the `ember` ramp [V art_info]); chimney smoke (CPUParticles2D,
3 puff sizes, alpha steps); water (3-colour palette cycling [U] or 1 px scroll); banners (per-column 1 px
sine, 6 frames); the Wheel (RotSprite, 8 angles); walkers (hero walk cycles, y-sorted); pets in the pen.

---

## 10. Dungeon: rooms per zone (MOST DEPTH)

### 10.1 Where the dungeon shows
- **2D battle backgrounds** `art/bg` 320x180 (`shots/boss/boss_1.png`).
- **3D low-res halls** (32x32 textures, Godot lights; liked by Juzo [V memory]; `shots/room3d/`).
Both share zone palettes and materials.

### 10.1b Handheld style for rooms (0.2)
Rooms follow the same crisp handheld look as the monsters: few colours per layer (6-10), bold dark
contour lines on architecture edges (pillars, arches, steps), dither bands instead of gradients for fog
falloff and light pools (6.5), simple readable shapes, fantasy architecture per zone (catacomb niches,
root-choked halls, forge galleries, gilded choir lofts). The stage is a flat oval platform/ellipse under
the monster with a 1-2 px dark rim, like classic handheld battle bases [U craft]. Prompt: `retro handheld
JRPG dungeon battle background, 16-color pixel art, bold outlines, dithered shading, fantasy {zone}
architecture, dark`.

### 10.2 Backgrounds with depth (replace all 60; 3+ per zone)
The v2 mock background (flat brick wall + flat floor band) shows the problem [L `02_mockup_B.png`].
Build in:
1. **Layers**: far (back wall, distant arches fading into fog), mid (pillars, alcoves, chains, statues),
   floor (perspective plane, lines converging to a vanishing point in the upper third), near (dark
   foreground silhouettes framing the stage: arch edges, rubble, roots). 4 PNGs per composition.
2. **Atmospheric perspective**: farther layers compressed toward the zone fog colour (fewer values, lower
   contrast); near layer darkest, almost silhouette [U craft].
3. **One warm light pool** (torch/brazier) on mid + floor spill; everything else cool.
4. **Stage**: empty band y 100-150 of 180 + stage ellipse under the monster (critique [V]); low detail there.
5. **Vignette**: edges 1-2 ramp steps darker (hard steps).
Recipe:
1. Code draws a **label map** (far/mid/floor/near) and a **value sketch** at 1344x768.
2. G3: union ControlNet `depth` from the label map (far = dark ... near = light) at 0.5-0.7; init = value
   sketch, denoise 0.75-0.85; zone prompt; IP-Adapter = approved zone 1 composition (once it exists) at 0.3.
3. Clean -> ~168x96 -> fit 160x90 -> **split into layers with our own label map** (no segmentation model)
   -> per-layer budgets (far 8-12, mid 12-16, near 4-6 darks) -> atmospheric compression -> 2x -> four
   320x180 layers + a flattened PNG.
4. Ambient motion between layers: torch flicker on a light layer, slow fog strip between far and mid,
   dust/drips/embers particles in front of mid.
5. Zone 8 dusk interior; zone 6 deep violet night (critique).
Time ~40 min per composition with review [U]; 30 compositions ~20 h.

### 10.3 Tiles and 3D textures (replace ~80 + 32)
Procedural generator first (AI is weak at 32 px tiles [U judgement]; current textures rejected: 565-986
colours, no outlines [V critique]):
```
wall(zone):  blocks 8-12 px wide in staggered rows, 1 px mortar (darkest value); per block base value,
             1 px top-left highlight, bottom-right shadow, 0-2 cracks; decals (moss, stains, roots,
             bones) from an AI decal sheet; wraps on all edges.
floor(zone): flagstones by Voronoi on a torus (wrapping seeds), 1 px gaps, per-stone value jitter,
             2-3 value patterns (critique: readable, not noise).
ceiling:     beams/vaults, darker than walls but NOT near-black (critique: several zones too dark).
variants:    3-4 seeds per kind. Doors 32x48: the current Solaria-drawn doors are the bar.
```
Brick size/contrast reference: kept z0/z5/z7 walls [V critique]. Decals: AI 4x4 sheets (moss, cracks,
skulls, roots) cleaned to 6-10 colours. 3D textures import Lossless (Detect 3D would switch to VRAM
compressed) [V docs].

### 10.4 Props, doors, lighting
Props as 3x3 G2 sheets at 32x32 with outline; traps = floor plates with clear hazard marks; pillar and
altar with a top face + front face (like town cliffs). Godot lights in the halls, baked light pools in 2D,
ambient particles per zone.

---

## 11. Other HIGH items (critique)
- **Item icons** (32x32 in the 44 frame): guide = 4x4 grey silhouettes in 256 px cells (45-degree
  weapons, 2 px shafts; helmets/chest/legs/feet as whole objects); G2 denoise 0.6; 16 icons per image;
  material pixels on the `mat` key ramp; rarity = frame colour + gem tint in code. ~2 h for ~35.
- **FX**: extend `tools/make_fx.gd`: arcs swept over 3-5 frames with 2-3 ramp colours and a dark rim;
  rings with the 5 alpha steps; rising motes; lightning random walk at 2 art px; ~48 px footprint; glow
  by code; keep slash, slash_crit, shatter, poison, nature as the bar [V critique].
- **Consumables, skill icons (24x24 on a uniform plate)**: icon recipe.

---

## 12. Quality control

### 12.1 Automated `qc.py` (writes qc.json; failures are rejected)
| Check | Rule |
|---|---|
| size | exact target |
| palette | non-outline pixels in the palette; outline only `#0e0812` |
| alpha | 0/255 (FX: 5 steps) |
| 2x flatness | all aligned 2x2 blocks one colour (2x assets) |
| outline | closed 4-neighbour ring |
| colours | within budget |
| noise | <= 2% orphan pixels; checker 2x2 cells < 5% outside recorded dither bands (audit metric) |
| IP check | contact sheet reviewed for resemblance to known Pokemon/Stardew designs; reject look-alikes |
| fill | monster body bbox >= 24x24 art px |
| feet | lowest opaque row = foot row |
| contrast | mean OKLab L difference sprite vs zone stage band >= 0.15 [U threshold] |
| light | rim pixels top/left only |
| layers | only key or allowed fixed colours; bbox within 1 px of the guide |
| frames | unchanged parts identical; no palette change between frames |
| depth | background layer mean contrast ordered near > mid > far; every building has a shadow layer |

### 12.2 Human review
Contact sheets at game scale on the real background, next to anchors and hero; 1x thumbnails; GIFs at
game fps; old vs new. Fable reviews before merge (experts.md).

---

## 13. Godot import and setup
- Import Lossless, mipmaps off, Fix Alpha Border on, Premult off; 3D textures Lossless too [V docs].
- `textures/canvas_textures/default_texture_filter=0` is set [V project.godot] (0 = Nearest [U]). Stretch
  `canvas_items` + `expand` [V]; Godot recommends `viewport` + `integer` for pure pixel games [V docs],
  but Solaria's UI is high-res: keep it and scale art by whole numbers in code.
- Heroes: produce the same `anims` dictionary shape as `lpc.gd` so `battle_view.gd` stays unchanged;
  recolour per layer, stack, cache per appearance [V].
- SpriteFrames from strips in code: `add_animation`, `set_animation_speed`, `add_frame(anim, tex,
  duration)` where duration is a relative multiplier (seconds = duration / (fps x speed));
  `set_animation_loop` is deprecated, use `set_animation_loop_mode` [V docs].
- Town: `y_sort_enabled` on the root, origins at feet [V docs]; shadows/light pools as separate Sprite2D
  layers; CPUParticles2D (Compatibility renderer [V project.godot]).
- One runtime shader: hit flash.

---

## 14. Time budget [U]
| Block | Days |
|---|---|
| Setup: union ControlNet, `qc.py`, sheet tool, guide drawer, jobs runner | 0.5-1 |
| Heroes: mannequin v3, 12 races, 4-6 outfit families, 13 hair, helmets, 7 weapons, portraits | 4-5 |
| Hero rig + 8 animations (back-3/4), walk views for town | 2-3 |
| Monsters: 3 anchors + 141 redraws + 20 pets | 6-8 |
| Dungeon: 30 layered backgrounds | 3 |
| Tile/texture generator + ~112 tiles | 1.5 |
| Town: layout/elevation/shadow tool, 12 buildings x 3 levels, props, animation | 4-5 |
| Icons, FX, consumables | 2 |
| Total | ~23-29 working days, spread over Sun-Tue build days |

---

## 15. Risks and fallbacks
| # | Risk | Fallback |
|---|---|---|
| R1 | back-3/4 flips to pure back or front | stronger guide (cheek/ear painted), negative `front view, face`, denoise 0.45 |
| R2 | layers misalign | fixed window crop [L]; reject candidates whose bbox moves > 1 px |
| R3 | style drifts across sessions | locked seeds, anchors as IP-Adapter refs, settings in `AI_SOURCES.md` |
| R4 | 16 GB RAM swapping | one ControlNet at a time, batch 1, close Godot |
| R5 | ComfyUI used by another agent (port 8188) | never stop it; queue or wait |
| R6 | IPAdapter_plus breaks on a ComfyUI update (maintenance mode [V]) | pin ComfyUI; fallback img2img + canny |
| R7 | 144 monsters takes long | zone by zone behind an old/new setting |
| R8 | town still reads flat | go through the 9.1 table on a phone crop; add elevation/shadows before detail |
| R9 | grid detection fails | 6.1 chain; reject |
| R10 | players dislike AI art | cleaned, palette-baked, curated; no App Store disclosure [V]; commissions later for Calamities/title |

---

## 16. First week (each build day ends in one Juzo decision)
| Day | Work | Output / decision |
|---|---|---|
| 1 | `qc.py`, `sheet.py`, guide drawer; mannequin v3 (C head + B body) back-3/4 + front; human/elf/orc/dwarf/goblin bodies + warrior/mage/ranger outfits | hero sheet v3 -> **hero look** |
| 2 | 3 anchor monsters with the hero sheet as style ref; Zone 8 stopgap | anchor sheet -> **monster style** |
| 3 | hero rig + combat_idle/slash/hit + portrait; plug into a worktree test via the `anims` shape | battle mock GIF |
| 4 | dungeon label-map tool + zone 1, 3 layered compositions; tile generator for zone 1 | 430x932 mock -> **dungeon look** |
| 5 | town projection contract, elevation + shadow tool, 3 buildings rebuilt from block-outs, phone crop | **town depth** |
| 6-7 | zone 1 monsters complete; remaining races/hair; Fable review | zone 1 sheet, fix list |

---

## 17. Open questions for Juzo (defaults keep work moving)
- Q1 Monster style: match the new chibi heroes (default) or more realistic?
- Q2 Town pixel scale: 2x like everything else (default).
- Q3 Gear page: front portrait instead of a full side-view hero (default)?
- Q4 Icons: 32x32 art inside the 44 frame (default).
- Q5 Monster size for the handheld look: keep 32x32 art px at 2x (default; one pixel density with heroes,
  Gen-2-like chunkiness) or 48x48 art px at 2x (more Gen-3 detail; needs a bigger canvas and battle layout
  changes)?

---

## 18. Sources
- pixel-art-xl https://huggingface.co/nerijs/pixel-art-xl ; SDXL license https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/blob/main/LICENSE.md ; VAE https://huggingface.co/madebyollin/sdxl-vae-fp16-fix
- xinsir https://huggingface.co/xinsir/controlnet-openpose-sdxl-1.0 , https://huggingface.co/xinsir/controlnet-canny-sdxl-1.0 , https://huggingface.co/xinsir/controlnet-union-sdxl-1.0
- IP-Adapter https://huggingface.co/h94/IP-Adapter ; https://github.com/cubiq/ComfyUI_IPAdapter_plus (README, NODES.md, IPAdapterPlus.py) ; CLIP https://huggingface.co/laion/CLIP-ViT-H-14-laion2B-s32B-b79K
- LCM https://huggingface.co/latent-consistency/lcm-lora-sdxl ; Z-Image https://huggingface.co/Tongyi-MAI/Z-Image-Turbo , https://huggingface.co/tarn59/pixel_art_style_lora_z_image_turbo , https://lilting.ch/en/articles/z-image-pixel-art-conversion
- Wan https://huggingface.co/Wan-AI/Wan2.2-TI2V-5B , https://huggingface.co/styly-agents/Wan2-2-pixel-animate
- Cleanup https://github.com/Hugo-Dz/spritefusion-pixel-snapper , https://github.com/KennethJAllen/proper-pixel-art , https://pypi.org/project/unfake/ , https://github.com/danielgatis/rembg ; Kopf et al. https://johanneskopf.de/publications/downscaling
- Small sprites https://pixie.haus/resources/mastering-the-ai-pixel-art-generator-tips-tricks ; https://arxiv.org/html/2412.03685v2 ; https://www.pixellab.ai/docs/tools/skeleton-animation
- RotSprite https://en.wikipedia.org/wiki/Pixel-art_scaling_algorithms
- Town depth https://www.slynyrd.com/blog/2019/9/18/pixelblog-21-top-down-objects , https://blakecrosley.com/blog/pixel-art-structures-on-iphone , https://pixelfrog-assets.itch.io/tiny-swords/devlog/1138989/tilemap-guide
- Godot https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html , https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html , https://docs.godotengine.org/en/stable/classes/class_spriteframes.html , https://docs.godotengine.org/en/stable/classes/class_canvasitem.html
- Copyright https://www.copyright.gov/ai/ , https://ipwatchdog.com/2025/01/29/part-two-copyright-office-ai-report-says-creative-prompting-doesnt-constitute-authorship/
- Seamless https://github.com/spinagon/ComfyUI-seamless-tiling ; quantizer https://docs.rs/zenquant
- Local: `C:\ai\README.md`, `C:\ai\workflows\*.json`, `C:\ai\scripts\*.py`, `C:\ai\art_work\*`,
  `C:\gamedev\solaria_wt_newart\claude\art_test\README.md`, `v2\README.md`, `v2\01_variants_ABC.png`,
  `v2\02_mockup_B.png`, `v2\13_town_phone_market_dusk.png`, `claude\art_refs\town_ref.png`, ComfyUI source.

## 19. Still unverified
SDXL latent factor (standard, not re-read); exact `SetUnionControlNetType` type strings; spinagon on
SDXL; frame timings (tutorial summaries); contrast and colour-budget thresholds; `default_texture_filter=0`
meaning; 2x-guide quality (needs the A/B in 4.2); town wall/roof pixel numbers scaled to our grid.

---

## Round log
- **Round 1**: read inputs; licenses (SDXL, pixel-art-xl, xinsir openpose, IP-Adapter, IPAdapter_plus GPL
  + maintenance mode); alternative models (Z-Image, FLUX schnell); cleanup tools. Found the battle is
  behind-the-hero, not side view (code + screenshots).
- **Round 2**: animation methods (puppet vs per-frame vs video); Wan 2.2 needs 24 GB; Z-Image i2i test
  failed for pixel conversion; Godot import/stretch docs; rembg/BiRefNet; seamless nodes; union
  ControlNet; LCM LoRA. Fixed: IP-Adapter nodes are a custom pack, not core.
- **Round 3**: SDXL Attachment A and output clause verified; Copyright Office page; critique HIGH list
  turned into recipes. Web tools hit the session limit mid-round.
- **Round 4**: verification against local primary sources only (ComfyUI node names/routes, IPAdapter
  inputs, recolour keys, layer conventions, project settings); first full draft.
- **Round 5** (after reset): verified VAE (MIT), CLIP-ViT-H (MIT), xinsir canny (Apache-2.0), RotSprite
  steps, union promax 2.51 GB, Copyright Office conclusions; fixed: `--lowvram` does nothing with dynamic
  VRAM (draft recommended it); style transfer is SDXL-only.
- **Round 6**: Juzo's round-2 verdict; v2 README, A/B/C, mockups, town sheets and reference viewed.
  Fixed: IP-Adapter already in use (draft said "not installed"); heroes = dark chibi back-3/4 with C head +
  B armour; monsters = full redraw of all 144 (draft: HIGH list only).
- **Round 7**: the 32 px problem (art pixel = latent cell) explains the OpenPose failure; pixie.haus read
  at the source: it says miniature subject + trim, NOT downscale (search summary had it backwards; fixed);
  2x-guide method kept as an A/B test, not a default; PixelLab's skeleton tool checked as evidence.
- **Round 8**: town depth: SLYNYRD top-down objects, blakecrosley's measured Emerald numbers, Tiny
  Swords elevation cues; flat-vs-depth table and projection contract; Godot y-sort verified.
- **Round 9**: dungeon depth: layered backgrounds split by our own label map, atmospheric compression,
  procedural tiles; SpriteFrames duration verified as relative; loop setter deprecation noted.
- **Round 10**: whole rewrite; consistency pass (sizes, budgets, times); first week reordered so each
  build day ends in one Juzo decision; unverified list updated. Not committed.
- **Round 10b** (Juzo's direction update): added the two target looks (0.1-0.4): handheld battle-sprite
  recipe (15-colour Gen 3 limit from a ROM-hacking guide, 10-14 colour budget, bold outlines, dither bands
  algorithm 6.5, dynamic poses, IP rules) and dark farm-town recipe (16x16 tiles, cliff/terrace autotiles,
  layered tree canopies, fences/crops/villagers); LoRA licence table (PixelArtRedmond OpenRAIL-M; icon
  LoRA avoided for provenance); own-LoRA option per sd-scripts 8 GB notes; QC dither + IP checks; Q5.
