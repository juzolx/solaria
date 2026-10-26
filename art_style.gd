class_name ArtStyle
extends RefCounted
## The art bible in numbers: the shared palette, the outline color and the sizes that
## every monster, companion, prop and item picture follows. tools/bake_art.gd writes these
## rules into the PNGs (offline, no shaders); tests/stage6_art_rules.gd checks them so new
## art can't drift.

## The Solaria palette (74 colors): ENDESGA 32 plus the gear material ramps and skin tones
## from art_info.gd, with near-duplicates removed, plus four neutral dark stone greys. Heroes and gear already use these colors,
## so baking monsters and props onto it makes them one family. Also in art/palette.gpl.
const PALETTE := ["be4a2f", "d77643", "ead4aa", "e4a672", "b86f50", "733e39", "3e2731", "a22633",
	"e43b44", "f77622", "feae34", "fee761", "63c74d", "3e8948", "265c42", "193c3e", "124e89", "0099db",
	"2ce8f5", "ffffff", "c0cbdc", "8b9bb4", "5a6988", "3a4466", "262b44", "181425", "ff0044", "68386c",
	"b55088", "f6757a", "e8b796", "c28569", "a8624a", "7fb2e0", "4f8fba", "3c5e8b", "253a5e", "172038",
	"f4e6c4", "a3825f", "5a3f35", "8f563b", "fff4a3", "c8b08a", "a4dddb", "d0da91", "a8ca58", "75a743",
	"ffb0b0", "e8b8f0", "c27ad8", "9a4fc0", "c8f2ee", "4fb0c6", "2e7896", "2a1a1e", "5a72a8", "d4ecaa",
	"d0dcc8", "a8b89a", "7f9478", "566a56", "e4e0ec", "bdb6cc", "7d8798", "545d70", "c8a060", "9a7040",
	"6a4a28", "a8a8ba", "1f1d24", "34323b", "4a4852", "625f6a"]

## The one dark outline: one art pixel wide around every monster, companion, prop and effect.
## Not in the palette on purpose, so outline pixels can always be told apart.
const OUTLINE := Color8(14, 8, 18)

## Monsters, bosses, Calamities and companions: 2x art (each art pixel a 2x2 block), a 32x32
## art-pixel body plus the outline ring = 68x68 files; two-tile giants are 68x132.
const ART_PX := 2
const MONSTER_SIZE := Vector2i(68, 68)
const TALL_SIZE := Vector2i(68, 132)
## Redrawn monsters (art_info "hd": 1): native pixels, any size up to this (Calamities up to ~160 px)
const NATIVE_MAX := Vector2i(168, 168)
## A common's widest share of the fight stage (battle_view._width_cap; stage6_art_rules checks
## every common keeps the hero's scale inside it).
const COMMON_SHARE := 0.6
## The iPhone SE's fight stage (design px) and stretch, after interface round 1: the tallest
## boss or Calamity must keep the hero's 2x in it (stage6_art_rules; battle_view._rect_for
## lets them stand from CALAMITY_TUCK under the 34 px boss bar down to 2 px above the bottom).
const SE_STAGE := Vector2(488.0, 417.0)
const SE_SCALE := 0.744
## ...with at most this many colours each (outline included)
const NATIVE_COLORS := 24
## Dungeon props and consumable icons: 32x32 files, 1x art (Dungeon Crawl tiles).
const PROP_SIZE := Vector2i(32, 32)
## Room props and events (art/props: chests, shrine, campfire, statues...): 40x40 files, 1x art.
const ROOM_PROP_SIZE := Vector2i(40, 40)
## Gear item icons: every icon sits centered in one square frame, at the gear art's own pixel size.
const ICON_FRAME := 44
## ONE pixel scale (2.1): in battle every art pixel of the hero, monsters and pets is this many
## design points (430 pt phone layout), rounded to whole screen pixels. Native art only.
const SCREEN_PX := 3.0
## Screen pixels per art pixel at a window stretch factor.
static func unit(scr: float) -> int:
	return maxi(1, roundi(SCREEN_PX * scr))
## Effects keep a few hard alpha steps instead of soft gradients.
const FX_ALPHA := [0, 64, 128, 192, 255]

static var _lut := {}
static var _labs: Array = []

## The palette color nearest to c (by OKLab distance). Cached per color.
static func nearest(c: Color) -> Color:
	var k := (c.r8 << 16) | (c.g8 << 8) | c.b8
	if _lut.has(k):
		return _lut[k]
	if _labs.is_empty():
		for h in PALETTE:
			var p := Color(h)
			_labs.append([oklab(p), p])
	var best: Color = _labs[0][1]
	var bd := INF
	var lc := oklab(c)
	for e in _labs:
		var d: float = lc.distance_squared_to(e[0])
		if d < bd:
			bd = d
			best = e[1]
	_lut[k] = best
	return best

static func in_palette(c: Color) -> bool:
	var n := nearest(c)
	return n.r8 == c.r8 and n.g8 == c.g8 and n.b8 == c.b8

static func is_outline(c: Color) -> bool:
	return c.r8 == OUTLINE.r8 and c.g8 == OUTLINE.g8 and c.b8 == OUTLINE.b8

static func oklab(c: Color) -> Vector3:
	var r := _lin(c.r)
	var g := _lin(c.g)
	var b := _lin(c.b)
	var l := pow(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b, 1.0 / 3.0)
	var m := pow(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b, 1.0 / 3.0)
	var s := pow(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b, 1.0 / 3.0)
	return Vector3(0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
		1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
		0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)

static func _lin(x: float) -> float:
	return x / 12.92 if x <= 0.04045 else pow((x + 0.055) / 1.055, 2.4)
