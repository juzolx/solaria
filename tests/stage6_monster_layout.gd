extends SceneTree
## Fight layout at phone size (fable monsters r3, item 11): the real BattleView in the real main
## scene at 430x932 and 375x667 (iPhone SE), with the monsters that broke before: commons, a pack,
## two wide bosses and the tallest Calamities. Checks the one pixel scale, plates under the feet,
## the boss stage room, plates that stay put while the hero lunges, the boss chip column and the
## menagerie pet beside the hero plate.
const TestHero := preload("res://tests/test_hero.gd")
const KEYS := ["kobold", "umibozu", "chimera", "barghest+pack", "garmr+pack", "boss_grendel", "boss_charybdis",
	"calamity_0", "calamity_1", "calamity_2", "calamity_3", "calamity_4", "calamity_5", "calamity_6", "calamity_7", "calamity_8", "calamity_9"]
const SIZES := [Vector2i(430, 932), Vector2i(375, 667)]
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		if fails <= 40:
			print("FAIL: ", m)

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
			main.play_slot(1)
			await process_frame
	main.timer.stop()
	main.codex.stats["guide_skip"] = 1
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	var st: GameState = main.state
	st.in_town = false
	main.nav_page = 0
	main._apply_nav()
	var bv = main.battle
	for wsz in SIZES:
		root.size = wsz
		# headless never applies the stretch: give the fight the phone's (504 design px wide)
		if DisplayServer.get_name() == "headless":
			BattleView.test_scale = minf(wsz.x / 504.0, wsz.y / 896.0)
		for i in 6:  # the stretch and main's fit settle over a few frames
			await process_frame
		for arg in KEYS:
			_fight(main, st, arg)
			await process_frame
			await process_frame
			_check_fight(bv, st, arg, wsz)
			if arg in ["boss_charybdis", "calamity_2"]:
				await _check_chips(bv, st, arg, wsz)
			if arg == "calamity_2":
				await _check_death(main, bv, st, arg, wsz)
		await _check_bestiary(main, wsz)
	# (f) Epic, Legendary and Mythic are told apart by their pips too
	check(BattleView.tier_pips(3) != BattleView.tier_pips(4) and BattleView.tier_pips(4) != BattleView.tier_pips(5), "tiers 3-5 wear the same pips")
	print("STAGE6 MONSTER LAYOUT TESTS DONE, failures: %d" % fails)
	quit(1 if fails > 0 else 0)

func _fight(main, st: GameState, arg: String) -> void:
	var pack := arg.ends_with("+pack")
	var key := arg.trim_suffix("+pack")
	st.spawn_enemy()
	st.enemy_variant = ""
	st.enemy_tier = 0
	st.enemy_mods.clear()
	st.enemy_elite = false
	st.enemy_calamity = 0
	st.horde_left = 3 if pack else 0
	st.horde_total = 3 if pack else 0
	st.horde_pack = pack
	st.enemy_species = key.trim_prefix("boss_")
	st.enemy_name = Monsters.name_of(st.enemy_species)
	st.enemy_art = key
	st.enemy_is_boss = key.begins_with("boss_")
	if key.begins_with("calamity_"):
		st.enemy_calamity = int(key.trim_prefix("calamity_")) + 1
	main.refresh()

