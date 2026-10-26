extends SceneTree
## Redrawn monsters in the real fight at phone size, for Juzo: one picture per art key.
##   godot --path . --resolution 430x932 -s tests/_monster_shot.gd -- <tag> <key>[@floor][#tier][+pack][+mods][+status][+pet][+dead] ...
## -> shots/monsters/<tag>/<key>.png (floor picks the zone's hall behind it, tier 0-5 its rank,
## +pack two pack-mates waiting behind it; +mods two mods; +status burning, poisoned and winding
## up; +pet a menagerie pet out; +dead a frame of its burn (alpha under 0.6); calamity_N keys appear as
## that Calamity; +banner a rank banner over it)
const TestHero := preload("res://tests/test_hero.gd")
func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	# The title screen comes up when slot 1 doesn't load in time: play the test hero instead
	# (fable r2: 7 of 23 round-1 "fight shots" were the title screen)
	if _title(main) != null:
		_title(main).queue_free()
		main.play_slot(1)
		await process_frame
	main.timer.stop()
	main.codex.stats["guide_skip"] = 1
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	var st: GameState = main.state
	st.in_town = false  # the fight, never the town (a reused test save may be in town)
	main.nav_page = 0
	main._apply_nav()
	var dir := TestHero.shots_dir("monsters/" + args[0])
	for arg in args.slice(1):
		var flags: Array = []
		for f in ["+dead", "+pet", "+status", "+mods", "+pack", "+banner"]:
			if arg.contains(f):
				flags.append(f)
				arg = arg.replace(f, "")
		var pack := "+pack" in flags
		var tier := int(arg.get_slice("#", 1)) if arg.contains("#") else 0
		arg = arg.get_slice("#", 0)
		var key: String = arg.get_slice("@", 0)
		if arg.contains("@"):
			st.floor_num = int(arg.get_slice("@", 1))
			main.battle.last_floor = st.floor_num
		st.spawn_enemy()
		# the plain monster: no variant recolour, rarity aura or mods
		st.enemy_variant = ""
		st.enemy_tier = tier
		st.enemy_mods.clear()
		st.enemy_elite = false
		st.enemy_calamity = 0
		# one monster, labelled with its own name (not a pack of whatever spawned)
		st.horde_left = 0
		st.horde_pack = false
		st.horde_total = 0
		st.enemy_species = key.trim_prefix("boss_")
		st.enemy_name = Monsters.name_of(st.enemy_species)
		st.enemy_art = key
		st.enemy_is_boss = key.begins_with("boss_")
		if key.begins_with("calamity_"):
			st.enemy_calamity = int(key.trim_prefix("calamity_")) + 1
			st.enemy_name = String(Calamity.info(st.enemy_calamity - 1)[0])
		if pack:
			st.horde_left = 3
			st.horde_total = 3
			st.horde_pack = true
		if "+mods" in flags:
			st.enemy_mods = ["Swift", "Armored"]
		st.burn_turns = 3 if "+status" in flags else 0
		st.enemy_poison_turns = 2 if "+status" in flags else 0
		if "+status" in flags:
			st.cfight["windup"] = 1
		else:
			st.cfight.erase("windup")
		if "+pet" in flags and Menagerie.out(st).is_empty():
			Menagerie.make_pet(st, "afanc", "afanc", 0, "shot")
			st.events = st.events.filter(func(e): return e.get("type", "") != "first_find")   # no popup over the fight
		elif not "+pet" in flags:
			st.pets_out.clear()
		var shot := key + ("_t%d" % tier if tier > 0 else "")
		for f in flags:
			shot += "_" + String(f).trim_prefix("+")
		Sprites.clear_monster_cache()
		main.refresh()
		await create_timer(3.0 if st.enemy_is_boss or st.enemy_calamity > 0 else 1.5).timeout
		var why := _not_a_fight(main, key)
		if why != "":
			push_error("%s: not a fight on screen (%s), no picture saved" % [shot, why])
			quit(1)
			return
		if "+banner" in flags:
			main.battle.banner_text = "RARE MONSTER!"
			main.battle.banner_sub = "%s  -  Swift, Armored" % st.enemy_name
			main.battle.banner_color = Color("#60a5fa")
			main.battle.banner_alpha = 1.5
			await create_timer(0.1).timeout
		if "+dead" in flags:
			# the kill as the game sends it (a Calamity's flag is cleared first: Calamity.on_slain)
			var cal := st.enemy_calamity > 0
			st.enemy_calamity = 0
			var ev: Array[Dictionary] = [{"type": "enemy_dead", "shape": st.enemy_shape, "color": st.enemy_color, "boss": st.enemy_is_boss,
				"name": st.enemy_name, "art": st.enemy_art, "tier": tier, "calamity": cal}]
			main.battle.play(ev)
			# into the burn itself (fable r5: 0.3 s was still the kill burst at full alpha)
			var waited := 0.0
			while waited < 2.0 and float(main.battle.dying.get("alpha", 1.0)) > 0.6:
				await process_frame
				waited += 1.0 / 60.0
		root.get_texture().get_image().save_png(dir.path_join(shot + ".png"))
	quit()

static func _title(main: Node) -> Node:
	for c in main.get_children():
		if c is TitleScreen:
			return c
	return null

## "" when the fight with `key` is what the screen shows, else what is wrong.
static func _not_a_fight(main: Node, key: String) -> String:
	if _title(main) != null:
		return "title screen"
	var st: GameState = main.state
	if st == null:
		return "no hero"
	if st.in_town:
		return "in town"
	if main.nav_page != 0:
		return "page %d" % main.nav_page
	if st.enemy_art != key or st.enemy_hp <= 0:
		return "monster is %s" % st.enemy_art
	return ""
