class_name CreditsData
extends RefCounted
## Every third-party source in Solaria, in one place. To credit a new pack, add ONE line to SOURCES.
## Fields: group (one of GROUPS), name, author, license, link (text, shown not clicked), used (where in the game).
## Keep claude/licenses-audit.md in step with this table.

const GROUPS := ["Art", "Sound", "Music", "Fonts", "Code and engine"]

const GAME := {
	"title": "Solaria",
	"by": "Made by Juzo",
	"line": "Design, story and game by Juzo. Thank you for playing.",
}

const SOURCES := [
	# Art
	{"group": "Art", "name": "Dungeon Crawl Stone Soup tiles (32x32)", "author": "The DCSS tile artists", "license": "CC0", "link": "opengameart.org/content/dungeon-crawl-32x32-tiles (artists: github.com/crawl/tiles)", "used": "Every monster, boss, Calamity and companion; dungeon props; scroll, key and other item icons. Recolored, outlined and upscaled."},
	{"group": "Art", "name": "cc0 potion icons", "author": "Dungeon Crawl Stone Soup artists, collected by AntumDeluge", "license": "CC0", "link": "opengameart.org/content/cc0-potion-icons", "used": "Potion icons."},
	{"group": "Art", "name": "Solaria original art", "author": "Juzo", "license": "All rights reserved (Solaria)", "link": "-", "used": "Heroes, room people and town keepers, the town, the 3D rooms, room props, baby pets (all made with PixelLab, pixellab.ai, on Juzo's subscription), gear, backgrounds, hit and spell effects, doors, icons, logo and everything else not listed above."},
	# Sound
	{"group": "Sound", "name": "Solaria sound effects and ambience", "author": "Juzo", "license": "All rights reserved (Solaria)", "link": "-", "used": "Every sound effect and ambience loop. Made from scratch in code, no third-party samples."},
	# Music
	{"group": "Music", "name": "Solaria music", "author": "Juzo", "license": "All rights reserved (Solaria)", "link": "-", "used": "Title, town, zone and boss music. Made from scratch in code, no third-party samples."},
	# Fonts
	{"group": "Fonts", "name": "Pixelify Sans", "author": "The Pixelify Sans Project Authors", "license": "SIL Open Font License 1.1", "link": "github.com/eifetx/Pixelify-Sans (art/ui/fonts/OFL.txt, from google/fonts ofl/pixelifysans)", "used": "All game text (art/ui/fonts/PixelifySans.ttf)."},
	{"group": "Fonts", "name": "Open Sans SemiBold (Godot's built-in default font)", "author": "The Open Sans Project Authors", "license": "SIL Open Font License 1.1", "link": "github.com/googlefonts/opensans (Godot COPYRIGHT.txt: thirdparty/fonts/OpenSans*.woff2, 2020, OFL-1.1)", "used": "Fallback for characters Pixelify Sans does not have. Comes inside the Godot engine."},
	# Code and engine
	{"group": "Code and engine", "name": "Godot Engine 4", "author": "Juan Linietsky, Ariel Manzur and the Godot Engine contributors", "license": "MIT", "link": "godotengine.org/license", "used": "The engine Solaria runs on.", "notice": "Copyright (c) 2014-present Godot Engine contributors. Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."},
	{"group": "Code and engine", "name": "Godot third-party components", "author": "Various (zlib, FreeType, HarfBuzz, ICU, libpng, mbedTLS, Vorbis and others)", "license": "Permissive (zlib, MIT, BSD, FTL, OFL and similar)", "link": "godotengine.org/license (full list in Godot's COPYRIGHT.txt)", "used": "Parts of the engine itself (text, images, audio, networking)."},
]

## Sources in one group, in table order.
static func in_group(group: String) -> Array:
	return SOURCES.filter(func(s): return s["group"] == group)
