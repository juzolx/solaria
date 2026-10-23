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

func _initialize() -> void:
	# The table is complete: every family has a passive with 6 ranks and a trick; every region a signature
	for f in PetAbilities.FAMILIES:
		var d: Dictionary = PetAbilities.FAMILIES[f]
		check((d["passive"]["values"] as Array).size() == 6, "%s passive has a value per rank" % f)
		check((d["trick"]["chance"] as Array).size() == 2 and (d["trick"]["value"] as Array).size() == 2, "%s trick has Epic and Legendary values" % f)
		var vals: Array = d["passive"]["values"]
		for i in 5:
			check(float(vals[i + 1]) >= float(vals[i]), "%s passive never gets weaker with rank" % f)
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
	check(is_equal_approx(g.effect_value("crit"), crit0), "a hurt pet's passive is off")
	(a[1] as Dictionary)["hurt"] = 0
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
	var gold := gg.gold
	PetAbilities.apply(gg, gs[1], "gold", 3, 0, "Pickpocket")
	check(gg.gold > gold, "Pickpocket steals gold")
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
		Menagerie.make_pet(tm, spirit, "", 5, "egg")
	check(Menagerie.out(tm).size() == 3, "a tamer brings three pets")
	check(tm.effect_value("regen") - regen0 <= PetAbilities.REGEN_CAP + 0.001, "three Mythic spirits heal at most %.1f%% a turn (%.2f)" % [PetAbilities.REGEN_CAP, tm.effect_value("regen") - regen0])
	check(str(PetAbilities.bonus_sources(tm)) == str(PetAbilities.bonus_sources(tm)), "cached passives stay the same")
	(Menagerie.out(tm)[0] as Dictionary)["hurt"] = 2
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
	print("STAGE6 PET ABILITY TESTS DONE, failures: ", fails)
	quit()
