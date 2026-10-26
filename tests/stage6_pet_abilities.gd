extends SceneTree
## 2.1 pet abilities by rank: a passive for every pet, a trick from Epic, a region signature at Mythic.
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
	g.level = 20
	g.floor_num = 20
	g.hero_hp = g.get_max_hp()
	return g

## A hero with one pet of this species and rank, coming along, facing a tough monster.
func with_pet(species: String, tier: int) -> Array:
	var g := hero()
	var p := Menagerie.make_pet(g, species, "", tier, "egg")
	g.enemy_hp = 1000000
	g.enemy_max_hp = 1000000
	g.cfight = {"turns": 1}
	return [g, p]

## A zone monster of this shape from the first region.
func of_shape(shape: String) -> String:
	for z in GameData.ZONES:
		for e in z["enemies"]:
			if String(e["shape"]) == shape:
				return String(e["id"])
	return ""

## The k-th zone monster of this shape (one of each kind per team, Juzo Oct 25), else the first.
func kind_of(shape: String, k: int) -> String:
	var all: Array = []
	for z in GameData.ZONES:
		for e in z["enemies"]:
			if String(e["shape"]) == shape:
				all.append(String(e["id"]))
	return String(all[k % all.size()]) if not all.is_empty() else ""

## Fable pets R2: kill signatures pay real gold, the fight's team fits the phone, UI pet
## pictures land on whole screen pixels.
func _r2_tests() -> void:
	# every "kill" signature (Fairy Gold) pays at least the floor's coin on a floor-50 kill
	for region in PetAbilities.SIGNATURES:
		var sig: Dictionary = PetAbilities.SIGNATURES[region]
		if String(sig["when"]) != "kill":
			continue
		var g := hero()
		g.floor_num = 50
		g.enemy_tier = 0
		g.enemy_is_boss = false
		g.enemy_variant = ""
		var p := Menagerie.make_pet(g, "", "", 5, "egg")
		var before := g.gold
		PetAbilities.apply(g, p, String(sig["do"]), float(sig["value"]), 0, String(sig["name"]))
		check(g.gold - before >= 2 + g.floor_num, "%s pays at least the floor's coin on a kill (%d)" % [sig["name"], g.gold - before])
	check(String(PetAbilities.SIGNATURES["fairy"]["text"]).contains("twice"), "Fairy Gold says what it does")
	# the fight: companion + three pets fit the stage of a 430x932 and a 375x667 phone (measured with
	# tests/_pets_shot.gd: 488x647 and 488x451 design units), no big overlaps, plate clear of them
	for phone in [[430, 647.0], [375, 451.0]]:
		var g := hero()
		g.hidden_class = "beast_tamer"
		g.hero_class = "Knight"   # a class with a companion
		g.level = maxi(g.level, World.PET_LEVEL)
		g.pet_on = true
		g.floor_num = 5
		for i in 3:
			Menagerie.make_pet(g, kind_of("spirit", i), "", 2, "egg")
		var bv := BattleView.new()
		bv.visible = false
		root.add_child(bv)
		bv.size = Vector2(488, float(phone[1]))
		bv.state = g
		var lay := bv.team_layout()
		var w := 32.0 * bv._u()
		check(lay.size() == 4, "companion and three pets all get a spot (%d)" % lay.size())
		var xs: Array = lay.values()
		for i in xs.size():
			check(float(xs[i]) >= 0.0 and float(xs[i]) + w <= bv.size.x + 0.01, "every pet stands on the stage at %d (x %.0f)" % [phone[0], xs[i]])
			for j in range(i + 1, xs.size()):
				var over := w - absf(float(xs[i]) - float(xs[j]))
				check(over <= w * 0.25 + 0.01, "pets overlap by at most a quarter at %d (%.0f of %.0f)" % [phone[0], over, w])
		var b := bv._bar_rect(bv._hero_rect())
		var plate_end := b.position.y + 24.0 + BattleView.NAME_FS
		var top := bv._team_ground() - 32.0 * bv._u()
		for x in xs:
			if float(x) + w > b.position.x and float(x) < b.end.x:
				check(plate_end <= top + 0.01, "the hero plate stays above the pets at %d (%.0f vs %.0f)" % [phone[0], plate_end, top])
		bv.queue_free()
	# UI: a 32 px pet in a PixelPic is a whole number of screen px per art px on both phones
	for sc in [0.853, 0.744, 1.0, 2.0]:
		for want in [2.0, 3.0, 5.0]:
			var px: float = PixelPic.side(32, want, sc) * sc / 32.0
			check(is_equal_approx(px, roundf(px)) and px >= 1.0, "PixelPic: %.1fx at stretch %.3f is whole screen pixels (%.2f)" % [want, sc, px])
	check(PixelPic.screen_px(2.0, 0.744) == 2 and PixelPic.screen_px(2.0, 0.853) == 2 and PixelPic.screen_px(3.0, 0.853) == 3, "a 2x slot is 2 screen px on both phones, a 3x card 3 at 430")

func _stage(g: GameState, h: float) -> BattleView:
	var bv := BattleView.new()
	bv.visible = false
	root.add_child(bv)
	bv.size = Vector2(488, h)
	bv.state = g
	return bv

