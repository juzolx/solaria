extends SceneTree
## 2.1: the Ring and Necklace gear slots (8 in all): data, drops, charms, equip, the Gear tab,
## loot filter, presets, shop, Wheel, reroll, crafting, Gear Score, collections, save/load.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

class FakeSfx:
	func play(_n: String) -> void:
		pass

class FakeMain extends Node:
	var state: GameState
	var sfx := FakeSfx.new()
	func refresh() -> void:
		pass

func _hero() -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.floor_num = 60
	g.best_floor = 60
	return g

func _give(g: GameState, slot: String, rarity: int, floor_num := 60) -> Dictionary:
	var it := GameData.make_item(slot, rarity, floor_num, g._new_id())
	g.bag.append(it)
	g.bag_version += 1
	return it

func _initialize() -> void:
	_data()
	_items()
	_drops()
	_equip_and_score()
	await _gear_tab()
	_filter_presets()
	_shop_smith_craft()
	_wheel_reroll()
	_collections_looks()
	_save_load()
	print("STAGE6 SLOTS TESTS DONE, failures: ", fails)
	quit()

func _data() -> void:
	check(GameData.SLOT_ORDER.size() == 8, "8 gear slots")
	check(GameData.SLOT_ORDER.slice(6) == ["Ring", "Necklace"], "Ring and Necklace come last")
	for s in GameData.SLOT_ORDER:
		check(GameData.SLOT_INFO.has(s) and ItemPool.TYPES.has(s), "slot has info and types: " + s)
	check(GameData.SHOP_SIZE >= GameData.SLOT_ORDER.size(), "the shop can stock one item per slot")
	for zi in ItemPool.ZONES.size():
		for s in GearSlots.JEWELRY:
			var list: Array = GearSlots.POOL[mini(zi, GearSlots.POOL.size() - 1)][s]
			check(list.size() >= 3, "zone %d has %s items" % [zi, s])
			for e in list:
				check(String(e[1]) in ItemPool.TYPES[s], "%s type fits its slot" % e[0])
	check(GearSlots.POOL.size() == ItemPool.ZONES.size(), "jewelry for every zone")
	for s in GearSlots.JEWELRY:
		for t in ItemPool.TYPES[s]:
			check(ResourceLoader.exists("res://art/gear/%s.png" % t), "icon art for " + t)
			var ic := Sprites.item_icon({"slot": s, "type": t, "rarity": 2})
			check(ic != null and ic.get_width() == ArtStyle.ICON_FRAME, "%s icon in the shared frame" % t)
	# half a slot: 15% of a weapon's Attack, 25% of a helmet's HP, same Gear Score scale
	var rw := GameData.base_bonus("Ring", 100) / GameData.base_bonus("Weapon", 100)
	var nh := GameData.base_bonus("Necklace", 100) / GameData.base_bonus("Helmet", 100)
	check(rw > 0.12 and rw < 0.2, "a ring is a small share of a weapon (%.2f)" % rw)
	check(nh > 0.2 and nh < 0.3, "a necklace is a small share of a helmet (%.2f)" % nh)
	var gw := GameData.gear_score(GameData.make_item("Weapon", 2, 100, 1))
	var gr := GameData.gear_score(GameData.make_item("Ring", 2, 100, 2))
	var gn := GameData.gear_score(GameData.make_item("Necklace", 2, 100, 3))
	check(absf(gr - gw) / gw < 0.15 and absf(gn - gw) / gw < 0.15, "Gear Score puts jewelry on the same scale (%d %d %d)" % [gw, gr, gn])

