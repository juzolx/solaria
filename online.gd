class_name Online
extends Node
## Online features through Supabase (a free hosted database):
## a name-only account, the Hardcore leaderboard, guilds, weekly guild raids
## and guild rankings. Nothing here is real-time; it all reads and writes rows.
##
## Every function is async: `var r := await online.top_runs()`.
## Results look like {"ok": true, "data": ...} or {"ok": false, "error": "message"}.
## If OnlineConfig is empty, everything returns ok=false with a friendly message.

signal status_changed

const GUILD_MAX := 20
const RAID_ATTACKS_PER_DAY := 3
const RAID_TURNS := 20  # one raid attack = 20 turns of fighting the raid boss
const RAID_BOSSES := [
	{"name": "Grendel's Mother", "art": "Grendel", "zone": 0},
	{"name": "Hel Unbound", "art": "Hel", "zone": 1},
	{"name": "Charybdis the Maelstrom", "art": "Charybdis", "zone": 2},
	{"name": "Surtr Ascendant", "art": "Surtr", "zone": 3},
	{"name": "Typhon Reborn", "art": "Typhon", "zone": 4},
]

var url := OnlineConfig.SUPABASE_URL
var key := OnlineConfig.ANON_KEY
var profile: Profile
var last_error := ""

func setup(p: Profile) -> void:
	profile = p

static func configured() -> bool:
	return OnlineConfig.SUPABASE_URL != "" and OnlineConfig.ANON_KEY != ""

func is_configured() -> bool:
	return url != "" and key != ""

func user_id() -> String:
	return str(profile.online.get("user_id", ""))

func has_name() -> bool:
	return profile.player_name != "" and profile.online.get("named", false)

# =====================================================================
# Raw requests
# =====================================================================

func _headers(auth := true, extra: Array = []) -> PackedStringArray:
	var h := PackedStringArray(["apikey: " + key, "Content-Type: application/json"])
	var token := str(profile.online.get("access_token", ""))
	if auth and token != "":
		h.append("Authorization: Bearer " + token)
	elif key.begins_with("eyJ"):
		h.append("Authorization: Bearer " + key)
	for e in extra:
		h.append(e)
	return h

## Sends one HTTP request and waits for it. Returns {ok, code, data, error}.
func _request(path: String, method := HTTPClient.METHOD_GET, body = null, extra_headers: Array = [], auth := true) -> Dictionary:
	if not is_configured():
		return {"ok": false, "error": "Online isn't set up yet. See ONLINE_SETUP.md."}
	var http := HTTPRequest.new()
	http.timeout = 12.0
	add_child(http)
	var payload := "" if body == null else JSON.stringify(body)
	var err := http.request(url.trim_suffix("/") + path, _headers(auth, extra_headers), method, payload)
	if err != OK:
		http.queue_free()
		return {"ok": false, "error": "Couldn't connect (error %d)." % err}
	var res: Array = await http.request_completed
	http.queue_free()
	var result: int = res[0]
	var code: int = res[1]
	var text: String = (res[3] as PackedByteArray).get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "code": 0, "error": "No connection to the server."}
	var data = JSON.parse_string(text) if text != "" else null
	if code >= 200 and code < 300:
		return {"ok": true, "code": code, "data": data}
	var msg := text
	if data is Dictionary:
		msg = str(data.get("message", data.get("msg", data.get("error_description", data.get("error", text)))))
	return {"ok": false, "code": code, "error": _friendly(msg), "data": data}

func _friendly(msg: String) -> String:
	if msg.contains("duplicate key") and msg.contains("name"):
		return "That name is taken."
	if msg.contains("guild_full"):
		return "That guild is full (%d members)." % GUILD_MAX
	if msg.contains("raid_limit"):
		return "You've used all %d raid attacks for today." % RAID_ATTACKS_PER_DAY
	if msg.contains("JWT expired"):
		return "Login expired, try again."
	return msg

## REST call with automatic login and one retry if the login expired.
func _rest(path: String, method := HTTPClient.METHOD_GET, body = null, extra: Array = []) -> Dictionary:
	var login := await ensure_login()
	if not login["ok"]:
		return login
	var r := await _request("/rest/v1/" + path, method, body, extra)
	if not r["ok"] and int(r.get("code", 0)) == 401:
		profile.online.erase("access_token")
		login = await ensure_login()
		if login["ok"]:
			r = await _request("/rest/v1/" + path, method, body, extra)
	if not r["ok"]:
		last_error = r["error"]
	return r

