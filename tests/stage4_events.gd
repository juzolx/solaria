extends SceneTree
## People events in the dungeon: each choice does what it says.
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
	g.level = 30
	g.floor_num = 30
	g.best_floor = 30
	g.in_town = false
	g.spawn_enemy()
	g.gold = 100000
	return g

func _initialize() -> void:
	var seen := {}
	for i in 300:
		var g := hero()
		World.start_event(g)
		for k in g.path_offer:
			seen[k] = true
	for k in ["give_potion", "free_prisoner", "buy_bundle", "hear_song", "follow_scout"]:
		check(seen.has(k), "the %s choice turns up" % k)
		check(World.EVENT_PATHS.has(k), "%s has a name and text" % k)
	var a := hero()
	a.potions = 2
	World.choose(a, "give_potion")
	check(a.potions == 1 and a.luck_turns >= 40, "the pilgrim takes a potion and blesses you")
	var b := hero()
	World.choose(b, "free_prisoner")
	check(b.enemy_name.begins_with("Jailer") and b.enemy_tier >= Monsters.EPIC and b.cfight.get("prisoner", false), "the jailer comes")
	var g0 := b.gold
	b.enemy_hp = 0
	b._enemy_defeated()
	check(b.gold > g0 and b.codex.stat("prisoners_freed") == 1, "beat the jailer: the prisoner pays")
	var c := hero()
	var n := c.bag.size()
	World.choose(c, "buy_bundle")
	check(c.bag.size() == n + 1 and c.gold < 100000, "the bundle costs gold and gives an item")
	var d := hero()
	World.choose(d, "hear_song")
	check(d.song_xp_turns == 40, "a song: more XP for a while")
	var e := hero()
	World.choose(e, "follow_scout")
	check(e.floor_num == 31, "the scout's shortcut: one floor down")
	print("STAGE4 EVENT TESTS DONE, failures: ", fails)
	quit()