func _items() -> void:
	var ring_fx: Array = GearSlots.CHARMS["Ring"].map(func(c): return String(c[0]))
	var neck_fx: Array = GearSlots.CHARMS["Necklace"].map(func(c): return String(c[0]))
	for i in 40:
		var c := GameData.make_item("Ring", 0, 20, i)
		check(c["stat"] == "Attack" and String(c["effect"]) == "", "a Common ring: Attack, no charm")
		for r in [1, 2, 3]:
			var ring := GameData.make_item("Ring", r, 20, i)
			check(String(ring["effect"]) in ring_fx and int(ring["effect_value"]) > 0, "rarity %d ring has a ring charm (%s)" % [r, ring["effect"]])
			var neck := GameData.make_item("Necklace", r, 20, i)
			check(neck["stat"] == "HP" and String(neck["effect"]) in neck_fx and int(neck["effect_value"]) > 0, "rarity %d necklace has a necklace charm (%s)" % [r, neck["effect"]])
		var lr := GameData.make_item("Ring", GameData.LEGENDARY, 20, i)
		check(String(lr["effect"]) in GearSlots.LEGENDARY_POOL["Ring"], "Legendary ring rolls a ring effect (%s)" % lr["effect"])
		var ln := GameData.make_item("Necklace", GameData.LEGENDARY, 20, i)
		check(String(ln["effect"]) in GearSlots.LEGENDARY_POOL["Necklace"], "Legendary necklace rolls a necklace effect (%s)" % ln["effect"])
		check(GameData.make_item("Helmet", 2, 20, i)["effect"] == "", "body gear below Legendary still has no effect")
	check(GearSlots.legendary_effects("Weapon").size() == GameData.LEGENDARY_EFFECTS.size(), "body gear keeps every Legendary effect")
	var mythic := GameData.make_item("Necklace", GameData.MYTHIC, 20, 1)
	check(String(mythic["effect"]) in GearSlots.LEGENDARY_POOL["Necklace"], "Mythic jewelry works")
	# uniques for both slots (so "a rare find for every slot" can be finished)
	var have := {}
	for zi in GameData.ZONES.size():
		for u in GameData.zone_uniques(zi):
			have[String(u["slot"])] = true
			var it := GameData.make_unique(u, 50, 1)
			check(GameData.item_power(it) > 0 and Sprites.item_icon(it) != null, "unique works: " + String(u["id"]))
	check(have.has("Ring") and have.has("Necklace"), "uniques exist for Ring and Necklace")
	var txt := ItemText.plain(GameData.make_item("Necklace", 2, 20, 9))
	check(txt.contains("Necklace"), "item text names the slot")

func _drops() -> void:
	var g := _hero()
	var seen := {}
	for i in 3000:
		seen[g._drop_slot("kobold")] = true
	check(seen.has("Ring") and seen.has("Necklace"), "monsters drop rings and necklaces")
	var picks := {}
	for i in 400:
		picks[GameData.SLOT_ORDER.pick_random()] = true
	check(picks.size() == 8, "chests, bosses and events (SLOT_ORDER) can give all 8 slots")

func _equip_and_score() -> void:
	var g := _hero()
	var atk := g.get_attack()
	var hp := g.get_max_hp()
	var ring := _give(g, "Ring", 2)
	var neck := _give(g, "Necklace", 2)
	g.equip(int(ring["id"]))
	g.equip(int(neck["id"]))
	check(g.equipped.has("Ring") and g.equipped.has("Necklace"), "both slots equip")
	check(g.get_attack() > atk, "a ring adds Attack")
	check(g.get_max_hp() > hp, "a necklace adds HP")
	check(g.average_gear_score() == int(round((GameData.gear_score(ring) + GameData.gear_score(neck)) / 2.0)), "Gear Score averages the jewelry")
	var e := String(ring["effect"])
	var tot := g.effect_value(e) if not e in GameData.ITEM_BONUS_EFFECTS else g._flat(e)
	check(tot >= float(ring["effect_value"]), "the ring's charm counts (%s)" % e)
	# Equip Best fills empty jewelry slots
	var g2 := _hero()
	_give(g2, "Ring", 1)
	_give(g2, "Necklace", 1)
	check(g2.has_upgrade("Ring") and g2.has_upgrade("Necklace"), "an empty jewelry slot shows an upgrade")
	g2.equip_best()
	check(g2.equipped.has("Ring") and g2.equipped.has("Necklace"), "Equip Best wears jewelry")
	# blessings: half a slot
	var g3 := _hero()
	g3.equipped["Ring"] = GameData.make_item("Ring", 2, 60, g3._new_id())
	g3.equipped["Ring"]["blessed"] = true
	var src := Church.bonus_sources(g3)
	check(src.size() == 1 and is_equal_approx(float(src[0]["atk"]), 1.0 + (Economy.BLESS_POWER - 1.0) * 0.5), "a blessed ring gives half a blessing")

