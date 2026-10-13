extends SceneTree
## Tests online.gd against a local stand-in for Supabase (real PostgREST + Postgres
## running supabase_setup.sql, with fake anonymous logins). Not part of the game.

var failures := 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
	else:
		print("ok: ", what)

func make_online() -> Online:
	var o := Online.new()
	var p := Profile.new()
	o.setup(p)
	o.url = "http://127.0.0.1:3000"
	o.key = "test-anon-key"
	root.add_child(o)
	return o

func _initialize() -> void:
	var a := make_online()
	var b := make_online()
	await process_frame

	var r := await a.ensure_login()
	check(r["ok"] and a.user_id() != "", "anonymous login")
	r = await a.register_name("Ju")
	check(not r["ok"] and r["error"].contains("3-16"), "short name rejected")
	r = await a.register_name("Juzo")
	check(r["ok"] and a.has_name(), "name registered")
	r = await a.register_name("Juzo the Bold")
	check(r["ok"] and a.profile.player_name == "Juzo the Bold", "rename works")

	var s := GameState.new()
	s.autosave = false
	s.new_game()
	s.choose_class("Warrior")
	s.best_floor = 57
	s.level = 33
	await a.submit_run(s)
	s.best_floor = 42
	await a.submit_run(s)
	r = await a.top_runs()
	check(r["ok"] and r["data"].size() == 1 and int(r["data"][0]["floor"]) == 57, "leaderboard keeps the best run")

	r = await b.register_name("Juzo the Bold")
	check(not r["ok"] and r["error"] == "That name is taken.", "duplicate name: " + str(r.get("error", "")))
	r = await b.register_name("Friend")
	check(r["ok"], "second player named")

	r = await a.create_guild("Sun Seekers", "sun", 80)
	check(r["ok"], "guild created " + str(r.get("error", "")))
	var gid := int(r["data"]["id"]) if r["ok"] else 0
	r = await a.my_guild()
	check(r["ok"] and r["data"] != null and r["data"]["name"] == "Sun Seekers", "my guild found")
	r = await b.my_guild()
	check(r["ok"] and r["data"] == null, "no guild yet")
	r = await b.list_guilds("sun")
	check(r["ok"] and r["data"].size() == 1 and int(r["data"][0]["members"]) == 1, "guild search")
	r = await b.join_guild(gid, 20)
	check(r["ok"], "joined guild")
	r = await a.guild_members(gid)
	check(r["ok"] and r["data"].size() == 2, "two members")
	await b.update_best(30)
	r = await a.guild_rankings()
	check(r["ok"] and int(r["data"][0]["power"]) == 110, "rankings power = sum of best floors (%s)" % str(r.get("data", "")))

	r = await a.raid_status(gid)
	check(r["ok"] and r["data"]["attacks_left"] == 3 and not r["data"]["dead"], "raid status")
	var hp := int(r["data"]["hp"]) if r["ok"] else 0
	var dmg := Online.raid_damage(s)
	check(dmg > 0, "raid damage computed (%d)" % dmg)
	for i in 3:
		r = await a.raid_attack(gid, hp / 2)
		check(r["ok"], "raid attack %d" % (i + 1))
	r = await a.raid_attack(gid, 10)
	check(not r["ok"] and r["error"].contains("raid attacks"), "4th attack blocked: " + str(r.get("error", "")))
	r = await a.raid_status(gid)
	check(r["ok"] and r["data"]["dead"] and r["data"]["attacks_left"] == 0, "boss dead, no attacks left")
	r = await a.raid_claim(gid)
	check(r["ok"], "reward claimed")
	r = await a.raid_claim(gid)
	check(not r["ok"], "can't claim twice")
	r = await a.raid_status(gid)
	check(r["ok"] and r["data"]["claimed"], "claim shows")

	# Expired login refreshes
	a.profile.online["expires_at"] = 0
	r = await a.my_guild()
	check(r["ok"], "login refresh works")

	r = await a.leave_guild()
	check(r["ok"], "leader leaves")
	r = await b.my_guild()
	check(r["ok"] and r["data"] != null, "guild survives with new leader")
	r = await b.leave_guild()
	r = await b.list_guilds("sun")
	check(r["ok"] and r["data"].size() == 0, "empty guild deleted")

	# Not configured: friendly message, nothing breaks
	var off := Online.new()
	off.setup(Profile.new())
	off.url = ""
	root.add_child(off)
	await process_frame
	r = await off.top_runs()
	check(not r["ok"] and r["error"].contains("ONLINE_SETUP"), "offline message")

	print("ONLINE TESTS DONE, failures: ", failures)
	quit(1 if failures > 0 else 0)
