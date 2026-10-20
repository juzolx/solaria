extends SceneTree
## Next update: saves are towns. Old hero saves each become their own town.
const TestHero := preload("res://tests/test_hero.gd")
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _old_hero(n: int, nm: String, best: int) -> void:
	GameState.town = 1
	var g := GameState.new()
	g.codex.path = ""
	g.slot = n
	g.new_game()
	g.choose_class("Warrior")
	g.hero_name = nm
	g.best_floor = best
	g.save_game()
	var p := GameState.town_slot_paths(1, n)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(p[0]), ProjectSettings.globalize_path(GameState.OLD_SLOT_PATH % n))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p[1]))

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	GameState.delete_saves()
	Profile.delete()
	_old_hero(1, "Ana", 40)
	_old_hero(2, "Bram", 300)
	_old_hero(3, "Cole", 75)
	var p := Profile.new()
	p.skill_book = {"cleave": 3}
	p.stash = [{"id": 99}]
	p.stash_level = 2
	p.active_slot = 2
	var placed := GameState.migrate_to_towns()
	p.build_towns(placed)
	check(placed.size() == 3, "three old heroes moved (%d)" % placed.size())
	for t in [1, 2, 3]:
		check(GameState.town_heroes(t) == 1, "town %d has one hero" % t)
		check(int(p.towns[str(t)]["skill_book"].get("cleave", 0)) == 3, "town %d keeps the skill book" % t)
	check(not FileAccess.file_exists(GameState.OLD_SLOT_PATH % 1), "old save files are moved")
	check(FileAccess.file_exists("user://pre_towns_backup/hero_2.dat"), "a backup of the old saves is kept")
	check(p.town == 2 and GameState.town == 2, "you land in the town of the hero you played last")
	check(p.stash.size() == 1 and p.stash_level == 2, "that town gets the old stash")
	check(p.max_floor == 300, "town max floor comes from its heroes (%d)" % p.max_floor)
	check(str(GameState.slot_meta(1).get("name", "")) == "Bram", "town 2 slot 1 is Bram")
	p.switch_town(1)
	check(GameState.town == 1 and p.stash.is_empty() and p.max_floor == 40, "town 1: its own stash and depth")
	check(str(GameState.slot_meta(1).get("name", "")) == "Ana", "town 1 slot 1 is Ana")
	p.stash.append({"id": 5})
	p.save()
	var q := Profile.load_profile()
	check(q.town == 1 and q.stash.size() == 1 and int(q.towns["2"]["stash"].size()) == 1, "towns survive a reload")
	check(q.slots_open() == GameData.MAX_HEROES, "locks off: all 9 hero slots open")
	q.max_floor = 300
	check(q.earned_slots() == 3, "earned slots by depth: start, floor 51, floor 250")
	check(q.slot_lock_note(9).contains("bought") or not GameData.SLOT_LOCKS_ON, "slots 6-9 are the paid ones")
	q.towns_v1 = true
	check(GameState.migrate_to_towns().is_empty(), "migration runs once")
	GameState.delete_saves()
	Profile.delete()
	GameState.town = 1
	print("STAGE5 TOWN TESTS DONE, failures: ", fails)
	quit()
