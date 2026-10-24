extends SceneTree
## Headless balance simulator: several heroes play on Auto like a sensible player
## (dive, go home when the bag is full or potions/HP run low, buy potions, equip the
## best, upgrade, spend stats) and the numbers go into claude/balance-report.md.
##   godot --headless --path . -s tools/balance_sim.gd -- [heroes] [hours] [quick]
##   heroes  how many heroes (default 6, max 12)
##   hours   play time per hero at normal speed (default 24; quick: 3)
##   quick   3 heroes, 3 hours, about a minute
## One turn is one second at the default (1x) speed (main.gd TURN_SECONDS).
## Each hero also has a real-time budget so a full run stays under ~10 minutes; a hero that
## runs out of budget stops there and the report says how much play time it covered.
## BALANCE_BUDGET=<seconds> raises the real-time budget per hero (default 480; heroes run side by side, one process each).
## Runs against the test user folder only (override.cfg): never touches real saves.

const TURN_SECONDS := 1.0
const MILESTONES := [25, 50, 100, 250, 500, 750]
const SAMPLE_MIN := 10        # curve sample spacing, in play minutes
const POTION_TARGET := 8
const STALL_TURNS := 150
const LONG_FIGHT := 300       # turns without a kill before the hero tries to run
const SHOP_ROLLS := 8         # shop looks per town visit (the first is free)
const RESTOCK_SPARE := 20     # re-roll the shop only with this many restocks' worth of gold to spare
const REPORT_PATH := "res://claude/balance-report.md"
const QUICK_REPORT_PATH := "res://claude/balance-report-quick.md"

# base class, race. A spread of classes and races.
const HEROES := [
	["Warrior", "Human"], ["Mage", "Elf"], ["Ranger", "Dwarf"], ["Cleric", "Angel"],
	["Trickster", "Goblin"], ["Knight", "Orc"], ["Acolyte", "Demon"], ["Bard", "Fairy"],
	["Wanderer", "Beastkin"], ["Sentinel", "Golem"], ["Ironbark", "Undead"], ["Nightstalker", "Dragonkin"],
]

var budget_s := 480.0          # real seconds each hero may use (heroes run side by side)
var death_turns: Array = []   # when the current hero fell (for the retreat rule)
var retreat_to := 0

func _initialize() -> void:
	if not OS.get_user_data_dir().contains("test"):
		push_error("Refusing to run: user data is %s, not a test folder (override.cfg)." % OS.get_user_data_dir())
		quit(1)
		return
	var n := 6
	var hours := 24.0
	var quick := false
	var nums: Array = []
	var child := -1
	var args := OS.get_cmdline_user_args()
	for k in args.size():
		var a: String = args[k]
		# (a child gets "child <index> <hours>", so its numbers line up as n=index, hours)
		if a == "quick":
			quick = true
		elif a == "child":
			child = int(args[k + 1])
		elif a.is_valid_float():
			nums.append(float(a))
	if quick:
		n = 3
		hours = 3.0
		budget_s = 60.0
	if nums.size() > 0:
		n = clampi(int(nums[0]), 1, HEROES.size())
	if nums.size() > 1:
		hours = maxf(0.1, float(nums[1]))
	if OS.get_environment("BALANCE_BUDGET") != "":
		budget_s = float(OS.get_environment("BALANCE_BUDGET"))
	if child >= 0:
		# One hero in its own process; the result goes to a file for the parent
		seed(1000 + child)
		var r := _play(String(HEROES[child][0]), String(HEROES[child][1]), hours, budget_s)
		var rf := FileAccess.open("user://balance_sim_%d.txt" % child, FileAccess.WRITE)
		rf.store_string(var_to_str(r))
		rf.close()
		quit()
		return
	var started := Time.get_ticks_msec()
	for i in n:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://balance_sim_%d.txt" % i))
	# At most BALANCE_PARALLEL heroes (default 3) play at once, so the PC stays usable
	var parallel := 3
	if OS.get_environment("BALANCE_PARALLEL") != "":
		parallel = maxi(1, int(OS.get_environment("BALANCE_PARALLEL")))
	var pids: Array = []
	pids.resize(n)
	pids.fill(-1)
	var started_at: Array = []
	started_at.resize(n)
	started_at.fill(0.0)
	var results: Array = []
	var waited := 0.0
	var pending: Array = range(n)
	while not pending.is_empty():
		var running := 0
		for i in pending:
			if int(pids[i]) >= 0:
				running += 1
		for i in pending:
			if running >= parallel:
				break
			if int(pids[i]) < 0:
				var cargs: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", "tools/balance_sim.gd", "--", "child", str(i), str(hours), ("quick" if quick else "full")]
				pids[i] = OS.create_process(OS.get_executable_path(), cargs)
				started_at[i] = waited
				running += 1
		OS.delay_msec(1000)
		waited += 1.0
		for i in pending.duplicate():
			if int(pids[i]) < 0:
				continue
			if waited - float(started_at[i]) > budget_s + 120.0:
				push_error("Hero %d never reported back" % i)
				OS.kill(int(pids[i]))
				pending.erase(i)
				continue
			var path := "user://balance_sim_%d.txt" % i
			if FileAccess.file_exists(path) and not OS.is_process_running(int(pids[i])):
				var r: Dictionary = str_to_var(FileAccess.get_file_as_string(path))
				results.append(r)
				pending.erase(i)
				print("%s/%s: floor %d, level %d, %.1f h played, %d deaths (%.0f s real)" % [r["class"], r["race"], r["best_floor"], r["level"], r["minutes"] / 60.0, r["deaths"], r["real_s"]])
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if results.is_empty():
		quit(1)
		return
	results.sort_custom(func(a, b): return HEROES.find([a["class"], a["race"]]) < HEROES.find([b["class"], b["race"]]))
	var text := _report(results, hours, quick)
	var out_path := QUICK_REPORT_PATH if quick else REPORT_PATH
	if OS.get_environment("BALANCE_REPORT") != "":
		out_path = OS.get_environment("BALANCE_REPORT")   # e.g. res://claude/balance-before.md
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write %s" % REPORT_PATH)
	else:
		f.store_string(text)
		f.close()
	print("BALANCE SIM DONE: %d heroes, %.0f s real, report in claude/%s" % [results.size(), (Time.get_ticks_msec() - started) / 1000.0, "balance-report-quick.md" if quick else "balance-report.md"])
	quit()