func _r3_tests() -> void:
	# 1: a party of two out: pets stand in front of the members (drawn after them), clear of each
	# other, and none hides mostly behind a member (488 design units can't fit four creatures and
	# three heroes side by side, so some cover is the trade)
	var src := FileAccess.get_file_as_string("res://battle_view.gd")
	check(src.find("_draw_members()") < src.find("_draw_menagerie()
"), "party members draw before the pets")
	for phone in [[430, 647.0], [375, 451.0]]:
		var g := hero()
		g.hidden_class = "beast_tamer"
		g.hero_class = "Knight"
		g.level = maxi(g.level, World.PET_LEVEL)
		g.pet_on = true
		for i in 3:
			Menagerie.make_pet(g, kind_of("spirit", i), "", 2, "egg")
		var pt := Party.new()
		for n in 2:
			var mem := Party.Member.new()
			mem.slot = 20 + n
			mem.hp = 50
			pt.members.append(mem)
		g.party = pt
		var bv := _stage(g, float(phone[1]))
		var w := 32.0 * bv._u()
		var lay := bv.team_layout()
		check(lay.size() == 4, "with a party, everyone still gets a spot (%d)" % lay.size())
		var xs: Array = lay.values()
		for i in 2:
			var mc := bv._member_canvas(i).get_center().x
			for x in xs:
				var over := minf(float(x) + w, mc + 16.0 * bv._u()) - maxf(float(x), mc - 16.0 * bv._u())
				check(over <= w * 0.8 + 0.01, "no pet is hidden by party member %d at %d (%.0f of %.0f)" % [i, phone[0], over, w])
		for i in xs.size():
			for j in range(i + 1, xs.size()):
				check(w - absf(float(xs[i]) - float(xs[j])) <= w * 0.25 + 0.01, "with a party, pets overlap each other by at most a quarter at %d" % phone[0])
		check(bv.team_layout() == lay, "the layout is built once a frame")
		bv.queue_free()
	# 14: a wide pet in the first spot keeps clear of the hero's legs
	var wide := ""
	for sp in Menagerie.all_species():
		if Pets.width(String(sp)) > 24:
			wide = String(sp)
			break
	check(wide != "", "some pet is wide (%s)" % wide)
	for phone in [[430, 647.0], [375, 451.0]]:
		var g := hero()
		g.hero_class = "Warrior"   # no companion: the pet takes slot 0
		Menagerie.make_pet(g, wide, "", 5, "egg")
		var bv := _stage(g, float(phone[1]))
		var w := float(Pets.width(wide)) * bv._u()
		var hc := bv._hero_canvas()
		var x0 := float(bv.team_layout().get(0, 0.0)) + (32.0 - Pets.width(wide)) / 2.0 * bv._u()   # its body, roughly centred
		var over := minf(x0 + w, hc.get_center().x + hc.size.x / 6.0) - maxf(x0, hc.get_center().x - hc.size.x / 6.0)
		check(over <= w * 0.25 + 0.01, "a wide pet in slot 0 is at most a quarter behind the hero at %d (%.0f of %.0f)" % [phone[0], over, w])
		bv.queue_free()
	# 4: "Hits for" is Menagerie.turn's own sum (a Beast Lord's song, the party's strength)
	var bl := hero()
	bl.hidden_class = "beast_tamer"
	bl.level = maxi(bl.level, int(Hidden.STAGE_LEVELS[1]))
	var blp := Menagerie.make_pet(bl, of_shape("beast"), "", 3, "egg")
	check(Menagerie.whisperer_near(bl), "a Beast Lord sings to the pets")
	var tab := PetTab.new()
	tab.state = bl
	var want := int(Menagerie.power(blp) * Menagerie.WHISPER_POWER * bl.party_mult() * 100)
	check(tab._hits(blp) == want and want > int(Menagerie.power(blp) * 100), "the Pet tab's Hits for counts the song (%d)" % tab._hits(blp))
	tab.free()
	# 5: the Codex and Collections count the same pet kinds
	check(Collections.total("pets") == Menagerie.all_species().size() and Menagerie.all_species().size() == Monsters.all_monsters().size() + Calamity.LIST.size(), "Codex and Collections count the same pets (%d)" % Collections.total("pets"))
	var cg := hero()
	cg.codex.pet_book[Calamity.pet_id(Calamity.LIST[0])] = 5
	check(Collections.count(cg.codex, "pets") >= 1, "an owned Calamity pet counts as a kind owned")
	# 6: Fairy Gold on a treasure goblin pays the goblin's gold again (2x in all)
	var fairy := ""
	for z in GameData.ZONES:
		if String(z["id"]) == "fairy":
			fairy = String(z["enemies"][0]["id"])
	var fg := with_pet(fairy, 5)
	var gg: GameState = fg[0]
	var drop := (2 + gg.floor_num) * GameData.GOBLIN_GOLD
	var b0 := gg.gold
	gg._add_gold(drop)
	var one := gg.gold - b0
	b0 = gg.gold
	Menagerie.on_kill(gg, drop)
	check(gg.gold - b0 == one, "Fairy Gold doubles a goblin's drop (%d, the drop %d)" % [gg.gold - b0, one])
	check(FileAccess.get_file_as_string("res://game_state.gd").contains("Menagerie.on_kill(self, gold_gain)"), "the kill hands the real drop to the pets")
	# 7: a name can't carry BBCode into the log
	var rg := hero()
	var rp := Menagerie.make_pet(rg, of_shape("beast"), "", 1, "egg")
	Menagerie.rename(rg, int(rp["id"]), "[b]x[/b]")
	check(not String(rp["name"]).contains("[") and not String(rp["name"]).contains("]") and String(rp["name"]) == "bx/b", "a rename drops BBCode brackets (%s)" % rp["name"])
	check(Menagerie.clean_name("  [color=red]Rex  ") == "color=redRex", "the companion's name is cleaned the same way")
	# 8: "Swap in" sends a resting pet home before a fighting one
	var sg := hero()
	sg.hidden_class = "beast_tamer"
	var ps: Array = []
	for i in 3:
		ps.append(Menagerie.make_pet(sg, kind_of("beast", i), "", 1, "egg"))
	(ps[0] as Dictionary)["hurt"] = 2
	Menagerie.changed(sg)   # set by hand: caches start over
	var fourth := Menagerie.make_pet(sg, kind_of("beast", 3), "", 1, "egg")
	check(int(fourth["id"]) in sg.pets_out, "a new pet takes a resting pet's spot")
	check(not int(ps[0]["id"]) in sg.pets_out and int(ps[1]["id"]) in sg.pets_out and int(ps[2]["id"]) in sg.pets_out, "the resting one left, the two healthy stay")
	var sg2 := hero()
	sg2.hidden_class = "beast_tamer"
	var qs: Array = []
	for i in 3:
		qs.append(Menagerie.make_pet(sg2, kind_of("beast", i), "", 1, "egg"))
	var extra := Menagerie.make_pet(sg2, kind_of("beast", 3), "", 1, "egg")   # waits at home: the team is full
	(qs[0] as Dictionary)["hurt"] = 2
	Menagerie.changed(sg2)   # set by hand: caches start over
	Menagerie.toggle_out(sg2, int(extra["id"]))
	check(not int(qs[0]["id"]) in sg2.pets_out and int(qs[1]["id"]) in sg2.pets_out and int(qs[2]["id"]) in sg2.pets_out and int(extra["id"]) in sg2.pets_out, "Swap in drops the hurt pet, not a fighter (%s)" % str(sg2.pets_out))
	# 12: copy
	check(PetAbilities.family_trick_text("beast", PetAbilities.TRICK_RANK).contains("pounce again for its hit"), "Pounce at 1x says its hit")

func _find_button(n: Node, text: String) -> Button:
	for c in n.get_children():
		if c is Button and (c as Button).text == text:
			return c
		var b := _find_button(c, text)
		if b != null:
			return b
	return null

func _r4_tests() -> void:
	# 1: who lunges for a hit: the summon, the companion (no "pet"), never the companion for a menagerie pet
	check(BattleView.who_lunges({"name": "Imp"}, "Imp", 2, true) == "summon_lunge", "a summon's hit lunges the summon")
	check(BattleView.who_lunges({"name": "Chick"}, "Imp", 0, true) == "pet_lunge", "the companion's hit lunges the companion")
	check(BattleView.who_lunges({"name": "Rex", "pet": 7}, "Imp", 0, true) == "", "a menagerie pet's hit doesn't move the companion")
	# 2: pet events say whose and how rare
	var a := with_pet(of_shape("beast"), 3)
	var g: GameState = a[0]
	g.events.clear()
	Menagerie.turn(g)
	var hit: Array = g.events.filter(func(e): return e["type"] == "summon_hit")
	check(not hit.is_empty() and hit[0].has("tier") and hit[0].has("pet"), "a pet's hit carries its id and rank")
	g.events.clear()
	PetAbilities.apply(g, a[1], "strike", 1.0, 100, "Pounce")
	PetAbilities.apply(g, a[1], "shield", 5, 10, "Guard")
	var ev: Array = g.events.filter(func(e): return e["type"] == "buff" and e.has("pet"))
	check(ev.size() == 2, "a Pounce and a Guard float over the pet that did them (%d)" % ev.size())
	g.events.clear()
	PetAbilities.apply(g, a[1], "gold", 30, 0, "Pickpocket")
	check(g.events.any(func(e): return e["type"] == "pet_gold" and int(e["amount"]) > 0), "pet gold shows as a number")
	# 3: a nest gets its moment (no banner), with the egg's rank and region
	var ng := hero()
	ng.events.clear()
	Menagerie.give_egg(ng, "nest", 0, 4)
	var em: Array = ng.events.filter(func(e): return e["type"] == "egg_moment")
	check(em.size() == 1 and int(em[0]["tier"]) == 4 and String(em[0]["zone"]) == String(GameData.ZONES[0]["id"]), "a nest is one egg moment with its rank and region")
	check(not ng.events.any(func(e): return e["type"] == "mini_event"), "no banner over the nest moment")
	# 4: a hatch is announced once and says where the baby went
	ng.events.clear()
	ng.messages.clear()
	var baby := Menagerie.hatch(ng, ng.eggs[0])
	check(ng.events.filter(func(e): return e["type"] == "hatch_moment").size() == 1 and not ng.events.any(func(e): return e["type"] == "mini_event"), "a hatch is one moment, no banner")
	check(str(ng.messages).contains("joins your team") or str(ng.messages).contains("waits at home"), "the hatch line says where the baby went")
	# 5: the light for rare hatches and nests is tested on Menagerie.moment itself (_r5_tests)
	# 14: the Codex reward lands with the find
	var cg := hero()
	cg.codex.coll_earned.clear()
	Menagerie.make_pet(cg, of_shape("beast"), "", 5, "egg")
	check(cg.codex.coll_earned.has("pet_myth"), "a first Mythic earns its Codex reward right away")
	check(baby.has("id"), "the hatch made a pet")
	# 6: the tab shows the team, then healthy by rank, then hurt; a kill doesn't rebuild it
	var og := hero()
	var hurt_rare := Menagerie.make_pet(og, of_shape("beast"), "", 2, "egg")
	og.pets_out.clear()
	Menagerie.changed(og)
	var common := Menagerie.make_pet(og, of_shape("beast"), "", 0, "egg")
	og.pets_out.clear()
	Menagerie.changed(og)
	var myth := Menagerie.make_pet(og, of_shape("beast"), "", 5, "egg")
	hurt_rare["hurt"] = 3
	Menagerie.changed(og)   # set by hand: caches start over
	og.pets_out.clear()
	Menagerie.changed(og)
	og.pets_out.append(int(myth["id"]))
	Menagerie.changed(og)
	var order := PetTab.sorted(og)
	check(order.size() == 3 and order[0] == myth and order[1] == common and order[2] == hurt_rare, "Pet tab order: coming along, healthy, resting")
	var key := PetTab.pets_key(og)
	myth["kills"] = int(myth["kills"]) + 1
	check(PetTab.pets_key(og) == key, "a kill doesn't rebuild the Pet tab")
	# 7: a hurt pet's button can't drop it from the team
	og.pets_out.append(int(hurt_rare["id"]))
	Menagerie.changed(og)
	var tab := PetTab.new()
	tab.state = og
	var row := tab._pet_row(hurt_rare)
	var rb := _find_button(row, "Resting")
	check(rb != null and rb.disabled, "a hurt pet's Resting button is off")
	row.free()
	tab.free()
	# 8: the Pet tab uses the game's tap size
	check(not FileAccess.get_file_as_string("res://pet_tab.gd").contains("52"), "Pet tab buttons are UI.TAP tall")
	# 10: the room's row keeps off party members too
	for phone in [430.0, 375.0]:
		var rg := hero()
		rg.hidden_class = "beast_tamer"
		for i in 3:
			Menagerie.make_pet(rg, kind_of("spirit", i), "", 2, "egg")
		var rv := RoomView.new()
		rv.state = rg
		rv.size = Vector2(488, phone * 1.5)
		var k := 3.0
		var w := 32.0 * k
		var xs := rv._row(Vector2(244, 600), 144.0, k, Menagerie.out(rg), [0.22, 0.78])
		for m in [0.22, 0.78]:
			var mc: float = 488.0 * m
			for x in xs:
				var over := minf(float(x) + w, mc + 16.0 * k) - maxf(float(x), mc - 16.0 * k)
				check(over <= w * 0.8 + 0.01, "room: no pet hidden by a party member (%.0f of %.0f)" % [over, w])
		rv.free()
	# Juzo (Oct 25): one of each kind per team
	check(kind_of("beast", 0) != kind_of("beast", 3) and kind_of("spirit", 0) != kind_of("spirit", 2), "enough kinds for distinct teams")
	var dg := hero()
	dg.hidden_class = "beast_tamer"
	var sp := kind_of("beast", 0)
	var p1 := Menagerie.make_pet(dg, sp, "", 2, "egg")
	var p2 := Menagerie.make_pet(dg, sp, "", 4, "egg")
	check(int(p1["id"]) in dg.pets_out and not int(p2["id"]) in dg.pets_out, "a second copy of a kind waits at home")
	check(not Menagerie.toggle_out(dg, int(p2["id"])) and not int(p2["id"]) in dg.pets_out, "a second copy can't be brought along")
	check(Menagerie.out_block(dg, int(p2["id"])).begins_with("You already have a %s out" % Monsters.name_of(sp)), "it says why (%s)" % Menagerie.out_block(dg, int(p2["id"])))
	Menagerie.toggle_out(dg, int(p1["id"]))
	check(Menagerie.toggle_out(dg, int(p2["id"])), "with the first one home, the other copy can come")
	# old saves: two of a kind out -> the highest rank stays, the rest go home, a note says so
	var mg := hero()
	mg.hidden_class = "beast_tamer"
	var lo := Menagerie.make_pet(mg, sp, "", 1, "egg")
	var hi := Menagerie.make_pet(mg, sp, "", 5, "egg")
	var other := Menagerie.make_pet(mg, kind_of("beast", 1), "", 0, "egg")
	mg.pets_out = [int(lo["id"]), int(hi["id"]), int(other["id"])]
	Menagerie.changed(mg)
	mg.slot = 6
	mg.autosave = true
	mg.save_game()
	var ld := GameState.new()
	ld.codex.path = ""
	ld.slot = 6
	check(ld.load_game(), "the old save loads")
	check(ld.pets_out.size() == 2 and int(hi["id"]) in ld.pets_out and int(other["id"]) in ld.pets_out and ld.pets.size() == 3, "on load the best copy stays out, the other goes home (%s)" % str(ld.pets_out))
	check(str(ld.messages).contains("one of each kind"), "and a note says so")
	for path in GameState.slot_paths(6):
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# Fairy Gold pays once per kind now
	var fairy2 := ""
	for z in GameData.ZONES:
		if String(z["id"]) == "fairy":
			fairy2 = String(z["enemies"][0]["id"])
	var fg2 := hero()
	fg2.hidden_class = "beast_tamer"
	for i in 3:
		Menagerie.make_pet(fg2, fairy2, "", 5, "egg")
	check(Menagerie.out(fg2).size() == 1, "three Mythic fairies of a kind: one fights")
	var gb := fg2.gold
	fg2._add_gold(100)
	var once := fg2.gold - gb
	gb = fg2.gold
	Menagerie.on_kill(fg2, 100)
	check(fg2.gold - gb == once, "Fairy Gold pays the drop once, not three times (%d)" % (fg2.gold - gb))

	# Pet levels (Oct 25): early levels come fast, max takes long, never a rank's worth of power
	check(Menagerie.kills_for(2) == 50 and Menagerie.level_for(49) == 1 and Menagerie.level_for(50) == 2, "the first level takes 50 kills")
	check(Menagerie.kills_for(Menagerie.MAX_LEVEL) >= 10000, "max level is a long goal (%d kills)" % Menagerie.kills_for(Menagerie.MAX_LEVEL))
	for t in 5:
		var top := Menagerie.power({"tier": t, "level": Menagerie.MAX_LEVEL})
		check(top < float(Menagerie.POWER_BY_TIER[t + 1]), "a max-level %s hits softer than a new %s (%.3f)" % [Menagerie.TIER_NAMES[t], Menagerie.TIER_NAMES[t + 1], top])
	check(is_equal_approx(Menagerie.power({"tier": 2, "level": 99}), Menagerie.power({"tier": 2, "level": Menagerie.MAX_LEVEL})), "an old save's higher level gives the max bonus, no more")
	var lg := hero()
	var lp := Menagerie.make_pet(lg, kind_of("beast", 0), "", 1, "egg")
	for i in 50:
		Menagerie.on_kill(lg)
	check(int(lp["level"]) == 2, "50 kills: level 2 (%d)" % int(lp["level"]))
	var cg2 := hero()
	var old_hi := Menagerie.make_pet(cg2, kind_of("beast", 0), "", 1, "egg")
	old_hi["level"] = 40
	old_hi["kills"] = 1600
	var old_lo := Menagerie.make_pet(cg2, kind_of("beast", 1), "", 1, "egg")
	old_lo["level"] = 1
	old_lo["kills"] = 400
	old_lo.erase("curve")   # an old-curve pet
	old_hi.erase("curve")
	Menagerie.convert_levels(cg2)
	check(int(old_hi["level"]) == 40 and int(old_lo["level"]) == Menagerie.level_for(400) and int(old_lo["level"]) > 1, "converting old saves never lowers a level (%d, %d)" % [int(old_hi["level"]), int(old_lo["level"])])

	# 11: the fight asks Menagerie.out once a frame
	var bv := _stage(og, 647.0)
	check(is_same(bv._team_out(), bv._team_out()), "the fight's pets are listed once a frame")
	bv.queue_free()

func _tamer() -> GameState:
	var g := hero()
	g.hidden_class = "beast_tamer"
	return g

func _r5_tests() -> void:
	var sp := kind_of("beast", 0)
	# 1: an old save with a resting Mythic and a fighting Rare of one kind keeps the Rare out
	var g1 := _tamer()
	var rare := Menagerie.make_pet(g1, sp, "", 2, "egg")
	var myth := Menagerie.make_pet(g1, sp, "", 5, "egg")
	myth["hurt"] = 5
	g1.pets_out = [int(myth["id"]), int(rare["id"])]
	Menagerie.changed(g1)
	var home := Menagerie.one_of_each(g1)
	check(int(rare["id"]) in g1.pets_out and not int(myth["id"]) in g1.pets_out and home == [String(myth["name"])], "the healthy copy stays out, the resting one goes home (%s)" % str(g1.pets_out))
	# 2: a resting twin doesn't block the healthy copy: label and tap agree
	var g2 := _tamer()
	var a := Menagerie.make_pet(g2, sp, "", 2, "egg")
	var b := Menagerie.make_pet(g2, sp, "", 3, "egg")
	a["hurt"] = 4
	Menagerie.changed(g2)
	check(Menagerie.out_block(g2, int(b["id"])) == "" and Menagerie.same_kind_out(g2, int(b["id"])).is_empty(), "a resting twin doesn't count as out")
	var tab := PetTab.new()
	tab.state = g2
	var row := tab._pet_row(b)
	check(_find_button(row, "Bring along") != null or _find_button(row, "Swap in") != null, "its button offers to bring it")
	row.free()
	check(Menagerie.toggle_out(g2, int(b["id"])) and Menagerie.out(g2).filter(func(q): return String(q["species"]) == sp).size() == 1, "the tap brings it, and the team holds one of the kind")
	# 3 + 17: an old-curve save says so once, never lowers a level, and the note doesn't repeat
	var g3 := hero()
	var old := Menagerie.make_pet(g3, sp, "", 0, "egg")
	old["level"] = 20
	old["kills"] = 800
	old.erase("curve")
	g3.slot = 7
	g3.autosave = true
	g3.save_game()
	var l1 := GameState.new()
	l1.codex.path = ""
	l1.slot = 7
	l1.autosave = true
	check(l1.load_game() and str(l1.messages).contains("Pet levels were rebalanced") and int(l1.pets[0]["level"]) == 20, "an old-curve pet keeps its level and the load says levels changed")
	var l2 := GameState.new()
	l2.codex.path = ""
	l2.slot = 7
	l2.autosave = true
	check(l2.load_game() and not str(l2.messages).contains("rebalanced") and not str(l2.messages).contains("one of each kind"), "the note shows once")
	for path in GameState.slot_paths(7):
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(PetTab.level_line({"level": 1, "kills": 20}) == "Level 1: 30 more kills to level 2" and PetTab.level_line({"level": Menagerie.MAX_LEVEL, "kills": 0}).ends_with("(max)"), "levels show progress (%s)" % PetTab.level_line({"level": 1, "kills": 20}))
	# 4: one rank palette
	check(not FileAccess.get_file_as_string("res://pet_tab.gd").contains("color_of"), "the Pet tab uses the pets' rank colours")
	# 13 + 14: the moment entries themselves
	var mh := Menagerie.moment({"type": "hatch_moment", "name": "Rex", "species": sp, "art": "", "cherished": false, "tier": 5})
	var mc := Menagerie.moment({"type": "hatch_moment", "name": "Rex", "species": sp, "art": "", "cherished": true, "tier": 1})
	var mp := Menagerie.moment({"type": "hatch_moment", "name": "Rex", "species": sp, "art": "", "cherished": false, "tier": 2})
	var me := Menagerie.moment({"type": "egg_moment", "name": "Legendary Egg", "zone": String(GameData.ZONES[0]["id"]), "tier": 4})
	check(mh[0] == "hatch" and mh[4] == "rare" and mp[4] == "" and mc[4] == "rare", "Mythic and Cherished hatches open with light, a Rare doesn't")
	check(me[0] == "egg" and me[4] == "rare" and me[5] == Pets.egg(String(GameData.ZONES[0]["id"])), "a Legendary nest shows its region's egg, with light")
	check(mh[3] == Color(Menagerie.TIER_COLORS[5]), "the hatch uses the pets' rank colour")
	# 16: no head for a pet that isn't out
	var bv := _stage(g2, 647.0)
	check(bv._pet_head(999999) == Vector2.INF, "a pet that isn't out floats nothing over the hero")
	bv.queue_free()
	# 6: a kill doesn't change the team's revision; out() is cached
	var r0 := g2.pets_rev
	Menagerie.on_kill(g2)
	check(g2.pets_rev == r0 and is_same(Menagerie.out(g2), Menagerie.out(g2)), "a kill keeps the cached team")

## 5: every one-word pet name fits a Codex cell on one line.
func _codex_names() -> void:
	var l := UI.label("x", UI.FONT_CAPTION)
	root.add_child(l)
	await process_frame
	var font := l.get_theme_font("font")
	var book := PetBookTab.new()
	var worst := ""
	var widest := 0.0
	for n in Menagerie.all_species():
		var nm := book._name(String(n))
		var fs := UI.FONT_CAPTION   # as _cell shows names
		for word in ([nm] if not nm.contains(" ") else nm.split(" ")):
			var w := font.get_string_size(String(word), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if w > widest:
				widest = w
				worst = String(word)
	check(widest <= 104.0, "every Codex name fits its cell line (widest %s, %.0f px)" % [worst, widest])
	book.free()
	l.queue_free()

## 13: a live PixelPic in a container shows whole screen pixels per art pixel.
func _live_pic() -> void:
	var vb := VBoxContainer.new()
	vb.size = Vector2(300, 400)
	root.add_child(vb)
	var pic := PixelPic.make(Pets.art("barghest"))
	vb.add_child(pic)
	await process_frame
	await process_frame
	var px: float = pic.size.x * PixelPic.stretch(pic) / pic.art_px
	check(absf(px - roundf(px)) < 0.02 and px >= 1.0, "a PixelPic in a VBox is whole screen pixels (%.2f)" % px)
	vb.queue_free()

func _initialize() -> void:
	# The table is complete: every family has a passive with 6 ranks and a trick; every region a signature
	for f in PetAbilities.FAMILIES:
		var d: Dictionary = PetAbilities.FAMILIES[f]
		check((d["passive"]["values"] as Array).size() == 6, "%s passive has a value per rank" % f)
		check((d["trick"]["chance"] as Array).size() == 2 and (d["trick"]["value"] as Array).size() == 2, "%s trick has Epic and Legendary values" % f)
		var vals: Array = d["passive"]["values"]
		for i in 5:
			check(float(vals[i + 1]) >= float(vals[i]), "%s passive never gets weaker with rank" % f)
			# Fable pets R1: "a stronger passive" means a bigger number (Calamity pets only come at Mythic)
			if f != "calamity":
				check(float(vals[i + 1]) > float(vals[i]), "%s passive is stronger at every rank (%s)" % [f, str(vals)])
	for z in GameData.ZONES:
		check(PetAbilities.SIGNATURES.has(String(z["id"])), "region %s has a Mythic signature" % z["id"])
	# Every zone monster maps to a known family and its home region
	for z in GameData.ZONES:
		for e in z["enemies"]:
			check(PetAbilities.FAMILIES.has(PetAbilities.family(String(e["id"]))), "%s has a family" % e["id"])
			check(PetAbilities.home(String(e["id"])) == String(z["id"]), "%s lives in %s" % [e["id"], z["id"]])
	check(PetAbilities.family(Calamity.pet_id(Calamity.LIST[0])) == "calamity" and PetAbilities.home(Calamity.pet_id(Calamity.LIST[0])) == "calamity", "a Calamity's pet is its own family")

	# Unlock by rank
	var beast := of_shape("beast")
	check(beast != "", "found a beast")
	for t in 6:
		var p := {"id": 1, "species": beast, "tier": t}
		var ls := PetAbilities.lines(p)
		var on := ls.filter(func(x): return x["on"]).size()
		check(on == (1 if t < 3 else (2 if t < 5 else 3)), "rank %d knows %d abilities (got %d)" % [t, 1 if t < 3 else (2 if t < 5 else 3), on])
		check(ls.any(func(x): return not x["on"]) == (t < 5), "rank %d shows what's still locked" % t)
		check(PetAbilities.has_trick(p) == (t >= 3) and PetAbilities.has_signature(p) == (t >= 5), "rank %d trick/signature flags" % t)
	check(PetAbilities.lines({"id": 1, "species": beast, "tier": 3}).any(func(x): return not x["on"] and x["rank"] == 4), "an Epic shows the stronger trick as locked")

	# Passives apply through the normal stat code
	var g0 := hero()
	var crit0 := g0.effect_value("crit")
	var a := with_pet(beast, 2)
	var g: GameState = a[0]
	check(is_equal_approx(g.effect_value("crit") - crit0, PetAbilities.passive_value(beast, 2)), "a Rare beast adds its crit (%.1f vs %.1f)" % [g.effect_value("crit"), crit0])
	var brute := of_shape("brute")
	var hp0 := g0.get_max_hp()
	var b := with_pet(brute, 5)
	check((b[0] as GameState).get_max_hp() > hp0, "a brute adds max HP (%d vs %d)" % [(b[0] as GameState).get_max_hp(), hp0])
	var hum := of_shape("humanoid")
	var gf := with_pet(hum, 0)
	check((gf[0] as GameState).effect_value("gold_find") > g0.effect_value("gold_find"), "a folk pet adds gold find")
	# A hurt pet, or one left home, gives nothing
	(a[1] as Dictionary)["hurt"] = 3
	Menagerie.changed(g)   # set by hand: caches start over
	check(is_equal_approx(g.effect_value("crit"), crit0), "a hurt pet's passive is off")
	(a[1] as Dictionary)["hurt"] = 0
	Menagerie.changed(g)   # set by hand: caches start over
	Menagerie.toggle_out(g, int((a[1] as Dictionary)["id"]))
	check(is_equal_approx(g.effect_value("crit"), crit0), "a pet left home gives nothing")
	# Balance: even a Mythic's passive stays small next to class skills and gear
	for f in PetAbilities.FAMILIES:
		var d: Dictionary = PetAbilities.FAMILIES[f]
		check(float(d["passive"]["values"][5]) <= 12.0, "%s Mythic passive stays small" % f)
		check(float(d["trick"]["chance"][1]) <= 30.0, "%s trick is a chance, not every turn" % f)

	# Tricks: a Common never tricks; an Epic does, sometimes
	var c := with_pet(beast, 0)
	var gc: GameState = c[0]
	for i in 300:
		Menagerie.turn(gc)
	check(int(gc.feats.get("pet_tricks", 0)) == 0, "a Common pet has no trick")
	var e := with_pet(beast, 3)
	var ge: GameState = e[0]
	for i in 300:
		Menagerie.turn(ge)
	var n := int(ge.feats.get("pet_tricks", 0))
	check(n > 20 and n < 90, "an Epic beast pounces about 15%% of turns (%d of 300)" % n)
	var l := with_pet(beast, 4)
	for i in 300:
		Menagerie.turn(l[0])
	check(int((l[0] as GameState).feats.get("pet_tricks", 0)) > 35, "a Legendary tricks more often (%d)" % int((l[0] as GameState).feats.get("pet_tricks", 0)))
	# Each trick does what it says
	var gs := with_pet(brute, 3)
	var gg: GameState = gs[0]
	gg.shield_hp = 0
	check(PetAbilities.apply(gg, gs[1], "shield", 5, 10, "Guard") and gg.shield_hp == int(gg.get_max_hp() * 0.05), "Guard shields you")
	gg.hero_hp = 10
	PetAbilities.apply(gg, gs[1], "heal", 5, 10, "Mend")
	check(gg.hero_hp > 10, "Mend heals you")
	gg.leader_down = true
	check(not PetAbilities.apply(gg, gs[1], "heal", 5, 10, "Mend"), "no healing a hero who is down")
	gg.leader_down = false
	PetAbilities.apply(gg, gs[1], "poison", 0.5, 100, "Venom")
	check(gg.enemy_poison_turns == Combat.POISON_TURNS and gg.enemy_poison_dmg == 50, "Venom poisons")
	PetAbilities.apply(gg, gs[1], "poison", 0.5, 100, "Venom")
	check(gg.enemy_poison_dmg == 50, "pet poison doesn't stack")
	# Fable pets R1: a pet's weaker venom/burn never keeps the hero's stronger one going
	gg.enemy_poison_dmg = 500
	gg.enemy_poison_turns = 1
	PetAbilities.apply(gg, gs[1], "poison", 0.5, 100, "Venom")
	check(gg.enemy_poison_dmg == 500 and gg.enemy_poison_turns == 2, "weak venom only tops a strong poison up to 2 turns (%d, %d)" % [gg.enemy_poison_dmg, gg.enemy_poison_turns])
	gg.burn_dmg = 400
	gg.burn_turns = 1
	PetAbilities.apply(gg, gs[1], "burn", 1.0, 40, "Ember Breath")
	check(gg.burn_dmg == 400 and gg.burn_turns == 2, "weak pet fire only tops a strong burn up to 2 turns (%d, %d)" % [gg.burn_dmg, gg.burn_turns])
	gg.burn_turns = 0
	gg.enemy_poison_turns = 0
	gg.enemy_poison_dmg = 0
	var gold := gg.gold
	PetAbilities.apply(gg, gs[1], "gold", 3, 0, "Pickpocket")
	check(gg.gold > gold, "Pickpocket steals gold")
	# Fable pets R1: Pickpocket at Epic beats Folk's best passive on the same kill
	var kill := float(2 + gg.floor_num) * float(Monsters.TIERS[gg.enemy_tier]["gold"])
	gold = gg.gold
	PetAbilities.apply(gg, gs[1], "gold", float(PetAbilities.FAMILIES["humanoid"]["trick"]["value"][0]), 0, "Pickpocket")
	check(gg.gold - gold >= int(kill * float(PetAbilities.FAMILIES["humanoid"]["passive"]["values"][5]) / 100.0), "Pickpocket is worth more than Sticky Fingers (%d)" % (gg.gold - gold))
	var hp := gg.enemy_hp
	PetAbilities.apply(gg, gs[1], "strike", 2.0, 100, "Pounce")
	check(gg.enemy_hp < hp, "Pounce hits")
	gg.enemy_stun = 0
	PetAbilities.apply(gg, gs[1], "stun", 1, 0, "Bramble Snare")
	check(gg.enemy_stun == 1, "a snare stuns")
	gg.enemy_weaken_turns = 0
	PetAbilities.apply(gg, gs[1], "weaken", 25, 0, "Grave Chill")
	check(is_equal_approx(gg.enemy_weaken, 0.75) and gg.enemy_weaken_turns == 3, "a chill weakens")
	gg.burn_turns = 0
	PetAbilities.apply(gg, gs[1], "burn", 1.0, 40, "Ember Breath")
	check(gg.burn_turns == GameData.BURN_TURNS and gg.burn_dmg == 40, "Ember Breath burns")
	gg.burn_tag = "Blood"
	PetAbilities.apply(gg, gs[1], "burn", 1.0, 40, "Ember Breath")
	check(gg.burn_tag == "Blood", "a pet's fire doesn't overwrite a bleed")

	# Balance caps
	var mx := gg.get_max_hp()
	gg.shield_hp = 0
	gg.set_meta("pet_shield", 0)
	for i in 30:
		PetAbilities.apply(gg, gs[1], "shield", 8, 10, "Guard")
	check(gg.shield_hp <= int(mx * PetAbilities.SHIELD_CAP), "pet shields stop at half your max HP (%d of %d)" % [gg.shield_hp, mx])
	check(PetAbilities.pet_shield(gg) == gg.shield_hp, "the game knows the shield is the pet's")
	ClassTree.on_fight_start(gg)
	PetAbilities._fight_start(gg)  # the clear itself; a pet turn could roll a fresh Guard
	check(gg.shield_hp == 0, "pet shields don't carry into the next fight (%d)" % gg.shield_hp)
	var tm := hero()
	tm.hidden_class = "beast_tamer"
	var spirit := of_shape("spirit")
	var regen0 := tm.effect_value("regen")
	for i in 3:
		Menagerie.make_pet(tm, kind_of("spirit", i), "", 5, "egg")
	check(Menagerie.out(tm).size() == 3, "a tamer brings three pets")
	check(tm.effect_value("regen") - regen0 <= PetAbilities.REGEN_CAP + 0.001, "three Mythic spirits heal at most %.1f%% a turn (%.2f)" % [PetAbilities.REGEN_CAP, tm.effect_value("regen") - regen0])
	check(str(PetAbilities.bonus_sources(tm)) == str(PetAbilities.bonus_sources(tm)), "cached passives stay the same")
	var shares: Array = []
	for p in Menagerie.out(tm):
		shares.append(PetAbilities.regen_share(tm, p))
	check(is_equal_approx(shares[0] + shares[1] + shares[2], minf(PetAbilities.REGEN_CAP, 3 * PetAbilities.passive_value(spirit, 5))) and float(shares[2]) < PetAbilities.passive_value(spirit, 5), "regen_share shows the cap cutting the third spirit (%s)" % str(shares))
	(Menagerie.out(tm)[0] as Dictionary)["hurt"] = 2
	Menagerie.changed(tm)   # set by hand: caches start over
	check(Menagerie.out(tm).size() == 2 and PetAbilities.bonus_sources(tm).size() == 2, "the cache notices a pet getting hurt")
	# Pickpocket: once a fight
	var pk := with_pet(of_shape("humanoid"), 4)
	var gpk: GameState = pk[0]
	for i in 200:
		Menagerie.turn(gpk)
	check(int(gpk.feats.get("pet_tricks", 0)) == 1, "Pickpocket steals once a fight (%d)" % int(gpk.feats.get("pet_tricks", 0)))

	# Signatures: a Mythic from the Mossy Hollows snares on its first turn, once a fight
	var moss := String(GameData.ZONES[0]["enemies"][0]["id"])
	check(PetAbilities.home(moss) == "mossy_hollows", "first region monster is from the Mossy Hollows")
	var m := with_pet(moss, 5)
	var gm: GameState = m[0]
	gm.enemy_stun = 0
	Menagerie.turn(gm)
	check(gm.enemy_stun >= 1, "Bramble Snare goes off on the first turn")
	gm.enemy_stun = 0
	Menagerie.turn(gm)
	check(gm.enemy_stun == 0, "and only once a fight")
	ClassTree.on_fight_start(gm)
	Menagerie.turn(gm)
	check(gm.enemy_stun >= 1, "again next fight")
	var rare := with_pet(moss, 4)
	(rare[0] as GameState).enemy_stun = 0
	Menagerie.turn(rare[0])
	check((rare[0] as GameState).enemy_stun == 0, "a Legendary has no signature")
	# A "low" signature waits until you're hurt
	var flood := ""
	for z in GameData.ZONES:
		if String(z["id"]) == "flooded_depths":
			flood = String(z["enemies"][0]["id"])
	var fl := with_pet(flood, 5)
	var gfl: GameState = fl[0]
	Menagerie.turn(gfl)
	check(not gfl.cfight.get("pet_sig", {}).has(int((fl[1] as Dictionary)["id"])), "Undertow waits while you're healthy")
	gfl.hero_hp = int(gfl.get_max_hp() * 0.2)
	var before := gfl.hero_hp
	Menagerie.turn(gfl)
	check(gfl.hero_hp > before, "Undertow heals when you drop low (%d -> %d)" % [before, gfl.hero_hp])
	# A "kill" signature: Fairy Gold
	var fairy := ""
	for z in GameData.ZONES:
		if String(z["id"]) == "fairy":
			fairy = String(z["enemies"][0]["id"])
	var fy := with_pet(fairy, 5)
	var gfy: GameState = fy[0]
	var g1 := gfy.gold
	Menagerie.on_kill(gfy)
	check(gfy.gold > g1, "Fairy Gold pays out on a kill")

	# Works with Auto play: real turns with a Mythic pet, nothing to press
	var ga := GameState.new()
	ga.codex.path = ""
	ga.autosave = false
	ga.new_game()
	ga.choose_class("Warrior")
	var ap := Menagerie.make_pet(ga, moss, "", 5, "egg")
	ga.auto_ability = true
	ga.auto_potion = true
	for i in 400:
		ga.take_turn()
		ga.messages.clear()
		ga.events.clear()
	check(int(ap["kills"]) > 0, "the pet fights through Auto turns (%d kills)" % int(ap["kills"]))

	# Save and load: the pet keeps its rank, so it keeps its abilities
	var sv := with_pet(of_shape("spirit"), 5)
	var gsv: GameState = sv[0]
	gsv.slot = 5
	gsv.autosave = true
	var regen := gsv.effect_value("regen")
	var lines_before := str(PetAbilities.lines(sv[1]))
	gsv.save_game()
	var ld := GameState.new()
	ld.codex.path = ""
	ld.slot = 5
	check(ld.load_game(), "the save loads")
	check(ld.pets.size() == 1 and int(ld.pets[0]["tier"]) == 5, "the pet comes back at its rank")
	if ld.pets.size() == 1:
		check(str(PetAbilities.lines(ld.pets[0])) == lines_before, "same abilities after loading")
		check(is_equal_approx(ld.effect_value("regen"), regen), "its passive still applies after loading (%.2f vs %.2f)" % [ld.effect_value("regen"), regen])
	for path in GameState.slot_paths(5):
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_r2_tests()
	_r3_tests()
	_r4_tests()
	_r5_tests()
	await _live_pic()
	await _codex_names()
	print("STAGE6 PET ABILITY TESTS DONE, failures: ", fails)
	quit()
