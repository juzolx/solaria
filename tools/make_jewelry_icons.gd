extends SceneTree
## 2.1: placeholder art for the Ring and Necklace slots (the art team redraws them later).
## Writes art/gear/band.png, signet.png, pendant.png and amulet.png in the same KEY colors as
## every other gear picture (yellow = material, magenta = rarity trim; Sprites recolors them),
## with the same outlines: material-line on the top-left, dark on the bottom-right, both at
## alpha 201. Run: godot --headless --path . -s tools/make_jewelry_icons.gd
##
## Legend: . empty   O mat line (top-left outline)   K dark outline (bottom-right)
##         1-4 material light to dark   a-d trim light to dark   e trim line

const KEYS := {
	"O": [195, 195, 0, 201], "K": [24, 20, 37, 201],
	"1": [255, 255, 0, 255], "2": [240, 240, 0, 255], "3": [225, 225, 0, 255], "4": [210, 210, 0, 255],
	"a": [255, 0, 255, 255], "b": [240, 0, 240, 255], "c": [225, 0, 225, 255], "d": [210, 0, 210, 255],
	"e": [195, 0, 195, 201],
}

const ART := {
	# A plain band with a small stone set on top
	"band": [
		"......eae......",
		".....eabcK.....",
		"....O1dcd3K....",
		"...O12KKK34K...",
		"..O12K...K34K..",
		"..O2K.....K4K..",
		"..O2K.....K4K..",
		"..O2K.....K4K..",
		"..O23K...K44K..",
		"...O34KKK44K...",
		"....K34444K....",
		".....KKKKK.....",
	],
	# A heavy signet: a flat face with a crest in the trim color
	"signet": [
		"....OOOOOOO....",
		"...O1122334K...",
		"...O1abbcc4K...",
		"...O2bccdd4K...",
		"...O2333344K...",
		"...KO2KKK4KK...",
		"..O2K.....K4K..",
		"..O2K.....K4K..",
		"..O23K...K44K..",
		"...O34KKK44K...",
		"....K34444K....",
		".....KKKKK.....",
	],
	# A fine chain in a V with a teardrop stone
	"pendant": [
		"O2............O2",
		".3K..........O3.",
		".O2K........O2K.",
		"..3K........3K..",
		"..O2K......O2K..",
		"...3K......3K...",
		"...O2K....O2K...",
		"....3K....3K....",
		"....O2K..O2K....",
		".....3KOO3K.....",
		"......O12K......",
		".....OabbcK.....",
		"....OabbccdK....",
		"....ObbccddK....",
		".....KccddK.....",
		"......KddK......",
		".......KK.......",
	],
	# A round medallion on a heavier chain, with a stone in the middle
	"amulet": [
		".O2K........O2K.",
		".O3K........O3K.",
		".O2K........O2K.",
		"..O3K......O3K..",
		"...O2K....O2K...",
		"....O3KOOO3K....",
		".....O1223K.....",
		"....O122334K....",
		"...O12aabb34K...",
		"...O2abccd34K...",
		"...O2bccdd44K...",
		"...O33cdd444K...",
		"....K334444K....",
		".....KKKKKK.....",
	],
}

func _initialize() -> void:
	for name in ART:
		var rows: Array = ART[name]
		var w := 0
		for r in rows:
			w = maxi(w, String(r).length())
		var img := Image.create(w + 2, rows.size() + 2, false, Image.FORMAT_RGBA8)
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				var ch := row[x]
				if KEYS.has(ch):
					var k: Array = KEYS[ch]
					img.set_pixel(x + 1, y + 1, Color8(int(k[0]), int(k[1]), int(k[2]), int(k[3])))
		img.save_png("res://art/gear/%s.png" % name)
		print("wrote art/gear/%s.png (%dx%d)" % [name, img.get_width(), img.get_height()])
	quit()
