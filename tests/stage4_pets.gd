extends SceneTree
## Pets swap: with the spot taken, bringing another sends the first home.
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
	var a := Menagerie.make_pet(g, "barghest", "barghest", 1, "t")
	var b := Menagerie.make_pet(g, "kobold", "kobold", 1, "t")
	check(Menagerie.out(g).size() == 1 and int(a["id"]) in g.pets_out, "the first pet comes along")
	check(Menagerie.toggle_out(g, int(b["id"])), "bringing the second works with the spot taken")
	check(g.pets_out == [int(b["id"])], "the two swap places")
	b["hurt"] = 3
	Menagerie.changed(g)   # set by hand: caches start over
	g.pets_out.clear()
	Menagerie.changed(g)
	check(not Menagerie.toggle_out(g, int(b["id"])), "a hurt pet still has to rest")
	print("STAGE4 PET TESTS DONE, failures: ", fails)
	quit()