func _gear_tab() -> void:
	var g := _hero()
	var fm := FakeMain.new()
	fm.state = g
	root.add_child(fm)
	var ring := _give(g, "Ring", 3)
	g.equip(int(ring["id"]))
	_give(g, "Necklace", 1)
	var tab := GearTab.new()
	tab.setup(fm)
	fm.add_child(tab)
	tab.size = Vector2(406, 780)  # grows to its widest line under the test's default theme; the slot row is checked below
	tab.refresh()
	await process_frame
	await process_frame
	check(tab.slot_labels.has("Ring") and tab.slot_labels.has("Necklace"), "the Gear tab has Ring and Necklace slots")
	# Interface pass: slots are squares with a name under them; each slot's full line is its tap-tip (slot_info)
	check(String(tab.slot_info["Ring"]).contains("RING") and String(tab.slot_info["Ring"]).contains(String(ring["name"])), "the Ring card shows the worn ring")
	check(String(tab.slot_info["Necklace"]).contains("NECKLACE") and String(tab.slot_info["Necklace"]).contains("UPGRADE"), "the Necklace card shows the upgrade in the bag")
	var doll_row: Control = tab.slot_pics["Ring"].get_parent().get_parent().get_parent().get_parent()
	check(doll_row.get_combined_minimum_size().x <= 406.0, "the slot columns and hero fit a phone width (min %s)" % doll_row.get_combined_minimum_size())
	for s in GameData.SLOT_ORDER:
		var card: Control = tab.slot_pics[s].get_parent().get_parent()
		check(card.get_global_rect().size.y >= 60, "%s card is a big touch target (%s)" % [s, card.get_global_rect()])
	var ev := InputEventMouseButton.new()
	ev.pressed = true
	ev.button_index = MOUSE_BUTTON_LEFT
	tab._on_card_input(ev, "Necklace")
	tab.refresh()
	check(tab.slot == "Necklace" and tab.item_grid.get_child_count() >= 1, "tapping Necklace lists necklaces from the bag")
	fm.queue_free()
	await process_frame

func _filter_presets() -> void:
	var g := _hero()
	LootRules.test_ignore_upgrades = true
	LootRules.toggle_slot(g, "Ring")
	var r := GameData.make_item("Ring", 0, 5, g._new_id())
	var n := GameData.make_item("Necklace", 0, 5, g._new_id())
	check(LootRules.decide(g, r) != "keep", "the slot rule lets Common rings go")
	check(LootRules.decide(g, n) == "keep", "necklaces are kept when only Ring is marked")
	LootRules.test_ignore_upgrades = false
	# presets remember jewelry
	var ring := _give(g, "Ring", 2)
	var neck := _give(g, "Necklace", 2)
	g.equip(int(ring["id"]))
	g.equip(int(neck["id"]))
	Presets.save(g, 0, "Jewels")
	g.unequip(int(ring["id"]))
	g.unequip(int(neck["id"]))
	check(not g.equipped.has("Ring"), "setup: ring taken off")
	Presets.apply(g, 0)
	check(g.equipped.has("Ring") and int(g.equipped["Ring"]["id"]) == int(ring["id"]) and g.equipped.has("Necklace"), "a preset puts the ring and necklace back on")

func _shop_smith_craft() -> void:
	var g := _hero()
	for s in GearSlots.LOOK_SLOTS:
		g.equipped[s] = GameData.make_item(s, 1, 60, g._new_id())
	g.restock_shop()
	check(g.shop.size() == 8, "the shop has 8 items")
	var slots: Array = g.shop.map(func(it): return String(it["slot"]))
	check(slots.slice(0, 2).has("Ring") and slots.slice(0, 2).has("Necklace"), "missing ring and necklace are stocked first (%s)" % [slots])
	g.equipped.clear()
	g.restock_shop()
	slots = g.shop.map(func(it): return String(it["slot"]))
	check(slots == GameData.SLOT_ORDER, "an empty hero gets one item per slot (%s)" % [slots])
	var seen := {}
	for i in 60:
		Smith.restock(g)
		for e in g.smith_stock:
			seen[String(e["item"]["slot"])] = true
	check(seen.has("Ring") and seen.has("Necklace"), "the Blacksmith forges jewelry too")
	g.scrap = 1000
	g.craft_gear("Ring")
	g.craft_gear("Necklace")
	var crafted: Array = g.bag.filter(func(it): return it["slot"] in ["Ring", "Necklace"])
	check(crafted.size() == 2, "mystery gear crafts a ring and a necklace")

