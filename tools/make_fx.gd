extends SceneTree
## Draws Solaria's hit and spell effects as pixel art: 64x64 frames in a
## horizontal strip, one PNG per effect, frame counts in art/fx/fx.json.
## Original art (CC0, made for Solaria), replacing a non-commercial pack.
## godot --headless --path . --script tools/make_fx.gd

const S := 64
var rng := RandomNumberGenerator.new()

const FRAMES := {"slash": 13, "slash_crit": 13, "claw": 12, "pierce": 9, "impact": 8, "impact_red": 8, "crit": 9,
	"burst": 11, "fire": 13, "ice": 8, "lightning": 8, "poison": 11, "holy": 9, "shadow": 16, "nature": 5,
	"arcane": 9, "shatter": 9, "heal": 11, "levelup": 14, "blood": 8}

# ---------------------------------------------------------------- drawing helpers

func px(img: Image, ox: int, x: float, y: float, c: Color) -> void:
	var ix := int(roundf(x))
	var iy := int(roundf(y))
	if ix < 0 or iy < 0 or ix >= S or iy >= S or c.a <= 0.01:
		return
	var under := img.get_pixel(ox + ix, iy)
	var a := c.a + under.a * (1.0 - c.a)
	if a <= 0.0:
		return
	var rgb := (Color(c.r, c.g, c.b) * c.a + Color(under.r, under.g, under.b) * under.a * (1.0 - c.a)) / a
	img.set_pixel(ox + ix, iy, Color(rgb.r, rgb.g, rgb.b, a))