# =====================================================================
# One hero
# =====================================================================

func _play(cls: String, race: String, hours: float, budget_s: float) -> Dictionary:
	var g := GameState.new()
	g.autosave = false
	g.codex.path = ""
	g.appearance = {"body": "masc", "skin": 1, "hair": "Long", "hair_color": 0, "eyes": 4, "race": race}
	g.hero_name = cls
	g.new_game()
	g.choose_class(cls)
	g.class_auto = true
	g.auto_stats = true
	g._check_spec()
	var res := {"class": cls, "race": race, "snaps": {}, "samples": [], "death_floors": [], "stalls": [], "stop": "time", "trips": 0}
	var max_turns := int(hours * 3600.0 / TURN_SECONDS)
	var t0 := Time.get_ticks_msec()
	var deaths := 0
	death_turns = []
	retreat_to = 0
	var last_floor := 1
	var next_ms := 0     # next milestone index
	var next_band := 25
	var stall_sig := ""
	var stall_count := 0
	var last_sample := -1
	var kills_mark := 0
	var turn_mark := 0
	var turn := 0
	var last_kills := 0
	var kill_turn := 0
	while turn < max_turns:
		turn += 1
		var minutes := int(turn * TURN_SECONDS / 60.0)
		if g.in_town:
			_town_routine(g)
			res["trips"] += 1
			continue
		if g.calamity_pending:
			Calamity.fight(g)
		var worn := g.equipped.size()
		g.take_turn()
		for ev in g.events:
			if String(ev.get("type", "")) == "elite":
				res["elites"] = int(res.get("elites", 0)) + 1
		g.messages.clear()
		g.events.clear()
		var d := g.codex.stat("deaths")
		if d > deaths:
			deaths = d
			(res["death_floors"] as Array).append(last_floor)
			# What killed us (for the "How heroes fall" table)
			var ld: Dictionary = g.last_death
			var top := ""
			for k in ld.get("taken", {}):
				if top == "" or int(ld["taken"][k]) > int(ld["taken"][top]):
					top = k
			if not res.has("killers"):
				res["killers"] = []
			(res["killers"] as Array).append({"floor": last_floor, "tier": int(ld.get("tier", 0)), "boss": bool(ld.get("boss", false)), "elite": bool(ld.get("elite", false)),
				"turns": int(ld.get("turns", 0)), "top": top, "worn": worn, "left": float(ld.get("enemy_left", 0.0)),
				"mods": (ld.get("mods", []) as Array).duplicate()})
			_note_death(turn, last_floor)
			if not g.in_town:
				_go_home(g)
		last_floor = g.floor_num
		if not g.in_town and not g.go_home_after:
			_check_home(g)
		# A fight neither side can win (the hero heals faster than it hurts): a player
		# would run, go home and come back a stretch higher up
		var kn := g.codex.stat("kills")
		if kn != last_kills or g.in_town:
			last_kills = kn
			kill_turn = turn
		elif turn - kill_turn > LONG_FIGHT:
			if turn - kill_turn == LONG_FIGHT + 1:
				if not res.has("long_fights"):
					res["long_fights"] = []
				(res["long_fights"] as Array).append("floor %d: %s %s (tier %d, boss %s, mods %s)" % [g.floor_num, g.enemy_name, g.enemy_species, g.enemy_tier, str(g.enemy_is_boss), str(g.enemy_mods)])
			if turn - kill_turn > LONG_FIGHT * 6:
				(res["stalls"] as Array).append("no kill for %d turns on floor %d fight %d: enemy %s hp %d/%d atk %d boss %s mech %s, hero hp %d/%d, portal %s, path %s, doors %s, trial %s, down %s" % [turn - kill_turn, g.floor_num, g.fight, g.enemy_name, g.enemy_hp, g.enemy_max_hp, g.enemy_attack, str(g.enemy_is_boss), str(g.boss_mechanics), g.hero_hp, g.get_max_hp(), str(g.portal), str(g.path_offer), str(g.doors), str(g.trial_active), str(g.leader_down)])
				res["stop"] = "stalled"
				break
			if (turn - kill_turn) % 5 == 0 and Lineage.try_escape(g):
				kill_turn = turn
				retreat_to = maxi(1, GameState.checkpoint_start(g.floor_num) - GameData.BOSS_EVERY)
				_go_home(g)
		# Milestones: first time the best floor reaches every 25 floors
		while g.best_floor >= next_band and next_band <= 1000:
			(res["snaps"] as Dictionary)[next_band] = _snap(g, turn)
			next_band += 25
		# Curve sample
		if minutes != last_sample and minutes % SAMPLE_MIN == 0:
			last_sample = minutes
			var kills := g.codex.stat("kills")
			var tpk := float(turn - turn_mark) / maxf(1.0, float(kills - kills_mark))
			kills_mark = kills
			turn_mark = turn
			(res["samples"] as Array).append({"min": minutes, "floor": g.best_floor, "level": g.level, "gs": g.average_gear_score(),
				"gold": g.total_gold(), "scrap": g.scrap, "dust": g.dust, "deaths": deaths, "atk": g.get_attack(), "hp": g.get_max_hp(), "tpk": tpk, "upg": _avg_upg(g)})
		# Stuck check
		if turn % 25 == 0:
			var sig := "%d|%d|%d|%d|%s|%d" % [g.floor_num, g.fight, g.enemy_hp, g.hero_hp, str(g.in_town), g.codex.stat("turns")]
			if sig == stall_sig:
				stall_count += 25
			else:
				stall_sig = sig
				stall_count = 0
			if stall_count >= STALL_TURNS:
				(res["stalls"] as Array).append("floor %d fight %d: pending=%s path=%s doors=%s exploring=%s" % [g.floor_num, g.fight, str(g.calamity_pending), str(g.path_offer), str(g.doors), str(g.exploring)])
				res["stop"] = "stalled"
				break
			# Real-time budget
			if (Time.get_ticks_msec() - t0) / 1000.0 > budget_s:
				res["stop"] = "budget"
				break
		if g.best_floor >= GameData.MAX_FLOOR:
			res["stop"] = "bottom"
			break
	res["minutes"] = turn * TURN_SECONDS / 60.0
	res["best_floor"] = g.best_floor
	res["level"] = g.level
	res["deaths"] = deaths
	res["gs"] = g.average_gear_score()
	res["gold"] = g.total_gold()
	res["scrap"] = g.scrap
	res["dust"] = g.dust
	res["real_s"] = (Time.get_ticks_msec() - t0) / 1000.0
	res["turns"] = turn
	res["class_title"] = g.title()
	res["pets"] = g.pets.size()
	res["upg"] = _avg_upg(g)
	return res

