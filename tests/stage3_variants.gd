extends SceneTree
## Monster variants: rare, recolored, one twist each.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero() -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.level = 30
	g.floor_num = 20
	g.in_town = false
	g.spawn_enemy()
	g.enemy_is_boss = false
	return g

func _initialize() -> void:
	var g := hero()
	var n := 0
	for i in 4000:
		g.enemy_is_boss = false
		g.enemy_wanderer = false
		g.enemy_grave = false
		Variants.maybe(g)
		if g.enemy_variant != "":
			n += 1
	check(n > 4000 * 0.035 and n < 4000 * 0.09, "about 1 fight in 16 (%d of 4000)" % n)
	var a := hero()
	var hp := a.enemy_max_hp
	Variants.make(a, "Ashen")
	check(a.enemy_max_hp > hp and a.enemy_name.begins_with("Ashen "), "Ashen: tougher, and named")
	var t: Texture2D = Sprites.enemy_by_key("barghest").get("tex")
	var r := Variants.tex(t, "Gilded")
	check(r != t and r.get_image().get_data() != t.get_image().get_data(), "a variant is recolored")
	check(Variants.tex(t, "Gilded") == r, "and cached")
	var b := hero()
	Variants.make(b, "Blighted")
	var poisoned := 0
	for i in 300:
		b.hero_status.clear()
		Combat.on_enemy_hit(b, 10)
		if b.hero_status.has("poison"):
			poisoned += 1
	check(poisoned > 30, "Blighted hits can poison (%d of 300)" % poisoned)
	print("STAGE3 VARIANT TESTS DONE, failures: ", fails)
	quit()
