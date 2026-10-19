extends SceneTree
## 0.13 dark art grade (dark_grade.gd) and elite rooms always being a step up.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _initialize() -> void:
	DarkGrade.set_enabled(true)
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(4, 4, 8, 8), Color(0.2, 0.7, 0.3))  # a green body
	img.set_pixel(8, 8, Color(1.0, 0.45, 0.05))                # a glowing ember
	img.set_pixel(5, 9, Color(0.8, 0.8, 0.8, 0.5))             # half see-through
	var body_before := img.get_pixel(9, 10)
	var g := DarkGrade.image(img)
	check(g.get_size() == img.get_size(), "same size")
	check(g.get_pixel(0, 0).a == 0.0, "empty space stays empty")
	check(is_equal_approx(g.get_pixel(5, 9).a, img.get_pixel(5, 9).a), "alpha kept")
	var body := g.get_pixel(9, 10)
	check(body.s < img.get_pixel(9, 10).s and body.v <= img.get_pixel(9, 10).v, "body gets darker and greyer")
	var ember := g.get_pixel(8, 8)
	check(ember.s > 0.8 and ember.v > 0.9, "glowing pixels keep their color")
	check(g.get_pixel(8, 6).v > DarkGrade.image(img, DarkGrade.SPRITE, false).get_pixel(8, 6).v, "top edge gets a rim light")
	check(img.get_pixel(9, 10) == body_before, "source image untouched")

	DarkGrade.set_enabled(false)
	check(DarkGrade.image(img) == img, "off: the picture is left as it is")
	DarkGrade.set_enabled(true)
	var t := DarkGrade.texture("res://art/bg/zone_0.png", DarkGrade.SCENE, false)
	check(t != null and t == DarkGrade.texture("res://art/bg/zone_0.png", DarkGrade.SCENE, false), "graded backgrounds are cached")
	check(DarkGrade.texture("res://art/bg/missing.png") == null, "missing art gives null")
	var e := Sprites.enemy_by_key("banshee")
	check(not e.is_empty() and e["tex"] != null, "monsters still load")

	# Elite rooms: always tougher, even when the monster was already rare
	for tier in [0, Monsters.EPIC, Monsters.MYTHIC]:
		var h := GameState.new()
		h.autosave = false
		h.codex.path = ""
		h.new_game()
		h.choose_class("Warrior")
		h.floor_num = 12
		h.spawn_enemy()
		if h.enemy_is_boss or h.enemy_goblin:
			continue
		h._apply_tier(tier)
		var before := h.enemy_max_hp
		h.path_offer = ["elite", "rest", "treasure"]
		h.choose_path("elite")
		check(h.enemy_elite and h.enemy_max_hp > before, "elite is tougher (from tier %d)" % tier)
		check(h.enemy_tier >= Monsters.EPIC and h.enemy_tier <= Monsters.MYTHIC, "elite tier in range")
	print("STAGE2 DARK GRADE TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	quit()
