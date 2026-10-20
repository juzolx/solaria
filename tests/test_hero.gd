extends RefCounted
## Shared setup for screenshot and performance runs: a fresh test hero in slot 1.
## Refuses to touch saves unless user data points at the test folder (override.cfg),
## so a run can never wipe Juzo's real saves.

const TEST_DIR := "solaria_claude_test"
const SHOTS := "res://shots"

static func safe() -> bool:
	if OS.get_user_data_dir().contains(TEST_DIR):
		return true
	push_error("Refusing to run: user data is %s, not the test folder. Put override.cfg in place first." % OS.get_user_data_dir())
	return false

## Where screenshots go: <repo>/shots/<sub> (git-ignored, hidden from Godot's importer).
static func shots_dir(sub: String) -> String:
	var root := ProjectSettings.globalize_path(SHOTS)
	DirAccess.make_dir_recursive_absolute(root)
	if not FileAccess.file_exists(root.path_join(".gdignore")):
		FileAccess.open(root.path_join(".gdignore"), FileAccess.WRITE).store_string("")
	var dir := root.path_join(sub)
	DirAccess.make_dir_recursive_absolute(dir)
	return dir

## A mid-game Warrior on the given floor, saved in slot 1 and set as the active hero.
static func make(floor_num := 30, hero_class := "Warrior") -> void:
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	var prof := Profile.new()
	prof.save_epoch = Profile.SAVE_EPOCH
	prof.max_floor = floor_num
	prof.active_slot = 1
	prof.notes_seen = PatchNotes.VERSION
	prof.towns_v1 = true
	prof.save()
	var g := GameState.new()
	g.slot = 1
	g.codex.path = ""
	g.appearance = {"body": "masc", "skin": 1, "hair": "Long", "hair_color": 0, "eyes": 4, "race": "Human"}
	g.hero_name = "Thorin"
	g.new_game()
	g.choose_class(hero_class)
	g.level = 30
	g.best_floor = floor_num
	g.floor_num = floor_num
	g.gold = 9000
	g.stat_points = 5 * 29
	g.auto_spend()
	g.hero_hp = g.get_max_hp()
	g.save_game()
	# Mark today's daily reward as taken so its popup doesn't cover the screens
	var cx := Codex.load_codex()
	var _day := cx.check_login()
	cx.save()