## Everything the report needs at one moment.
func _snap(g: GameState, turn: int) -> Dictionary:
	var dmg := maxi(1, g.damage_taken())
	return {"min": turn * TURN_SECONDS / 60.0, "floor": g.best_floor, "level": g.level, "gs": g.average_gear_score(),
		"atk": g.get_attack(), "def": g.get_defense(), "hp": g.get_max_hp(), "e_hp": g.enemy_max_hp, "e_atk": g.enemy_attack,
		"swings": float(g.enemy_max_hp) / maxf(1.0, float(g.get_attack())), "hits": float(g.get_max_hp()) / float(dmg),
		"deaths": g.codex.stat("deaths"), "gold": g.total_gold(), "scrap": g.scrap, "dust": g.dust, "boss": g.enemy_is_boss, "upg": _avg_upg(g)}

## Average upgrade level of worn gear.
func _avg_upg(g: GameState) -> float:
	var lv := 0
	for sl in g.equipped:
		lv += int(g.equipped[sl]["level"])
	return float(lv) / maxf(1.0, g.equipped.size())

# =====================================================================
# Player behaviour
# =====================================================================

## Head home between floors when the bag is full or supplies run low.
func _check_home(g: GameState) -> void:
	if not g.shop_unlocked():
		return
	var why := false
	if g.bag_full():
		why = true
	elif g.total_gold() + g.gold >= g.potion_cost() * 3:
		var maxhp := g.get_max_hp()
		if g.potions == 0 or (g.potions <= 1 and g.hero_hp < maxhp * 0.5):
			why = true
	if why:
		_go_home(g)

