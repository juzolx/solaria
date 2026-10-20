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
	_purchases()
	GameState.delete_saves()
	Profile.delete()
	print("STAGE5 STORE TESTS DONE, failures: ", fails)
	quit()

## Real-money purchase code: switched off, and only looks.
func _purchases() -> void:
	check(not Store.ENABLED and not Store.available(), "the App Store is switched off")
	check(not Store.buy("solaria.supporter") and not Store.restore(), "buying and restoring do nothing while it's off")
	check(not Store.PRODUCTS.keys().any(func(k): return String(k).contains("slot")), "hero slots are never sold")
	for id in Store.PRODUCTS:
		check(String(Store.PRODUCTS[id]["kind"]) == "looks", "only looks are sold (%s)" % id)
	var p := Profile.new()
	var c := Codex.new()
	c.path = ""
	var eclipse := {}
	for e in Cosmetics.colors():
		if String(e["id"]) == "eclipse":
			eclipse = e
	check(not eclipse.is_empty() and not Cosmetics.has(c, eclipse), "supporter color exists, not owned")
	for e in Cosmetics.shop_list():
		check(String(e[1]["need"]) == "shop", "supporter looks aren't sold for gold (%s)" % e[1]["name"])
	# What Apple's plugin hands back
	Store.handle({"type": "purchase", "result": "ok", "product_id": "solaria.supporter"}, p, c)
	check(Cosmetics.has(c, eclipse) and "Keeper of the Flame" in c.titles(), "supporter pack gives its looks and title")
	Store.handle({"type": "purchase", "result": "ok", "product_id": "solaria.gems"}, p, c)
	check(p.owned_products.size() == 1, "unknown products give nothing")
	Store.busy = true
	Store.handle({"type": "purchase", "result": "error", "product_id": "solaria.supporter"}, p, c)
	check(not Store.busy and p.owned_products.size() == 1, "a failed purchase gives nothing and frees the button")
	Store.handle({"type": "product_info", "ids": ["solaria.supporter"], "localized_prices": ["$2.99"]}, p, c)
	check(String(Store.prices.get("solaria.supporter", "")) == "$2.99", "prices come from the App Store")
	print("store: owned %s" % [p.owned_products])
