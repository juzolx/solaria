extends SceneTree
## Deeper statuses: stacking poison and bleeding, weakness, shape statuses, potion cleanse.
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
	g.in_town = false
	g.spawn_enemy()
	return g

func stick(g: GameState, kind: String, turns: int) -> void:
	for i in 50:  # Wisdom can shrug a status off: try until it sticks
		var before := int(g.hero_stacks.get(kind, 0))
		Combat.afflict(g, kind, turns)
		if g.hero_status.has(kind) and int(g.hero_stacks.get(kind, 1)) > before:
			return
		if g.hero_status.has(kind) and not kind in Combat.STACKING:
			return

func _initialize() -> void:
	var g := hero()
	stick(g, "bleed", 3)
	check(g.hero_status.has("bleed") and int(g.hero_stacks.get("bleed", 0)) == 1, "bleeding, one stack")
	stick(g, "bleed", 3)
	stick(g, "bleed", 3)
	stick(g, "bleed", 3)
	check(int(g.hero_stacks.get("bleed", 0)) == Combat.MAX_STACKS, "stacks cap at 3 (%d)" % int(g.hero_stacks.get("bleed", 0)))
	g.hero_hp = g.get_max_hp()
	var d3 := Combat.tick_hero(g)
	var one := hero()
	stick(one, "bleed", 3)
	one.hero_hp = one.get_max_hp()
	var d1 := Combat.tick_hero(one)
	check(d3 >= d1 * 2, "three stacks bleed much more than one (%d vs %d)" % [d3, d1])
	var w := hero()
	var atk := w.get_attack()
	stick(w, "weak", 2)
	check(w.get_attack() < atk, "weakened: less Attack")
	# a potion washes it all off
	w.potions = 1
	stick(w, "poison", 3)
	w.hero_hp = 1
	w.use_potion()
	check(not w.hero_status.has("weak") and not w.hero_status.has("poison") and w.hero_stacks.is_empty(), "a potion cleanses")
	# beasts make you bleed
	var b := hero()
	b.enemy_shape = "beast"
	b.enemy_is_boss = false
	var bled := 0
	for i in 400:
		b.hero_status.clear()
		b.hero_stacks.clear()
		Combat.on_enemy_hit(b, 10)
		if b.hero_status.has("bleed"):
			bled += 1
	check(bled > 400 * 0.08 and bled < 400 * 0.3, "beasts sometimes draw blood (%d of 400)" % bled)
	var e := hero()
	e.floor_num = 3
	e.enemy_shape = "beast"
	e.enemy_is_boss = false
	for i in 200:
		Combat.on_enemy_hit(e, 10)
	check(not e.hero_status.has("bleed"), "not on the first floors")
	# brutes break your armor
	var s := hero()
	var d0 := s.get_defense()
	stick(s, "sunder", 3)
	check(s.hero_status.has("sunder") and s.get_defense() < d0, "armor broken: less Defense (%d vs %d)" % [s.get_defense(), d0])
	print("STAGE3 STATUS TESTS DONE, failures: ", fails)
	quit()
