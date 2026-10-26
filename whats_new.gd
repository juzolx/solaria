class_name WhatsNew
extends Overlay
## 2.1 G9: "What's new" after an update. Shown once per version to players who
## played an older version (a brand-new player gets the welcome instead), and any
## time from Settings or the title screen's update banner. A short friendly
## summary first; the full list (PatchNotes.NOTES[0]) is one tap away.
## Plain words, no casino words (the summary is checked by tests/stage6_onboarding.gd).

## version -> [[heading, one short line], ...]. Only the newest version needs one;
## an older version, or one without a summary, shows its patch notes instead.
const SUMMARY := {
	"2.1": [
		["God classes", "Above every rank stand the God classes. Nobody knows the way. Keep your ears open."],
		["Pets from nests", "Each region hides a rare nest with its own egg. Epic and better pets learn a special trick."],
		["Three currencies", "Just gold, scrap and dust now. Simpler to read, easier to plan."],
		["The Legendary Wheel", "From floor 250 the Wheel has a Legendary prize table, with every chance shown up front. Game gold only."],
		["Your town grows", "Level up the Inn, Smith and more. Build a Church to lift curses and a Trophy Cabin for your best finds."],
		["Collections and share card", "Fill your Codex for titles and looks (never power). Make a picture of your hero to share."],
		["Portals", "Rifts, realm gates and champion trial gates now share one simple set of rules."],
		["Safer saves", "Every save is checked first, with backups. If one breaks, it's quietly repaired."],
		["Your heroes came along", "Every town, hero, pet and item from 2.0 is here. Old zone materials became dust."],
	],
}

## Shown once to players whose 2.0 heroes were moved into 2.1.
const MIGRATED_TEXT := "Your heroes made it into 2.1! Every town, hero, pet and item came along, and your old zone materials were turned into dust. Classes now evolve at levels 15, 35 and 75, so a hero whose class pick came earlier than that can choose it again when they get there."

## Words a friendly update screen never uses (store age-rating rule: no casino feel).
const CASINO_WORDS := ["gamble", "gambling", "casino", "jackpot", "bet ", "bets", "slot machine", "loot box", "lucky spin", "odds"]

var m

## Is the screen due? Once per version, for players who knew an older version.
static func due(p: Profile, first_run: bool) -> bool:
	if p.whats_new_seen == PatchNotes.VERSION:
		return false
	if first_run:
		p.whats_new_seen = PatchNotes.VERSION  # a brand-new player: nothing is "new" to them
		p.save()
		return false
	return true

static func summary() -> Array:
	return SUMMARY.get(String(PatchNotes.NOTES[0]["version"]), [])

## Opens the screen and marks it seen. fresh: also say that saves were reset (only saves
## from before 0.12). migrated: say that 2.0 heroes were moved into 2.1 (save_migrate.gd).
func show_for(main_node, fresh := false, on_done := Callable(), migrated := false) -> WhatsNew:
	m = main_node
	var n: Dictionary = PatchNotes.NOTES[0]
	open(m, "What's new", 480.0, UI.GOLD)
	var head := UI.label("%s  ·  v%s" % [String(n["name"]), String(n["version"])], UI.FONT_TITLE, UI.GOLD.lightened(0.15))
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(head)
	if fresh:
		content.add_child(UI.wrap("A fresh start: every town and hero begins again under the new rules. Your settings are kept.", UI.FONT_BODY, UI.TEXT))
	if migrated:
		content.add_child(UI.wrap(MIGRATED_TEXT, UI.FONT_BODY, UI.GOLD.lightened(0.2)))
	var items := summary()
	if items.is_empty():
		for l in (n["lines"] as Array).slice(0, 6):
			items.append(["", String(l)])
	for it in items:
		var r := UI.rich(15)
		r.text = ("[color=#e8b14a][b]%s[/b][/color]\n%s" % [it[0], it[1]]) if String(it[0]) != "" else String(it[1])
		content.add_child(r)
	var details := UI.rich(13)
	var lines: Array = []
	for l in n["lines"]:
		lines.append("- " + String(l))
	details.text = "\n".join(lines)
	details.visible = false
	var more := UI.button("All the details", func(): details.visible = not details.visible)
	more.custom_minimum_size = Vector2(0, UI.TAP)
	content.add_child(more)
	content.add_child(details)
	var go := UI.primary("Let's go", close, UI.GOLD)
	go.custom_minimum_size = Vector2(0, UI.TAP + 8)
	go.add_theme_font_size_override("font_size", UI.FONT_BODY)
	content.add_child(go)
	if on_done.is_valid():
		tree_exiting.connect(on_done, CONNECT_ONE_SHOT)  # "Let's go" or Close
	m.profile.whats_new_seen = PatchNotes.VERSION
	m.profile.save()
	return self
