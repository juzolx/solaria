extends SceneTree
## Earnable name colors and plate frames (looks only).
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _initialize() -> void:
	var c := Codex.new()
	c.path = ""
	check(Cosmetics.name_color(c) == Color("#e5e7eb") and String(Cosmetics.frame(c)["id"]) == "", "a new hero: plain name, no frame")
	c.name_color = "moss"
	c.frame = "bark"
	check(Cosmetics.name_color(c) == Color("#e5e7eb") and String(Cosmetics.frame(c)["id"]) == "", "unearned looks don't show")
	c.achievements["f50"] = "2026-10-19"
	check(Cosmetics.name_color(c) == Color("#86efac"), "reaching floor 50 earns Moss")
	check(String(Cosmetics.frame(c)["id"]) == "bark", "and the Barkwood frame")
	for e in Cosmetics.COLORS + Cosmetics.FRAMES:
		check(String(e["need"]) == "" or Cosmetics.need_name(e) != "", "every look names its deed (%s)" % e["name"])
	var d := Codex.new()
	d.path = ""
	d._from({"name_color": "moss", "frame": "bark", "achievements": {"f50": "x"}})
	check(d.name_color == "moss" and d.frame == "bark", "looks are saved with the Codex")
	print("STAGE3 COSMETICS TESTS DONE, failures: ", fails)
	quit()
