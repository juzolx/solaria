extends SceneTree
## The new hair and eye colors draw a hero.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _initialize() -> void:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	var base: Dictionary = g.appearance.duplicate()
	var plain := Sprites.portrait(base, g.hero_looks())
	check(plain != null, "a hero portrait draws")
	for i in range(18, Sprites.hair_colors().size()):
		var app := base.duplicate()
		app["hair_color"] = i
		var p := Sprites.portrait(app, g.hero_looks())
		check(p != null and p.get_image().get_data() != plain.get_image().get_data(), "hair color %d draws, and looks different" % i)
	for i in range(7, Sprites.eye_colors().size()):
		var app := base.duplicate()
		app["eyes"] = i
		check(Sprites.portrait(app, g.hero_looks()) != null, "eye color %d draws" % i)
	print("STAGE3 LOOKS TESTS DONE, failures: ", fails)
	quit()