# =====================================================================
# Account (just a name; the login is tied to this device)
# =====================================================================

## Logs in (creating an anonymous account the first time) and refreshes the login when needed.
func ensure_login() -> Dictionary:
	if not is_configured():
		return {"ok": false, "error": "Online isn't set up yet. See ONLINE_SETUP.md."}
	var now := int(Time.get_unix_time_from_system())
	if profile.online.get("access_token", "") != "" and now < int(profile.online.get("expires_at", 0)) - 60:
		return {"ok": true}
	var r: Dictionary
	if profile.online.get("refresh_token", "") != "":
		r = await _request("/auth/v1/token?grant_type=refresh_token", HTTPClient.METHOD_POST, {"refresh_token": profile.online["refresh_token"]}, [], false)
	if r.is_empty() or not r["ok"]:
		r = await _request("/auth/v1/signup", HTTPClient.METHOD_POST, {"data": {}}, [], false)
		if not r["ok"]:
			if str(r.get("error", "")).to_lower().contains("anonymous"):
				r["error"] = "Turn on 'Allow anonymous sign-ins' in Supabase (see ONLINE_SETUP.md)."
			return r
		profile.online["named"] = false
	var d: Dictionary = r["data"]
	profile.online["access_token"] = d.get("access_token", "")
	profile.online["refresh_token"] = d.get("refresh_token", "")
	profile.online["expires_at"] = now + int(d.get("expires_in", 3600))
	var user: Dictionary = d.get("user", {})
	if user.has("id"):
		profile.online["user_id"] = user["id"]
	profile.save()
	return {"ok": true}

## Claims your online name (3-16 letters, numbers, spaces, - or _).
func register_name(player_name: String) -> Dictionary:
	player_name = player_name.strip_edges()
	var re := RegEx.create_from_string("^[A-Za-z0-9 _-]{3,16}$")
	if re.search(player_name) == null:
		return {"ok": false, "error": "Use 3-16 letters, numbers, spaces, - or _."}
	var login := await ensure_login()
	if not login["ok"]:
		return login
	var r := await _rest("players?on_conflict=id", HTTPClient.METHOD_POST, {"id": user_id(), "name": player_name},
		["Prefer: resolution=merge-duplicates,return=representation"])
	if r["ok"]:
		profile.player_name = player_name
		profile.online["named"] = true
		profile.save()
		status_changed.emit()
	return r

# =====================================================================
# Leaderboard (deepest Hardcore floor)
# =====================================================================

func submit_run(state: GameState) -> void:
	if not is_configured() or not has_name():
		return
	await _rest("hc_runs", HTTPClient.METHOD_POST, {"player_id": user_id(), "name": profile.player_name,
		"floor": state.best_floor, "level": state.level, "title": state.title(), "race": state.race()})

func top_runs(limit := 50) -> Dictionary:
	return await _rest("leaderboard?select=name,floor,level,title,race,player_id&order=floor.desc&limit=%d" % limit)

# =====================================================================
# Guilds
# =====================================================================

## Your guild membership: {"ok", "data": {guild row} or null}
func my_guild() -> Dictionary:
	var r := await _rest("guild_members?select=guild_id,guilds(id,name,tag,leader)&player_id=eq.%s" % user_id())
	if not r["ok"]:
		return r
	var rows: Array = r["data"]
	return {"ok": true, "data": (rows[0]["guilds"] if not rows.is_empty() else null)}

func list_guilds(search := "") -> Dictionary:
	var q := "guild_rankings?select=*&order=power.desc&limit=30"
	if search.strip_edges() != "":
		q += "&name=ilike.*%s*" % search.strip_edges().uri_encode()
	return await _rest(q)

func guild_rankings() -> Dictionary:
	return await _rest("guild_rankings?select=*&order=power.desc&limit=50")

func create_guild(guild_name: String, tag: String, best_floor: int) -> Dictionary:
	guild_name = guild_name.strip_edges()
	tag = tag.strip_edges().to_upper()
	if guild_name.length() < 3 or guild_name.length() > 24:
		return {"ok": false, "error": "Guild names are 3-24 characters."}
	if tag.length() < 2 or tag.length() > 4:
		return {"ok": false, "error": "Tags are 2-4 characters."}
	var r := await _rest("guilds", HTTPClient.METHOD_POST, {"name": guild_name, "tag": tag, "leader": user_id()}, ["Prefer: return=representation"])
	if not r["ok"]:
		return r
	var g: Dictionary = r["data"][0]
	var j := await join_guild(int(g["id"]), best_floor)
	return j if not j["ok"] else {"ok": true, "data": g}

