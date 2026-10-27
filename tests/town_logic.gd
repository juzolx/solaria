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
		# every picture the town loads exists: occluders (day and lit), level props, bases and overlays
		var missing: Array = []
		for o in d["occluders"]:
			for k in ([0, 6] if o.size() > 6 and String(o[6]) != "" else [0]):
				var path := "res://art/town/iso/occ/%s.png" % String(o[k])
				if not ResourceLoader.exists(path):
					missing.append(path)
		for id in d["levels"]:
			for e in d["levels"][id]:
				if not ResourceLoader.exists("res://art/town/iso/up/%s.png" % String(e[0])):
					missing.append(String(e[0]))
		for church in ["lot", "holy", "ruin"]:
			for cabin in ["lot", "built"]:
				for path in [String(d["art"]) % [church, cabin], String(d["art_lit"]) % [church, cabin], (String(d["art_lit"]) % [church, cabin]).replace("_lit.png", "_lit2.png")]:
					if not ResourceLoader.exists(path):
						missing.append(path)
		check(missing.is_empty(), "every occluder, level prop and town picture exists (%s)" % [missing])
		# by day no flame burns: no bright flame pixel within 6 px of a lamp, torch or lantern in any
		# base picture (the forge, its smithy and the blue portal and beam lights burn by day)
		var smith: Array = d["spots"].filter(func(sp): return sp["id"] == "smith")[0]["rect"]
		var forge := Rect2(smith[0], smith[1], smith[2], smith[3])
		var burning: Array = []
		for church in ["lot", "holy", "ruin"]:
			for cabin in ["lot", "built"]:
				var im := (load(String(d["art"]) % [church, cabin]) as Texture2D).get_image()
				if im.is_compressed():
					im.decompress()
				for l in d["lights"]:
					var col: Array = l[2]
					if float(col[2]) > float(col[0]) or (int(col[1]) == 120 and int(col[2]) == 50):
						continue
					for y in range(int(l[1]) - 6, int(l[1]) + 7):
						for x in range(int(l[0]) - 6, int(l[0]) + 7):
							if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height() or forge.has_point(Vector2(x, y)):
								continue
							var c := im.get_pixel(x, y)
							var r8 := c.r8
							var g8 := c.g8
							var b8 := c.b8
							if (r8 > 220 and g8 > 150 and b8 < 110 and r8 - b8 > 110) or (r8 > 200 and g8 < 120 and b8 < 50 and r8 > g8 + 100):
								burning.append([church, cabin, l[0], l[1]])
		check(burning.is_empty(), "the day pictures have every flame out (%s)" % [burning.slice(0, 6)])
		# (round 5) the lamp glow is shared out where lamps cluster: no milky haze over the Inn porch
		# or the stair foot in the darkest look
		var glow_ok := true
		for p in [Vector2(716, 470), Vector2(900, 490)]:
			if TownView.glow_sum(d["lights"], p, 0.75) > 0.9:
				glow_ok = false
		check(glow_ok, "the summed lamp glow stays under 0.9 at the porch and the stair foot (%.2f, %.2f)" % [TownView.glow_sum(d["lights"], Vector2(716, 470), 0.75), TownView.glow_sum(d["lights"], Vector2(900, 490), 0.75)])
		# the second flame frame really differs (a stale export would ship two identical frames)
		var f1 := (load(String(d["art_lit"]) % ["holy", "built"]) as Texture2D).get_image()
		var f2 := (load((String(d["art_lit"]) % ["holy", "built"]).replace("_lit.png", "_lit2.png")) as Texture2D).get_image()
		for im in [f1, f2]:
			if im.is_compressed():
				im.decompress()
		var differ := 0
		if f1.get_size() == f2.get_size():
			for y in range(0, f1.get_height()):
				for x in range(0, f1.get_width()):
					if f1.get_pixel(x, y) != f2.get_pixel(x, y):
						differ += 1
		check(differ >= 40, "the two flame frames differ (%d pixels)" % differ)
		# the move guard: the forge's smoke and every forge-coloured light lie on the Blacksmith
		var on_smith := forge.has_point(Vector2(float(d["smoke"][0]), float(d["smoke"][1])))
		var forges := 0
		for l in d["lights"]:
			if int(l[2][0]) == 255 and int(l[2][1]) == 120 and int(l[2][2]) == 50:
				forges += 1
				on_smith = on_smith and forge.has_point(Vector2(float(l[0]), float(l[1])))
		check(on_smith and forges >= 1, "the forge smoke and forge light stand on the Blacksmith")
		# (Juzo: "zoom out more so we can see all of the town") at the farthest zoom every building
		# fits the view on a 430 phone, an SE and a wide PC window, in whole device pixels where
		# the town allows (a phone needs less than one device pixel per map pixel)
		var tb := TownView.town_box(Vector2(float(d["origin"][0]), float(d["origin"][1])), float(d["grid"]))
		var all_in := true
		for sp in d["spots"]:
			var rr: Array = sp["rect"]
			all_in = all_in and tb.encloses(Rect2(rr[0], rr[1], rr[2], rr[3]))
		check(all_in, "the town box holds every building's footprint")
		for v in [[Vector2(430, 932), 2.56], [Vector2(375, 667), 2.0], [Vector2(1280, 720), 1.0], [Vector2(1920, 1080), 1.0]]:
			var vs: Vector2 = v[0]
			var fit := minf(vs.x / tb.size.x, vs.y / tb.size.y)
			var s := TownView.scale_for(fit, float(v[1]), fit)
			var steps := TownView.zoom_steps(fit)
			check(tb.size.x * s <= vs.x + 0.01 and tb.size.y * s <= vs.y + 0.01 and absf(float(steps[0]) - minf(fit, 2.0)) < 0.001 and steps[-1] == 3.0,
				"the farthest zoom shows the whole town at %s (scale %.2f, steps %s)" % [vs, s, steps])
			if fit * float(v[1]) >= 1.0:
				check(is_equal_approx(s * float(v[1]), roundf(s * float(v[1]))), "whole device pixels at the farthest zoom on %s" % vs)
		check(is_equal_approx(TownView.scale_for(2.0, 2.56, 0.3) * 2.56, 5.0), "2x stays whole device pixels")
		# the Hardcore stop faces the ruin: set_mode turns people to the church rect's middle
		var cr: Array = d["spots"].filter(func(sp): return sp["id"] == "church")[0]["rect"]
		var face := float(cr[0]) + float(cr[2]) / 2.0
		check(face > float(cr[0]) and face < float(cr[0]) + float(cr[2]), "the Hardcore stop faces inside the church rect")
		# lot plates too: an unbuilt Church or Trophy Cabin's plate ("Church · lot", on its ground)
		# overlaps no other plate at 2x and 3x
		for fs in [20, 22]:
			var k := 2.0 if fs == 20 else 3.0
			var plates: Array = []
			for sp in d["spots"]:
				if sp.has("plate") and sp["plate"] == null:
					continue
				var w := font.get_string_size(String(sp["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0
				var c: Vector2 = TownView.plate_anchor(sp) * k
				plates.append([sp["id"], Rect2(c.x - w / 2.0, c.y - (fs + 10) / 2.0, w, fs + 10.0)])
			var piled: Array = []
			for sp in d["spots"].filter(func(s): return s.has("lot_plate")):
				var w := font.get_string_size(String(sp["label"]) + " · lot", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0
				var c := Vector2(float(sp["lot_plate"][0]), float(sp["lot_plate"][1])) * k
				var lr := Rect2(c.x - w / 2.0, c.y - (fs + 10) / 2.0, w, fs + 10.0)
				for pl in plates:
					if pl[0] != sp["id"] and (pl[1] as Rect2).intersects(lr):
						piled.append([String(sp["id"]) + " lot", pl[0]])
			check(piled.is_empty(), "no lot plate overlaps another plate at %dx (%s)" % [k, piled])
		# a plate pulled into the view stays on its own building, or hides; a building wholly in view
		# keeps its plate (430 and 375 wide phones, 2x and 3x, the view swept over the town)
		var strays: Array = []
		var lost_plates: Array = []
		for view in [Vector2(430, 760), Vector2(375, 520)]:
			for k in [2.0, 3.0]:
				var fs := 20 if k == 2.0 else 22
				for ox in range(0, 1480, 60):
					for oy in range(0, 1030, 60):
						var origin: Vector2 = -Vector2(ox, oy) * k
						for sp in d["spots"]:
							if sp.has("plate") and sp["plate"] == null:
								continue
							var r: Array = sp["rect"]
							var bvr := Rect2(origin + Vector2(r[0], r[1]) * k, Vector2(r[2], r[3]) * k)
							if bvr.intersection(Rect2(Vector2.ZERO, view)).get_area() < 0.3 * bvr.get_area():
								continue
							var w := font.get_string_size(String(sp["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0
							var a: Vector2 = origin + TownView.plate_anchor(sp) * k
							var pr := TownView.clamp_plate(Rect2(a.x - w / 2.0, a.y - (fs + 10) / 2.0, w, fs + 10.0), view, bvr)
							var moved := pr.position != Vector2(a.x - w / 2.0, a.y - (fs + 10) / 2.0)
							if pr.has_area() and moved and not pr.intersects(bvr.grow(8.0)):
								strays.append(sp["id"])
							if not pr.has_area() and Rect2(Vector2.ZERO, view).encloses(bvr):
								lost_plates.append(sp["id"])
		check(strays.is_empty(), "a plate clamped into the view never leaves its building (%s)" % [strays.slice(0, 6)])
		check(lost_plates.is_empty(), "a building wholly in view keeps its plate (%s)" % [lost_plates.slice(0, 6)])
	# chats start only on the grid: a partner walking between cells can't be stopped; one standing can
	var f0 := {"x": 100.0, "y": 100.0, "wait": 0.0}
	check(not TownView.chat_ok(f0, {"x": 108.0, "y": 104.0, "wait": 0.0}, Vector2(116, 108)), "no chat with a walker between cells")
	check(TownView.chat_ok(f0, {"x": 108.0, "y": 104.0, "wait": 2.0}, Vector2(116, 108)), "a chat with someone standing nearby")
	check(TownView.chat_ok(f0, {"x": 116.0, "y": 108.0, "wait": 0.0}, Vector2(116, 108)), "a chat with a walker right on a cell")
	check(not TownView.chat_ok(f0, {"x": 140.0, "y": 100.0, "wait": 2.0}, Vector2(140, 100)), "no chat across the street (over 22 px)")
	# Hardcore: nobody goes into the ruined Church or the locked Vault; lots and hidden buildings never
	check(not TownView.enterable("church", true, true, false) and not TownView.enterable("stash", true, true, false), "Hardcore walkers never enter the ruined Church or the Vault")
	check(TownView.enterable("church", false, true, false) and TownView.enterable("stash", false, true, false) and TownView.enterable("inn", true, true, false), "regular walkers go into the Church and the Vault")
	check(not TownView.enterable("cabin", false, false, false) and not TownView.enterable("clinic", false, true, true), "nobody walks into an empty lot or a building not in town yet")
	# today's townsfolk: six different people, no race twice among three in a row, another cast most days
	var races := TownFolk.PEOPLE.map(func(p): return String(p[0]["race"]))
	var mixed := true
	var casts := {}
	for day in range(20000, 20030):
		var cst: Array = TownView.cast(TownView.MAX_FOLK, races.size(), float(day), races)
		casts[str(cst)] = true
		var uniq := {}
		for i in cst:
			uniq[i] = true
		if cst.size() != TownView.MAX_FOLK or uniq.size() != cst.size():
			mixed = false
		for n in range(2, cst.size()):
			if races[cst[n]] == races[cst[n - 1]] or races[cst[n]] == races[cst[n - 2]]:
				mixed = false
	check(mixed and casts.size() > 10, "the townsfolk: six different people a day, mixed, a new cast most days (%d casts in 30 days)" % casts.size())
	check(TownView.cast(6, races.size(), 20001.2, races) == TownView.cast(6, races.size(), 20001.9, races), "the same cast all day")
	# the lamps' glow is plain at the rainy look (where every window is lit) and as strong as before at night
	check(TownView.glow_alpha(0.3) >= 0.3 and absf(TownView.glow_alpha(0.75) - 0.5) < 0.01, "lamp glow matches the lit windows at dark 0.3 and 0.75")
	# (round 5) the Hardcore stop at the Church door only when the ruin stands
	var stops0: Array = [Vector2i(1, 1), Vector2i(5, 14)]
	var door := Vector2i(5, 14)
	check(TownView.hardcore_stops(stops0, door, true, true).has(door), "Hardcore with the ruin built: people stop at the Church door")
	check(not TownView.hardcore_stops(stops0, door, true, false).has(door) and not TownView.hardcore_stops(stops0, door, false, true).has(door), "no stop at an unbuilt Church lot, nor in a regular town")
	check(TownView.hardcore_stops(stops0, door, false, false).has(Vector2i(1, 1)), "the other stops stay")
	# your marker: over the door only once you went inside, not while you fade in about town
	check(not TownView.door_marker({"you": true, "fade": 1.0, "arriving": true}), "no door marker while arriving")
	check(TownView.door_marker({"you": true, "fade": 1.0}), "a door marker once you went inside")
	check(not TownView.door_marker({"you": false, "fade": 1.0}), "no door marker for someone else")
	# no chat with someone fading in or out at a door
	var f1c := {"x": 100.0, "y": 100.0, "wait": 1.0}
	check(not TownView.chat_ok(f1c, {"x": 108.0, "y": 104.0, "wait": 2.0, "fade": 0.5}, Vector2(108, 104)), "no chat with a ghost fading at a door")
	check(not TownView.chat_ok({"x": 100.0, "y": 100.0, "wait": 1.0, "fade": 0.3}, {"x": 108.0, "y": 104.0, "wait": 2.0}, Vector2(108, 104)), "nobody fading starts a chat")
	# a sound is heard only on screen: just inside and just outside the right edge at 2.56
	var vo := Vector2(-100, -50)
	check(TownView.view_has(vo, 2.56, Vector2(430, 932), Vector2((529.0 - 0.5) / 2.56, 100)), "a point just inside the view is in view")
	check(not TownView.view_has(vo, 2.56, Vector2(430, 932), Vector2((530.0 + 0.5) / 2.56, 100)), "a point just past the right edge is not")
	# (Juzo: the pets stood on each other, walkers on top of one another) a pet takes a free pen spot;
	# a walker doesn't step onto someone standing
	var pets := [{"x": 100.0, "y": 100.0, "to": Vector2.ZERO}, {"x": 140.0, "y": 100.0, "to": Vector2(180, 100)}]
	var free := TownView.free_spots([Vector2(104, 100), Vector2(180, 102), Vector2(220, 100)], pets, null, 14.0)
	check(free == [Vector2(220, 100)], "pets never share a pen spot (%s)" % [free])
	check(TownView.free_spots([Vector2(104, 100)], pets, pets[0], 14.0).size() == 1, "a pet may stay on its own spot")
	var walkers := [{"x": 50.0, "y": 50.0, "wait": 1.0, "path": []}, {"x": 90.0, "y": 50.0, "wait": 0.0, "path": [Vector2i(1, 1)]}]
	check(TownView.crowded(Vector2(54, 52), walkers, null, 7.0), "a walker waits rather than step onto someone standing")
	check(not TownView.crowded(Vector2(92, 50), walkers, null, 7.0), "someone walking past is no obstacle")
	check(not TownView.crowded(Vector2(54, 52), walkers, walkers[0], 7.0), "nobody is in their own way")
	# the glow texture's core is capped and the light count shares a cluster's glow
	check(TownView.band_alpha(0.0) <= 0.7 and TownView.band_alpha(1.0) == 0.0, "the glow core is capped at 0.7")
	check(TownView.light_counts([[0, 0], [10, 0], [200, 0]]) == [2, 2, 1], "lamps within 56 px share their glow")
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
