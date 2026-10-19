extends SceneTree
## The 0.13+ branches open through the deeper dungeon's systems.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _initialize() -> void:
	var names := {"Stormbreaker": "staggers", "Grave-Walker": "graves_recovered", "Team Captain": "team_strikes", "Vault Breaker": "rifts",
		"Legend Hunter": "wanderers", "Silver Tongue": "haggles_won", "Weatherwise": "hazard_bursts", "Friend of Peoples": "peaceful"}
	for n in names:
		var b := ClassTree.by_name(n)
		check(not b.is_empty(), "%s exists in the class tree" % n)
		if b.is_empty():
			continue
		var parent := ""
		for row in ClassTree.BRANCHES:
			if row[1] == n:
				parent = String(row[0])
		var p := ClassTree.by_name(parent)
		check(not p.is_empty() and ClassTree.branches(String(p["id"])).any(func(o): return o["name"] == n), "%s hangs off %s" % [n, parent])
		var g := GameState.new()
		g.codex.path = ""
		g.autosave = false
		check(not ClassTree.branch_ready(g, b), "%s is locked at first" % n)
		g.ctrack[names[n]] = 99999.0
		check(ClassTree.branch_ready(g, b), "%s opens when its deed is done" % n)
	print("STAGE3 BRANCH TESTS DONE, failures: ", fails)
	quit()
