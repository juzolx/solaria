---
name: solaria-godot-build
description: Hands-on build notes for Solaria in Godot 4.7.2 - engine changes, Compatibility vs Mobile renderer limits, the low-res 3D room recipe, sprite lighting, game-feel numbers, tweens, phone lifecycle and safe area, the cloud iOS build route, store rules, and how to test safely on Juzo's Windows PC. Read before writing rendering, UI, juice, mobile or export code for Solaria.
---

# Solaria build notes (researched Oct 2026, Godot 4.7.2)

Facts marked (verified) come from official docs or were tested in this project. (unverified) means community sources or untested; check before relying on it.

## Godot 4.7 changes that affect our code (verified, official migration guide)
- An override of a method with a typed return inherits that type and needs an explicit `return` (e.g. `return null`).
- Setting one element of a packed array no longer calls the setter for the whole property.
- Mouse/keyboard device IDs are now `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD`, not `0`.
- CanvasItem lines lost their antialiasing feather and draw thinner: check `draw_line`/`draw_polyline` widths in battle_view.gd and ui.gd.
- `AudioStreamPlayer.area_mask` defaults to none.
- New and useful: `Tween.tween_await(signal)`; `Control.offset_transform_*` moves, rotates or scales a Control visually without breaking its container layout (CSS-transform-like, visual only by default, so hover still works). Use it for button pops, card flips and shake on UI inside containers.
- New: nearest-neighbor filtering for 3D resolution scaling (exact property name not confirmed; it applies to 3D scaling, not 2D).

## Renderer: Compatibility (current) vs Mobile (verified, renderer docs)
Compatibility does NOT have: depth-of-field blur, decals, volumetric fog, SSR, SDFGI/VoxelGI/SSIL, TAA/FXAA/SMAA, MSAA 2D, particle trails, light projectors, PCSS soft shadows, HDR output. It has: depth and height fog, glow, tonemap, adjustments, SSAO, MSAA 3D. Light limit: 8 omni + 8 spot per mesh (shadowed lights use extra passes). Max 2 reflection probes per mesh.
- So: fake depth of field (fog plus darker far layers), no decals (use flat quads with alpha scissor, as the prototype does for moss and rune circles).
- iOS: Forward+ and Mobile run on Godot's native Metal driver (4.4+; 4.7 uses Metal 4 on iOS 26+, else Metal 3). Compatibility uses OpenGL ES there. The 4.7 notes say Mobile now matches or beats Compatibility in some benchmarks. **Decide by testing**: try `rendering/renderer/rendering_method.mobile = "mobile"` on a TestFlight build vs Compatibility. The iOS simulator only runs Compatibility. (Mobile-vs-Compatibility on iPhone: unverified.)

## Low-res 3D room recipe (tested in proto/room3d.gd)
- SubViewport at 208x304, `own_world_3d = true`, `msaa_3d` off, shown through a TextureRect with `TEXTURE_FILTER_NEAREST` at a whole-number scale (2x).
- Materials: `StandardMaterial3D` with `TEXTURE_FILTER_NEAREST`, `uv1_triplanar = true` for walls and floors (32px hall textures tile per world unit).
- Arched doorways: CSGCombiner3D, a CSGBox3D wall minus a CSGBox3D plus a CSGCylinder3D (rotated 90° on X) per door. Works in Compatibility.
- Additive glow (light shafts, mist, runes): `BLEND_MODE_ADD` ignores alpha here, so **the albedo color is the strength** (about 0.03-0.06 x color for a shaft). Unshaded, `CULL_DISABLED`, `cast_shadow` off.
- Mist: a horizontal QuadMesh with a seamless `NoiseTexture2D`, scrolled through `uv1_offset`. Keep it at y≈0.1, because higher layers slice through sprites with a hard line.
- Fireflies and dust: CPUParticles3D with a tiny unshaded billboard QuadMesh.
- Monsters as `Sprite3D` (`ALPHA_CUT_DISCARD`, `BILLBOARD_FIXED_Y`, shaded), plus a soft warm "lantern" OmniLight near the camera, or front faces lit from above read as silhouettes.
- Shadow budget for phones: at most 1-2 shadowed lights. Spot shadows render 1 view, omni shadows 6.
- Pixel camera motion: if the camera moves, render 1px of border and shift the upscaled image by the sub-pixel remainder (voithos/godot-smooth-pixel-camera-demo), or edges shimmer.

## Sprites lit like 3D (tested; Juzo picked this)
- 2D CanvasTexture normal maps do not work on 3D nodes. Use a QuadMesh with a `StandardMaterial3D`: `albedo_texture`, `normal_enabled`, `normal_texture`, `billboard_mode = BILLBOARD_FIXED_Y`, `TRANSPARENCY_ALPHA_SCISSOR`, `quad.center_offset.y = height/2`.
- Generate the normal map from the sprite's shape: chamfer distance to the transparent edge, height = sqrt(distance), normal from neighbor differences (x negated, y as-is), `normal_scale` about 1.6. Cache per monster.
- Voxel extrusion (rejected for now): needs `vertex_color_is_srgb = true`, one even thickness (stepped thickness makes stripes), `CULL_DISABLED`.