func _check_fight(bv, st: GameState, arg: String, wsz: Vector2i) -> void:
	var tag := "%s at %dx%d" % [arg, wsz.x, wsz.y]
	var big: bool = bv._boss_stage()   # bosses, Calamities and, on a short screen, tall commons
	var art: Dictionary = bv._enemy_art(st.enemy_is_boss)
	check(not art.is_empty(), tag + ": no art")
	if art.is_empty():
		return
	var sc: float = bv._scr()
	var unit: int = bv._unit()
	check(unit == ArtStyle.unit(sc), "%s: pixel unit %d, the phone's is %d" % [tag, unit, ArtStyle.unit(sc)])
	if arg == "kobold":
		print("%s: stretch %.3f, stage %s" % [tag, sc, bv.size])
	var er: Rect2 = bv._enemy_rect(st.enemy_is_boss)
	var ui := er.size.x / (art["size"] as Vector2).x * sc
	check(absf(ui - roundf(ui)) < 0.01, "%s: monster pixel %.2f screen px, not whole" % [tag, ui])
	if big:
		# boss stage: the hero's scale or less, feet on the team line, below the boss bar and name
		check(roundf(ui) <= bv._hero_unit(), "%s: boss pixel %d over the hero's %d" % [tag, roundf(ui), bv._hero_unit()])
		if not st.enemy_is_boss and st.enemy_calamity == 0:
			check(roundf(ui) == unit, "%s: tall common pixel %d, not the unit %d" % [tag, roundf(ui), unit])
		if st.enemy_calamity > 0 and wsz.y < 800:
			# fable r3 item 2: all ten Calamities keep the hero's 2x on an SE (a taller one fails here)
			check(roundf(ui) == unit, "%s: Calamity pixel %d on the SE, not %d" % [tag, roundf(ui), unit])
		if st.horde_pack:
			# a tall pack on the boss stage: the mates stay under the top bar and its name, on screen
			for side in [-1.0, 1.0]:
				var pr: Rect2 = bv._pack_rect(er, art, side)
				check(pr.position.y >= bv._boss_bar().end.y + bv.BOSS_NAME - 0.5, "%s: pack-mate top %.0f under the boss bar" % [tag, pr.position.y])
				check(pr.end.y <= bv._team_ground() + 0.5, "%s: pack-mate feet %.0f under the team line" % [tag, pr.end.y])
		var feet_y := er.position.y + (float(art["foot"]) + 1.0) * er.size.y / (art["size"] as Vector2).y   # the lowest solid row
		# feet on or above the team line; only a Calamity too tall for that may go lower, behind the hero
		var floor_y: float = bv.size.y if st.enemy_calamity > 0 else bv._team_ground()
		check(feet_y <= floor_y + 0.5, "%s: feet %.0f under %.0f" % [tag, feet_y, floor_y])
		if feet_y > bv._team_ground() + 0.5:
			check(er.position.y <= bv._boss_bar().end.y + bv.BOSS_NAME + 0.5, "%s: below the team line with room left above" % tag)
		var top_min: float = bv._boss_bar().end.y + (bv.CALAMITY_TUCK if st.enemy_calamity > 0 else bv.BOSS_NAME)
		check(er.position.y >= top_min - 0.5, "%s: top %.0f over the boss bar and name" % [tag, er.position.y])
		if er.position.y < bv._boss_bar().end.y + bv.BOSS_NAME - 0.5:
			check(feet_y >= bv.size.y - 3.0, "%s: crown under the name with room left below" % tag)
		# (b) a banner sits clear of the boss bar and its name
		var bl: Rect2 = bv._banner_line()
		var band := Rect2(bl.position.x, bl.position.y - 26.0, bl.size.x, 26.0 + bl.size.y + 4.0)
		check(not band.intersects(Rect2(bv._boss_bar().position.x, 14.0, bv._boss_bar().size.x, bv.BOSS_NAME + 20.0)), "%s: banner %s on the boss name" % [tag, band])
		if not st.enemy_is_boss and st.enemy_calamity == 0:
			# (e) a tall common stands right of the hero: the hero covers its flank, not its face
			var hf: Rect2 = bv._hero_rect()   # the 64 px frame; the drawn back is its middle half
			var hr := hf.grow_individual(-hf.size.x * 0.25, 0.0, -hf.size.x * 0.25, 0.0)
			var cut := er.intersection(hr)
			check(cut.get_area() < 0.2 * er.get_area(), "%s: the hero covers %d%% of the tall common" % [tag, roundi(100.0 * cut.get_area() / er.get_area())])
			check(not (er.get_center().x > hr.position.x and er.get_center().x < hr.end.x), "%s: the tall common's centre is behind the hero" % tag)
	else:
		check(roundf(ui) == unit, "%s: common pixel %d, not the unit %d" % [tag, roundf(ui), unit])
		var plate: Rect2 = bv._bar_rect(er)
		check(er.end.y <= plate.position.y - 4.0, "%s: feet %.0f on the plate at %.0f" % [tag, er.end.y, plate.position.y])
		# the plate and feet stay put while the hero lunges or recoils (fable r3 item 1)
		var keep := [bv.hero_lunge, bv.recoil]
		for lr in [[1.4, 0.0], [0.0, 1.0], [1.4, 1.0]]:
			bv.hero_lunge = lr[0]
			bv.recoil = lr[1]
			check(bv._enemy_rect(false) == er and bv._bar_rect(er) == plate, "%s: monster or plate moves with lunge %s recoil %s" % [tag, lr[0], lr[1]])
		bv.hero_lunge = keep[0]
		bv.recoil = keep[1]
		if st.horde_pack:
			var pr: Rect2 = bv._pack_rect(er, art, -1.0)
			var pu := pr.size.x / (art["size"] as Vector2).x * sc
			check(absf(pu - (unit - 1)) < 0.01, "%s: pack-mate pixel %.2f, not %d" % [tag, pu, unit - 1])
	# no pet (companion or menagerie, placed by team_layout) under the hero's plate
	var w: float = 32.0 * bv._u()
	var hp: Rect2 = bv._bar_rect(bv._hero_rect())
	var lay: Dictionary = bv.team_layout()
	for k in lay:
		var body := Rect2(float(lay[k]) + w * 0.2, bv._team_ground() - w, w * 0.6, w)
		check(not body.intersects(hp), "%s: pet %s at %s under the hero plate %s" % [tag, k, body, hp])