func _wheel_reroll() -> void:
	var g := _hero()
	g.gold = 1000000
	g.dev_mode = true
	g.dev_always_win = true
	var ring := _give(g, "Ring", 1)
	var fx := String(ring["effect"])
	var v1 := int(ring["effect_value"])
	var out := g.gamble(int(ring["id"]))
	check(bool(out.get("ok", true)) and int(ring["rarity"]) == 2, "the Wheel takes a ring")
	check(String(ring["effect"]) == fx and int(ring["effect_value"]) >= v1, "a Wheel win keeps the charm and makes it stronger")
	g.gamble(int(ring["id"]))
	g.gamble(int(ring["id"]))
	check(int(ring["rarity"]) == GameData.LEGENDARY and String(ring["effect"]) in GearSlots.LEGENDARY_POOL["Ring"], "a ring won up to Legendary gets a ring effect")
	var neck := _give(g, "Necklace", 2)
	g.scrap = 100000
	g.dust = 100000
	var tries := 0
	while int(neck["rarity"]) == 2 and tries < 200:
		g.reroll(int(neck["id"]))
		tries += 1
	check(int(neck["rarity"]) == 3 and String(neck["effect"]) in GearSlots.CHARMS["Necklace"].map(func(c): return String(c[0])), "a rerolled necklace keeps a necklace charm")
	check(GameData.sell_value(neck) > 0 and GameData.scrap_value(neck) > 0 and GameData.upgrade_cost(neck) > 0, "sell, scrap and upgrade work for jewelry")

func _collections_looks() -> void:
	check(Collections.total("slots") == 8, "the every-slot milestone counts 8 slots")
	var need := 0
	for m in Collections.all():
		if String(m["id"]) == "slots_all":
			need = int(m["need"])
	check(need == 8, "Fully Kitted needs all 8")
	var c := Codex.new()
	c.path = ""
	for zi in GameData.ZONES.size():
		for u in GameData.zone_uniques(zi):
			c.collection[String(u["id"])] = "x"
	check(Collections.count(c, "slots") == 8, "uniques can fill all 8 slots (%d)" % Collections.count(c, "slots"))
	var g := _hero()
	var before := g.wardrobe.size()
	g.add_to_wardrobe(GameData.make_item("Ring", 2, 10, g._new_id()))
	check(g.wardrobe.size() == before, "rings don't go in the wardrobe (no look)")
	g.equipped["Necklace"] = GameData.make_item("Necklace", 2, 10, g._new_id())
	check(not g.hero_looks().has("Necklace") and not g.hero_looks().has("Ring"), "jewelry doesn't change the hero's look")

func _save_load() -> void:
	var g := _hero()
	g.autosave = true
	g.slot = 7
	var ring := _give(g, "Ring", 3)
	var neck := _give(g, "Necklace", GameData.LEGENDARY)
	g.equip(int(ring["id"]))
	g.equip(int(neck["id"]))
	g.save_game(true)
	var ld := GameState.new()
	ld.codex.path = ""
	ld.slot = 7
	check(ld.load_game(), "loads")
	check(ld.equipped.has("Ring") and String(ld.equipped["Ring"]["effect"]) == String(ring["effect"]), "the ring and its charm survive a save")
	check(ld.equipped.has("Necklace") and String(ld.equipped["Necklace"]["effect"]) == String(neck["effect"]), "the necklace survives a save")
	# a slot this version doesn't know: dropped, never a crash
	ld.autosave = true
	var odd: Dictionary = (ld.equipped["Ring"] as Dictionary).duplicate()
	odd["slot"] = "Earring"
	ld.equipped["Earring"] = odd
	var odd2: Dictionary = odd.duplicate()
	odd2["id"] = ld._new_id()
	odd2["slot"] = "Tail"
	odd2.erase("type")
	ld.bag.append(odd2)
	ld.save_game(true)
	var l2 := GameState.new()
	l2.codex.path = ""
	l2.slot = 7
	check(l2.load_game(), "a save with unknown slots still loads")
	check(not l2.equipped.has("Earring") and l2.bag.all(func(it): return GameData.SLOT_INFO.has(String(it["slot"]))), "unknown-slot gear is put away")
	check(l2.equipped.has("Ring") and l2.equipped.has("Necklace"), "known jewelry stays on")
	check(GameData.gear_score({"slot": "Tail", "bonus": 5, "level": 0}) == 0 and GameData.item_type({"slot": "Tail"}) != "", "odd items never crash the helpers")
	GameState.delete_slot(7)
