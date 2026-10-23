extends SceneTree
## v0.10: the HD art, the battle screen and the class family trees.
## Run: xvfb-run -a godot --path . --script res://tests/screenshot_v10.gd

var main
var only := ""

func shot(n: String, wait := 0.6) -> void:
	await create_timer(wait).timeout
	root.get_texture().get_image().save_png("/root/shots/%s.png" % n)

func close_overlays() -> void:
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	await process_frame

func make_hero(cls: String, app: Dictionary, lvl: int, fl: int, slot := 1) -> GameState:
	var g := GameState.new()
	g.slot = slot
	g.codex.path = ""
	g.appearance = app
	g.hero_name = "Thorin"
	g.new_game()
	g.choose_class(cls)
	var looks: Dictionary = g.class_info()["look"]
	for s in looks:
		var it := GameData.make_item(s, 3, fl, g._new_id())
		it["type"] = looks[s]
		g.equipped[s] = it
	g.level = lvl
	g.stat_points = 0
	g.stats = {"STR": 120, "VIT": 90, "AGI": 30, "INT": 10}
	g.hero_hp = g.get_max_hp()
	g.best_floor = fl
	g.floor_num = fl
	return g

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		only = a
	DirAccess.make_dir_recursive_absolute("/root/shots")
	seed(11)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	var prof := Profile.new()
	prof.max_floor = 300
	prof.save()
	var g := make_hero("Warrior", {"body": "masc", "skin": 2, "hair": "Spiky", "hair_color": 6, "eyes": 0, "race": "Human"}, 72, 40)
	g.class_path.assign(["champion", "weaponmaster", "colossus"])
	g.unique["Might"] = 40.0
	g.save_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
	main.play_slot(1)
	await process_frame
	await close_overlays()
	main.timer.stop()
	var s: GameState = main.state
	s.codex.stats["guide_skip"] = 1
	s.spawn_enemy()
	for i in 7:
		s.take_turn()
		main.refresh()
		await create_timer(0.12).timeout
	await close_overlays()
	await shot("v1_battle_titan", 0.25)
	main.show_tab(0, 1)
	main.refresh()
	await shot("v2_class_titan", 0.4)
	# A Knight choosing at level 35, with branch-offs on the way
	var k0 := make_hero("Knight", {"body": "fem", "skin": 1, "hair": "Long", "hair_color": 3, "eyes": 2, "race": "Elf"}, 36, 80, 2)
	k0.class_path.assign(["guardian"])
	k0.faith = 40
	k0.ctrack["blocks"] = 1450.0
	k0.ctrack["kills"] = 900.0
	k0.ctrack["first_hit_kill"] = 20.0
	k0.save_game()
	main.play_slot(2)
	await process_frame
	await close_overlays()
	main.timer.stop()
	var k: GameState = main.state
	main.show_tab(0, 1)
	main.refresh()
	await shot("v3_class_pick", 0.4)
	main._show_tree_picker()
	await shot("v4_picker", 0.4)
	await close_overlays()
	ClassTree.pick(k, "paladin")
	k.level = 60
	k.ctrack["trial_holy_bulwark"] = 1
	k.events.clear()
	ClassTree.pick(k, "holy_bulwark")
	main.refresh()
	await shot("v5_unique_moment", 3.2)
	await close_overlays()
	k.floor_num = 30
	k.spawn_enemy()
	for i in 6:
		k.take_turn()
		main.refresh()
		await create_timer(0.12).timeout
	await close_overlays()
	await shot("v6_battle_knight", 0.2)
	main.show_tab(0, 1)
	main.refresh()
	await shot("v6b_class_knight", 0.3)
	# A calm fight at normal speed, nothing on top
	k.path_offer = []
	k.floor_num = 12
	k.spawn_enemy()
	main.battle.toasts.clear()
	main.battle.toast_life = 0.0
	main.battle.banner_alpha = 0.0
	for i in 2:
		k.take_turn()
		main.refresh()
		await create_timer(0.9).timeout
	main.battle.toast_life = 0.0
	await shot("v0_battle_clean", 0.35)
	# A Wanderer meeting the Old Swordmaster
	var w0 := make_hero("Wanderer", {"body": "masc", "skin": 3, "hair": "Bun", "hair_color": 0, "eyes": 3, "race": "Human"}, 40, 60, 3)
	w0.class_path.assign(["swordsman"])
	w0.ctrack["first_hit_kill"] = 640.0
	w0.ctrack["realm_nocamp_streak"] = 3.0
	w0.save_game()
	main.play_slot(3)
	await process_frame
	await close_overlays()
	main.timer.stop()
	var w: GameState = main.state
	w.spawn_enemy()
	w.ctrack["item_wait"] = 100
	ClassTree.on_floor(w)
	main.refresh()
	await close_overlays()
	await shot("v7_wanderer_encounter", 0.4)
	main.show_tab(0, 1)
	main.refresh()
	await shot("v8_class_wanderer", 0.4)
	# The creator
	var cc := CharacterCreator.new()
	cc.show_for(main, {"body": "fem", "skin": 6, "hair": "Ponytail", "hair_color": 2, "eyes": 1, "race": "Goblin"}, func(_a): pass, "Create your hero", false, {}, true)
	await shot("v9_creator", 0.5)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	quit()