## (c) statuses and mods on the boss stage stay off the boss (rows under its plate).
func _check_chips(bv, st: GameState, arg: String, wsz: Vector2i) -> void:
	var tag := "%s at %dx%d with chips" % [arg, wsz.x, wsz.y]
	st.burn_turns = 3
	st.enemy_poison_turns = 2
	st.cfight["windup"] = 1
	st.enemy_mods = ["Swift", "Armored", "Giant"]
	await process_frame
	await process_frame
	var er: Rect2 = bv._enemy_rect(st.enemy_is_boss)
	var lay: Array = bv._boss_chip_layout()
	check(lay.size() >= 6, "%s: %d chips laid out, not 6+" % [tag, lay.size()])
	var squeezed: bool = er.position.y < bv._boss_bar().end.y + bv.BOSS_NAME + bv._boss_chip_room()
	for it in lay:
		var box: Rect2 = it[1]
		check(box.position.y >= bv._boss_bar().end.y + bv.BOSS_NAME, "%s: chip %s on the boss name" % [tag, it[0][0]])
		check(box.position.x >= 0.0 and box.end.x <= bv.size.x, "%s: chip %s off screen" % [tag, it[0][0]])
		if not squeezed:   # only the tallest Calamity on a short screen can't leave room
			check(not box.intersects(er), "%s: chip %s on the boss" % [tag, it[0][0]])
	var bl: Rect2 = bv._banner_line()
	check(bl.position.y - 26.0 >= (lay[-1][1] as Rect2).end.y, "%s: banner over the chips" % tag)
	st.burn_turns = 0
	st.enemy_poison_turns = 0
	st.cfight.erase("windup")
	st.enemy_mods.clear()
	await process_frame

## (a) a Calamity's death keeps its size, place and crimson edge (its state flag is cleared
## before the view gets the event: Calamity.on_slain).
func _check_death(main, bv, st: GameState, arg: String, wsz: Vector2i) -> void:
	var tag := "%s at %dx%d dying" % [arg, wsz.x, wsz.y]
	var er: Rect2 = bv._enemy_rect(false)
	st.enemy_calamity = 0   # what Calamity.on_slain does first
	var ev: Array[Dictionary] = [{"type": "enemy_dead", "shape": st.enemy_shape, "color": st.enemy_color, "boss": false,
		"name": st.enemy_name, "art": st.enemy_art, "tier": 0, "calamity": true}]
	bv.play(ev)
	check(not bv.dying.is_empty(), tag + ": no dying monster")
	if not bv.dying.is_empty():
		check(bv._dying_rect() == er, "%s: corpse %s, it stood at %s" % [tag, bv._dying_rect(), er])
		check(String(bv.dying["edge"]) == "e43b44", "%s: burn edge %s, not crimson" % [tag, bv.dying["edge"]])
	bv.dying = {}
	bv.enemy_alpha = 1.0
	await process_frame

## (d) the Bestiary shows commons and bosses at one scale: 2 screen px per art px on a phone,
## Charybdis (126 px, the widest boss) included, on the SE too.
func _check_bestiary(main, wsz: Vector2i) -> void:
	var cx: Codex = main.codex
	for id in ["kobold", "grendel", "charybdis"]:
		cx.entry(id)["kills"] = maxi(1, int(cx.entry(id)["kills"]))
	main.state._check_codex()
	main.show_tab(3, 0)
	var bt = main.bestiary_tab
	for id in ["kobold", "grendel", "charybdis"]:
		bt.selected = id
		bt.shown = ""
		main.refresh()
		for i in 3:
			await process_frame
		var sc: float = bt._screen_scale()
		var k: float = bt.pic.size.x * sc / maxf(1.0, bt.pic_size.x)
		check(absf(k - 2.0) < 0.05, "Bestiary %s at %dx%d: %.2f screen px per art px, not 2" % [id, wsz.x, wsz.y, k])
	main.nav_page = 0
	main._apply_nav()
	for i in 3:
		await process_frame

