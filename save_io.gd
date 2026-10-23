class_name SaveIO
extends RefCounted
## R4 save safety (2.1): every save file goes through here.
##
## Writing (write): the new data goes to <name>.tmp, is read back to prove it
## parses, the last good main file is copied into the rolling backups
## (<name>.bak, .bak2, .bak3: newest first; the chain moves at most once a
## minute) and a daily copy (<name>.day, at most once a day), and only then is
## the .tmp renamed over the main file. A crash or a full disk at any point
## leaves the old main file, the verified .tmp or a backup intact.
##
## Reading (load): main file, then a verified .tmp (a crash between write and
## rename), then the backups newest first, then .day. A damaged main file is kept as
## <name>.corrupt, repaired from the backup, and the player gets a gentle notice
## (main shows `notices`). Nothing ever crashes or silently starts over.
##
## Every file carries "save_version" (per kind, below) and "save_kind". To
## change a format in 3.0: bump VERSIONS[kind] and add a step to MIGRATIONS,
## e.g. MIGRATIONS["hero"][1] = func(d): d["new_key"] = 0; return d
## Each step takes a file at version N and returns it at N + 1.
## (2.1 is a deliberate fresh start at Profile.SAVE_EPOCH 13: no steps yet.)
##
## Throttle: GameState.save_game() is called after almost every fight. In the
## real game (`coalesce` on, set by main) a hero writes at most once every
## MIN_INTERVAL_MS; calls in between only mark the hero dirty, and main flushes
## dirty heroes every second, on pause / focus out / quit and on going back to
## the title. Tests leave `coalesce` off, so every save writes at once.
## Nothing here looks at the wall clock: there is still no offline progress.

## SaveIO's own file-format version per kind. Not the same thing as
## GameData.SAVE_VERSION: that is the hero's game-data layout inside the file
## ("version", converted by GameState._convert_old_save in load_game). If a
## hero format change can be expressed as a MIGRATIONS["hero"] step, bump
## VERSIONS["hero"] here; if it needs GameState logic, bump GameData.SAVE_VERSION
## and extend _convert_old_save. Never bump both for the same change.
const VERSIONS := {"hero": 1, "profile": 1, "codex": 1}
const BACKUPS := 3
const MIN_INTERVAL_MS := 3000
const BAK_EVERY_S := 60        # the .bak chain moves at most once a minute
const DAY_EVERY_S := 86400     # .day: one copy a day from a known-good main file

## kind -> {from_version: Callable(d: Dictionary) -> Dictionary}
static var MIGRATIONS := {"hero": {}, "profile": {}, "codex": {}}
static var coalesce := false
static var test_now_ms := -1     # tests set this to drive the throttle clock
static var test_now_unix := -1   # tests set this to age the backups
static var test_truncate := false  # tests: simulate a write cut short (disk full, crash)
static var notices: Array[String] = []
static var _noticed := {}

static func now_ms() -> int:
	return test_now_ms if test_now_ms >= 0 else Time.get_ticks_msec()

## Only used to space out backups, never for game progress.
static func now_unix() -> int:
	return test_now_unix if test_now_unix >= 0 else int(Time.get_unix_time_from_system())

# ---------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------

static func tmp_path(path: String) -> String:
	return path.get_basename() + ".tmp"

## Backup i (1 = newest): .bak, .bak2, .bak3 (.bak is the old single backup name).
static func backup_path(path: String, i: int) -> String:
	return path.get_basename() + (".bak" if i == 1 else ".bak%d" % i)

## One copy a day, the last fallback.
static func day_path(path: String) -> String:
	return path.get_basename() + ".day"

static func corrupt_path(path: String) -> String:
	return path.get_basename() + ".corrupt"

static func all_paths(path: String) -> Array:
	var out := [path, tmp_path(path), corrupt_path(path), day_path(path)]
	for i in range(1, BACKUPS + 1):
		out.append(backup_path(path, i))
	return out

static func delete_all(path: String) -> void:
	for p in all_paths(path):
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

## True if a save exists under any name it can be read back from (main, the
## verified .tmp, the backups or the daily copy). A .corrupt copy alone isn't a save.
static func exists(path: String) -> bool:
	for p in fallback_paths(path):
		if FileAccess.file_exists(p):
			return true
	return false

## Main file first, then the fallbacks in the order load_file tries them.
static func fallback_paths(path: String) -> Array:
	var out := [path, tmp_path(path)]
	for i in range(1, BACKUPS + 1):
		out.append(backup_path(path, i))
	out.append(day_path(path))
	return out

## True if a readable copy of this save was written by SaveIO (it carries
## "save_kind"): i.e. by Solaria 2.1 or later. Reads only, never repairs.
static func made_by_save_io(path: String, kind: String) -> bool:
	for p in fallback_paths(path):
		var d = _parse(p, kind)
		if d != null:
			return (d as Dictionary).has("save_kind")
	return false

static func backup_count(path: String) -> int:
	var n := 0
	for i in range(1, BACKUPS + 1):
		if FileAccess.file_exists(backup_path(path, i)):
			n += 1
	return n

# ---------------------------------------------------------------------
# Writing
# ---------------------------------------------------------------------

