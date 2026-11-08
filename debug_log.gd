class_name DebugLog
extends RefCounted
## R6: a small local log of errors and warnings (last MAX lines), kept on the
## phone only so Juzo can copy it from Menu › "Copy report info" when a TestFlight
## build misbehaves. Nothing is ever sent anywhere (the privacy policy says no
## analytics): the player sees the text and decides to paste it.
##
## Errors are caught by a Godot Logger (OS.add_logger) that may run on any thread,
## so it only appends under a mutex; the file is written later from the main
## thread (flush(): every turn when something changed, and when the app pauses).

const PATH := "user://debug_log.txt"
const MAX := 120          # lines kept (oldest drop off)
const LINE_MAX := 300     # characters per line

static var lines: PackedStringArray = []
static var dirty := false
static var _loaded := false
static var _mutex := Mutex.new()
static var _logger: Logger = null

## A Godot Logger that copies errors and warnings (not ordinary prints) into the log.
class Catcher extends Logger:
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		var kind := "WARN" if error_type == ERROR_TYPE_WARNING else "ERROR"
		var what := rationale if rationale != "" else code
		DebugLog.add("%s %s (%s:%d %s)" % [kind, what, file.get_file(), line, function])

	func _log_message(message: String, error: bool) -> void:
		if error:
			DebugLog.add("ERR " + message.strip_edges())

## Call once at start: loads the old log and starts catching errors.
static func start() -> void:
	load_file()
	if _logger == null:
		_logger = Catcher.new()
		OS.add_logger(_logger)
	add("--- session %s, Solaria %s, %s" % [Time.get_datetime_string_from_system(), PatchNotes.VERSION, OS.get_name()])

## Adds one line (thread safe, cheap: no file work here).
static func add(text: String) -> void:
	var t := Time.get_time_string_from_system()
	var line := (t + " " + text.replace("\n", " ").replace(OS.get_user_data_dir(), "user://")).left(LINE_MAX)  # no user folder names in reports
	_mutex.lock()
	lines.append(line)
	if lines.size() > MAX:
		lines = lines.slice(lines.size() - MAX)
	dirty = true
	_mutex.unlock()

## Writes the log if it changed. Main thread only.
static func flush() -> void:
	if not dirty:
		return
	_mutex.lock()
	var text := "\n".join(lines)
	dirty = false
	_mutex.unlock()
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()

static func load_file() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(PATH):
		return
	var old := FileAccess.get_file_as_string(PATH).split("\n", false)
	_mutex.lock()
	var merged := old
	merged.append_array(lines)
	lines = merged.slice(maxi(0, merged.size() - MAX))
	_mutex.unlock()

static func clear() -> void:
	_mutex.lock()
	lines = PackedStringArray()
	dirty = true
	_mutex.unlock()
	flush()

## Tests: forget what's in memory so the next load reads the file like a restart.
static func reset_memory() -> void:
	_mutex.lock()
	lines = PackedStringArray()
	dirty = false
	_loaded = false
	_mutex.unlock()

## Everything a bug report needs, as plain text (no names, ids or save data).
static func report() -> String:
	var out := PackedStringArray()
	out.append("Solaria %s" % PatchNotes.VERSION)
	out.append("Device: %s %s (%s), %s" % [OS.get_name(), OS.get_version(), OS.get_model_name(), Engine.get_architecture_name()])
	out.append("Graphics: %s / %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_method()])
	var win := DisplayServer.window_get_size() if DisplayServer.get_name() != "headless" else Vector2i.ZERO
	out.append("Screen: %dx%d, fps %d" % [win.x, win.y, Engine.get_frames_per_second()])
	out.append("Memory: %d MB" % int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	out.append("Godot %s" % Engine.get_version_info().get("string", "?"))
	out.append("")
	_mutex.lock()
	if lines.is_empty():
		out.append("(no errors logged)")
	else:
		out.append_array(lines)
	_mutex.unlock()
	return "\n".join(out)
