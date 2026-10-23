extends SceneTree
## R4 save safety (save_io.gd): atomic writes, rolling backups, fallback on a
## damaged file, a version in every file, the migration hook and the throttle.
## godot --headless --path . -s tests/stage6_saves.gd
const TestHero := preload("res://tests/test_hero.gd")
const P := "user://r4_test.dat"
var fails := 0

func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func raw(p: String) -> Variant:
	if not FileAccess.file_exists(p):
		return null
	var f := FileAccess.open(p, FileAccess.READ)
	var d = f.get_var()
	f.close()
	return d

func garble(p: String) -> void:
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string("this is not a save file at all")
	f.close()

## Backups are spaced by file age: pretend s seconds have passed (0 = real time).
func later(s: int) -> void:
	SaveIO.test_now_unix = int(Time.get_unix_time_from_system()) + s if s > 0 else -1

func hero(n: int) -> GameState:
	var g := GameState.new()
	g.slot = n
	g.codex = Codex.new()
	g.codex.path = ""
	g.new_game()
	g.choose_class("Warrior")
	return g

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	SaveIO.delete_all(P)
	SaveIO.notices.clear()

	# --- A version in every file
	check(SaveIO.write(P, {"n": 1}, "codex"), "a write succeeds")
	var r = raw(P)
	check(r is Dictionary and int(r.get("save_version", 0)) == SaveIO.VERSIONS["codex"] and r.get("save_kind") == "codex", "the file carries save_version and save_kind")
	check(not FileAccess.file_exists(SaveIO.tmp_path(P)), "no temp file is left behind")
	var prof := Profile.new()
	prof.save_epoch = Profile.SAVE_EPOCH
	prof.volume = 0.42
	prof.save()
	var pr = raw(Profile.PATH)
	check(pr is Dictionary and pr.has("save_version") and pr.get("save_kind") == "profile", "profile.dat has a version")
	var g := hero(1)
	g.gold = 111
	g.save_game()
	var hr = raw(GameState.slot_paths(1)[0])
	check(hr is Dictionary and hr.has("save_version") and hr.get("save_kind") == "hero" and hr.has("version"), "hero save has a version")
	var cx := Codex.new()
	cx.add("kills", 3)
	cx.save()
	var cr = raw(Codex.PATH)
	check(cr is Dictionary and cr.has("save_version"), "codex.dat has a version")
	check(Codex.load_codex().stat("kills") == 3, "codex reads back")

	# --- Backup rotation keeps the last 3 good copies
	SaveIO.delete_all(P)
	for i in range(1, 6):
		later(61)
		SaveIO.write(P, {"n": i}, "codex")
	later(0)
	check(SaveIO.backup_count(P) == SaveIO.BACKUPS, "exactly %d backups after 5 saves (%d)" % [SaveIO.BACKUPS, SaveIO.backup_count(P)])
	check(int(raw(P)["n"]) == 5, "main is the newest save")
	check(int(raw(SaveIO.backup_path(P, 1))["n"]) == 4 and int(raw(SaveIO.backup_path(P, 2))["n"]) == 3 and int(raw(SaveIO.backup_path(P, 3))["n"]) == 2, "backups are newest first")
	check(int(raw(SaveIO.day_path(P))["n"]) == 1, "the daily copy holds the first good save")
	# saves within a minute replace the main file but don't move the backups
	SaveIO.write(P, {"n": 6}, "codex")
	SaveIO.write(P, {"n": 7}, "codex")
	check(int(raw(P)["n"]) == 7 and int(raw(SaveIO.backup_path(P, 1))["n"]) == 4 and int(raw(SaveIO.backup_path(P, 2))["n"]) == 3, "saves within a minute don't push out the backups")

	# --- A damaged main file: the newest good backup is restored, with a notice
	garble(P)
	SaveIO.notices.clear()
	var res := SaveIO.load_file(P, "codex")
	check(res["data"] != null and int(res["data"]["n"]) == 4 and res["restored"], "corrupt file -> newest backup restored")
	check(not SaveIO.notices.is_empty(), "the player gets a notice")
	check(FileAccess.file_exists(SaveIO.corrupt_path(P)), "the damaged file is kept aside")
	check(raw(P) is Dictionary and int(raw(P)["n"]) == 4, "the main file is repaired")
	# a damaged file is never rotated into the backups
	garble(P)
	later(61)
	SaveIO.write(P, {"n": 6}, "codex")
	later(0)
	check(int(raw(SaveIO.backup_path(P, 1))["n"]) == 4, "a damaged main file is not kept as a backup")
	# main and newer backups gone: older ones still work
	SaveIO.delete_all(P)
	for i in range(1, 5):
		later(61)
		SaveIO.write(P, {"n": i}, "codex")
	later(0)
	garble(P)
	garble(SaveIO.backup_path(P, 1))
	check(int(SaveIO.read(P, "codex")["n"]) == 2, "falls back past a damaged backup to an older one")

	# --- Hero saves: corrupt main -> backup loads, flagged for the notice
	var h := hero(2)
	h.gold = 500
	h.save_game()
	h.gold = 900
	later(61)
	h.save_game()
	later(0)
	garble(GameState.slot_paths(2)[0])
	var h2 := GameState.new()
	h2.slot = 2
	h2.codex = Codex.new()
	h2.codex.path = ""
	check(h2.load_game() and h2.gold == 500 and h2.restored_backup, "damaged hero save -> backup hero loads (gold %d)" % h2.gold)
	check(GameState.has_slot(2) and not GameState.slot_meta(2).is_empty(), "the title screen still lists the hero")
	# nothing readable at all: no crash, the slot just reads as empty
	SaveIO.delete_all(GameState.slot_paths(3)[0])
	garble(GameState.slot_paths(3)[0])
	var h3 := GameState.new()
	h3.slot = 3
	h3.codex = Codex.new()
	h3.codex.path = ""
	check(not h3.load_game(), "an unreadable hero with no backup doesn't load (and doesn't crash)")
	GameState.delete_slot(3)

	# --- A write cut short leaves the old save intact
	SaveIO.delete_all(P)
	SaveIO.write(P, {"n": 1}, "codex")
	SaveIO.test_truncate = true
	var ok := SaveIO.write(P, {"n": 2}, "codex")
	SaveIO.test_truncate = false
	check(not ok, "a truncated write is refused")
	check(int(raw(P)["n"]) == 1, "truncated write -> old save intact")
	check(not FileAccess.file_exists(SaveIO.tmp_path(P)), "the broken temp file is removed")
	# a crash mid-write leaves half a temp file: ignored
	var whole := FileAccess.get_file_as_bytes(P)
	var tf := FileAccess.open(SaveIO.tmp_path(P), FileAccess.WRITE)
	tf.store_buffer(whole.slice(0, whole.size() >> 1))
	tf.close()
	check(int(SaveIO.read(P, "codex")["n"]) == 1, "half-written temp file is ignored")
	# crash between the write and the rename: the verified temp file is used
	DirAccess.remove_absolute(ProjectSettings.globalize_path(P))
	SaveIO.delete_all(P)
	SaveIO.write(P, {"n": 7}, "codex")
	DirAccess.rename_absolute(ProjectSettings.globalize_path(P), ProjectSettings.globalize_path(SaveIO.tmp_path(P)))
	check(int(SaveIO.read(P, "codex")["n"]) == 7, "a finished temp file is used when the main file is missing")

	# --- A broken settings file never wipes the heroes
	SaveIO.delete_all(Profile.PATH)
	garble(Profile.PATH)
	var lp := Profile.load_profile()
	check(not lp.fresh_start_due(), "unreadable profile with no backup doesn't trigger the fresh-start wipe")
	prof.save()
	prof.volume = 0.7
	prof.save()
	garble(Profile.PATH)
	check(is_equal_approx(Profile.load_profile().volume, 0.42), "damaged profile -> backup settings")

	# --- The daily copy: a run of bad saves can't overwrite all history
	SaveIO.delete_all(P)
	SaveIO.write(P, {"n": 1}, "codex")
	SaveIO.write(P, {"n": 2}, "codex")
	for i in range(3, 9):
		later(61 * i)
		SaveIO.write(P, {"n": i}, "codex")
	check(int(raw(SaveIO.backup_path(P, 3))["n"]) >= 5 and int(raw(SaveIO.day_path(P))["n"]) == 1, "the .bak chain moved on but the daily copy kept the old save")
	later(SaveIO.DAY_EVERY_S + 10)
	SaveIO.write(P, {"n": 9}, "codex")
	later(0)
	check(int(raw(SaveIO.day_path(P))["n"]) == 8, "the daily copy refreshes after a day from the last good main")
	garble(P)
	for i in range(1, SaveIO.BACKUPS + 1):
		garble(SaveIO.backup_path(P, i))
	check(int(SaveIO.read(P, "codex")["n"]) == 8, "the daily copy is the last fallback")

	# --- A failed hero write stays pending and is retried; a deleted hero isn't brought back
	var rt := hero(5)
	rt.gold = 10
	rt.save_game()
	SaveIO.test_truncate = true
	rt.gold = 20
	rt.save_game()
	SaveIO.test_truncate = false
	check(rt.save_pending and int(raw(GameState.slot_paths(5)[0])["gold"]) == 10, "a failed write stays pending (old save intact)")
	rt.flush_save()
	check(not rt.save_pending and int(raw(GameState.slot_paths(5)[0])["gold"]) == 20, "the retry writes it")
	rt.save_pending = true
	GameState.delete_slot(5)
	rt.flush_save()
	check(not GameState.has_slot(5), "a pending save for a deleted hero (companion) is dropped")

	# --- Cloud restore: a bad bundle never deletes local heroes
	var pf := Profile.load_profile()
	var h2raw: Dictionary = raw(GameState.slot_paths(2)[0])
	check(GameState.has_slot(1) and GameState.has_slot(2), "setup: two local heroes")
	check(not Online.unpack_local(pf, {"heroes": {}}), "a bundle with no heroes is refused")
	check(not Online.unpack_local(pf, {"heroes": {2: {"floor": 3}, 3: "junk"}}), "a bundle with a broken hero is refused")
	check(not Online.unpack_local(pf, {"heroes": {99: {"floor": 3}}}), "a bundle with a bad slot is refused")
	check(not Online.unpack_local(pf, {"heroes": {2: {"floor": 3}}, "codex": "junk"}), "a bundle with a broken codex is refused")
	check(GameState.has_slot(1) and GameState.has_slot(2) and int(raw(GameState.slot_paths(2)[0])["gold"]) == int(h2raw["gold"]), "refused bundles changed nothing")
	h2raw["gold"] = 4242
	check(Online.unpack_local(pf, {"heroes": {2: h2raw}}), "a good bundle restores")
	check(int(raw(GameState.slot_paths(2)[0])["gold"]) == 4242 and not GameState.has_slot(1), "bundle heroes written, the others removed")

	# --- Migration hook
	SaveIO.MIGRATIONS["codex"][0] = func(d: Dictionary) -> Dictionary:
		d["migrated"] = true
		return d
	var m := SaveIO.migrate("codex", {"save_version": 0})
	check(m.get("migrated", false) and int(m["save_version"]) == SaveIO.VERSIONS["codex"], "migration steps run up to the current version")
	SaveIO.MIGRATIONS["codex"].erase(0)
	check(int(SaveIO.migrate("hero", {"floor": 1}).get("save_version", 0)) == 1, "files from before R4 count as version 1")

	# --- Throttle: frequent saves coalesce, flush writes the latest
	var t := hero(4)
	SaveIO.coalesce = true
	SaveIO.test_now_ms = 100000
	t.gold = 1
	t.save_game()
	check(int(raw(GameState.slot_paths(4)[0])["gold"]) == 1, "the first save writes at once")
	SaveIO.test_now_ms = 100500
	t.gold = 2
	t.save_game()
	SaveIO.test_now_ms = 101000
	t.gold = 3
	t.save_game()
	check(t.save_pending and int(raw(GameState.slot_paths(4)[0])["gold"]) == 1, "saves inside the window wait")
	t.flush_save()
	check(not t.save_pending and int(raw(GameState.slot_paths(4)[0])["gold"]) == 3, "flush writes the latest state")
	SaveIO.test_now_ms = 101200
	t.gold = 4
	t.save_game()
	SaveIO.test_now_ms = 101200 + SaveIO.MIN_INTERVAL_MS
	t.gold = 5
	t.save_game()
	check(not t.save_pending and int(raw(GameState.slot_paths(4)[0])["gold"]) == 5, "after the window a save writes again")
	t.save_game()
	check(t.save_pending, "pending again inside the new window")
	t.save_game(true)
	check(not t.save_pending, "force skips the throttle (pause / quit)")
	t.save_game()
	t.delete_own_saves()
	t.flush_save()
	check(not GameState.has_slot(4), "a held-back save can't bring a deleted hero back")
	SaveIO.coalesce = false
	SaveIO.test_now_ms = -1

	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	SaveIO.delete_all(P)
	SaveIO.notices.clear()
	print("STAGE6 SAVES TESTS DONE, failures: ", fails)
	quit()