func join_guild(guild_id: int, best_floor: int) -> Dictionary:
	var r := await _rest("guild_members", HTTPClient.METHOD_POST, {"guild_id": guild_id, "player_id": user_id(),
		"name": profile.player_name, "best_floor": best_floor}, ["Prefer: return=representation"])
	status_changed.emit()
	return r

func leave_guild() -> Dictionary:
	var r := await _rest("guild_members?player_id=eq.%s" % user_id(), HTTPClient.METHOD_DELETE)
	status_changed.emit()
	return r

func guild_members(guild_id: int) -> Dictionary:
	return await _rest("guild_members?select=name,best_floor,player_id,joined_at&guild_id=eq.%d&order=best_floor.desc" % guild_id)

## Keeps your best floor up to date in your guild (used for rankings and raid size).
func update_best(best_floor: int) -> void:
	if not is_configured() or not has_name():
		return
	await _rest("guild_members?player_id=eq.%s" % user_id(), HTTPClient.METHOD_PATCH, {"best_floor": best_floor})

# =====================================================================
# Weekly raids
# =====================================================================

static func week_id(unix := -1.0) -> String:
	var t := Time.get_unix_time_from_system() if unix < 0 else unix
	# Weeks start on Monday (UTC). Day 0 of the epoch was a Thursday.
	var days := floori(t / 86400.0)
	var monday := days - ((days + 3) % 7)
	return "W" + str(monday)

static func day_id(unix := -1.0) -> String:
	var t := Time.get_unix_time_from_system() if unix < 0 else unix
	return "D" + str(floori(t / 86400.0))

static func raid_boss_for(week: String) -> Dictionary:
	var n := int(week.substr(1)) / 7
	return RAID_BOSSES[posmod(n, RAID_BOSSES.size())]

## Raid boss HP: enough that every member needs about 8 good attacks over the week.
static func raid_hp(best_floors: Array) -> int:
	var total := 0.0
	for f in best_floors:
		var fl := maxi(1, int(f))
		var enemy_hp := (15 + fl * 15) * pow(GameData.ENEMY_GROWTH, fl - 1)
		total += enemy_hp / 3.0 * RAID_TURNS * 8.0
	return maxi(10000, int(total))

## How much damage one raid attack does: 20 turns of your normal attacks plus abilities.
static func raid_damage(state: GameState) -> int:
	var total := 0.0
	var crit := clampf(state.effect_total("crit") / 100.0, 0.0, 0.75)
	var dbl := clampf(state.effect_total("double_strike") / 100.0, 0.0, 1.0)
	var per_turn := state.get_attack() * (1.0 + crit) * (1.0 + dbl)
	total += per_turn * RAID_TURNS
	if state.hero_class != "":
		total += state.get_attack() * state._ability_share() * RAID_TURNS
	return int(total * randf_range(0.9, 1.1))

## Everything the raid screen needs in one go.
func raid_status(guild_id: int) -> Dictionary:
	var week := week_id()
	var members := await guild_members(guild_id)
	if not members["ok"]:
		return members
	var hits := await _rest("raid_hits?select=player_id,name,damage,day&guild_id=eq.%d&week=eq.%s" % [guild_id, week])
	if not hits["ok"]:
		return hits
	var claim := await _rest("raid_claims?select=week&player_id=eq.%s&week=eq.%s" % [user_id(), week])
	var floors := []
	for m in members["data"]:
		floors.append(int(m["best_floor"]))
	var hp := raid_hp(floors)
	var dealt := 0
	var mine_today := 0
	var by_player := {}
	for h in hits["data"]:
		dealt += int(h["damage"])
		by_player[h["name"]] = int(by_player.get(h["name"], 0)) + int(h["damage"])
		if h["player_id"] == user_id() and h["day"] == day_id():
			mine_today += 1
	return {"ok": true, "data": {
		"week": week, "boss": raid_boss_for(week), "hp": hp, "dealt": dealt, "dead": dealt >= hp,
		"attacks_left": maxi(0, RAID_ATTACKS_PER_DAY - mine_today), "damage_by": by_player,
		"claimed": claim["ok"] and not (claim["data"] as Array).is_empty(), "members": members["data"].size(),
	}}

