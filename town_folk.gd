class_name TownFolk
extends RefCounted
## Town walkers from the PixelLab heroes (HeroArt): the two front idle frames, flipped for left /
## right (the battle's back frames are drawn bigger, so a walker would grow when it turned),
## halved to a true ~30 px sprite on the town's own pixel grid (1 walker pixel = 1 map pixel,
## a clean 2x/3x on screen like the buildings). Built once per look and cached.
## Walking: idle, left step, idle, right step (HeroArt.steps lifts one leg of the idle frame).

const CELL := 48          # HeroArt.CELL / 2
const FOOT := 40          # heroes.json "foot" (80) / 2: the feet row inside a cell

## The townsfolk: [appearance, class, tier] - races, builds and outfits mixed so the street looks lived in.
## town_view shows the first TownView.MAX_FOLK of them, so the first six mix races and sexes on their own.
const PEOPLE := [
	[{"body": "fem", "race": "Human", "skin": 2, "hair": "Bun", "hair_color": 6}, "Cleric", 0],
	[{"body": "masc", "race": "Dwarf", "skin": 1, "hair": "Bald", "hair_color": 8}, "Warrior", 0],
	[{"body": "fem", "race": "Elf", "skin": 0, "hair": "Long", "hair_color": 16}, "Ranger", 0],
	[{"body": "masc", "race": "Orc", "skin": 3, "hair": "Mohawk", "hair_color": 0}, "Wanderer", 0],
	[{"body": "fem", "race": "Goblin", "skin": 2, "hair": "Short", "hair_color": 4}, "Trickster", 0],
	[{"body": "masc", "race": "Beastkin", "skin": 4, "hair": "Shaggy", "hair_color": 2}, "Bard", 0],
	[{"body": "fem", "race": "Fairy", "skin": 1, "hair": "Pixie", "hair_color": 12}, "Mage", 0],
	[{"body": "masc", "race": "Dragonkin", "skin": 5, "hair": "Buzz", "hair_color": 10}, "Knight", 0],
	[{"body": "fem", "race": "Angel", "skin": 0, "hair": "Braid", "hair_color": 3}, "Acolyte", 0],
	[{"body": "masc", "race": "Human", "skin": 3, "hair": "Short", "hair_color": 10}, "Wanderer", 0],
	[{"body": "fem", "race": "Demon", "skin": 2, "hair": "Wavy", "hair_color": 7}, "Conjurer", 0],
	[{"body": "masc", "race": "Undead", "skin": 1, "hair": "Unkempt", "hair_color": 5}, "Nightstalker", 0],
]

static var _cache := {}

## {"s": [2 front idle textures], "walk": [idle, step, idle, step]} for one look (cached).
static func walker(app: Dictionary, cls: String, tier: int, weapon: String) -> Dictionary:
	var key := "%s|%s|%d|%s" % [str(app), cls, tier, weapon]
	if _cache.has(key):
		return _cache[key]
	var out := {"s": [], "walk": []}
	if HeroArt.available():
		var front := HeroArt.frames(app, cls, tier, weapon, false)
		for i in HeroArt.PORTRAIT:
			out["s"].append(ImageTexture.create_from_image(half(front["img"][i])))
		var st: Array = HeroArt.steps(front["img"][HeroArt.PORTRAIT[0]])
		out["walk"] = [out["s"][0], ImageTexture.create_from_image(half(st[0])), out["s"][0], ImageTexture.create_from_image(half(st[1]))]
	_cache[key] = out
	return out

## A hero from the game's looks (Sprites.hero's inputs), as a walker.
static func hero(app: Dictionary, looks: Dictionary) -> Dictionary:
	var ct := HeroArt.class_of(looks)
	var wt: String = (looks.get("Weapon", {}) as Dictionary).get("type", "")
	return walker(Sprites.race_look(app)["app"], ct[0], ct[1], wt)

static func townsfolk(i: int) -> Dictionary:
	var p: Array = PEOPLE[i % PEOPLE.size()]
	return walker(p[0], p[1], p[2], "")

## Halves a frame by 2x2 blocks: blocks on the silhouette's edge keep their darkest pixel (the
## outline stays closed), inside blocks keep their most common colour (ties go to the darker).
static func half(src: Image) -> Image:
	var w := src.get_width() / 2
	var h := src.get_height() / 2
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var cols: Array = []
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				var c := src.get_pixel(x * 2 + d.x, y * 2 + d.y)
				if c.a > 0.5:
					cols.append(c)
			if cols.is_empty():
				continue
			var pick: Color = cols[0]
			if cols.size() < 4:
				for c in cols:
					if c.get_luminance() < pick.get_luminance():
						pick = c
			else:
				var best := 0
				for c in cols:
					var n := 0
					for o in cols:
						if o.is_equal_approx(c):
							n += 1
					if n > best or (n == best and c.get_luminance() < pick.get_luminance()):
						best = n
						pick = c
			pick.a = 1.0
			out.set_pixel(x, y, pick)
	return out

static func clear_cache() -> void:
	_cache.clear()