func _go_home(g: GameState) -> void:
	if g.in_town:
		return
	if Town.blocked(g) == "":
		Town.enter(g)
	else:
		g.go_home_after = true

func _town_routine(g: GameState) -> void:
	g.equip_best()
	# Sort the bag: keep upgrades, salvage the good stuff for scrap, sell the rest
	for it in g.bag.duplicate():
		if it.get("locked", false) or GameState.is_bound(it) or g.is_upgrade(it):
			continue
		if int(it["rarity"]) >= 2:
			g.salvage(int(it["id"]))
		else:
			g.sell(int(it["id"]))
	while g.potions < POTION_TARGET and g.gold >= g.potion_cost():
		g.buy_potion()
	# Gear from the shop when it is a real upgrade and not most of the purse; with lots
	# of gold to spare (restocking costs more the deeper you are) the shop is re-rolled
	for round in SHOP_ROLLS:
		for i in range(g.shop.size() - 1, -1, -1):
			if i < g.shop.size() and not g.bag_full() and g.is_upgrade(g.shop[i]) and g.shop_cost(g.shop[i]) <= g.gold * 0.5:
				g.buy_shop(i)
		if not g.featured.is_empty() and not g.bag_full() and g.is_upgrade(g.featured) and g.featured_price() <= g.gold * 0.5:
			g.buy_featured()
		if round < SHOP_ROLLS - 1 and g.gold > g.restock_cost() * RESTOCK_SPARE:
			g.paid_restock()
		else:
			break
	if g.bag_level < GameData.BAG_MAX_LEVEL and g.next_bag_cost() <= g.gold * 0.4:
		g.buy_bag_upgrade()
	for set_name in GameData.SET_ORDER:
		for slot in GameData.SETS[set_name]["pieces"]:
			# only a piece that would beat what we wear (it used to re-craft every visit
			# and salvage the copies, burning dust and scrap)
			if g.set_block_reason(set_name) == "" and g.is_upgrade(GameData.make_set_item(set_name, slot, g.best_floor, -1)):
				g.craft_set_piece(set_name, slot)
				g.equip_best()
	# scrap is for upgrades: sew a bigger bag only when the gold one is out of reach
	if g.bag_craft_block_reason() == "" and g.next_bag_cost() > g.gold:
		g.craft_bag()
	g.equip_best()
	# Scrap into the cheapest upgrade that can be paid now (one that needs dust we don't
	# have is skipped, not a reason to stop)
	for _i in 80:
		var pick: Dictionary = {}
		var best_cost := 1 << 60
		for slot in g.equipped:
			var it: Dictionary = g.equipped[slot]
			if int(it["level"]) >= GameData.MAX_UPGRADE or Economy.upgrade_short(g, it) != "":
				continue
			var c := GameData.upgrade_cost(it)
			if c < best_cost:
				best_cost = c
				pick = it
		if pick.is_empty():
			break
		var before := int(pick["level"])
		g.upgrade(int(pick["id"]))
		if int(pick["level"]) == before:
			break
	# 2.1 pets: take the strongest healthy pets along (they come from rare nests)
	var healthy: Array = g.pets.filter(func(p): return int(p["hurt"]) <= 0)
	healthy.sort_custom(func(a, b): return Menagerie.power(a) > Menagerie.power(b))
	for p in healthy.slice(0, Menagerie.max_out(g)):
		if not int(p["id"]) in g.pets_out:
			Menagerie.toggle_out(g, int(p["id"]))
	# 2.1: dust into skills (rank up the equipped ones, cheapest first)
	for _i in 20:
		var sk := ""
		var sk_cost := 1 << 60
		for id in g.active_slots + g.passive_slots:
			var sid := String(id)
			if sid == "" or g.skill_rank(sid) >= SkillData.MAX_RANK:
				continue
			var c := SkillData.craft_cost(sid, g.skill_rank(sid))
			if c < sk_cost:
				sk_cost = c
				sk = sid
		if sk == "" or g.dust < sk_cost:
			break
		g.craft_skill(sk)
	if g.hero_hp < g.get_max_hp():
		Town.rest(g)
	g.messages.clear()
	g.events.clear()
	if retreat_to > 0:
		g.go_to_floor(retreat_to)
		retreat_to = 0
	Town.leave(g)