func raid_attack(guild_id: int, damage: int) -> Dictionary:
	return await _rest("raid_hits", HTTPClient.METHOD_POST, {"guild_id": guild_id, "player_id": user_id(),
		"name": profile.player_name, "week": week_id(), "day": day_id(), "damage": damage})

## Claims this week's raid reward (once per week). ok=true means you may give the reward.
func raid_claim(guild_id: int) -> Dictionary:
	return await _rest("raid_claims", HTTPClient.METHOD_POST, {"guild_id": guild_id, "player_id": user_id(), "week": week_id()})

# =====================================================================
# Cloud backup: every hero, the Codex and the stash in one blob.
# The backup code lets you restore on another device.
# =====================================================================

const CODE_CHARS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

func cloud_code() -> String:
	var code := str(profile.online.get("cloud_code", ""))
	if code == "":
		for _i in 10:
			code += CODE_CHARS[randi() % CODE_CHARS.length()]
		profile.online["cloud_code"] = code
		profile.save()
	return code

## Packs the files on this device into one Variant.
static func pack_local(p: Profile) -> Dictionary:
	var heroes := {}
	for n in range(1, GameData.MAX_HEROES + 1):
		var paths := GameState.slot_paths(n)
		for path in [paths[0], paths[1]]:
			if FileAccess.file_exists(path):
				var f := FileAccess.open(path, FileAccess.READ)
				heroes[n] = f.get_var()
				break
	var codex = null
	if FileAccess.file_exists(Codex.PATH):
		codex = FileAccess.open(Codex.PATH, FileAccess.READ).get_var()
	return {"version": 1, "heroes": heroes, "codex": codex, "stash": p.stash, "stash_level": p.stash_level, "max_floor": p.max_floor,
		"hc_best": p.hc_best, "hc_runs": p.hc_runs, "active_slot": p.active_slot}

## Writes a packed backup over the files on this device.
static func unpack_local(p: Profile, bundle: Dictionary) -> void:
	for n in range(1, GameData.MAX_HEROES + 1):
		GameState.delete_slot(n)
	var heroes: Dictionary = bundle.get("heroes", {})
	for n in heroes:
		var f := FileAccess.open(GameState.slot_paths(int(n))[0], FileAccess.WRITE)
		f.store_var(heroes[n])
		f.close()
	if bundle.get("codex") != null:
		var cf := FileAccess.open(Codex.PATH, FileAccess.WRITE)
		cf.store_var(bundle["codex"])
		cf.close()
	p.stash = bundle.get("stash", [])
	p.stash_level = int(bundle.get("stash_level", 0))
	p.max_floor = maxi(p.max_floor, int(bundle.get("max_floor", 0)))
	p.hc_best = maxi(p.hc_best, int(bundle.get("hc_best", 0)))
	p.hc_runs = bundle.get("hc_runs", p.hc_runs)
	p.active_slot = int(bundle.get("active_slot", 1))
	p.save()

func cloud_backup() -> Dictionary:
	var blob := Marshalls.variant_to_base64(pack_local(profile))
	var r := await _rest("cloud_saves?on_conflict=code", HTTPClient.METHOD_POST, {"code": cloud_code(), "data": blob},
		["Prefer: resolution=merge-duplicates,return=minimal"])
	if r["ok"]:
		r["code"] = cloud_code()
	return r

## Restores the backup with this code (your own code if empty).
func cloud_restore(code := "") -> Dictionary:
	if code == "":
		code = cloud_code()
	var r := await _rest("rpc/get_cloud_save", HTTPClient.METHOD_POST, {"p_code": code.strip_edges().to_upper()})
	if not r["ok"]:
		return r
	if r["data"] == null or str(r["data"]) == "":
		return {"ok": false, "error": "No backup found with that code."}
	var bundle = Marshalls.base64_to_variant(str(r["data"]))
	if typeof(bundle) != TYPE_DICTIONARY:
		return {"ok": false, "error": "That backup couldn't be read."}
	unpack_local(profile, bundle)
	profile.online["cloud_code"] = code.strip_edges().to_upper()
	profile.save()
	return {"ok": true}