func disc(img: Image, ox: int, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			if Vector2(x - cx, y - cy).length() <= r:
				px(img, ox, x, y, c)

func ring(img: Image, ox: int, cx: float, cy: float, r: float, w: float, c: Color) -> void:
	for y in range(int(cy - r - w) - 1, int(cy + r + w) + 2):
		for x in range(int(cx - r - w) - 1, int(cx + r + w) + 2):
			var d := Vector2(x - cx, y - cy).length()
			if absf(d - r) <= w * 0.5:
				px(img, ox, x, y, c)

func line(img: Image, ox: int, a: Vector2, b: Vector2, w: float, c: Color) -> void:
	var n := maxi(1, int(a.distance_to(b) * 2.0))
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		if w <= 1.0:
			px(img, ox, p.x, p.y, c)
		else:
			disc(img, ox, p.x, p.y, w * 0.5, c)

## An arc of a circle from angle a0 to a1 (radians), thickness w.
func arc(img: Image, ox: int, cx: float, cy: float, r: float, a0: float, a1: float, w: float, c: Color) -> void:
	var n := maxi(4, int(absf(a1 - a0) * r * 1.5))
	for i in n + 1:
		var ang := lerpf(a0, a1, float(i) / n)
		var p := Vector2(cx, cy) + Vector2.from_angle(ang) * r
		disc(img, ox, p.x, p.y, w * 0.5, c)

func fade(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * clampf(a, 0.0, 1.0))

# ---------------------------------------------------------------- the effects

## A thick crescent: thickest in the middle, tapering to points (a sword's swoosh).
func crescent(img: Image, ox: int, c: Vector2, r: float, a0: float, a1: float, wmax: float, edge: Color, core: Color, life: float) -> void:
	var n := maxi(8, int(absf(a1 - a0) * r * 2.0))
	for i in n + 1:
		var f := float(i) / n
		var w := wmax * sin(PI * f) * (0.4 + 0.6 * f)  # fuller toward the leading edge
		var p := c + Vector2.from_angle(lerpf(a0, a1, f)) * r
		disc(img, ox, p.x, p.y, w * 0.5 + 0.5, fade(edge, life * 0.55))
		disc(img, ox, p.x, p.y, w * 0.25, fade(core, life * (0.4 + 0.6 * f)))

## A sword swing: a double swoosh sweeping across, with a bright core and a glow.
func fx_slash(img: Image, ox: int, t: float, big: bool) -> void:
	var core := Color("#fffaf0") if big else Color("#f2f8ff")
	var edge := Color("#ff9d2e") if big else Color("#6fb8ff")
	var r := 28.0 if big else 26.0
	var sweep := minf(t * 1.7, 1.0)
	var head := lerpf(-2.6, 1.0, sweep)
	var tail := head - (2.8 if big else 2.4) * (0.5 + 0.5 * sweep)
	var life := 1.0 - maxf(0.0, t - 0.5) / 0.5
	crescent(img, ox, Vector2(30, 33), r, tail, head, 15.0 if big else 12.0, edge, core, life)
	if t > 0.15:  # a second, smaller swoosh just behind the first
		crescent(img, ox, Vector2(34, 37), r * 0.72, tail + 0.3, head - 0.2, 7.0 if big else 5.0, edge, core, life * 0.8)
	if big:
		rng.seed = 11 + int(t * 13.0)
		for i in 6:
			var p := Vector2(30, 34) + Vector2.from_angle(head + rng.randf_range(-0.3, 0.2)) * (r + rng.randf_range(2, 10) * t)
			px(img, ox, p.x, p.y, fade(Color("#ffe08a"), life))

func fx_claw(img: Image, ox: int, t: float) -> void:
	var life := 1.0 - maxf(0.0, t - 0.5) / 0.5
	var reach := minf(t * 2.2, 1.0)
	for k in 3:
		var a := Vector2(12 + k * 12, 8 + k * 3)
		var b := a + Vector2(20, 46) * reach
		line(img, ox, a, b, 7.0, fade(Color("#5a0a14"), 0.6 * life))
		line(img, ox, a, b, 4.0, fade(Color("#e0323c"), life))
		line(img, ox, a.lerp(b, 0.35), b, 2.0, fade(Color("#ffd8cf"), life))

func fx_pierce(img: Image, ox: int, t: float) -> void:
	var life := 1.0 - maxf(0.0, t - 0.45) / 0.55
	var x1 := lerpf(4, 60, minf(t * 2.2, 1.0))
	# speed lines above and below
	for k in [-9.0, -5.0, 5.0, 9.0]:
		line(img, ox, Vector2(maxf(2, x1 - 30 - absf(k) * 1.5), 32 + k), Vector2(x1 - 10 - absf(k), 32 + k), 1.0, fade(Color("#a8d8ff"), 0.7 * life))
	line(img, ox, Vector2(maxf(2, x1 - 44), 32), Vector2(x1, 32), 8.0, fade(Color("#3d86d6"), 0.4 * life))
	line(img, ox, Vector2(maxf(2, x1 - 36), 32), Vector2(x1, 32), 3.0, fade(Color("#eef7ff"), life))
	disc(img, ox, x1, 32, 4.0 + 6.0 * minf(t * 2.0, 1.0), fade(Color("#ffffff"), life * 0.9))
	ring(img, ox, x1, 32, 6.0 + 10.0 * t, 1.5, fade(Color("#a8d8ff"), life))

func fx_impact(img: Image, ox: int, t: float, col: Color) -> void:
	var life := 1.0 - t
	# a spiky star that bursts out, then shards and a ring
	rng.seed = 7
	for i in 10:
		var dir := Vector2.from_angle(TAU * i / 10.0 + rng.randf_range(-0.15, 0.15))
		var length := (16.0 if i % 2 == 0 else 10.0) * (1.0 - t * 0.6) * minf(1.0, t * 4.0 + 0.4)
		line(img, ox, Vector2(32, 32), Vector2(32, 32) + dir * length, 5.0 * life + 1.0, fade(col, life))
		var p := Vector2(32, 32) + dir * (10.0 + t * 26.0)
		line(img, ox, p, p + dir * 5.0 * life, 3.0, fade(col.lightened(0.4), life))
	disc(img, ox, 32, 32, 9.0 * (1.0 - t * 0.8), fade(Color("#ffffff"), life))
	ring(img, ox, 32, 32, 6.0 + t * 24.0, 3.0 * life + 1.0, fade(col, life * 0.8))

func fx_crit(img: Image, ox: int, t: float) -> void:
	var life := 1.0 - maxf(0.0, t - 0.3) / 0.7
	var gold := Color("#ffd34d")
	for i in 12:
		var dir := Vector2.from_angle(TAU * i / 12.0 + t * 0.6)
		var length := (10.0 + (8.0 if i % 2 == 0 else 0.0)) * minf(1.0, t * 3.0) + 6.0
		line(img, ox, Vector2(32, 32) + dir * 4.0, Vector2(32, 32) + dir * (4.0 + length), 2.0 if i % 2 == 0 else 1.0, fade(gold, life))
	disc(img, ox, 32, 32, 6.0 + 2.0 * sin(t * PI), fade(Color("#fff8d0"), life))
	ring(img, ox, 32, 32, 8.0 + t * 20.0, 2.0, fade(Color("#ff9d2e"), life * 0.8))

func fx_burst(img: Image, ox: int, t: float) -> void:
	var r := 4.0 + t * 24.0
	var life := 1.0 - t
	disc(img, ox, 32, 32, r, fade(Color("#3a2a2a"), 0.5 * life))      # smoke
	disc(img, ox, 32, 32, r * 0.8, fade(Color("#ff6a2a"), 0.8 * life))
	disc(img, ox, 32, 32, r * 0.5, fade(Color("#ffc94a"), life))
	disc(img, ox, 32, 32, r * 0.25, fade(Color("#fff6d0"), life))
	rng.seed = 3
	for i in 10:
		var dir := Vector2.from_angle(rng.randf() * TAU)
		var p := Vector2(32, 32) + dir * (r + 4.0)
		px(img, ox, p.x, p.y, fade(Color("#ffb347"), life))

## Flames: columns that rise and flicker, hot at the bottom.
func fx_fire(img: Image, ox: int, t: float) -> void:
	var life := 1.0 - maxf(0.0, t - 0.6) / 0.4
	var grow := minf(1.0, t * 2.5)
	rng.seed = 21
	for col in 12:
		var x := 8.0 + col * 4.2 + rng.randf_range(-1, 1)
		var middle := 1.0 - absf(col - 5.5) / 7.0  # tallest in the middle
		var h := (16.0 + 30.0 * middle + rng.randf_range(0, 8)) * grow * (0.8 + 0.2 * sin(t * 40.0 + col))
		var wv := 2.5 + 2.0 * middle
		for y in int(h):
			var f := float(y) / maxf(1.0, h)
			var c := Color("#fff7c0").lerp(Color("#ff8c1a"), f * 1.3).lerp(Color("#a8201a"), maxf(0.0, f - 0.55) * 2.2)
			var sx := x + sin(y * 0.35 + t * 22.0 + col) * 2.0 * f
			disc(img, ox, sx, 58 - y, wv * (1.0 - f * 0.7), fade(c, life * (1.0 - f * 0.35)))

func fx_ice(img: Image, ox: int, t: float) -> void:
	var life := 1.0 - maxf(0.0, t - 0.5) / 0.5
	var grow := minf(1.0, t * 2.0)
	for i in 6:
		var dir := Vector2.from_angle(TAU * i / 6.0 - PI / 2.0)
		var tip := Vector2(32, 32) + dir * (6.0 + 18.0 * grow)
		line(img, ox, Vector2(32, 32), tip, 4.0, fade(Color("#3aa7d9"), 0.6 * life))
		line(img, ox, Vector2(32, 32), tip, 2.0, fade(Color("#dff7ff"), life))
		var side := dir.rotated(PI / 2.0) * 4.0 * grow
		line(img, ox, Vector2(32, 32) + dir * 12.0 * grow, Vector2(32, 32) + dir * 16.0 * grow + side, 1.0, fade(Color("#bfefff"), life))
	disc(img, ox, 32, 32, 4.0, fade(Color("#ffffff"), life))

## A forked bolt from the top, re-drawn every frame so it flickers.
func fx_lightning(img: Image, ox: int, t: float) -> void:
	var life := 1.0 - t * 0.85
	rng.seed = 40 + int(t * 8.0)
	var p := Vector2(32 + rng.randf_range(-6, 6), 2)
	while p.y < 58:
		var q := p + Vector2(rng.randf_range(-7, 7), rng.randf_range(5, 9))
		line(img, ox, p, q, 5.0, fade(Color("#6a5cff"), 0.35 * life))
		line(img, ox, p, q, 2.0, fade(Color("#f2f0ff"), life))
		if rng.randf() < 0.25:
			var b := q + Vector2(rng.randf_range(-10, 10), rng.randf_range(4, 10))
			line(img, ox, q, b, 1.0, fade(Color("#c9c3ff"), life * 0.8))
		p = q
	disc(img, ox, p.x, 58, 5.0 * life, fade(Color("#ffffff"), life * 0.7))

func fx_poison(img: Image, ox: int, t: float) -> void:
	rng.seed = 5
	for i in 10:
		var start := rng.randf_range(0.0, 0.5)
		var lt := (t - start) / 0.5
		if lt < 0.0 or lt > 1.0:
			continue
		var x := 16.0 + rng.randf_range(0, 32) + sin(lt * 6.0 + i) * 2.0
		var y := 52.0 - lt * 36.0
		var r := 2.0 + rng.randf_range(0, 3) * (1.0 - absf(lt - 0.5))
		if lt > 0.85:
			ring(img, ox, x, y, r + 2.0, 1.0, fade(Color("#c6f26b"), 1.0 - lt))  # pop
		else:
			disc(img, ox, x, y, r, fade(Color("#4f8a1e"), 0.9))
			px(img, ox, x - r * 0.4, y - r * 0.4, Color("#e8ffb0"))

func fx_holy(img: Image, ox: int, t: float) -> void:
	var life := 1.0 - maxf(0.0, t - 0.5) / 0.5
	var w := 10.0 * minf(1.0, t * 3.0)
	for y in S:
		for x in range(int(32 - w), int(32 + w) + 1):
			var edge := absf(x - 32) / maxf(1.0, w)
			px(img, ox, x, y, fade(Color("#fff3b0"), 0.35 * life * (1.0 - edge)))
	line(img, ox, Vector2(32, 14), Vector2(32, 42), 3.0, fade(Color("#ffffff"), life))
	line(img, ox, Vector2(22, 24), Vector2(42, 24), 3.0, fade(Color("#ffffff"), life))
	ring(img, ox, 32, 24, 6.0 + t * 10.0, 1.5, fade(Color("#ffd34d"), life))

func fx_shadow(img: Image, ox: int, t: float) -> void:
	var life := 1.0 - maxf(0.0, t - 0.6) / 0.4
	for k in 5:
		var a0 := t * 5.0 + TAU * k / 5.0
		for i in 18:
			var f := float(i) / 18.0
			var ang := a0 + f * 2.4
			var r := 4.0 + f * 22.0 * minf(1.0, t * 2.0)
			var p := Vector2(32, 34) + Vector2.from_angle(ang) * r
			disc(img, ox, p.x, p.y, 3.0 * (1.0 - f) + 0.5, fade(Color("#3b1d5c").lerp(Color("#b388ff"), 1.0 - f), life * (1.0 - f * 0.5)))
	disc(img, ox, 32, 34, 5.0 * life, fade(Color("#120818"), life))

func fx_nature(img: Image, ox: int, t: float) -> void:
	for i in 7:
		var ang := TAU * i / 7.0 + t * 4.0
		var r := 6.0 + t * 20.0
		var p := Vector2(32, 34) + Vector2.from_angle(ang) * r
		var c := Color("#5fbf4a") if i % 2 == 0 else Color("#a6e36a")
		disc(img, ox, p.x, p.y, 2.5, fade(c, 1.0 - t * 0.6))
		px(img, ox, p.x + 2, p.y - 2, fade(Color("#2f6e2a"), 1.0 - t * 0.6))

func fx_arcane(img: Image, ox: int, t: float) -> void:
	var life := 1.0 - maxf(0.0, t - 0.5) / 0.5
	var r := 8.0 + t * 14.0
	ring(img, ox, 32, 32, r, 2.0, fade(Color("#c084fc"), life))
	ring(img, ox, 32, 32, r * 0.6, 1.0, fade(Color("#e9d5ff"), life))
	for i in 6:
		var p := Vector2(32, 32) + Vector2.from_angle(TAU * i / 6.0 + t * 3.0) * r
		disc(img, ox, p.x, p.y, 2.0, fade(Color("#f5e8ff"), life))
	disc(img, ox, 32, 32, 3.0, fade(Color("#ffffff"), life))

func fx_shatter(img: Image, ox: int, t: float) -> void:
	rng.seed = 13
	var life := 1.0 - t
	for i in 12:
		var dir := Vector2.from_angle(rng.randf() * TAU)
		var p := Vector2(32, 32) + dir * (3.0 + t * rng.randf_range(16, 28)) + Vector2(0, t * t * 10.0)
		var s := rng.randf_range(2, 4)
		line(img, ox, p, p + dir.rotated(rng.randf_range(-1, 1)) * s, 2.0, fade(Color("#cfeeff"), life))
		px(img, ox, p.x, p.y, fade(Color("#ffffff"), life))

func fx_heal(img: Image, ox: int, t: float) -> void:
	rng.seed = 17
	for i in 8:
		var start := rng.randf_range(0.0, 0.45)
		var lt := (t - start) / 0.55
		if lt < 0.0 or lt > 1.0:
			continue
		var p := Vector2(16.0 + rng.randf_range(0, 32), 54.0 - lt * 40.0)
		var a := 1.0 - absf(lt - 0.4) * 1.4
		var s := 2.0 if i % 3 else 3.0
		line(img, ox, p - Vector2(s, 0), p + Vector2(s, 0), 1.0 if s < 3.0 else 2.0, fade(Color("#7dffa0"), a))
		line(img, ox, p - Vector2(0, s), p + Vector2(0, s), 1.0 if s < 3.0 else 2.0, fade(Color("#7dffa0"), a))
		px(img, ox, p.x, p.y, fade(Color("#ffffff"), a))
	ring(img, ox, 32, 50, 6.0 + t * 16.0, 1.0, fade(Color("#4ade80"), 0.6 * (1.0 - t)))

func fx_levelup(img: Image, ox: int, t: float) -> void:
	var life := 1.0 - maxf(0.0, t - 0.6) / 0.4
	var y := 54.0 - t * 30.0
	for k in 3:
		var rr := 18.0 - k * 4.0
		arc(img, ox, 32, y + k * 6.0, rr, PI * 0.05, PI * 0.95, 2.0, fade(Color("#ffd34d").lerp(Color("#fff6d0"), k / 3.0), life * (1.0 - k * 0.2)))
	rng.seed = 29
	for i in 10:
		var p := Vector2(rng.randf_range(10, 54), 58.0 - fposmod(t * 60.0 + rng.randf_range(0, 40), 48.0))
		px(img, ox, p.x, p.y, fade(Color("#fff2a8"), life))
		px(img, ox, p.x, p.y - 1, fade(Color("#ffd34d"), life * 0.6))

func fx_blood(img: Image, ox: int, t: float) -> void:
	rng.seed = 23
	var life := 1.0 - maxf(0.0, t - 0.5) / 0.5
	for i in 10:
		var dir := Vector2.from_angle(rng.randf_range(-PI, 0.0))
		var spd := rng.randf_range(12, 24)
		var p := Vector2(32, 34) + dir * spd * t + Vector2(0, 30.0 * t * t)
		disc(img, ox, p.x, p.y, rng.randf_range(1.0, 2.5), fade(Color("#8b0f1a"), life))
		px(img, ox, p.x - 0.5, p.y - 0.5, fade(Color("#e04b4b"), life))

func draw(name: String, img: Image, ox: int, t: float) -> void:
	match name:
		"slash": fx_slash(img, ox, t, false)
		"slash_crit": fx_slash(img, ox, t, true)
		"claw": fx_claw(img, ox, t)
		"pierce": fx_pierce(img, ox, t)
		"impact": fx_impact(img, ox, t, Color("#e6f3ff"))
		"impact_red": fx_impact(img, ox, t, Color("#ff5a5a"))
		"crit": fx_crit(img, ox, t)
		"burst": fx_burst(img, ox, t)
		"fire": fx_fire(img, ox, t)
		"ice": fx_ice(img, ox, t)
		"lightning": fx_lightning(img, ox, t)
		"poison": fx_poison(img, ox, t)
		"holy": fx_holy(img, ox, t)
		"shadow": fx_shadow(img, ox, t)
		"nature": fx_nature(img, ox, t)
		"arcane": fx_arcane(img, ox, t)
		"shatter": fx_shatter(img, ox, t)
		"heal": fx_heal(img, ox, t)
		"levelup": fx_levelup(img, ox, t)
		"blood": fx_blood(img, ox, t)

func _init() -> void:
	var out := ProjectSettings.globalize_path("res://art/fx")
	for name in FRAMES:
		var n: int = FRAMES[name]
		var img := Image.create(S * n, S, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for f in n:
			draw(name, img, f * S, float(f) / float(maxi(1, n - 1)))
		img.save_png(out.path_join("%s.png" % name))
	var j := FileAccess.open(out.path_join("fx.json"), FileAccess.WRITE)
	j.store_string(JSON.stringify(FRAMES))
	print("MADE %d effects" % FRAMES.size())
	quit()