# =====================================================================
# Report
# =====================================================================

func _median(a: Array) -> float:
	if a.is_empty():
		return -1.0
	var b := a.duplicate()
	b.sort()
	return float(b[b.size() / 2]) if b.size() % 2 == 1 else (float(b[b.size() / 2 - 1]) + float(b[b.size() / 2])) / 2.0

func _hm(minutes: float) -> String:
	if minutes < 0.0:
		return "-"
	return "%dh%02d" % [int(minutes) / 60, int(minutes) % 60]

func _hrs(minutes: float) -> String:
	return "%.1f hours" % (minutes / 60.0)

func _name(r: Dictionary) -> String:
	return "%s/%s" % [r["class"], r["race"]]

func _num(v: float) -> String:
	if absf(v) >= 1.0e9:
		return "%.2fB" % (v / 1.0e9)
	if absf(v) >= 1.0e6:
		return "%.2fM" % (v / 1.0e6)
	if absf(v) >= 1.0e4:
		return "%.1fk" % (v / 1.0e3)
	return "%d" % int(v)

func _report(results: Array, hours: float, quick: bool) -> String:
	var out := "# Balance report (headless simulator)\n\n"
	out += "Made by `tools/balance_sim.gd` (%s mode). One turn = %.0f second at normal speed, so 3,600 turns = 1 hour of play. Heroes play on Auto like a sensible player: dive, go home when the bag is full or potions run low, buy potions, equip the best, upgrade gear, spend stats and pick classes automatically. They do not fetch graves on purpose (the dive does it by itself if the killer is beaten on the way), take their strongest pets along when they find one (nests are rare), and use no elixirs, parties or realms. Fixed seeds, so a rerun gives the same numbers.\n\n" % ["quick" if quick else "full", TURN_SECONDS]
	# --- Summary
	out += "## In plain words\n\n"
	var played: Array = []
	for r in results:
		played.append(float(r["minutes"]))
	out += "- %d heroes, up to %.0f hours of play each (played %s to %s).\n" % [results.size(), hours, _hrs(played.min()), _hrs(played.max())]
	for m in [100, 250, 500, 750]:
		var times: Array = []
		var reached := 0
		for r in results:
			if (r["snaps"] as Dictionary).has(m):
				times.append(float(r["snaps"][m]["min"]))
				reached += 1
		if reached == 0:
			out += "- Floor %d: not reached by any hero.\n" % m
		else:
			out += "- Floor %d: median time %s (%d of %d heroes got there, fastest %s, slowest %s).\n" % [m, _hrs(_median(times)), reached, results.size(), _hrs(times.min()), _hrs(times.max())]
	var furthest: Array = []
	for r in results:
		furthest.append(int(r["best_floor"]))
	out += "- Furthest floor when play stopped: median %d (lowest %d, highest %d). Floors beyond that need more play time than was simulated.
