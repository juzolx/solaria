extends SceneTree
## Credits and licenses: every source has a name, author and license; the screen opens.
const TestHero := preload("res://tests/test_hero.gd")
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var seen := {}
	for s in CreditsData.SOURCES:
		var nm: String = s.get("name", "")
		check(nm != "", "entry has a name")
		check(String(s.get("author", "")) != "", "%s has an author" % nm)
		check(String(s.get("license", "")) != "", "%s has a license" % nm)
		check(String(s.get("used", "")) != "", "%s says where it is used" % nm)
		check(String(s.get("link", "")) != "", "%s has a link (or -)" % nm)
		check(CreditsData.GROUPS.has(s.get("group", "")), "%s is in a known group" % nm)
		check(not seen.has(nm), "%s is listed once" % nm)
		seen[nm] = true
		var lic := String(s.get("license", "")).to_lower()
		check(not lic.contains("non-commercial") and not lic.contains("noncommercial") and not lic.contains("-nc"), "%s is not non-commercial" % nm)
	for g in CreditsData.GROUPS:
		check(CreditsData.in_group(g).size() > 0, "group %s has an entry" % g)
	var blob := ""
	for s in CreditsData.SOURCES:
		blob += JSON.stringify(s)
	check(blob.contains("Godot") and blob.contains("MIT"), "Godot's MIT notice is listed")
	check(not blob.contains("BDragon"), "the non-commercial FX pack is not credited as used")
	check(Credits.TEXT.contains("Redshrike"), "LPC part list is present")
	# the screen opens
	TestHero.make(5)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	var o: Overlay = CreditsScreen.new().show_for(main)
	await process_frame
	await process_frame
	check(is_instance_valid(o) and o.is_inside_tree(), "credits screen opens")
	check(o.content.get_child_count() > CreditsData.SOURCES.size(), "credits screen lists the sources")
	print("STAGE6 CREDITS TESTS DONE, failures: ", fails)
	quit()
