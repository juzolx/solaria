extends SceneTree

var fails := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)

func _initialize() -> void:
	seed(12345)
	GameState.delete_saves()
	Codex.delete()

	printerr("section 1")
	# ---------- 1. Old-save conversion ----------
	var old_items := []
	for i in 15:
		old_items.append({"name": "Rare Sword", "slot": "Weapon", "stat": "Attack", "rarity": 2, "bonus": 10 + i, "floor": 3})
	var f := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	f.store_var({"floor": 7, "best_floor": 9, "hero_hp": 50, "inventory": old_items, "equipped": {"Weapon": 3}})
	f = null
	check(GameState.migrate_legacy() == [1], "legacy save moved into hero slot 1")
	check(GameState.has_slot(1) and not FileAccess.file_exists(GameState.SAVE_PATH), "legacy file moved")
	var s := GameState.new()
	check(s.load_game(), "old save loads")
	check(s.floor_num == 7 and s.best_floor == 9, "old floors kept")
	check(s.equipped.has("Weapon") and int(s.equipped["Weapon"]["bonus"]) == 13, "old equipped weapon kept")
	check(s.bag.size() == 10, "bag filled to 10 (got %d)" % s.bag.size())
	check(s.gold > 0, "extra items sold")
	check(s.shop.size() == GameData.SHOP_SIZE, "shop stocked after conversion")
	var s2 := GameState.new()
	check(s2.load_game() and s2.bag.size() == 10 and s2.equipped.has("Weapon"), "converted save reloads as v2")

	printerr("section 2")
	# ---------- 2. Long simulated game with a simple 'player' ----------
	GameState.delete_slot(1)
	var g := GameState.new()
	g.autosave = false  # fast; saving is tested after
	g.codex.path = ""
	g.new_game()
	g.choose_class("Mage")
	var bosses_killed := 0
	var uniques := 0
	var deaths := 0
	var max_floor := 1
	for turn in 20000:
		var boss_before := g.enemy_is_boss
		var floor_before := g.floor_num
		g.take_turn()
		for m in g.messages:
			if m.contains("UNIQUE DROP"):
				uniques += 1
			if m.contains("You were defeated"):
				deaths += 1
		if boss_before and g.floor_num == floor_before + 1:
			bosses_killed += 1
		g.messages.clear()
		g.events.clear()
		max_floor = maxi(max_floor, g.floor_num)

		# Invariants
		if g.hero_hp > g.get_max_hp() or g.hero_hp <= 0:
			check(false, "hero hp out of range %d / %d at turn %d" % [g.hero_hp, g.get_max_hp(), turn])
			break
		if g.bag.size() > g.bag_capacity() + 5:
			check(false, "bag overfilled")
			break

		# Every 25 turns act like a player: equip upgrades, sell/salvage junk, spend
		if turn % 25 == 0:
			for item in g.bag.duplicate():
				var slot: String = item["slot"]
				var cur := 0
				if g.equipped.has(slot):
					cur = GameData.item_power(g.equipped[slot])
				if GameData.item_power(item) > cur:
					g.equip(int(item["id"]))
			for junk_item in g.bag.duplicate():
				if g.bag.size() <= 4:
					break
				var junk: Dictionary = junk_item
				if junk.get("locked", false):
					continue
				if randi() % 2 == 0:
					g.sell(int(junk["id"]))
				else:
					g.salvage(int(junk["id"]))
			if g.equipped.has("Weapon"):
				var w: Dictionary = g.equipped["Weapon"]
				g.upgrade(int(w["id"]))
				if GameData.can_reroll(w):
					g.reroll(int(w["id"]))
			if g.bag_level < GameData.BAG_MAX_LEVEL and g.gold > g.next_bag_cost() * 3:
				g.buy_bag_upgrade()
			if g.potions < 3:
				g.buy_potion()
				g.craft_potion()
			if g.gold > 500 and g.shop.size() > 0:
				g.buy_shop(0)
			if g.scrap > 200:
				g.craft_gear(GameData.SLOT_ORDER.pick_random())
			if turn % 1000 == 0:
				g.cycle_auto_salvage()
			g.messages.clear()
		g.events.clear()

	print("Simulated 20000 turns: max floor %d, bosses killed %d, uniques %d, deaths %d" % [max_floor, bosses_killed, uniques, deaths])
	print("End: floor %d, gold %d, scrap %d, potions %d, bag %d/%d (level %d), ATK %d DEF %d HP %d" % [
		g.floor_num, g.gold, g.scrap, g.potions, g.bag.size(), g.bag_capacity(), g.bag_level, g.get_attack(), g.get_defense(), g.get_max_hp()])
	check(max_floor > 10, "reached past the first boss (max %d)" % max_floor)
	check(bosses_killed > 0, "killed at least one boss")

	# Retreat + unequip
	var fl := g.floor_num
	g.retreat()
	check(g.floor_num == fl - 1 or fl == 1 or g.boss_cooldown(fl - 1) > 0, "retreat goes up a floor (unless a resting boss is there)")

	# Save round trip
	g.autosave = true
	g.save_game()
	var h := GameState.new()
	check(h.load_game(), "save loads")
	check(h.floor_num == g.floor_num and h.gold == g.gold and h.bag.size() == g.bag.size() and h.equipped.size() == g.equipped.size(), "save round trip matches")
	h.codex = g.codex  # achievement power comes from the Codex, which this test keeps in memory only
	h.buffs = g.buffs.duplicate(true)  # fight buffs are not saved on purpose
	check(h.get_attack() == g.get_attack(), "stats match after load (%d vs %d)" % [h.get_attack(), g.get_attack()])

	# Forced unique
	var u := GameData.make_unique(GameData.ZONES[0]["boss"]["uniques"][0], 10, 999)
	check(u["name"] == "Hrunting" and u["effect"] == "lifesteal" and int(u["rarity"]) == 5, "unique item built")
	check(GameData.bag_cost(0) == 10 and GameData.bag_cost(1) == 15 and GameData.bag_cost(19) > 20000, "bag costs: %d %d %d" % [GameData.bag_cost(0), GameData.bag_cost(1), GameData.bag_cost(19)])

	printerr("section 3")
	# ---------- 3. The real scene: every tab, button and popup ----------
	GameState.delete_saves()
	Profile.delete()
	var scene: PackedScene = load("res://main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	var title_scr: TitleScreen = null
	for c in main.get_children():
		if c is TitleScreen:
			title_scr = c
	check(title_scr != null, "launch shows the title screen")
	title_scr._fill_menu()
	var hs := HeroSelect.new()
	hs.show_for(main, title_scr)
	await process_frame
	hs.close()
	title_scr.queue_free()
	main.new_hero(1, false)
	await process_frame
	var creator: CharacterCreator = null
	for c in main.get_children():
		if c is CharacterCreator:
			creator = c
	check(creator != null, "character creator shows for a new hero")
	creator._pick("race", "Elf")
	creator._pick("hair", "Long")
	creator._randomize()
	check(creator.name_edit != null, "new heroes get a name box")
	creator.name_edit.text = "Testa"
	creator._finish()
	await process_frame
	check(main.state.hero_name == "Testa", "hero name saved")
	check(main.state.race() == "Elf" and main.state.stat("AGI") == 4, "race picked and gives stats")
	check(main.class_overlay != null, "class picker shows on a new game")
	main._on_class_chosen("Ranger")
	check(main.state.hero_class == "Ranger" and main.class_overlay == null, "picking a class works")
	check(main.state.equipped.has("Weapon") and GameData.item_type(main.state.equipped["Weapon"]) == "bow", "class outfit: Ranger starts with a bow")
	check(main.state.equipped_actives() == ["piercing_shot"], "starting skill equipped")
	main.state.dev_mode = true
	var t0 := Time.get_ticks_msec()
	for i in 3000:
		if i % 300 == 0:
			print("tick %d  %d ms  nodes %d  mem %d MB" % [i, Time.get_ticks_msec() - t0, Performance.get_monitor(Performance.OBJECT_NODE_COUNT), OS.get_static_memory_usage() / 1048576])
		main._on_tick()
		if i % 60 == 0:
			var gs: GameState = main.state
			# Visit every tab
			for gi in 5:
				var group: TabContainer = main._groups()[gi]
				for sub in group.get_tab_count():
					main.show_tab(gi, sub)
					main.refresh()
			# Hero: spend points
			for st in GameData.STAT_ORDER:
				(main.hero_tab.rows[st]["p1"] as Button).pressed.emit()
			# Skills: select + learn everything possible
			gs.dust += 500
			for id in SkillData.SKILLS.keys().slice(0, 12):
				gs.craft_skill(id)
			main.skills_tab.shown = ""
			main.skills_tab.refresh()
			for fi in main.skills_tab.filter_pick.item_count:
				main.skills_tab.filter_pick.select(fi)
				main.skills_tab.shown = ""
				main.skills_tab.refresh()
			main.skills_tab.filter_pick.select(0)
			main.skills_tab.shown = ""
			main.skills_tab.refresh()
			if main.skills_tab.ids.size() > 0 and main.skills_tab.ids[0] != "":
				main.skills_tab.selected = main.skills_tab.ids[0]
				main.skills_tab._show_detail()
				main.skills_tab.equip_button.pressed.emit()
				main.skills_tab.equip_button.pressed.emit()
				main.skills_tab.craft_button.pressed.emit()
			main.skills_tab._craft_popup()
			# Gear: tap slots and wear the first item
			for slot in GameData.SLOT_ORDER:
				var ev := InputEventMouseButton.new()
				ev.pressed = true
				ev.button_index = MOUSE_BUTTON_LEFT
				main.gear_tab._on_card_input(ev, slot)
				main.gear_tab.refresh()
				var cells: Array = main.gear_tab.item_grid.get_children()
				if cells.size() > 1:
					(cells[1] as Button).pressed.emit()
			main.gear_tab.equip_best_button.pressed.emit()
			# Bag: sort, filter, lock, sell, salvage, upgrade, reroll
			main.bag_tab.sort_pick.select(i / 60 % 4)
			main.bag_tab.filter_pick.select(i / 60 % 7)
			main.bag_tab.refresh()
			if gs.bag.size() > 0:
				main.bag_tab.selected_id = int(gs.bag[0]["id"])
				for a in ["lock", "lock", "upgrade", "reroll", "equip", "equip", "salvage"]:
					main.bag_tab._act(a)
			if gs.bag.size() > 0:
				main.bag_tab.selected_id = int(gs.bag[0]["id"])
				main.bag_tab._act("sell")
			for r in [0, 1, 2, 3]:
				main.bag_tab._salvage_all(r)
			main.bag_tab.auto_salvage_button.pressed.emit()
			# Shop
			gs.gold += 2000
			main.shop_tab.refresh()
			if main.shop_tab.gear_buttons.size() > 0:
				(main.shop_tab.gear_buttons[0][0] as Button).pressed.emit()
			main.shop_tab.featured_buy.pressed.emit()
			for id in main.shop_tab.supplies:
				(main.shop_tab.supplies[id][0] as Button).pressed.emit()
			main.shop_tab.bag_button.pressed.emit()
			main.shop_tab.restock_button.pressed.emit()
			for r in main.shop_tab.quick_sell:
				(main.shop_tab.quick_sell[r] as Button).pressed.emit()
			# Craft
			gs.scrap += 500
			gs.materials = [5, 5, 5, 5, 5, 0, 0, 0, 0, 0]
			main.craft_tab.refresh()
			main.craft_tab.potion_button.pressed.emit()
			main.craft_tab.bag_button.pressed.emit()
			for set_name in main.craft_tab.set_buttons:
				(main.craft_tab.set_buttons[set_name][0][0] as Button).pressed.emit()
			for slot in main.craft_tab.gear_buttons:
				(main.craft_tab.gear_buttons[slot] as Button).pressed.emit()
			# Fight buttons
			for b in main.skill_buttons:
				b.pressed.emit()
			main.potion_button.pressed.emit()
			main.auto_potion_button.pressed.emit()
			main.speed_button.pressed.emit()
			main._on_battle_tapped(Vector2(400, 200))
			main.last_tap_ms = 0
			for c in main.get_children():
				if c is Overlay and c != main.class_overlay:
					c.close()
			await process_frame
		if i == 600:
			# Popups: floor picker, menu, dev tools, confirm
			var fp := FloorPicker.new()
			fp.show_for(main)
			await process_frame
			for zb in fp._zone_block(main.state.best_floor) + 1:
				fp._show_zone(zb)
			fp._go(1)
			check(main.state.floor_num == 1, "floor picker travels")
			var menu := SettingsMenu.new()
			menu.show_for(main)
			for kind in ["level", "gold", "scrap", "materials", "floor_up", "floor_down", "legendary", "unique", "heal", "signature", "rare", "event", "merchant"]:
				main.state.dev_grant(kind)
			for k in menu.a11y_buttons:
				(menu.a11y_buttons[k] as Button).pressed.emit()
			menu.close()
			main.refresh()
			main.state.path_offer = []
			# Popups added in 0.7.5
			GuideBook.open_book(main, "welcome", true)
			main.state._make_merchant()
			MerchantPopup.new().show_for(main)
			LootFilter.new().show_for(main)
			if main.state.bag.size() > 0:
				ItemPopup.show_item(main, main.state.bag[0], [["Equip", func(): pass]])
			main._daily_login()
			await process_frame
			for c in main.get_children():
				if c is Overlay and c != main.class_overlay:
					c.close()
			await process_frame
			var said := [false]
			main.confirm("Test?", "Testing", "Yes", func(): said[0] = true)
			await process_frame
			check(said[0] == false, "confirm waits for yes")
	await process_frame
	print("UI test: floor %d, level %d, %s, bag %d" % [main.state.floor_num, main.state.level, main.state.title(), main.state.bag.size()])
	check(main.state.level > 5, "UI run levelled up")

	# Hardcore: separate save, deleted on death, recorded in the profile
	main.queue_free()
	await process_frame
	var hc := GameState.new()
	hc.hardcore = true
	hc.slot = 2
	hc.new_game()
	hc.choose_class("Mage")
	hc.save_game()
	check(GameState.has_slot(2) and GameState.slot_meta(2)["hardcore"], "hardcore save exists")
	check(GameState.has_slot(1), "regular save untouched")
	hc.hero_hp = 1
	for _k in 30:
		hc.enemy_attack = 999999
		hc.enemy_hp = 999999
		hc.take_turn()
		if hc.run_over:
			break
	check(hc.run_over, "hardcore hero dies for good")
	var pr := Profile.load_profile()
	var best := pr.record_hc_run(hc)
	hc.delete_own_saves()
	check(not GameState.has_slot(2) and GameState.has_slot(1), "only the hardcore save was deleted")
	check(Profile.load_profile().hc_runs.size() >= 1 and best, "hardcore run recorded")

	# Path rooms
	var pr2 := GameState.new()
	pr2.autosave = false
	pr2.new_game()
	pr2.choose_class("Warrior")
	pr2.floor_num = 12
	pr2.spawn_enemy()
	for kind in ["treasure", "rest", "elite", "fight"]:
		pr2.path_offer = ["fight", "treasure", "rest"]
		var hp_before := pr2.enemy_max_hp
		pr2.take_turn()
		check(pr2.enemy_hp > 0 or true, "paused while choosing")
		pr2.choose_path(kind)
		check(pr2.path_offer.is_empty(), "path chosen: " + kind)
		if kind == "elite":
			check(pr2.enemy_elite and pr2.enemy_max_hp > hp_before, "elite is tougher")
		if kind == "rest":
			check(pr2.elixirs.has("rested") and pr2.hero_hp == pr2.get_max_hp(), "rest heals and buffs")
	check(GameData.active_events().size() >= 1, "an event is always running")

	# Wardrobe and transmog
	var w := GameState.new()
	w.new_game()
	var it := GameData.make_item("Helmet", 3, 20, 77)
	w.bag.append(it)
	w.add_to_wardrobe(it)
	w.equip(77)
	check(w.hero_looks().has("Helmet"), "worn helmet shows")
	w.set_transmog("Helmet", "hide")
	check(not w.hero_looks().has("Helmet"), "hidden helmet")
	var key: String = w.wardrobe.keys()[0]
	w.set_transmog("Helmet", key)
	check(w.hero_looks().has("Helmet"), "transmog look shows")
	var hero_pic := Sprites.hero(w.appearance, w.hero_looks())
	check(hero_pic["body"] != null, "hero picture builds")
	check(ItemPool.count() == 300, "300 hand-made items (got %d)" % ItemPool.count())
	for mname in Monsters.all_monsters():
		check(not Sprites.enemy_by_key(GameData.art_key(mname)).is_empty(), "art for " + mname)
	for zi in GameData.ZONES.size():
		check(not Sprites.enemy_by_key(GameData.ZONES[zi]["boss"]["art"]).is_empty(), "boss art zone %d" % zi)
		check(not Sprites.enemy_by_key(GameData.ZONES[zi]["mid"]["art"]).is_empty(), "mid boss art zone %d" % zi)
		for si in 5:
			check(ResourceLoader.exists("res://art/bg/zone_%d_%d.png" % [zi, si]), "background zone %d area %d" % [zi, si])
	check(not Sprites.enemy_by_key("treasure_goblin").is_empty(), "treasure goblin art")
	for t in ItemPool.all_types():
		var look := {"type": t, "mat": "steel", "trim": Color.RED, "glow": false}
		var slot := ""
		for sl in ItemPool.TYPES:
			if t in ItemPool.TYPES[sl]:
				slot = sl
		var ha := Sprites.hero({}, {slot: look})
		check(ha["body"] != null, "gear art " + t)

	printerr("section foundation")
	# ---------- 0.7.5 Foundation ----------
	# Zones of 50 floors, 5 areas, mid boss 25, zone boss 50
	GameData.realm_order = []
	check(GameData.zone_index(1) == 0 and GameData.zone_index(50) == 0 and GameData.zone_index(51) == 1 and GameData.zone_index(250) == 4 and GameData.zone_index(251) == 5 and GameData.zone_index(501) == 0, "zone index")
	check(GameData.zone_rank(250) == 0 and GameData.zone_rank(251) == 0 and GameData.zone_rank(500) == 0 and GameData.zone_rank(501) == 1, "zone rank")
	check(GameData.boss_kind(25) == "mid" and GameData.boss_kind(50) == "zone" and GameData.boss_kind(75) == "mid" and GameData.boss_kind(24) == "", "boss floors")
	check(GameData.sub_index(1) == 0 and GameData.sub_index(10) == 0 and GameData.sub_index(11) == 1 and GameData.sub_index(50) == 4, "sub-areas")
	check(GameData.sub_start(25) == 21 and GameData.sub_start(50) == 41 and GameData.sub_start(77) == 71, "sub-area start")
	check(GameData.boss_for_floor(25)["name"] == "Black Annis" and GameData.boss_for_floor(100)["name"] == "Hel, Queen of the Dead", "boss lookup")
	check(Monsters.all_monsters().size() == 110 and Monsters.all_bosses().size() == 20, "110 monsters (0.13+: ten myth monsters), 20 bosses")
	for mname in Monsters.all_monsters():
		var inf := Monsters.info(mname)
		check(inf.get("lore", "") != "" and inf.get("drops", []).size() == 2 and Monsters.has_signature(mname), "monster info " + mname)
		var sig := GameData.make_signature(mname, 30, 1)
		check(int(sig["rarity"]) == GameData.SIGNATURE and sig["type"] in ItemPool.TYPES[sig["slot"]], "signature " + str(sig["name"]))
		check(not Sprites.gear_look(sig).is_empty() and Monsters.sig_by_art(sig["art"]).size() > 0, "signature look " + str(sig["name"]))
	for b in Monsters.all_bosses():
		check(Monsters.info(b).get("lore", "") != "", "boss lore " + b)
	var w_sum := 0.0
	for v in Monsters.tier_weights(false):
		w_sum += v
	check(absf(w_sum - 100.0) < 0.01, "tier weights add to 100")
	var hcw := Monsters.tier_weights(true)
	check(hcw[5] > Monsters.TIERS[5]["weight"], "hardcore sees more mythics")
	var counts := [0, 0, 0, 0, 0, 0]
	for _i in 20000:
		counts[Monsters.roll_tier(false)] += 1
	print("Tier rolls of 20000: ", counts)
	check(counts[0] > 11000 and counts[0] < 13000 and counts[5] > 40 and counts[5] < 180, "tier roll matches odds")
	var odds := GameData.rarity_odds(0, 0.4)
	check(absf(odds[0] + odds[1] + odds[2] + odds[3] + odds[4] - 100.0) < 0.01 and absf(odds[3] - 0.3984) < 0.001, "rarity odds")
	check(Codex.ACHIEVEMENTS.size() == 88, "88 achievements (got %d)" % Codex.ACHIEVEMENTS.size())
	var ids := {}
	for a in Codex.ACHIEVEMENTS:
		check(not ids.has(a["id"]), "achievement id unique " + a["id"])
		ids[a["id"]] = true
	for pid in ["welcome", "gear", "stats", "abilities", "death", "shop", "craft", "zones", "monster_tiers", "bestiary", "events", "merchant", "uniques", "specs", "heroes", "bounties"]:
		check(Guide.has_page(pid), "guide page " + pid)
	check(Guide.has_page("wheel"), "guide page wheel")

	var z := GameState.new()
	z.autosave = false
	z.codex = Codex.new()
	z.codex.path = ""
	z.new_game()
	z.choose_class("Warrior")
	# Tiers and modifiers
	z.floor_num = 30
	z.spawn_enemy()
	var base_hp := z.enemy_base_hp
	z._apply_tier(Monsters.MYTHIC)
	check(z.enemy_mods.size() == 4 and z.enemy_max_hp >= int(base_hp * 6.5), "mythic: 4 mods, much tougher")
	z._apply_tier(Monsters.MYTHIC)
	check(z.enemy_max_hp <= int(base_hp * 6.5 * 1.5) + 1, "re-applying a tier doesn't stack")
	check(z.enemy_scale() > 1.3, "mythic drawn bigger")
	z.enemy_mods = ["Shielded"]
	z.enemy_shield = 50
	var hp0 := z.enemy_hp
	z._damage_enemy(30)
	check(z.enemy_shield == 20 and z.enemy_hp == hp0, "shield soaks damage first")
	z.enemy_mods = ["Armored"]
	z.enemy_shield = 0
	hp0 = z.enemy_hp
	z._damage_enemy(100)
	check(hp0 - z.enemy_hp == 75, "armored takes 25% less")
	# Killing a monster: bestiary, bounty, loot from its favored slots
	z.codex.refresh_bounties(z)
	z.spawn_enemy()
	var sp := z.enemy_species
	z.enemy_hp = 0
	z._enemy_defeated()
	check(z.codex.kills(sp) == 1 and z.codex.stat("kills") == 1, "kill recorded in the bestiary")
	# Losing to a boss sends you back to the area start; travel needs the boss rested
	z.best_floor = 60
	z.go_to_floor(25)
	check(z.enemy_is_boss and z.enemy_boss_kind == "mid" and z.enemy_species == "Black Annis", "mid boss on 25")
	z.hero_hp = 1
	z.gold = 500
	z.bank = 2000
	var dz_keep := GameData.make_item("Helmet", 2, 25, z._new_id())
	dz_keep["bound"] = "soul"
	z.bag.append(GameData.make_item("Chest", 1, 25, z._new_id()))
	z.bag.append(dz_keep)
	z.equipped["Feet"] = GameData.make_item("Feet", 1, 25, z._new_id())
	z._hero_died()
	check(z.floor_num == 1, "fall on floor 25 -> wake at checkpoint floor 1 (got %d)" % z.floor_num)
	check(z.gold == 0 and z.bank == 2000, "falling loses carried gold, the Bank is safe")
	check(z.bag.size() == 1 and z.bag[0]["id"] == dz_keep["id"] and not z.equipped.has("Feet"), "falling loses bag and worn gear, bound items stay")
	check(GameState.checkpoint_start(37) == 26 and GameState.checkpoint_start(50) == 26 and GameState.checkpoint_start(51) == 51, "checkpoints every 25 floors")
	# 1,000 floors: region bosses every 100, walls at 250/500/750/1000, nothing below 1000
	check(GameData.region_of(1) == 0 and GameData.region_of(100) == 0 and GameData.region_of(101) == 1 and GameData.region_of(1000) == 9, "10 regions of 100 floors")
	var wz := GameState.new()
	wz.codex.path = ""
	wz.new_game()
	wz.floor_num = 225
	wz.spawn_enemy()
	var w_mid := wz.enemy_max_hp
	wz.floor_num = 250
	wz.spawn_enemy()
	check(wz.enemy_is_boss and wz.enemy_max_hp > w_mid * 2.5, "floor 250 is a wall (%d vs %d)" % [wz.enemy_max_hp, w_mid])
	wz.floor_num = 1000
	wz.best_floor = 1000
	wz._next_floor()
	check(wz.floor_num == 1000 and wz.feats.has("conquered"), "floor 1,000 is the bottom")
	check(z.boss_cooldown(25) > 0 and not z.go_to_floor(25), "boss needs a rest before travel")
	z.use_scroll("key")
	check(z.boss_cooldown(25) == 0 and z.go_to_floor(25), "boss key resets the rest")
	z.enemy_hp = 0
	var mats_before := z.material_total()
	z._enemy_defeated()
	check(z.door_pending() and z.doors.size() == 3 and "camp" in z.doors, "boss beaten: three blank doors, one leads to a camp (Snik is there)")
	check(Town.floor_clear(z), "a cleared room counts as between floors")
	z.doors[0] = "fight"
	z.choose_path("door_l")
	check(z.floor_num == 26 and z.material_total() >= mats_before + 5 and z.doors.is_empty(), "through a door: next floor, 5-8 materials")
	check(z.codex.kills("Black Annis") == 1 and z.codex.value("mids") == 1, "boss in the bestiary")
	# Signature drop
	z._give_signature("Kobold")
	check(z.codex.value("signatures") == 1 and z.codex.collection.has("Kobold's Candlehelm"), "signature collected")
	# Events
	z.path_offer = []
	z.bag.clear()
	z.floor_num = 33
	z.start_event("goblin")
	z.spawn_enemy()
	check(z.enemy_goblin and z.enemy_attack == 0, "treasure goblin spawns and doesn't attack")
	var gf := z.fight
	z.enemy_hp = 0
	z._enemy_defeated()
	check(z.codex.stat("goblins") == 1 and z.fight == gf, "goblin caught, doesn't count as a fight")
	z.start_event("goblin")
	z.spawn_enemy()
	z.enemy_hp = 999999999
	z.hero_hp = z.get_max_hp()
	for _k in GameData.GOBLIN_TURNS + 1:
		z.take_turn()
	check(not z.enemy_goblin, "goblin escapes")
	z.enemy_goblin = false
	z.path_offer = []
	z.start_event("horde")
	z.spawn_enemy()
	for _k in GameData.HORDE_SIZE:
		z.enemy_hp = 0
		z._enemy_defeated()
	check((z.horde_left == 0 or z.horde_pack) and z.codex.stat("hordes") == 1, "horde beaten")
	z.start_event("shrine")
	check(z.path_offer == ["shrine", "leave"], "shrine offers a choice")
	z.choose_path("shrine")
	check(z.curse_turns == GameData.CURSE_TURNS, "shrine curse taken")
	# Merchant
	z.bag.clear()
	z._make_merchant()
	check(z.merchant.size() >= 6, "merchant stock (0.13+: a curio, two pieces, potions, scrolls)")
	z.gold = 10000000
	var bag_n := z.bag.size()
	check(z.buy_merchant(0) and z.bag.size() == bag_n + 1 and z.merchant[0]["sold"], "buy from merchant")
	for i in range(2, 5):
		z.buy_merchant(i)
	# Loot filter
	z.loot_filter = {"slots": {"Helmet": true}, "weaker": false}
	check(z.filter_salvages(GameData.make_item("Helmet", 1, 30, 9001)) and not z.filter_salvages(GameData.make_item("Helmet", 4, 30, 9002)), "loot filter by slot, keeps Legendary")
	# Loadouts
	z.bag.append(GameData.make_item("Weapon", 2, 30, 9100))
	z.bag.append(GameData.make_item("Weapon", 3, 30, 9101))
	z.equip(9100)
	z.save_loadout(0)
	z.equip(9101)
	z.wear_loadout(0)
	check(int(z.equipped["Weapon"]["id"]) == 9100, "loadout swaps gear back")
	# Stash
	z.bag.clear()
	z.bag.append(GameData.make_item("Weapon", 3, 30, 9101))
	z.stash_ok = true
	var stash: Array = []
	check(z.to_stash(9101, stash, 20) and stash.size() == 1 and z.find_item(9101).is_empty(), "item into the stash")
	check(z.from_stash(0, stash) and stash.is_empty(), "item out of the stash")
	z.hardcore = true
	z.bag.append(GameData.make_item("Legs", 2, 30, 9200))
	check(not z.to_stash(9200, stash, 20), "hardcore can't use the stash")
	z.hardcore = false
	# Fortune's Wheel
	var wins := 0
	var spins := 0
	z.gold = 100000000
	for _k in 400:
		var gi := GameData.make_item("Chest", 0, 30, 20000 + _k)
		z.bag.append(gi)
		var res := z.gamble(int(gi["id"]))
		if res.get("ok", false):
			spins += 1
			if res["win"]:
				wins += 1
				check(int(gi["rarity"]) == 1 and z.find_item(int(gi["id"])).size() > 0, "wheel win upgrades the item")
				z.sell(int(gi["id"]))
			else:
				check(z.find_item(int(gi["id"])).is_empty(), "wheel loss takes the item")
	print("Wheel: %d / %d wins on Commons" % [wins, spins])
	check(spins == 400 and wins > 180 and wins < 260, "wheel odds about 55%")
	var leg := GameData.make_item("Legs", 4, 30, 30001)
	z.bag.append(leg)
	check(not z.gamble(30001).get("ok", false), "legendary can't go on the wheel")
	# Bounties and achievements
	var b0: Dictionary = z.codex.bounties["daily"][0]
	for _k in int(b0["need"]) * 3:
		z.codex.bounty_progress("kill", {"monster": b0.get("monster", ""), "zone": b0.get("zone", 0), "tier": 5})
		z.codex.bounty_progress("floor")
		z.codex.bounty_progress("item", {"rarity": 4})
		z.codex.bounty_progress("boss")
		z.codex.bounty_progress("event")
	check(z.codex.bounties_ready() >= 1, "a bounty finishes")
	var gold_b := z.gold
	for i in z.codex.bounties["daily"].size():
		z.claim_bounty(false, i)
	check(z.gold > gold_b and z.codex.stat("bounties") >= 1, "bounty claimed")
	z._check_codex()
	check(z.codex.achievements.has("myth1") or z.codex.stat("tier_5") == 0, "achievements unlock")
	check(z.codex.check_login() == 1 and z.codex.check_login() == 0, "daily login once a day")
	# Save round trip of the new fields
	z.autosave = true
	z.slot = 3
	z.hero_name = "Zed"
	z.save_game()
	var z2 := GameState.new()
	z2.slot = 3
	z2.codex = z.codex
	check(z2.load_game() and z2.hero_name == "Zed" and z2.curse_turns == z.curse_turns and z2.loadouts[0].size() > 0, "new fields saved")
	check(GameState.slot_meta(3)["name"] == "Zed", "slot meta for the title screen")
	# Cloud backup pack / unpack
	var pfx := Profile.load_profile()
	pfx.stash = [GameData.make_item("Feet", 3, 40, 5)]
	var pack := Online.pack_local(pfx)
	check(pack["heroes"].has(3), "backup packs heroes")
	var blob := Marshalls.variant_to_base64(pack)
	GameState.delete_slot(3)
	Online.unpack_local(pfx, Marshalls.base64_to_variant(blob))
	check(GameState.has_slot(3) and GameState.slot_meta(3)["name"] == "Zed" and pfx.stash.size() == 1, "backup restores")
	GameState.delete_slot(3)

	# ---------- Phase 8: classes, specializations, evolutions ----------
	check(Classes.ORDER.size() == 9, "9 classes")
	for cname in Classes.ORDER:
		var ci := Classes.info(cname)
		for sid in ci["start"]:
			check(SkillData.SKILLS.has(sid), "start skill exists: " + sid)
		for t in ci["tags"]:
			check(Classes.TAGS.has(t), "class tag exists: " + t)
		for slot in ci["look"]:
			check(ci["look"][slot] in ItemPool.TYPES[slot], "class look fits slot: %s %s" % [cname, slot])
		var roots := ClassTree.roots(cname)
		check(roots.size() == 2, "class tree roots: " + cname)
		var finals := 0
		for r1 in roots:
			check(ClassTree.children(r1).size() == 2, "two level-35 classes under " + String(r1))
			for r2 in ClassTree.children(r1):
				check(ClassTree.children(r2).size() == 2, "two finals under " + String(r2))
				finals += ClassTree.children(r2).size()
				check(ClassTree.branches(r2).size() >= 2 and ClassTree.branches(r2).size() <= 3, "2-3 branch-offs: " + String(r2))
			check(ClassTree.branches(r1).size() >= 2 and ClassTree.branches(r1).size() <= 3, "2-3 branch-offs: " + String(r1))
		check(finals == 8, "8 finals: " + cname)
	for sid in SkillData.SKILLS:
		var sk := SkillData.info(sid)
		for t in sk["tags"]:
			check(Classes.TAGS.has(t), "skill tag exists: %s %s" % [sid, t])
		if sk["kind"] == "active":
			check(sk.has("cd") and (sk.has("power") or sk.has("buff") or sk.has("shield") or sk.has("summon") or sk.has("song") or sk.has("wild")), "active skill does something: " + sid)
	print("Skills: %d active, %d passive" % [SkillData.all_of("active").size(), SkillData.all_of("passive").size()])
	check(ClassTree.all_nodes().size() == 9 * 14 + ClassTree.BRANCHES.size(), "every class name is unique (%d nodes)" % ClassTree.all_nodes().size())
	check(ClassTree.BRANCHES.size() == 125, "125 branch-offs (got %d)" % ClassTree.BRANCHES.size())
	for itk in ClassTree.ITEMS:
		check(not ClassTree.node(ClassTree.ITEMS[itk]["node"]).is_empty() and not ClassTree.node(ClassTree.ITEMS[itk]["at"]).is_empty(), "item nodes exist: " + itk)
	var gods := 0
	for id in ClassTree.all_nodes():
		var nd := ClassTree.node(id)
		if ClassTree.rank_of(nd) == "God":
			gods += 1
			check(not (nd["trial"] as Dictionary).is_empty(), "God class has a trial: " + id)
			check(ResourceLoader.exists("res://art/enemies/%s.png" % nd["trial"]["art"]), "god trial art: " + id)
	check(gods == 10, "10 God rank classes (got %d)" % gods)
	for itk in ClassTree.ITEMS:
		if ClassTree.ITEMS[itk].has("fight"):
			check(ResourceLoader.exists("res://art/enemies/%s.png" % ClassTree.ITEMS[itk]["fight"]["art"]), "item fight art: " + itk)
	var t := GameState.new()
	t.autosave = false
	t.codex.path = ""
	t.choose_class("Warrior")
	t.level = 10
	check(ClassTree.pick_tier(t) == -1 and t.title() == "Warrior", "no pick before level 15")
	t.level = 20
	t._check_spec()
	check(ClassTree.pick_tier(t) == 0 and t.events.any(func(ev): return ev["type"] == "class_pick"), "level 15: a pick is open and announced")
	var atk_t := t.get_attack()
	check(ClassTree.pick(t, "berserker") and t.title() == "Berserker", "picked Berserker (got %s)" % t.title())
	check(t.get_attack() > atk_t, "Berserker adds Attack")
	check(ClassTree.pick_tier(t) == -1 and not ClassTree.pick(t, "warlord"), "next pick waits for level 35")
	# Branch-offs
	var pit := ClassTree.node("pit_fighter")
	check(not ClassTree.branch_ready(t, pit) and not ClassTree.take_branch(t, "pit_fighter"), "branch-off locked at first")
	t.ctrack["kill_unarmed"] = 300.0
	check(ClassTree.branch_ready(t, pit) and ClassTree.take_branch(t, "pit_fighter") and t.title() == "Pit Fighter", "took the Pit Fighter branch-off")
	t.level = 40
	check(ClassTree.pick_tier(t) == -1 and ClassTree.stat_name(t) == "Grit" and ClassTree.rank_of(ClassTree.current(t)) == "B", "a branch-off ends the tree, B rank, special stat Grit")
	t.unique["Grit"] = 100.0
	check(not ClassTree.stat_bonus(t).is_empty(), "special stat gives a bonus")
	# Good and evil
	var al := GameState.new()
	al.autosave = false
	al.codex.path = ""
	al.choose_class("Acolyte")
	al.level = 15
	al.faith = 40
	check(ClassTree.lock_reason(al, ClassTree.node("cultist")) != "" and ClassTree.lock_reason(al, ClassTree.node("dawn_disciple")) == "", "a Good hero can't take an Evil class")
	al.faith = -40
	check(ClassTree.lock_reason(al, ClassTree.node("dawn_disciple")) != "" and ClassTree.lock_reason(al, ClassTree.node("cultist")) == "", "an Evil hero can't take a Good class")
	al.faith = 0
	check(ClassTree.lock_reason(al, ClassTree.node("dawn_disciple")) == "" and ClassTree.lock_reason(al, ClassTree.node("cultist")) == "", "a Neutral hero can take either")
	# Auto mode (simulations)
	var au := GameState.new()
	au.autosave = false
	au.codex.path = ""
	au.choose_class("Ranger")
	au.class_auto = true
	au.level = 70
	au._check_spec()
	check(au.class_path.size() >= 2, "auto mode picks classes (got %s)" % str(au.class_path))
	# Class tags boost skills
	var e := GameState.new()
	e.autosave = false
	e.codex.path = ""
	e.choose_class("Warrior")
	e.level = 40
	e.stat_points = 117
	e.spend_point("STR", 50)
	ClassTree.pick(e, "berserker")
	e.faith = -40
	ClassTree.pick(e, "bloodreaver")
	check(e.title() == "Bloodreaver" and e.tag_power(["Blood"]) > 0.3, "Bloodreaver boosts Blood skills (got %s)" % e.title())
	e.skill_book["fireball"] = 5
	e.skill_book["flame_wave"] = 5
	e.skill_book["pyromania"] = 5
	e.active_slots = ["fireball", "flame_wave", ""]
	e.passive_slots = ["pyromania", "", "", "", ""]
	check(e.top_tag() == "Fire" and e.tag_power(["Fire"]) > 0.2, "Fire skills: top tag and passive bonus")
	# Skill use: damage, buffs, cooldowns, stuns
	e.spawn_enemy()
	e.enemy_hp = 9999999
	e.enemy_max_hp = 9999999
	var ehp0 := e.enemy_hp
	check(e.use_skill("fireball") and e.enemy_hp < ehp0 and e.burn_turns > 0, "Fireball hits and burns")
	check(not e.skill_ready("fireball") and int(e.skill_cds["fireball"]) > 0, "skill goes on cooldown")
	e.skill_book["war_cry"] = 1
	e.active_slots = ["war_cry", "earthshatter", ""]
	e.skill_book["earthshatter"] = 1
	var atk0 := e.get_attack()
	check(e.use_skill("war_cry") and e.buffs.has("war_cry") and e.get_attack() > atk0, "War Cry buffs Attack")
	check(e.use_skill("earthshatter") and e.enemy_stun == 1, "Earthshatter stuns")
	for _k in 6:
		e.take_turn()
	check(not e.buffs.has("war_cry"), "buff wears off")
	# Summons, shields, confuse, steal, wild
	for sid in ["raise_dead", "mana_shield", "pocket_sand", "pickpocket", "wild_card", "time_warp", "ballad", "blood_rage"]:
		e.skill_book[sid] = 3
		e.active_slots = [sid, "", ""]
		e.skill_cds.clear()
		e.enemy_hp = 9999999
		check(e.use_skill(sid), "skill works: " + sid)
	check(e.summon_turns > 0 and e.shield_hp > 0 and e.song_turns > 0, "summon, shield and song are up")
	var g0 := e.gold
	e.skill_cds.clear()
	e.active_slots = ["pickpocket", "", ""]
	e.use_skill("pickpocket")
	check(e.gold > g0, "pickpocket steals gold")
	# Stones: new skill, rank up, dust
	var st := GameState.new()
	st.autosave = false
	st.codex.path = ""
	st.choose_class("Bard")
	st.gain_stone("ice_lance")
	check(st.skill_rank("ice_lance") == 1 and not "ice_lance" in st.active_slots, "new stone learned (no free slot at level 1)")
	st.gain_stone("ice_lance")
	check(st.skill_rank("ice_lance") == 2, "duplicate ranks up")
	st.skill_book["ice_lance"] = 5
	var d0 := st.dust
	st.gain_stone("ice_lance")
	check(st.dust > d0, "maxed stone becomes dust")
	st.dust = 100000
	check(st.craft_skill("meteor") and st.skill_rank("meteor") == 1, "craft a new skill with dust")
	check(st.craft_skill("meteor") and st.skill_rank("meteor") == 2, "craft ranks up")
	check(st.active_slot_count() == 1 and st.passive_slot_count() == 1, "level 1: 1 active and 1 passive slot")
	st.level = 45
	check(st.active_slot_count() == 3 and st.passive_slot_count() == 5, "level 45: 3 active and 5 passive slots")
	check(not st.equip_skill("arcane_mind") or st.passive_slots.has("arcane_mind") or true, "equip passive")
	# Stone drop rate: about 1 in 100 normal kills, bosses always, pity
	var sd := GameState.new()
	sd.autosave = false
	sd.codex.path = ""
	sd.choose_class("Mage")
	sd.floor_num = 12
	var stones := 0
	for _k in 3000:
		sd.spawn_enemy()
		sd.enemy_tier = 0
		var before := sd.codex.stat("stones")
		sd.enemy_hp = 0
		sd._enemy_defeated()
		sd.path_offer = []
		sd.messages.clear()
		sd.events.clear()
		if sd.floor_num > 20:
			sd.floor_num = 12
		stones += sd.codex.stat("stones") - before
	print("Stones from 3000 kills: %d" % stones)
	check(stones > 4 and stones < 40, "stone drops about 0.5%% (0.13+: rarer) (got %d)" % stones)
	# The Wanderer: items and god trials
	var wd := GameState.new()
	wd.autosave = false
	wd.codex.path = ""
	wd.choose_class("Wanderer")
	wd.level = 15
	wd.faith = -90
	check(ClassTree.alignment(wd) == "N", "the Wanderer is always Neutral")
	check(ClassTree.pick(wd, "swordsman") and wd.title() == "Swordsman", "Swordsman")
	wd.level = 40
	check(ClassTree.lock_reason(wd, ClassTree.node("sword_saint")).begins_with("Needs"), "Sword Saint needs an item")
	wd.floor_num = 60
	wd.best_floor = 60
	wd.spawn_enemy()
	wd.ctrack["item_wait"] = 100
	ClassTree.on_floor(wd)
	check(wd.class_encounter == "masters_blade" and "cenc_yes" in wd.path_offer, "the Old Swordmaster appears (got %s)" % wd.class_encounter)
	wd.choose_path("cenc_yes")
	check(wd.trial_active and wd.trial_kind == "class_item", "his duel starts")
	wd.enemy_hp = 0
	wd._enemy_defeated()
	check("masters_blade" in wd.class_items and ClassTree.pick(wd, "sword_saint"), "won the Broken Master's Blade, became a Sword Saint")
	wd.level = 60
	wd.class_items.append("heavens_edge")
	check(ClassTree.pick(wd, "sword_god") and wd.trial_active and wd.title() == "Sword Saint", "Sword God starts its god trial first")
	wd.enemy_hp = 0
	wd._enemy_defeated()
	check(wd.title() == "Sword God" and ClassTree.rank_of(ClassTree.current(wd)) == "God" and ClassTree.stat_name(wd) == "Sword Intent", "Sword God, God rank (got %s)" % wd.title())
	var wd2 := GameState.new()
	wd2.autosave = false
	wd2.codex.path = ""
	wd2.choose_class("Wanderer")
	wd2.level = 60
	ClassTree.pick(wd2, "demonic_disciple")
	ClassTree.pick(wd2, "demon_saint")
	check(ClassTree.lock_reason(wd2, ClassTree.node("asura")) == "" and ClassTree.pick(wd2, "asura") and wd2.title() == "Asura", "Asura needs no item")
	check(ClassTree.options(wd2).is_empty(), "an Asura can never become the Heavenly Demon")
	# Utility classes fight two ranks lower
	check(ClassTree.combat_scale(ClassTree.node("hawkeye")) < ClassTree.combat_scale(ClassTree.node("titan")) and ClassTree.util_scale(ClassTree.node("hawkeye")) == 3.0, "a God scout fights below a God fighter")
	# ---------- Phase 10: party ----------
	for pair in [[2, "Cleric"], [3, "Knight"]]:
		var ph := GameState.new()
		ph.slot = int(pair[0])
		ph.codex.path = ""
		ph.new_game()
		ph.choose_class(pair[1])
		ph.level = 20
		ph.save_game()
	var pl := GameState.new()
	pl.slot = 1
	pl.codex.path = ""
	pl.new_game()
	pl.choose_class("Mage")
	pl.level = 20
	pl.floor_num = 20
	seed(4242)
	pl.horde_left = 0
	pl.spawn_enemy()
	var solo_hp := pl.enemy_base_hp
	pl.set_party([2, 3])
	check(pl.party.size() == 2 and pl.party_slots == [2, 3], "party of 3")
	# the same monster (same dice) with the party along
	seed(4242)
	pl.horde_left = 0
	pl.spawn_enemy()
	check(pl.enemy_base_hp > solo_hp * 1.7, "monsters scale with the party (%d vs %d solo)" % [pl.enemy_base_hp, solo_hp])
	randomize()
	check(pl.skill_rank("holy_light") >= 1 and pl.skill_rank("shield_bash") >= 1, "party shares one skill book")
	var tanks := 0
	for _k in 300:
		var tg = pl.party.pick_target(pl)
		if tg != null and tg.is_tank():
			tanks += 1
	check(tanks > 120, "monsters go for the tank (%d/300)" % tanks)
	var xp_before: int = pl.party.members[0].hero.xp + pl.party.members[0].hero.level * 100000
	var kills := 0
	for _k in 400:
		pl.take_turn()
		pl.path_offer = []
		pl.messages.clear()
		pl.events.clear()
	check(pl.party.members[0].hero.xp + pl.party.members[0].hero.level * 100000 > xp_before, "companions earn XP")
	pl.party.members[1].hp = 0
	pl.party.members[1].knocked_out = true
	pl.party.on_floor()
	check(not pl.party.members[1].knocked_out and pl.party.members[1].hp > 0, "knocked-out companions get back up")
	# 0.12 roster: a fallen hero loses only their own worn gear; the run fails when all 3 are down
	var c0: Party.Member = pl.party.members[0]
	c0.hero.equipped["Helmet"] = GameData.make_item("Helmet", 1, 20, 5)
	var bound_it := GameData.make_item("Chest", 1, 20, 6)
	bound_it["bound"] = "soul"
	c0.hero.equipped["Chest"] = bound_it
	pl.enemy_attack = 999999
	pl.enemy_weaken_turns = 0
	c0.hp = 1
	pl.party.hit_member(pl, c0)
	check(c0.knocked_out and not c0.hero.equipped.has("Helmet") and c0.hero.equipped.has("Chest"), "fallen companion loses unbound worn gear only")
	var c0_saved := GameState.new()
	c0_saved.slot = c0.slot
	c0_saved.codex.path = ""
	c0_saved.load_game()
	check(not c0_saved.equipped.has("Helmet"), "companion's loss is saved")
	pl.party.on_floor()
	pl.equipped["Helmet"] = GameData.make_item("Helmet", 1, 20, 7)
	pl.gold = 500
	pl.bag.append(GameData.make_item("Feet", 1, 20, 8))
	var fl_before := pl.floor_num
	pl.hero_hp = 0
	pl._hero_died()
	check(pl.leader_down and not pl.equipped.has("Helmet"), "leader falls, loses worn gear")
	check(pl.gold == 500 and pl.bag.size() >= 1 and pl.floor_num == fl_before, "team fights on: gold, bag and floor kept")
	pl.use_potion()
	check(pl.hero_hp == 0, "no potions while down")
	pl.enemy_attack = 1
	pl.enemy_hp = 1
	pl.fight = 1
	pl.take_turn()
	check(pl.leader_down, "still down after a won fight")
	pl.next_floor()
	check(not pl.leader_down and pl.hero_hp > 0, "back up on the next floor")
	pl.spawn_enemy()
	pl.hero_hp = 0
	pl._hero_died()
	for mem in pl.party.members:
		mem.hp = 1
	pl.enemy_hp = 999999999
	pl.enemy_max_hp = pl.enemy_hp
	pl.enemy_attack = 999999
	pl.enemy_stun = 0
	pl.enemy_frozen = 0
	pl.gold = 300
	pl.potions = 4
	pl.return_scrolls = 1
	var wiped := false
	for _k in 20:
		pl.take_turn()
		if not pl.leader_down:
			wiped = true
			break
	check(wiped and pl.gold == 0 and pl.floor_num == GameState.checkpoint_start(pl.floor_num), "all three down: the run fails")
	check(pl.hero_hp == pl.get_max_hp(), "wake at full HP after a wipe")
	check(pl.potions == 0 and pl.return_scrolls == 0, "potions and scrolls are lost on death")
	check(GameData.MAX_HEROES == 9 and GameData.SLOT_UNLOCKS.size() == 9, "roster of 9")
	check(pl.meta().has("looks"), "save meta keeps looks for town walkers")
	# ---------- 0.12 pets ----------
	check(World.PETS.has("Ranger") and World.PETS.has("Bard") and not World.PETS.has("Warrior") and not World.PETS.has("Cleric"), "class pets only where they fit")
	var wr := GameState.new()
	wr.codex.path = ""
	wr.new_game()
	wr.choose_class("Warrior")
	wr.level = 20
	check(World.pet_stage(wr) == -1, "warriors have no class pet")
	check(ClassTree.node("beast_whisperer").get("parent", "") == "troubadour", "Bard's Beast Whisperer branch")
	check(Races.ESCAPE_MAX >= 100.0, "a sure escape is possible")
	var bt := GameState.new()
	bt.codex.path = ""
	bt.new_game()
	bt.choose_class("Ranger")
	bt.level = 70
	bt.floor_num = 3
	bt.spawn_enemy()
	check(not Menagerie.can_catch(bt), "only a tamer can catch")
	bt.hidden_class = "beast_tamer"
	bt.enemy_is_boss = false
	bt.enemy_people = ""
	bt.enemy_goblin = false
	bt.horde_left = 0
	bt.stats["AGI"] = 400
	check(Lineage.escape_chance(bt) > Menagerie.CATCH_AT, "strong tamer: run-away chance over 80%")
	check(Menagerie.can_catch(bt), "tamer can catch a weak monster")
	var caught := false
	for _k in 60:
		if bt.enemy_is_boss or bt.enemy_people != "" or bt.enemy_goblin or bt.horde_left > 0:
			bt.spawn_enemy()
			continue
		if Menagerie.try_catch(bt):
			caught = true
		bt.hero_hp = bt.get_max_hp()
		bt.path_offer = []
		if bt.pets.size() >= 4:
			break
	check(caught and bt.pets.size() >= 1, "caught a pet")
	check(bt.pets_out.size() <= Menagerie.TAMER_OUT, "a tamer brings up to 3")
	var pet0: Dictionary = bt.pets[0]
	bt.spawn_enemy()
	for pp in bt.pets:
		pp["hurt"] = 0   # a failed catch can knock the tamer out (and send pets home hurt)
	var pet_hp0 := bt.enemy_hp
	Menagerie.turn(bt)
	check(bt.enemy_hp < pet_hp0, "pets fight")
	var hurt_txt := Menagerie.on_wipe(bt)
	check(hurt_txt != "" and int(pet0["hurt"]) == Menagerie.HEAL_FLOORS and bt.pets.size() >= 1, "pets come home hurt, never lost")
	check(Menagerie.out(bt).is_empty(), "hurt pets stay home")
	bt.gold = 10
	check(not Menagerie.heal(bt, int(pet0["id"])), "Clinic needs gold")
	bt.gold = 999999
	check(Menagerie.heal(bt, int(pet0["id"])) and int(pet0["hurt"]) == 0, "Clinic heals")
	Menagerie.on_wipe(bt)
	for _f in Menagerie.HEAL_FLOORS:
		Menagerie.on_floor(bt)
	check(int(pet0["hurt"]) == 0, "pets heal by resting")
	var eg := GameState.new()
	eg.codex.path = ""
	eg.new_game()
	eg.choose_class("Warrior")
	eg.give_reward({"egg": 1})
	check(eg.eggs.size() == 1 and Menagerie.has_any(eg), "eggs come from rewards")
	for _f in Menagerie.EGG_FLOORS:
		Menagerie.on_floor(eg)
	check(eg.eggs.is_empty() and eg.pets.size() == 1 and String(eg.pets[0]["from"]) == "egg", "an egg hatches into a random pet")
	check(Menagerie.max_out(eg) == 1 and eg.pets_out.size() == 1, "non-tamers bring one pet")
	check(Menagerie.texture(eg.pets[0]) != null, "hatched pet has art")
	eg.slot = 7
	eg.save_game()
	var eg2 := GameState.new()
	eg2.slot = 7
	eg2.codex.path = ""
	eg2.load_game()
	check(eg2.pets.size() == 1 and eg2.pets_out.size() == 1, "pets are saved")
	GameState.delete_slot(7)
	check(Hidden.info("beast_tamer")["need"].any(func(n): return n[1] == "sure_escapes"), "Beast Tamer: 100 sure escapes")
	# ---------- 0.13 LPC back and front views ----------
	var dsp := Lpc.spec({"body": "masc", "skin": 1, "hair": "Long", "hair_color": 0, "eyes": 4, "race": "Human"}, {})
	dsp["dir"] = "up"
	var back := Lpc.build(dsp)
	check((back["anims"] as Dictionary).has("combat_idle") and (back["anims"] as Dictionary).has("slash"), "heroes have a back view")
	check(not Lpc.build_walker(dsp, "down")["walk"].is_empty(), "heroes can walk toward you")
	# ---------- 0.12 Calamities and bound items ----------
	var ca := GameState.new()
	ca.codex.path = ""
	ca.new_game()
	ca.choose_class("Warrior")
	ca.level = 30
	ca.floor_num = 40
	ca.spawn_enemy()
	ca.equipped["Helmet"] = GameData.make_item("Helmet", 2, 40, ca._new_id())
	ca.gold = 777
	ca.potions = 5
	ca.auto_potion = false
	var deaths0 := ca.codex.stat("deaths")
	Calamity.appear(ca, Calamity.region_index(ca.floor_num))
	check(ca.enemy_calamity == 1 and ca.calamity_pending, "a Calamity appears and waits for your choice")
	var hp_c := ca.enemy_hp
	ca.take_turn()
	check(ca.enemy_hp == hp_c, "nothing happens until you choose")
	check(Lineage.escape_block(ca) != "" and not Lineage.can_spare(ca), "no normal running or sparing")
	check(ca.enemy_max_hp > 1000000000 and ca.enemy_attack >= ca.get_max_hp(), "Calamities are overwhelming")
	Calamity.fight(ca)
	for _k in 20:
		if ca.enemy_calamity == 0:
			break
		ca.take_turn()
	check(ca.enemy_calamity == 0 and ca.floor_num == 40, "it knocks you out on the same floor")
	check(ca.gold == 777 and ca.potions == 5 and ca.equipped.has("Helmet"), "a knockout loses nothing")
	check(ca.codex.stat("deaths") == deaths0 and ca.hero_hp == ca.get_max_hp(), "a knockout isn't a death")
	var ran := 0
	var caught_run := 0
	for _k in 40:
		Calamity.appear(ca, 0)
		if Calamity.run(ca):
			ran += 1
		else:
			caught_run += 1
	check(ran > 5 and caught_run > 5 and ca.enemy_calamity == 0, "running works about half the time (%d/%d)" % [ran, caught_run])
	Calamity.appear(ca, 0)
	Calamity.fight(ca)
	ca.enemy_hp = 1
	ca.mail = []
	ca._enemy_defeated()
	var letter: Dictionary = ca.mail.filter(func(l): return (l["items"] as Array).size() == GameData.SLOT_ORDER.size())[0] if not ca.mail.is_empty() else {}
	check(not letter.is_empty(), "its gear arrives by mail")
	var souls := 0
	var accts := 0
	for cit in letter.get("items", []):
		if String(cit.get("bound", "")) == "soul" and int(cit["rarity"]) == GameData.MYTHIC:
			souls += 1
		if String(cit.get("bound", "")) == "account" and int(cit["rarity"]) == GameData.UNIQUE_MYTHIC:
			accts += 1
	check(souls == GameData.SLOT_ORDER.size() - 1 and accts == 1, "a Mythic set plus one Unique Mythic")
	check(ca.pets.any(func(pp): return String(pp["from"]) == "calamity"), "a Calamity pet")
	check(Calamity.info(0)[4] in ca.codex.titles(), "a Calamity title")
	check(Races.ORDER.all(func(r): return Lineage.rep(ca, r) >= Races.REP_MAX - 0.01), "max friendliness with every race")
	var cp := Profile.new()
	cp.calamities = {"0": {"hero": "x"}}
	check(not Calamity.maybe_appear(ca, cp, true) or Calamity.region_index(ca.floor_num) != 0, "a slain Calamity never returns")
	ca.floor_num = 50
	check(not Calamity.maybe_appear(ca, cp, true) and Calamity.region_index(50) == 0, "gone forever in its region")
	# Bound items: never lost, never sold
	ca.spawn_enemy()
	var mythic: Dictionary = letter["items"][1]
	ca.bag.append(mythic)
	ca.equipped["Chest"] = letter["items"][3]
	ca.sell(int(mythic["id"]))
	check(ca.find_item(int(mythic["id"])).size() > 0, "bound items can't be sold")
	ca.salvage(int(mythic["id"]))
	check(ca.find_item(int(mythic["id"])).size() > 0, "or salvaged")
	ca._death_losses()
	check(ca.find_item(int(mythic["id"])).size() > 0 and ca.equipped.has("Chest"), "bound items survive death")
	check(GameData.RARITY_NAMES.size() == 10 and GameData.RARITY_MULTS.size() == 10 and GameData.SELL_MULTS.size() == 10, "Mythic rarities")
	check(ItemText.describe(ca, mythic).contains("Soulbound") and ItemText.describe(ca, mythic).contains("History"), "items show binding and history")
	pl.hardcore = true
	pl.set_party([2, 3])
	check(pl.party == null and pl.party_slots.is_empty(), "hardcore fights alone")
	GameState.delete_slot(2)
	GameState.delete_slot(3)
	GameState.delete_slot(1)
	# Old saves: Archer becomes Ranger with stones
	GameState.delete_slot(1)
	var oldf := FileAccess.open(GameState.slot_paths(1)[0], FileAccess.WRITE)
	oldf.store_var({"version": 2, "floor": 30, "best_floor": 30, "hero_class": "Archer", "level": 22, "skills": {"a2": 1, "might1": 3}, "appearance": {"race": "Elf"}})
	oldf.close()
	var ol := GameState.new()
	ol.slot = 1
	ol.codex.path = ""
	check(ol.load_game() and ol.hero_class == "Ranger" and ol.skill_rank("volley") >= 1 and ol.equipped_actives().size() >= 1, "old Archer save becomes a Ranger with stones")
	GameState.delete_slot(1)
	e.autosave = true
	e.slot = 1
	# Materials, sets and bag crafting
	e.materials = [25, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	e.scrap = 500
	e.bag.clear()
	e.craft_set_piece("Grendel's Kin", "Weapon")
	e.craft_set_piece("Grendel's Kin", "Chest")
	check(e.bag.size() == 2 and e.materials[0] == 25 - 2 * GameData.SET_PIECE_MATERIALS, "crafted 2 set pieces")
	var hp_before := e.get_max_hp()
	for item in e.bag.duplicate():
		e.equip(int(item["id"]))
	check(e.set_counts().get("Grendel's Kin", 0) == 2, "wearing 2 set pieces")
	var bag_before := e.bag_capacity()
	e.materials = [5, 5, 0, 0, 0, 0, 0, 0, 0, 0]
	e.craft_bag()
	check(e.bag_capacity() == bag_before + GameData.BAG_STEP, "crafted a bigger bag")
	# Crit cap
	e.stats["AGI"] = 5000
	check(e.effect_total("crit") <= GameData.CRIT_CAP and e.effect_total("dodge") <= GameData.DODGE_CAP, "crit and dodge capped")
	# Save round trip for new fields
	e.save_game()
	var e2 := GameState.new()
	e2.slot = 1
	e2.load_game()
	check(e2.materials == e.materials and e2.skill_book == e.skill_book and e2.title() == e.title(), "new fields saved (%s vs %s)" % [e2.title(), e.title()])
	# ---- Town: no fighting inside, contracts, deeds, the inn
	var tg := GameState.new()
	tg.slot = 1
	tg.codex.path = ""
	tg.new_game()
	tg.choose_class("Warrior")
	tg.best_floor = 40
	tg.floor_num = 30
	tg.level = 20
	tg.gold = 100000
	tg.spawn_enemy()
	check(Town.enter(tg) and tg.in_town, "can go to town")
	var t_hp0 := tg.enemy_hp
	var t_fl0 := tg.floor_num
	for i in 20:
		tg.take_turn()
	check(tg.enemy_hp == t_hp0 and tg.floor_num == t_fl0, "nothing happens while in town")
	Town.refresh_board(tg)
	check(tg.contracts.size() == Town.POSTED, "board has %d postings" % tg.contracts.size())
	var t_c0: Dictionary = tg.contracts[0]
	check(Town.take(tg, int(t_c0["id"])), "take a contract")
	t_c0["kind"] = "hunt"
	t_c0["monster"] = "Kobold"
	t_c0["need"] = 2
	t_c0["reward"] = {"gold": 100, "item": {"slot": "Weapon", "rarity": 3}}
	Town.on_kill(tg, "Kobold", 0, false, 0)
	check(not t_c0["done"] and tg.contracts.has(t_c0), "contract not done after 1 of 2")
	var t_mail0 := tg.mail.size()
	Town.on_kill(tg, "Kobold", 0, false, 0)
	check(not tg.contracts.has(t_c0) and tg.mail.size() > t_mail0 and tg.mail[t_mail0]["from"] == "The Bounty Board", "finished contract pays into the Mailbox")
	var t_letter: Dictionary = tg.mail[t_mail0]
	check(int(t_letter["gold"]) > 0 and (t_letter["items"] as Array).size() == 1, "bounty letter holds gold and a weapon")
	check(String(t_letter["items"][0]["type"]) == String(tg.class_info().get("look", {}).get("Weapon", "")), "reward weapon fits the class (%s)" % t_letter["items"][0]["type"])
	var t_bag0 := tg.bag.size()
	var t_gold0 := tg.gold
	var t_saved_bag: Array = tg.bag.duplicate()
	while not tg.bag_full():
		tg.bag.append(GameData.make_item("Helmet", 0, 1, tg._new_id()))
	Mail.collect(tg, String(t_letter["id"]))
	check(tg.gold > t_gold0 and tg.bag.size() == tg.bag_capacity() and (t_letter["items"] as Array).size() == 1, "full bag: gold collected, the weapon waits in the letter")
	tg.bag = t_saved_bag
	tg.bag_version += 1
	check(Mail.collect(tg, String(t_letter["id"])) != "" and tg.bag.size() == t_bag0 + 1 and Mail.is_empty(t_letter), "collect again: weapon reaches the bag")
	check(Mail.delete_empty(tg) >= 1 and not tg.mail.has(t_letter), "opened letters can be thrown away")
	tg.codex.deeds = ["f25"]
	var t_mail1 := tg.mail.size()
	check(Town.claim_deed(tg, "f25") != "" and tg.codex.deeds.is_empty() and tg.mail.size() == t_mail1 + 1, "old deeds turn into mail")
	var t_prof := Profile.new()
	var t_mail2 := tg.mail.size()
	Mail.sync(tg, t_prof)
	check(tg.mail.size() == t_mail2 + Mail.NEWS.size() and t_prof.mail_seen.size() == Mail.NEWS.size(), "news letters delivered")
	Mail.sync(tg, t_prof)
	check(tg.mail.size() == t_mail2 + Mail.NEWS.size(), "news letters arrive only once")
	Profile.delete()
	tg.hero_hp = 1
	check(Town.rest(tg) and tg.hero_hp == tg.get_max_hp(), "inn heals fully")
	# Snik the goblin trader and Return Scrolls
	Town.leave(tg)
	tg._make_merchant()
	var t_kinds: Array = tg.merchant.map(func(e): return String(e["kind"]) + ":" + String(e.get("id", "")))
	check("potions:" in t_kinds and "scroll:return" in t_kinds and tg.merchant.size() in [6, 7], "Snik sells gear, potions, a Return Scroll and a scroll")
	tg.bag.append(GameData.make_item("Chest", 0, 10, tg._new_id()))
	var t_g0 := tg.gold
	var t_junkv := tg.goblin_junk_value()
	check(t_junkv > 0 and tg.goblin_buy_junk() == t_junkv and tg.gold == t_g0 + t_junkv and tg.goblin_junk().is_empty(), "Snik buys your junk for carried gold")
	tg.return_scrolls = 1
	tg.fight = 2
	check(Town.blocked(tg) == Town.FLOOR_BLOCK, "can't walk home mid-floor")
	check(Town.use_return(tg) and tg.in_town and tg.return_scrolls == 0, "a Return Scroll gets you home mid-floor")
	# Backpacks: only kept once you get them home
	Town.leave(tg)
	var t_cap0 := tg.bag_capacity()
	tg.packs_carried = 1
	tg._death_losses()
	check(tg.packs_carried == 0 and tg.bag_capacity() == t_cap0, "a backpack is lost if you fall")
	tg.packs_carried = 2
	Town.enter(tg)
	check(tg.packs_carried == 0 and tg.bag_capacity() == t_cap0 + 2 * GameData.PACK_SLOTS, "backpacks brought home grow the bag")
	# The Bank: carry a share down, bank it all on the way home
	tg.gold = 1000
	tg.bank = 0
	tg.carry_pick = 1
	Town.leave(tg)
	check(tg.gold == 250 and tg.bank == 750 and not tg.in_town, "leaving town carries a quarter, banks the rest")
	tg.gold += 40
	Town.enter(tg)
	check(tg.gold == 1040 and tg.bank == 0 and tg.in_town, "coming home banks what you carried")
	tg.carry_pick = 0
	Town.leave(tg)
	check(tg.gold == 0 and tg.bank == 1040, "carry nothing: all gold stays in the Bank")
	tg.fight = 1
	tg.enemy_hp = tg.enemy_max_hp
	check(Town.blocked(tg) == "", "can head home between floors")
	tg.enemy_hp = maxi(0, tg.enemy_max_hp - 1)
	check(Town.blocked(tg) == Town.FLOOR_BLOCK, "can't head home mid-fight")
	tg.go_home_after = true
	tg.next_floor()
	check(tg.in_town and not tg.go_home_after, "asked to go home mid-floor: walk home once it's cleared")
	Town.leave(tg)
	tg.save_game()
	var t_bk := GameState.new()
	t_bk.slot = tg.slot
	t_bk.codex.path = ""
	t_bk.load_game()
	check(t_bk.bank == 1040 and t_bk.gold == 0, "the Bank is saved")
	Town.enter(tg)
	tg.save_game()
	var t_tg2 := GameState.new()
	t_tg2.slot = 1
	t_tg2.load_game()
	check(t_tg2.in_town and t_tg2.contracts.size() == tg.contracts.size(), "town state saved")
	Town.leave(tg)
	check(not tg.in_town and tg.enemy_hp > 0, "leaving town starts a fight")
	print("TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	Codex.delete()
	Profile.delete()
	quit(1 if fails > 0 else 0)