" % [int(_median(furthest)), furthest.min(), furthest.max()]
	var deaths: Array = []
	var dfl: Array = []
	for r in results:
		deaths.append(int(r["deaths"]))
		dfl.append_array(r["death_floors"])
	var hrs_total := 0.0
	for r in results:
		hrs_total += float(r["minutes"]) / 60.0
	out += "- Deaths: median %d per hero (%d in total, %.2f per hour of play).\n" % [int(_median(deaths)), _sum(deaths), float(_sum(deaths)) / maxf(0.01, hrs_total)]
	var stalled := 0
	for r in results:
		if r["stop"] == "stalled":
			stalled += 1
	if stalled > 0:
		out += "- %d hero(s) got stuck and stopped early (see Problems).\n" % stalled
	out += _falling_behind(results)
	# Deaths per hour spent on floors 51-100 (from reaching floor 50 to reaching 100, or the end)
	var wall_deaths := 0
	var wall_min := 0.0
	for r in results:
		var sn: Dictionary = r["snaps"]
		if not sn.has(50):
			continue
		var end_min: float = float(sn[100]["min"]) if sn.has(100) else float(r["minutes"])
		wall_min += end_min - float(sn[50]["min"])
		for fl in r["death_floors"]:
			if int(fl) > 50 and int(fl) <= 100:
				wall_deaths += 1
	if wall_min > 0.0:
		out += "- Floors 51-100: %d deaths in %.1f hours there (%.2f per hour).\n" % [wall_deaths, wall_min / 60.0, wall_deaths / (wall_min / 60.0)]
	var boss_deaths := 0
	for fl in dfl:
		if int(fl) % GameData.BOSS_EVERY == 0:
			boss_deaths += 1
	out += "- Of all deaths, %d were on boss floors (every %dth floor).\n" % [boss_deaths, GameData.BOSS_EVERY]
	out += "\n"
	# --- Heroes
	out += "## The heroes\n\n| Hero | Final class | Floor | Level | Gear Score | Avg upgrade | Play time | Deaths | Home trips | Pets | Gold+bank | Scrap | Dust | Stopped |\n|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n"
	for r in results:
		out += "| %s | %s | %d | %d | %d | +%.1f | %s | %d | %d | %d | %s | %s | %s | %s |\n" % [_name(r), r["class_title"], r["best_floor"], r["level"], r["gs"], float(r.get("upg", 0.0)), _hm(r["minutes"]), r["deaths"], r["trips"], int(r.get("pets", 0)), _num(r["gold"]), _num(r["scrap"]), _num(r["dust"]), _stop_text(r["stop"])]
	out += "\n"
	# --- Milestones
	out += "## Time to reach each floor (play time, h:mm)\n\n| Hero |"
	var heads := ""
	var rule := "|---|"
	for m in MILESTONES:
		heads += " Floor %d |" % m
		rule += "---|"
	out += heads + "\n" + rule + "\n"
	for r in results:
		var row := "| %s |" % _name(r)
		for m in MILESTONES:
			row += " %s |" % (_hm(r["snaps"][m]["min"]) if (r["snaps"] as Dictionary).has(m) else "not reached")
		out += row + "\n"
	var mrow := "| **median** |"
	for m in MILESTONES:
		var ts: Array = []
		for r in results:
			if (r["snaps"] as Dictionary).has(m):
				ts.append(float(r["snaps"][m]["min"]))
		mrow += " %s |" % (_hm(_median(ts)) if not ts.is_empty() else "not reached")
	out += mrow + "\n\n"
	# --- Power at each milestone
	for m in MILESTONES:
		var any := false
		for r in results:
			if (r["snaps"] as Dictionary).has(m):
				any = true
		if not any:
			continue
		out += "### Floor %d: hero against the monster there\n\n" % m
		out += "| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |\n|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n"
		for r in results:
			if not (r["snaps"] as Dictionary).has(m):
				continue
			var s: Dictionary = r["snaps"][m]
			out += "| %s | %s | %d | %d | %s | %s | %s | %s | %.1f | %.1f | %d | %s | %s | %s |\n" % [_name(r), _hm(s["min"]), s["level"], s["gs"], _num(s["atk"]), _num(s["hp"]), _num(s["e_hp"]), _num(s["e_atk"]), s["swings"], s["hits"], s["deaths"], _num(s["gold"]), _num(s["scrap"]), _num(s["dust"])]
		out += "\n"
	out += "Swings to kill = monster HP divided by one plain hero attack (skills and crits make it faster). Hits to die = hero max HP divided by one monster hit after defense. Under about 4 hits to die the hero is in danger.\n\n"
	# --- Pace per band
	out += "## Pace: minutes of play for each 25 floors\n\n| Floors |"
	var hdr2 := ""
	var rl2 := "|---|"
	for r in results:
		hdr2 += " %s |" % _name(r)
		rl2 += "---|"
	out += hdr2 + " median |\n" + rl2 + "---|\n"
	for b in range(25, 1001, 25):
		var cells := ""
		var vals: Array = []
		var anyb := false
		for r in results:
			var snaps: Dictionary = r["snaps"]
			if snaps.has(b):
				var prev: float = float(snaps[b - 25]["min"]) if snaps.has(b - 25) else 0.0
				var d := float(snaps[b]["min"]) - prev
				vals.append(d)
				cells += " %.0f |" % d
				anyb = true
			else:
				cells += " - |"
		if not anyb:
			break
		out += "| %d-%d |%s %s |\n" % [b - 24, b, cells, ("%.0f" % _median(vals)) if not vals.is_empty() else "-"]
	out += "\n"
	# --- Deaths per band
	out += "## Where heroes die\n\n| Floors | Deaths | Heroes who died here |\n|---|---|---|\n"
	var bands := {}
	for r in results:
		for f in r["death_floors"]:
			var b2 := (int(f) - 1) / 25
			if not bands.has(b2):
				bands[b2] = []
			(bands[b2] as Array).append(_name(r))
	var keys := bands.keys()
	keys.sort()
	if keys.is_empty():
		out += "| (none) | 0 | |\n"
	for k in keys:
		var names: Array = []
		for nme in bands[k]:
			if not nme in names:
				names.append(nme)
		out += "| %d-%d | %d | %s |\n" % [int(k) * 25 + 1, int(k) * 25 + 25, (bands[k] as Array).size(), ", ".join(names)]
	out += "\n"
	# --- How heroes fall
	var ks: Array = []
	for r in results:
		ks.append_array(r.get("killers", []))
	if not ks.is_empty():
		var tiers := {}
		var tops := {}
		var turns: Array = []
		var left: Array = []
		var naked := 0
		var bosses := 0
		var modded := 0
		var modc := {}
		var elite_deaths := 0
		var elite_rooms := 0
		for r in results:
			elite_rooms += int(r.get("elites", 0))
		for kd in ks:
			if bool(kd.get("elite", false)):
				elite_deaths += 1
			var tn: String = Monsters.TIER_NAMES[clampi(int(kd["tier"]), 0, 5)]
			tiers[tn] = int(tiers.get(tn, 0)) + 1
			var tp: String = kd["top"] if String(kd["top"]) != "" else "?"
			tops[tp] = int(tops.get(tp, 0)) + 1
			turns.append(int(kd["turns"]))
			left.append(float(kd["left"]))
			if int(kd["worn"]) <= 2:
				naked += 1
			if bool(kd["boss"]):
				bosses += 1
			for mname in kd["mods"]:
				modc[mname] = int(modc.get(mname, 0)) + 1
			if not (kd["mods"] as Array).is_empty():
				modded += 1
		out += "## How heroes fall\n\n"
		out += "- %d deaths: %d with 2 or fewer gear pieces worn (re-gearing after a fall), %d to bosses, %d to monsters with modifiers.\n" % [ks.size(), naked, bosses, modded]
		out += "- Fight length at death: median %d turns. Monster HP left when the hero fell: median %d%%.\n" % [int(_median(turns)), int(_median(left) * 100.0)]
		out += "- Elite rooms: %d entered, %d deaths there (%d%% of all deaths, %.1f%% of elite rooms).\n" % [elite_rooms, elite_deaths, int(100.0 * elite_deaths / maxf(1.0, ks.size())), 100.0 * elite_deaths / maxf(1.0, elite_rooms)]
		var up100: Array = []
		for r in results:
			if (r["snaps"] as Dictionary).has(100):
				up100.append(float(r["snaps"][100].get("upg", 0.0)))
		if not up100.is_empty():
			out += "- Worn gear upgrade level on reaching floor 100: median +%.1f.\n" % _median(up100)
		out += "- Killer's tier: %s.\n" % ", ".join(tiers.keys().map(func(t): return "%s %d" % [t, tiers[t]]))
		out += "- Biggest damage source in the fatal fight: %s.\n" % ", ".join(tops.keys().map(func(t): return "%s %d" % [t, tops[t]]))
		out += "- Killer's modifiers: %s.\n\n" % ", ".join(modc.keys().map(func(t): return "%s %d" % [t, modc[t]]))
	# --- Curves
	out += "## Curves over play time\n\nEvery row is a play time; one column per hero.\n\n"
	var longest := 0
	for r in results:
		longest = maxi(longest, (r["samples"] as Array).size())
	var step := maxi(1, int(ceil(float(longest) / 16.0)))
	for metric in [["floor", "Best floor"], ["level", "Level"], ["gs", "Gear Score (average of worn gear)"], ["gold", "Gold + bank"], ["scrap", "Scrap"], ["upg", "Average upgrade level of worn gear"], ["dust", "Dust"], ["deaths", "Deaths so far"], ["atk", "Hero attack"], ["hp", "Hero max HP"], ["tpk", "Turns per kill (over the last 10 minutes)"]]:
		out += "### %s\n\n| Play time |" % metric[1]
		out += hdr2 + "\n" + rl2 + "\n"
		var i := step - 1
		while i < longest:
			var row2 := ""
			var label := ""
			for r in results:
				var smp: Array = r["samples"]
				if i < smp.size():
					label = _hm(smp[i]["min"])
					var v: float = float(smp[i][metric[0]])
					row2 += " %s |" % (("%.1f" % v) if metric[0] in ["tpk", "upg"] else _num(v))
				else:
					row2 += " - |"
			out += "| %s |%s\n" % [label, row2]
			i += step
		out += "\n"
	# --- Problems
	out += "## Problems seen while simulating\n\n"
	var any_prob := false
	for r in results:
		for s in r["stalls"]:
			out += "- %s stuck for %d turns at %s\n" % [_name(r), STALL_TURNS, s]
			any_prob = true
		var lf: Array = r.get("long_fights", [])
		if not lf.is_empty():
			out += "- %s had %d fights with no kill for %d turns (then ran), first: %s\n" % [_name(r), lf.size(), LONG_FIGHT, lf[0]]
			any_prob = true
		if r["stop"] == "budget":
			out += "- %s ran out of real-time budget at %s of play (floor %d); later milestones are unknown, not failed.\n" % [_name(r), _hm(r["minutes"]), r["best_floor"]]
	if not any_prob:
		out += "- Nothing got stuck.\n"
	return out