## GDScript in this project
- Warnings are errors. Common traps: `:=` from an untyped loop variable or Variant ("Cannot infer the type") needs an explicit type; shadowing members (`t`, `world`); unused locals; integer division.
- Static types make code faster (benchmarks show tens of percent); Packed*Array beats Array[T] for big data.
- Per-pixel work: avoid `get_pixel`/`set_pixel` loops on big images. Use `Image.get_data()`/`PackedByteArray` (see dark_grade.gd) or a shader. Do it once and cache.
- Headless runs: `DisplayServer` returns dummy values; rendering-dependent shots need a windowed run.

## Tweens
- Use `create_tween()` (bound to the node, so it's freed with it). One tween per property: `kill()` the old one before starting another on the same property, or it flickers. Tweens are single-use. `set_parallel(true)` and then `chain()` for grouped steps; `tween_method` for counting numbers; `set_ignore_time_scale`/process mode for UI that runs during hit stop.

## Game-feel numbers (community consensus)
- Hit stop 40-80 ms (longer on kills). Freeze visuals only; `Engine.time_scale` also slows the game logic. Check `battle_view.gd _hit_stop`.
- Shake as trauma: events add trauma, it decays, offset = trauma². Respect the Shake toggle, and offer intensity.
- Wind-up about 0.15 s; target flash, particles, number and sound layered; numbers tinted by meaning; HP bars eased, not snapped. Scale feedback down on Auto and 2x speed.

## Phone lifecycle, screen, power (verified docs unless noted)
- Save in `_notification(what)` on `NOTIFICATION_APPLICATION_PAUSED`. iOS allows about 5 s. Whether it fires on swipe-away isn't guaranteed, so keep autosaving after rooms.
- Safe area: `DisplayServer.get_display_safe_area()` (Android and iOS only; dummy on desktop). Pad the top bar with a MarginContainer. Pixel 7 reports a low top inset (unverified).
- Power: `Engine.max_fps` (30 in fights is fine for a turn-based game), `OS.low_processor_usage_mode` for static screens; adaptive vsync on 120 Hz phones.
- Haptics: `Input.vibrate_handheld(ms, amplitude 0-1)`; Android needs the VIBRATE permission in the export preset. Light tap about 30 ms/0.2, big moment about 400 ms/1.0 (unverified feel).

## iOS without a Mac (route chosen by Juzo)
- Godot cannot export the iOS project from Windows (verified, 4.7 docs). The cloud Mac must run Godot itself: download Godot 4.7.2 macOS plus export templates, then `--headless --export-release "iOS"`, then Xcode builds and signs, then upload to TestFlight.
- Codemagic personal plan: 500 free M2 minutes a month, then $0.095/min. App Store Connect API key with App Manager role, distribution certificate. Juzo enters the keys into Codemagic directly; never handle credentials in chat.
- Preset: `application/app_store_team_id` (10 chars), bundle identifier (reverse DNS), provisioning profile via `GODOT_IOS_PROVISIONING_PROFILE_UUID_RELEASE` env var.
- Apple: Xcode 26 / iOS 26 SDK required since 28 Apr 2026. Developer Program fee (about $99/yr). Screenshots 1320x2868 (6.9"), icon 1024x1024 with no alpha.
- Apple rules for Solaria: in-app account deletion (Supabase name account counts); purchases via StoreKit plus Restore button; no paid random items (Fortune's Wheel stays on gold); privacy policy plus App Privacy answers. No Sign in with Apple needed while there's no third-party login.
- StoreKit plugins: hrk4649 "Godot iOS plugin for In-App purchase" v0.4.0 for 4.7 (MIT); godot-iap (StoreKit 2 plus Play Billing). Verify purchases server-side (Supabase function).
- End-to-end Godot plus Codemagic is untested: expect build-script fixes on the first run.

## Testing safely on Juzo's PC (learned the hard way)
- Godot: `C:\Users\count\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe` (the console exe in Downloads lacks its main exe).
- **Protect real saves**: tests call `GameState.delete_saves()`. Before running tests, put an `override.cfg` in the project with `[application] config/use_custom_user_dir=true` and `config/custom_user_dir_name="solaria_claude_test"`, and remove it after. Real saves live in `%APPDATA%\Godot\app_userdata\solaria`.
- A copied hero save gets wiped by the fresh-start epoch check unless the test profile's `save_epoch = Profile.SAVE_EPOCH`.
- Run checks: `GODOT=<exe> bash tools/check.sh`. Rendering screenshots need a windowed run (`--resolution 430x932`).
- After replacing PNGs, reimport (`--headless --import`) or Godot keeps showing the old imported textures.
- Never glob-delete in tests/ (`_*.gd.uid` matched project files once).

## Sources
Godot 4.7 release (godotengine.org/releases/4.7), 4.7 migration guide, renderers overview (4.7), exporting for iOS (4.7), internal rendering architecture (Metal), lights and shadows docs, Tween and DisplayServer class refs, Codemagic pricing and App Store Connect publishing docs, Apple upcoming SDK requirements, Apple 5.1.1(v) account deletion, voithos pixel camera demo, community game-feel checklists. The full list with links is in the Solaria Polish Playbook artifact.
