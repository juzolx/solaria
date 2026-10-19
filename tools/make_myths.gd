extends SceneTree
## 0.13+ myth monsters: Dungeon Crawl Stone Soup tiles (CC0) -> art/enemies, 2x nearest (64x64),
## like tools/dcss_monsters.py did for the rest (the game's DarkGrade darkens them at load).
## godot --headless --path . -s tools/make_myths.gd -- "<...>/Dungeon Crawl Stone Soup Full/monster"
const MAP := {
	"hobyah": "gnoll_new", "jack_in_irons": "ettin_new",
	"ankou": "demons/reaper_new", "bog_body": "undead/bog_body",
	"ningyo": "mermaid", "afanc": "animals/alligator_snapping_turtle_new",
	"gullinbursti": "animals/hell_hog_new", "div": "demons/smoke_demon_new",
	"mare": "demons/shadow_fiend_new", "baku": "animals/elephant_demonic_new",
}

func _initialize() -> void:
	var src: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ""
	var made := 0
	for key in MAP:
		var img := Image.load_from_file(src.path_join(String(MAP[key]) + ".png"))
		if img == null or img.is_empty():
			print("MISSING ", MAP[key])
			continue
		img.convert(Image.FORMAT_RGBA8)
		img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
		img.save_png(ProjectSettings.globalize_path("res://art/enemies/%s.png" % key))
		made += 1
	print("MYTHS MADE ", made)
	quit()