func _sum(a: Array) -> int:
	var t := 0
	for v in a:
		t += int(v)
	return t

func _stop_text(s: String) -> String:
	match s:
		"time":
			return "full time"
		"budget":
			return "real-time budget"
		"stalled":
			return "stuck"
		"bottom":
			return "reached floor 1000"
	return s

## Finds the floor band where the heroes slow down most and where hits-to-die gets thin.
func _falling_behind(results: Array) -> String:
	var s := ""
	# Slowest band: median minutes for a 25-floor band, compared with the median of the first 100 floors
	var med: Dictionary = {}
	for b in range(25, 1001, 25):
		var vals: Array = []
		for r in results:
			var snaps: Dictionary = r["snaps"]
			if snaps.has(b):
				vals.append(float(snaps[b]["min"]) - (float(snaps[b - 25]["min"]) if snaps.has(b - 25) else 0.0))
		if vals.size() >= maxi(1, results.size() / 2):
			med[b] = _median(vals)
	if med.size() >= 3:
		var early: Array = []
		for b in med:
			if b <= 100:
				early.append(float(med[b]))
		var base := maxf(0.5, _median(early))
		var first_slow := -1
		var worst_b := -1
		var worst := 0.0
		for b in med:
			if float(med[b]) > worst:
				worst = float(med[b])
				worst_b = b
			if first_slow < 0 and b > 100 and float(med[b]) >= base * 4.0:
				first_slow = b
		s += "- Pace: the first 100 floors take about %.0f minutes per 25 floors. " % base
		if first_slow > 0:
			s += "Heroes slow to 4 times that or worse from floors %d-%d. " % [first_slow - 24, first_slow]
		s += "The slowest stretch is floors %d-%d at about %.0f minutes (%.1f times the early pace).\n" % [worst_b - 24, worst_b, worst, worst / base]
	# Hits to die and swings to kill by milestone
	var danger := -1
	var slow_kill := -1
	for m in range(25, 1001, 25):
		var hits: Array = []
		var sw: Array = []
		for r in results:
			if (r["snaps"] as Dictionary).has(m):
				hits.append(float(r["snaps"][m]["hits"]))
				sw.append(float(r["snaps"][m]["swings"]))
		if hits.is_empty():
			continue
		if danger < 0 and _median(hits) < 4.0:
			danger = m
		if slow_kill < 0 and _median(sw) > 12.0:
			slow_kill = m
	if danger > 0:
		s += "- Defense: from floor %d the median hero survives fewer than 4 monster hits.\n" % danger
	else:
		s += "- Defense: at every milestone the median hero survives 4 or more hits.\n"
	if slow_kill > 0:
		s += "- Offense: from floor %d a plain hero attack needs more than 12 swings to kill the monster.\n" % slow_kill
	else:
		s += "- Offense: a plain attack kills in 12 swings or fewer at every milestone.\n"
	return s

## Falling again and again: a sensible player goes back one 25-floor stretch to rebuild
## (you can only travel from town to the start of a stretch).
func _note_death(turn: int, floor_died: int) -> void:
	death_turns.append(turn)
	var recent := 0
	for t in death_turns:
		if turn - int(t) <= 900:   # within 15 minutes
			recent += 1
	if recent >= 2:
		retreat_to = maxi(1, GameState.checkpoint_start(floor_died) - GameData.BOSS_EVERY * (recent - 1))
