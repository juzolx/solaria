extends SceneTree
## Fight layout at phone size (fable monsters r3, item 11): the real BattleView in the real main
## scene at 430x932 and 375x667 (iPhone SE), with the monsters that broke before: commons, a pack,
## two wide bosses and the tallest Calamities. Checks the one pixel scale, plates under the feet,
## the boss stage room, plates that stay put while the hero lunges, the boss chip column and the
## menagerie pet beside the hero plate.
const TestHero := preload("res://tests/test_hero.gd")
const KEYS := ["kobold", "umibozu", "barghest+pack", "boss_grendel", "boss_charybdis", "calamity_2", "calamity_5"]
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
		BattleView.test_scale = minf(wsz.x / 504.0, wsz.y / 896.0)
		for i in 6:  # the stretch and main's fit settle over a few frames
			await process_frame
		for arg in KEYS:
			_fight(main, st, arg)
			await process_frame
			await process_frame
			_check_fight(bv, st, arg, wsz)
	print("stage6 monster layout: %d fails" % fails)
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
	check(unit == (3 if wsz.y > 800 else 2), "%s: pixel unit %d" % [tag, unit])
	var er: Rect2 = bv._enemy_rect(st.enemy_is_boss)
	var ui := er.size.x / (art["size"] as Vector2).x * sc
	check(absf(ui - roundf(ui)) < 0.01, "%s: monster pixel %.2f screen px, not whole" % [tag, ui])
	if big:
		# boss stage: the hero's scale or less, feet on the team line, below the boss bar and name
		check(roundf(ui) <= bv._hero_unit(), "%s: boss pixel %d over the hero's %d" % [tag, roundf(ui), bv._hero_unit()])
		if not st.enemy_is_boss and st.enemy_calamity == 0:
			check(roundf(ui) == unit, "%s: tall common pixel %d, not the unit %d" % [tag, roundf(ui), unit])
		check(er.end.y <= bv._team_ground() + 0.5, "%s: feet %.0f under the team line %.0f" % [tag, er.end.y, bv._team_ground()])
		check(er.position.y >= bv._boss_bar().end.y + bv.BOSS_NAME - 0.5, "%s: top %.0f over the boss bar and name" % [tag, er.position.y])
		check(bv._boss_chip_y(0) >= bv._boss_bar().end.y + bv.BOSS_NAME, "%s: status chips over the boss name" % tag)
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
	# no menagerie pet on the hero's plate (its drawn body: about 0.6 of the 32 px frame)
	var hc: Rect2 = bv._hero_canvas()
	var w: float = 32.0 * bv._u()
	var hp: Rect2 = bv._bar_rect(bv._hero_rect())
	for i in 3:
		var x: float = bv._pet_x(i, hc, w)
		var body := Rect2(x - w * 0.3, bv._team_ground() - w, w * 0.6, w)
		check(not body.intersects(hp) and body.position.x >= 0.0, "%s: menagerie pet %d at %s, hero plate %s" % [tag, i, body, hp])
