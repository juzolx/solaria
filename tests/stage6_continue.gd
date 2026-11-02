extends SceneTree
const TestHero := preload("res://tests/test_hero.gd")
## 2.1 crash (Juzo, Nov 1): with a hero already saved, tapping Continue on the title killed
## the game. The title is queued for deletion but still draws that frame; it and the fight
## both asked for the one shared 3D room (HallsScene.shared), and each move redrew the other,
## so the room was handed back and forth inside one frame until Godot crashed in reparent().
## Fresh-save tests never saw it: no hero means no Continue (and headless runs skip the 3D room).
##
## A synthetic save shaped like Juzo's (three towns of one hero each: a 2.1 hero, an older one
## from before 2.1 and a retired Golem) starts the game the way a player does: the loading
## screen, the title, a tap on Continue, then frames until the hero is in town.
## godot --headless --path . -s tests/stage6_continue.gd
## With a window (the real 3D room, where it crashed):
## godot --path . --audio-driver Dummy --resolution 430x932 -s tests/stage6_continue.gd
var fails := 0

func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text == text:
		return n
	for c in n.get_children():
		var b := _find_button(c, text)
		if b:
			return b
	return null

func _hero(slot: int, cls: String, look: Dictionary, lvl: int, fl: int, in_town: bool, hname: String) -> void:
	var g := GameState.new()
	g.codex.path = ""
	g.slot = slot
	g.new_game()
	g.choose_class(cls)
	g.hero_name = hname
	g.appearance.merge(look, true)
	g.level = lvl
	g.floor_num = fl
	g.best_floor = maxi(fl, 40)
	g.in_town = in_town
	g.save_game(true)

## Profile with towns 1..3, one hero in each (the shape of Juzo's save).
func _make_save(town1_in_town: bool) -> void:
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	var p := Profile.new()
	p.save_epoch = Profile.SAVE_EPOCH
	p.towns_v1 = true
	p.save()
	var looks := [{"body": "masc", "race": "Elf", "hair": "Very Long", "hair_color": 16, "skin": 2, "eyes": 4},
		{"body": "fem", "race": "Human", "hair": "Short", "hair_color": 3, "skin": 1, "eyes": 1},
		{"body": "masc", "race": "Golem", "skin": 10}]   # Golem: retired in 2.1, loads as a Dwarf
	for t in [3, 2, 1]:
		p.switch_town(t)
		_hero(1, ["Warrior", "Mage", "Warrior"][t - 1], looks[t - 1], [39, 25, 40][t - 1], [6, 3, 12][t - 1],
			town1_in_town if t == 1 else true, ["Aldric", "Brin", "Corr"][t - 1])
		p.active_slot = 1
		p.save()
	check(p.town == 1 and GameState.has_slot(1), "setup: town 1 has its hero")

## Starts the game like a player and taps Continue; returns main once the hero is playing.
func _launch_and_continue() -> Node:
	TitleScreen.pending = {}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for i in 10:
		await process_frame
	check(not main.started, "the title shows first")
	var cont := _find_button(main, "Continue")
	check(cont != null, "the title offers Continue for the saved hero")
	if cont == null:
		return main
	cont.pressed.emit()   # a tap
	for i in 90:
		await process_frame   # (the crash was here: the very next frame)
	return main

## The shared room never moves into a view on its way out, and moves at most once a frame.
func _hand_off() -> void:
	var a := Control.new()
	var b := Control.new()
	var c := Control.new()
	for v in [a, b, c]:
		root.add_child(v)
	var hs := HallsScene.new()
	HallsScene.shared = Room3D.new()
	a.add_child(HallsScene.shared)
	await process_frame
	a.queue_free()   # the title after Continue
	hs._move_room(b)   # the fight takes it
	check(HallsScene.shared.get_parent() == b, "the fight view gets the room")
	hs._move_room(a)   # the dying title asks for it back in the same frame
	check(HallsScene.shared.get_parent() == b, "a view queued for deletion never takes the room back")
	hs._move_room(c)
	check(HallsScene.shared.get_parent() == b, "at most one move a frame (no ping-pong inside a frame)")
	await process_frame
	check(is_instance_valid(HallsScene.shared), "the room outlives the freed title")
	hs._move_room(c)
	check(HallsScene.shared.get_parent() == c, "next frame it can move again")
	HallsScene.shared.queue_free()
	HallsScene.shared = null
	b.queue_free()
	c.queue_free()
	await process_frame

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	await _hand_off()

	# --- A hero standing in town: Continue lands in the town ---
	_make_save(true)
	var main = await _launch_and_continue()
	check(main.started, "Continue starts the game")
	check(main.state.hero_name == "Aldric" and main.state.level == 39, "the saved hero is the one playing")
	check(main.state.in_town, "the hero is in the town")
	check(not main.get_children().any(func(n): return n is TitleScreen and not n.is_queued_for_deletion()), "the title is gone")
	main.queue_free()
	await process_frame
	await process_frame

	# --- A hero mid-dive (Juzo's case: floor 6), with the loading screen's room up too ---
	_make_save(false)
	main = await _launch_and_continue()
	check(main.started and main.state.hero_name == "Aldric", "a hero mid-dive continues")
	check(not main.state.in_town and main.state.floor_num >= 6, "back on their floor")
	# the other towns' older heroes load too (the retired Golem as a Dwarf)
	for t in [2, 3]:
		main.profile.switch_town(t)
		var g := GameState.new()
		g.codex.path = ""
		g.autosave = false
		g.slot = 1
		check(g.load_game(), "town %d's hero loads" % t)
		if t == 3:
			check(g.race() == "Dwarf", "the old Golem hero comes back as a Dwarf")
	main.profile.switch_town(1)
	main.queue_free()
	await process_frame
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	print("STAGE6 CONTINUE DONE, failures: ", fails)
	quit()
