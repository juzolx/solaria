extends SceneTree
## Town logic only (also part of run_tests.gd).
var fails := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)

func _initialize() -> void:
	GameState.delete_saves()
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
	var hp0 := tg.enemy_hp
	var fl0 := tg.floor_num
	for i in 20:
		tg.take_turn()
	check(tg.enemy_hp == hp0 and tg.floor_num == fl0, "nothing happens while in town")
	Town.refresh_board(tg)
	check(tg.contracts.size() == Town.POSTED, "board has %d postings" % tg.contracts.size())
	var c0: Dictionary = tg.contracts[0]
	check(Town.take(tg, int(c0["id"])), "take a contract")
	c0["kind"] = "hunt"
	c0["monster"] = "kobold"
	c0["need"] = 2
	c0["reward"] = {"gold": 100, "item": {"slot": "Weapon", "rarity": 3}}
	Town.on_kill(tg, "kobold", 0, false, 0)
	check(not c0["done"] and tg.contracts.has(c0), "contract not done after 1 of 2")
	var mail0 := tg.mail.size()
	Town.on_kill(tg, "kobold", 0, false, 0)
	check(not tg.contracts.has(c0) and tg.mail.size() > mail0 and tg.mail[mail0]["from"] == "The Bounty Board", "finished contract pays into the Mailbox")
	var letter: Dictionary = tg.mail[mail0]
	check(int(letter["gold"]) > 0 and (letter["items"] as Array).size() == 1, "bounty letter holds gold and a weapon")
	check(String(letter["items"][0]["type"]) == String(tg.class_info().get("look", {}).get("Weapon", "")), "reward weapon fits the class (%s)" % letter["items"][0]["type"])
	var bag0 := tg.bag.size()
	var gold0 := tg.gold
	var saved_bag: Array = tg.bag.duplicate()
	while not tg.bag_full():
		tg.bag.append(GameData.make_item("Helmet", 0, 1, tg._new_id()))
	Mail.collect(tg, String(letter["id"]))
	check(tg.gold > gold0 and tg.bag.size() == tg.bag_capacity() and (letter["items"] as Array).size() == 1, "full bag: gold collected, the weapon waits in the letter")
	tg.bag = saved_bag
	tg.bag_version += 1
	check(Mail.collect(tg, String(letter["id"])) != "" and tg.bag.size() == bag0 + 1 and Mail.is_empty(letter), "collect again: weapon reaches the bag")
	check(Mail.delete_empty(tg) >= 1 and not tg.mail.has(letter), "opened letters can be thrown away")
	tg.codex.deeds = ["f25"]
	var mail1 := tg.mail.size()
	check(Town.claim_deed(tg, "f25") != "" and tg.codex.deeds.is_empty() and tg.mail.size() == mail1 + 1, "old deeds turn into mail")
	var prof := Profile.new()
	var mail2 := tg.mail.size()
	Mail.sync(tg, prof)
	check(tg.mail.size() == mail2 + Mail.NEWS.size() and prof.mail_seen.size() == Mail.NEWS.size(), "news letters delivered")
	Mail.sync(tg, prof)
	check(tg.mail.size() == mail2 + Mail.NEWS.size(), "news letters arrive only once")
	Profile.delete()
	tg.hero_hp = 1
	check(Town.rest(tg) and tg.hero_hp == tg.get_max_hp(), "inn heals fully")
	# Snik the goblin trader and Return Scrolls
	Town.leave(tg)
	tg._make_merchant()
	var kinds: Array = tg.merchant.map(func(e): return String(e["kind"]) + ":" + String(e.get("id", "")))
	check("potions:" in kinds and "scroll:return" in kinds and tg.merchant.size() in [6, 7], "Snik sells gear, potions, a Return Scroll and a scroll (sometimes an egg)")
	tg.bag.append(GameData.make_item("Chest", 0, 10, tg._new_id()))
	var g0 := tg.gold
	var junkv := tg.goblin_junk_value()
	check(junkv > 0 and tg.goblin_buy_junk() == junkv and tg.gold == g0 + junkv and tg.goblin_junk().is_empty(), "Snik buys your junk for carried gold")
	tg.return_scrolls = 1
	tg.fight = 2
	check(Town.blocked(tg) == Town.FLOOR_BLOCK, "can't walk home mid-floor")
	check(Town.use_return(tg) and tg.in_town and tg.return_scrolls == 0, "a Return Scroll gets you home mid-floor")
	# Backpacks: only kept once you get them home
	Town.leave(tg)
	var cap0 := tg.bag_capacity()
	tg.packs_carried = 1
	tg._death_losses()
	check(tg.packs_carried == 0 and tg.bag_capacity() == cap0, "a backpack is lost if you fall")
	tg.packs_carried = 2
	Town.enter(tg)
	check(tg.packs_carried == 0 and tg.bag_capacity() == cap0 + 2 * GameData.PACK_SLOTS, "backpacks brought home grow the bag")
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
	var bk := GameState.new()
	bk.slot = tg.slot
	bk.codex.path = ""
	bk.load_game()
	check(bk.bank == 1040 and bk.gold == 0, "the Bank is saved")
	Town.enter(tg)
	tg.save_game()
	var tg2 := GameState.new()
	tg2.slot = 1
	tg2.load_game()
	check(tg2.in_town and tg2.contracts.size() == tg.contracts.size(), "town state saved")
	Town.leave(tg)
	check(not tg.in_town and tg.enemy_hp > 0, "leaving town starts a fight")
	# The iso town's walk grid: every door, Inn door and stop is reachable from the Inn (no stuck walkers)
	var j := load("res://art/town/town.json") as JSON
	if j and j.data.get("iso", false):
		var d: Dictionary = j.data
		var walk := {}
		for c in d["walk"]:
			walk[Vector2i(int(c[0]), int(c[1]))] = true
		var start := Vector2i(int(d["inn_doors"][0][0]), int(d["inn_doors"][0][1]))
		var seen := {start: true}
		var q: Array = [start]
		while not q.is_empty():
			var c: Vector2i = q.pop_front()
			for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nb: Vector2i = c + dv
				if walk.has(nb) and not seen.has(nb):
					seen[nb] = true
					q.append(nb)
		var cells: Array = d["inn_doors"] + d["stops"]
		for sp in d["spots"]:
			cells.append(sp["door"])
		var lost: Array = cells.filter(func(c): return not seen.has(Vector2i(int(c[0]), int(c[1]))))
		check(lost.is_empty(), "every town door and stop can be walked to from the Inn (unreachable: %s)" % [lost])
		# buildings' tap areas never overlap (the Market is the square under them; points: below)
		var bld: Array = d["spots"].filter(func(sp): return String(sp["kind"]) in ["building", "lot"])
		var clash: Array = []
		for a in bld.size():
			for b in range(a + 1, bld.size()):
				var ra: Array = bld[a]["rect"]
				var rb: Array = bld[b]["rect"]
				if Rect2(ra[0], ra[1], ra[2], ra[3]).intersects(Rect2(rb[0], rb[1], rb[2], rb[3])):
					clash.append([bld[a]["id"], bld[b]["id"]])
		check(clash.is_empty(), "no two building tap areas overlap (%s)" % [clash])
		# a point (Bounty Board, Mailbox) sits inside at most one building's tap area and is smaller,
		# so _spot_at (smallest rect wins) always gives the tap to the point
		var bad_pts: Array = []
		for p in d["spots"].filter(func(sp): return String(sp["kind"]) == "point"):
			var pr: Array = p["rect"]
			var prr := Rect2(pr[0], pr[1], pr[2], pr[3])
			var holders: Array = []
			for b in bld:
				var br: Array = b["rect"]
				var brr := Rect2(br[0], br[1], br[2], br[3])
				if brr.intersects(prr):
					if not brr.encloses(prr) or brr.get_area() <= prr.get_area():
						bad_pts.append([p["id"], b["id"]])
					holders.append(b["id"])
			if holders.size() > 1:
				bad_pts.append([p["id"], holders])
		check(bad_pts.is_empty(), "points sit wholly inside at most one, bigger, building tap area (%s)" % [bad_pts])
		# name plates at 2x never cover each other (a plate takes the tap first)
		var th := ThemeDB.get_project_theme()
		var font: Font = th.default_font if th and th.default_font else ThemeDB.fallback_font   # the font the game draws plates with
		var o0: Array = d["origin"]
		var cell_px := func(c: Vector2i) -> Vector2:
			return Vector2(float(o0[0]) + (c.x - c.y) * 16.0, float(o0[1]) + (c.x + c.y + 1) * 8.0)
		for fs in [20, 22]:   # 2x draws plates at 20, 3x at 22
			var k := 2.0 if fs == 20 else 3.0
			var plates: Array = []
			for sp in d["spots"]:
				if sp.has("plate") and sp["plate"] == null:
					continue
				var w := font.get_string_size(String(sp["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0
				var c: Vector2 = TownView.plate_anchor(sp) * k
				plates.append([sp["id"], Rect2(c.x - w / 2.0, c.y - (fs + 10) / 2.0, w, fs + 10.0)])
			var piled: Array = []
			for a in plates.size():
				for b in range(a + 1, plates.size()):
					if (plates[a][1] as Rect2).intersects(plates[b][1]):
						piled.append([plates[a][0], plates[b][0]])
			check(piled.is_empty(), "no two name plates overlap at %dx (%s)" % [k, piled])
			# nobody standing at a stop has a plate across them
			var covered: Array = []
			for st in d["stops"]:
				var p: Vector2 = cell_px.call(Vector2i(int(st[0]), int(st[1])))
				var head := Rect2((p + Vector2(-6, -32)) * k, Vector2(12, 32) * k)
				for pl in plates:
					if (pl[1] as Rect2).intersects(head):
						covered.append([pl[0], st])
			check(covered.is_empty(), "no plate covers a walker at a stop at %dx (%s)" % [k, covered])
		# every stop faces something: a cell people can't walk on lies within 24 px of face_x beside it
		var blank: Array = []
		for st in d["stops"]:
			var sc := Vector2i(int(st[0]), int(st[1]))
			var faces := false
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					var nc := sc + Vector2i(dx, dy)
					if not walk.has(nc) and absf((cell_px.call(nc) as Vector2).x - float(st[2])) <= 24.0:
						faces = true
			if not faces:
				blank.append(st)
		check(blank.is_empty(), "every stop faces a stall, the well or a board, not open street (%s)" % [blank])
		# the hope path: walkers climb the stairs to the portal (the Dungeon door is up there)
		var gate: Array = d["spots"].filter(func(sp): return sp["id"] == "gate")[0]["door"]
		var up: Array = d["raised"].filter(func(c): return int(c[0]) == int(gate[0]) and int(c[1]) == int(gate[1]))
		check(not up.is_empty() and float(up[0][2]) > float(d.get("plateau_z", 24)) and walk.has(Vector2i(int(gate[0]), int(gate[1]))), "the Dungeon door is up the stairs, on the walk grid")
		# level props: at every level, the street cell each one stands on is off the walk grid (walkers
		# go round it) unless it's a door, and every door and stop can still be reached from the Inn
		var doors := {}
		var inns: Array = []
		for c in d["inn_doors"]:
			inns.append(Vector2i(int(c[0]), int(c[1])))
			doors[inns[-1]] = true
		var targets: Array = inns.duplicate()
		for sp in d["spots"]:
			targets.append(Vector2i(int(sp["door"][0]), int(sp["door"][1])))
			doors[targets[-1]] = true
		for c in d["stops"]:
			targets.append(Vector2i(int(c[0]), int(c[1])))
		for lvl in [1, 2, 3]:
			var blocked: Array = []
			for id in d["levels"]:
				for e in d["levels"][id]:
					var c := Vector2i(int(e[4]), int(e[5]))
					if int(e[3]) == lvl and walk.has(c) and not doors.has(c):
						blocked.append(c)
			var w := TownView.blocked_walk(walk, blocked, inns, targets)
			var through: Array = blocked.filter(func(c): return w.has(c))
			check(through.is_empty(), "level %d props stand off the walk grid (walked through: %s)" % [lvl, through])
			var lost2: Array = targets.filter(func(c): return walk.has(c) and not TownView._reaches(w, inns[0], [c]))
			check(lost2.is_empty(), "level %d props cut no door or stop off (%s)" % [lvl, lost2])
	# the town map lands on whole device pixels wherever the view sits in the UI
	var snapped := true
	for cs in [1.488, 2.56, 3.0]:
		for g in [Vector2(6, 57), Vector2(10.5, 63.25), Vector2(0, 0)]:
			for pan in [Vector2(-312.3, -401.7), Vector2(-0.4, -7.9)]:
				var o := TownView.snap_origin(g, pan, cs)
				var dev: Vector2 = (g + o) * cs
				if absf(dev.x - roundf(dev.x)) > 0.01 or absf(dev.y - roundf(dev.y)) > 0.01:
					snapped = false
	check(snapped, "the town map's origin is a whole device pixel for any UI offset")
	# a pinch keeps the map point under the fingers where it is, at the scale really drawn
	var still := true
	for cs in [1.488, 2.56]:
		for z in [2.0, 3.0]:
			var at := Vector2(215, 400)
			var m := Vector2(740, 560)
			var pan := TownView.zoom_pan(at, m, z, cs)
			var sf: float = maxf(1.0, roundf(z * cs)) / cs
			if not ((at - pan) / sf).is_equal_approx(m):
				still = false
	check(still, "a pinch zoom keeps the point under the fingers still")
	GameState.delete_saves()
	print("TOWN TESTS DONE, failures: ", fails)
	quit()
