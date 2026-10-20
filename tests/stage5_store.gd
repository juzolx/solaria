extends SceneTree
## Stage 4 store pieces: the Guild Hall looks shop (gold, looks only).
const TestHero := preload("res://tests/test_hero.gd")
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	GameState.delete_saves()
	Profile.delete()
	var g := GameState.new()
	g.codex.path = ""
	g.new_game()
	g.best_floor = 40
	var c := g.codex
	var list := Cosmetics.shop_list()
	check(list.size() == 12, "12 looks in the shop (4 titles, 4 colors, 4 frames)")
	var keys := {}
	for p in list:
		keys[Cosmetics.key(p[1])] = true
		check(not Cosmetics.has(c, p[1]), "nothing owned at the start (%s)" % p[1]["name"])
	check(keys.size() == 12, "every shop look has its own save key")
	var title: Dictionary = Cosmetics.SHOP_TITLES[0]
	var cost := Cosmetics.shop_price(g, title)
	check(cost > GameData.POTION_GOLD * 35, "price grows with depth (%d)" % cost)
	g.gold = cost - 1
	check(not Cosmetics.buy(g, c, title), "can't buy without the gold")
	check(g.gold == cost - 1 and c.bought.is_empty(), "nothing taken on a failed buy")
	g.gold = cost + 5
	check(Cosmetics.buy(g, c, title), "buy a title")
	check(g.gold == 5, "the price is paid")
	check(Cosmetics.has(c, title) and String(title["name"]) in c.titles(), "the title is yours and in the title picker")
	check(not Cosmetics.buy(g, c, title), "can't buy it twice")
	var col: Dictionary = Cosmetics.SHOP_COLORS[1]
	g.gold = 10000000
	check(Cosmetics.buy(g, c, col), "buy a name color")
	c.name_color = String(col["id"])
	check(Cosmetics.name_color(c) == Color(String(col["color"])), "a bought color shows on your name")
	var fr: Dictionary = {}
	for e in Cosmetics.FRAMES:
		if String(e["need"]) == "shop":
			fr = e
			break
	c.frame = String(fr["id"])
	check(String(Cosmetics.frame(c)["id"]) == "", "an unbought frame doesn't show")
	check(Cosmetics.buy(g, c, fr), "buy a frame")
	check(String(Cosmetics.frame(c)["id"]) == String(fr["id"]), "a bought frame shows")
	# Saved with the Codex
	var d := Codex.new()
	d.path = ""
	d._from({"bought": c.bought.duplicate(), "extra_titles": c.extra_titles.duplicate()})
	check(Cosmetics.has(d, col) and Cosmetics.has(d, fr) and Cosmetics.has(d, title), "bought looks are saved")
	GameState.delete_saves()
	Profile.delete()
	print("STAGE5 STORE TESTS DONE, failures: ", fails)
	quit()
