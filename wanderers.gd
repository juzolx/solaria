class_name Wanderers
extends RefCounted
## 0.13+ (Stage 3): rare wanderers. Now and then one of the old roaming things of
## folklore crosses your path: Legendary-strong, never in a pack, and it doesn't stay.
## Beat it before it wanders off and it leaves a Legendary behind.

const CHANCE := 0.4        # % of ordinary fights from FROM_FLOOR
const FROM_FLOOR := 15
const STAY_TURNS := 10     # it wanders off after this many turns
const LIST := [
	{"name": "Black Shuck", "art": "barghest", "shape": "beast", "color": "#1f2937",
		"lore": "The great black dog of the lonely roads. Its eyes burn like coals, and it is never seen twice in one night."},
	{"name": "The Lantern Man", "art": "grief_wisp", "shape": "spirit", "color": "#fde68a",
		"lore": "A swinging light over the marsh. Follow it and you are lost; chase it off and it drops what it was carrying."},
	{"name": "Old Hob", "art": "boggart", "shape": "humanoid", "color": "#92400e",
		"lore": "A hob who was kind once, and isn't now. It walks from house to empty house looking for someone who remembers it."},
	{"name": "Jenny Greenteeth", "art": "grindylow", "shape": "serpent", "color": "#4d7c0f",
		"lore": "She waits under the duckweed for anyone who walks too close to the water, and then she doesn't wait."},
	{"name": "The Grey Walker", "art": "barrow_wight", "shape": "spirit", "color": "#9ca3af",
		"lore": "A tall grey shape that walks the barrows at dusk. It is going somewhere, and it has been going there for a thousand years."},
]

## Maybe turns the monster just spawned into a wanderer (end of spawn_enemy).
static func maybe(g: GameState) -> void:
	g.enemy_wanderer = false
	if g.enemy_is_boss or g.enemy_goblin or g.trial_active or g.enemy_calamity > 0 or g.enemy_grave or g.horde_left > 0:
		return
	if g.floor_num < FROM_FLOOR or randf() * 100.0 >= CHANCE * TownEvents.wanderer_mult(g):
		return
	make(g, LIST.pick_random())

static func make(g: GameState, w: Dictionary) -> void:
	g.enemy_wanderer = true
	g.horde_left = 0  # always alone
	g.horde_pack = false
	g.enemy_species = String(w["name"])
	g.enemy_name = String(w["name"])
	g.enemy_art = String(w["art"])
	g.enemy_shape = String(w["shape"])
	g.enemy_color = String(w["color"])
	g._apply_tier(Monsters.LEGENDARY)
	# its own entrance, not the usual "Legendary monster!" one
	g.events = g.events.filter(func(e): return e.get("type", "") != "rare_monster")
	var keep: Array[String] = []
	for m in g.messages:
		if not (String(w["name"]) in m and "appears!" in m):
			keep.append(m)
	g.messages = keep
	g.hazard = ""
	g.codex.meet(g.enemy_species)
	g.events.append({"type": "mini_event", "kind": "wanderer", "title": "A WANDERER", "sub": "%s. Beat it in %d turns before it moves on." % [w["name"], STAY_TURNS]})
	g.say("[color=#fde68a]%s crosses your path.[/color] %s" % [w["name"], w["lore"]])
	g.tip("wanderer", "Wanderers are rare roaming legends. They leave after %d turns, so hit hard: beat one and it drops a Legendary." % STAY_TURNS)

## Turns before it leaves (-1 if this isn't a wanderer).
static func turns_left(g: GameState) -> int:
	if not g.enemy_wanderer:
		return -1
	return maxi(0, STAY_TURNS - int(g.cfight.get("turns", 0)))

## Each turn: has it had enough? Returns true if it left (the next monster is up).
static func wander_off(g: GameState) -> bool:
	if not g.enemy_wanderer or g.enemy_hp <= 0 or turns_left(g) > 0:
		return false
	g.say("[color=#9ca3af]%s turns away and walks on into the dark.[/color]" % g.enemy_name)
	g.events.append({"type": "toast", "text": "%s wandered off." % g.enemy_name})
	g.enemy_wanderer = false
	g.spawn_enemy()
	return true

## Beat one: a Legendary and a story to tell.
static func reward(g: GameState) -> void:
	if not g.enemy_wanderer:
		return
	g.enemy_wanderer = false
	var item := GameData.make_item(GameData.SLOT_ORDER.pick_random(), GameData.LEGENDARY, g.floor_num, g._new_id())
	g._give_item(item)
	g._add_gold((10 + g.floor_num * 8) * 5)
	g.codex.add("wanderers")
	ClassTree.count(g, "wanderers")
	# a trophy: a title of its own for each legend you bring down
	var trophy: String = {"Black Shuck": "Shuck-Slayer", "The Lantern Man": "Lantern-Snuffer", "Old Hob": "Hob's Bane", "Jenny Greenteeth": "Weed-Walker", "The Grey Walker": "Grey-Stopper"}.get(g.enemy_species, "")
	if trophy != "" and not trophy in g.codex.extra_titles:
		g.codex.extra_titles.append(trophy)
		g.codex.dirty = true
		g.say("[color=#fde68a]A trophy: the title \"%s\".[/color] Show it off in Town > Guild Hall." % trophy)
	g.events.append({"type": "mini_event", "kind": "wanderer", "title": "WANDERER DOWN", "sub": "%s leaves something behind" % g.enemy_name})