## Atomically writes data (a Dictionary) to path. Returns false (and leaves the
## old files untouched) if the new file could not be written and read back.
static func write(path: String, data: Dictionary, kind: String) -> bool:
	data = data.duplicate()  # the caller's dictionary is never changed
	data["save_version"] = int(VERSIONS.get(kind, 1))
	data["save_kind"] = kind
	var tmp := tmp_path(path)
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("SaveIO: can't open %s (%s)" % [tmp, error_string(FileAccess.get_open_error())])
		return false
	f.store_var(data)
	f.close()
	if test_truncate:
		_truncate_half(tmp)
	if _parse(tmp, kind) == null:
		push_warning("SaveIO: %s did not read back, the old save is kept" % tmp)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
		return false
	# Keep the last good main file as a backup (a damaged one is dropped). The
	# .bak chain only moves once a minute and .day once a day, so a run of bad
	# saves can't push every good copy out.
	if FileAccess.file_exists(path) and _parse(path, kind) != null:
		var main_abs := ProjectSettings.globalize_path(path)
		if _age(backup_path(path, 1)) >= BAK_EVERY_S:
			for i in range(BACKUPS, 1, -1):
				var older := backup_path(path, i - 1)
				if FileAccess.file_exists(older):
					_move(older, backup_path(path, i))
			DirAccess.copy_absolute(main_abs, ProjectSettings.globalize_path(backup_path(path, 1)))
		if _age(day_path(path)) >= DAY_EVERY_S:
			DirAccess.copy_absolute(main_abs, ProjectSettings.globalize_path(day_path(path)))
	_move(tmp, path)
	return true

## Seconds since a file was last written (huge if it doesn't exist, or if
## the clock was moved back so it looks written in the future: rotate then).
static func _age(p: String) -> int:
	if not FileAccess.file_exists(p):
		return 1 << 40
	var age := now_unix() - int(FileAccess.get_modified_time(p))
	return 1 << 40 if age < 0 else age

static func _move(from: String, to: String) -> void:
	var a := ProjectSettings.globalize_path(from)
	var b := ProjectSettings.globalize_path(to)
	if DirAccess.rename_absolute(a, b) != OK:
		# Some platforms won't rename over an existing file
		DirAccess.remove_absolute(b)
		DirAccess.rename_absolute(a, b)

static func _truncate_half(p: String) -> void:
	var bytes := FileAccess.get_file_as_bytes(p)
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f:
		f.store_buffer(bytes.slice(0, bytes.size() >> 1))
		f.close()

# ---------------------------------------------------------------------
# Reading
# ---------------------------------------------------------------------

## The data in path (migrated to the current version), or null if neither the
## file nor any backup can be read.
static func read(path: String, kind: String) -> Variant:
	return load_file(path, kind)["data"]

## {"data": Dictionary or null, "restored": a backup was used,
##  "lost": a save existed but nothing could be read, "from": the file used}
static func load_file(path: String, kind: String) -> Dictionary:
	var res := {"data": null, "restored": false, "lost": false, "from": ""}
	var main_exists := FileAccess.file_exists(path)
	var d = _parse(path, kind)
	if d != null:
		res["data"] = migrate(kind, d)
		res["from"] = path
		return res
	if main_exists:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(corrupt_path(path)))
	var tried_backup := false
	var order := fallback_paths(path).slice(1)
	for p in order:
		if p != order[0] and FileAccess.file_exists(p):
			tried_backup = true
		d = _parse(p, kind)
		if d == null:
			continue
		res["data"] = migrate(kind, d)
		res["from"] = p
		res["restored"] = p != order[0]
		# Repair the main file so this only happens once
		write(path, (res["data"] as Dictionary).duplicate(true), kind)  # the migrated data
		if res["restored"]:
			_notice(path, "A %s file was damaged (maybe the phone shut down mid-save), so your most recent backup was restored. You may have lost a few moments of progress." % _label(kind))
		return res
	if main_exists or tried_backup:
		res["lost"] = true
		_notice(path, "A %s file was damaged and no backup could be read, so it started fresh. A copy of the damaged file was kept." % _label(kind))
	return res

static func _label(kind: String) -> String:
	return {"hero": "hero save", "profile": "settings", "codex": "Codex"}.get(kind, "save")

static func _notice(path: String, text: String) -> void:
	if _noticed.has(path):
		return
	_noticed[path] = true
	notices.append(text)
	push_warning("SaveIO: " + text + " (" + path + ")")

## The parsed file, or null if it is missing, cut short, or not this kind of save.
static func _parse(p: String, kind: String) -> Variant:
	if not FileAccess.file_exists(p):
		return null
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null or f.get_length() < 8:
		return null
	# store_var writes a 4-byte length first: a cut-short file can't match it
	var need := f.get_32()
	if need <= 0 or need + 4 > f.get_length():
		return null
	f.seek(0)
	var d = f.get_var()
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return null
	if str((d as Dictionary).get("save_kind", kind)) != kind:
		return null
	if kind == "hero" and not (d as Dictionary).has("floor"):
		return null
	return d

## Runs the MIGRATIONS steps from the file's save_version up to the current one.
## Files from before R4 have no save_version: they count as version 1.
static func migrate(kind: String, d: Dictionary) -> Dictionary:
	var v := int(d.get("save_version", 1))
	var target := int(VERSIONS.get(kind, 1))
	var steps: Dictionary = MIGRATIONS.get(kind, {})
	while v < target:
		if steps.has(v):
			d = (steps[v] as Callable).call(d)
		v += 1
	d["save_version"] = v
	return d

# ---------------------------------------------------------------------
# Throttle
# ---------------------------------------------------------------------

## True if a hero's save should wait (it is marked dirty instead).
static func should_defer(last_write_ms: int) -> bool:
	return coalesce and now_ms() - last_write_ms < MIN_INTERVAL_MS
