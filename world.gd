class_name World
extends RefCounted
## The dungeon around the fights (v0.11):
##  - Floor hazards: some floors have poison fog, darkness, holy ground...
##  - New events between fights: a blood altar, a cursed chest, a gambler.
##  - Milestone floors: every 10th floor has a Champion and a reward chest.
##  - Opt-in curses: make the climb harder for better loot.
##  - Companions: a pet that fights beside you and evolves with you.
##  - The next goal: one line that always says what to chase.
##  - Achievement power: every 10 achievements make all your heroes a bit stronger.

# =====================================================================
# Floor hazards
# =====================================================================

const HAZARD_CHANCE := 30.0   # % of ordinary floors (from floor 8) that have one
const HAZARDS := {
	"fog": {"name": "Poison Fog", "color": "#a3e635", "text": "Poison fog: you lose 1.5% HP a turn (Wisdom resists it). Nature skills +20%."},
	"dark": {"name": "Darkness", "color": "#64748b", "text": "Darkness: 12% of your attacks miss (Dexterity helps). Shadow skills +25%."},
	"holy": {"name": "Holy Ground", "color": "#fde68a", "text": "Holy ground: you heal 1.5% a turn. Holy skills +25%, Shadow skills -15%."},
	"heat": {"name": "Scorching Heat", "color": "#fb923c", "text": "Scorching heat: you burn for 1.5% HP a turn (Wisdom resists it). Fire skills +25%, Frost -15%."},
	"flood": {"name": "Flooded Halls", "color": "#38bdf8", "text": "Flooded halls: Storm skills +30%, but no extra attacks from Agility."},
	"overgrowth": {"name": "Overgrowth", "color": "#63c74d", "text": "Overgrowth: monsters heal 1% a turn. Nature skills +25%."},
	"leyline": {"name": "Ley Line", "color": "#c084fc", "text": "A ley line: all skills +15%, and their cooldowns tick faster."},
	"frost": {"name": "Bitter Cold", "color": "#bae6fd", "text": "Bitter cold: Frost skills +25%, and every Frost hit chills."},
}
# Which hazards each zone has (by zone id)
const ZONE_HAZARDS := {
	"mossy_hollows": ["overgrowth", "fog", "leyline"],
	"sunken_catacombs": ["fog", "dark", "holy"],
	"flooded_depths": ["flood", "dark", "frost"],
	"ember_halls": ["heat", "dark", "leyline"],
	"the_shadow_deep": ["dark", "fog", "holy"],
}
const HAZARD_TAGS := {
	"fog": {"Nature": 0.2}, "dark": {"Shadow": 0.25}, "holy": {"Holy": 0.25, "Shadow": -0.15},
	"heat": {"Fire": 0.25, "Frost": -0.15}, "flood": {"Storm": 0.3}, "overgrowth": {"Nature": 0.25},
	"leyline": {"Fire": 0.15, "Frost": 0.15, "Storm": 0.15, "Arcane": 0.15, "Holy": 0.15, "Shadow": 0.15, "Nature": 0.15,
		"Blood": 0.15, "Blade": 0.15, "Fist": 0.15, "Song": 0.15, "Trick": 0.15},
	"frost": {"Frost": 0.25},
}

## The hazard on a floor ("" = none). Always the same for the same floor.
static func hazard_at(floor_num: int) -> String:
	if floor_num < 8 or GameData.is_boss_floor(floor_num) or GameData.realm_of(floor_num) != "" or is_milestone(floor_num):
		return ""
	var pool: Array = ZONE_HAZARDS.get(String(GameData.zone_for_floor(floor_num)["id"]), [])
	if pool.is_empty():
		return ""
	var h := absi(hash("hz%d" % floor_num))
	if float(h % 1000) / 10.0 >= HAZARD_CHANCE:
		return ""
	return String(pool[(h / 1000) % pool.size()])

static func hazard(g: GameState) -> String:
	if g.trial_active:
		return ""
	return hazard_at(g.floor_num)

static func hazard_tag_power(g: GameState, tags: Array) -> float:
	var hz := hazard(g)
	if hz == "":
		return 0.0
	var tp: Dictionary = HAZARD_TAGS.get(hz, {})
	var best := 0.0
	for t in tags:
		var v := float(tp.get(t, 0.0))
		if absf(v) > absf(best):
			best = v
	return best

## Your attacks miss in the dark (Dexterity helps).
static func dark_miss(g: GameState) -> bool:
	if hazard(g) != "dark":
		return false
	var miss := 12.0 * (1.0 - g.dim("DEX", [60.0, 120.0]) / 100.0)
	return randf() * 100.0 < miss

## Every turn: the floor's hazard does its thing. Returns a log line.
static func hazard_turn(g: GameState) -> String:
	match hazard(g):
		"fog", "heat":
			var d := maxi(1, int(g.get_max_hp() * 0.015 * g.status_mult()))
			g.hero_hp -= d
			Combat.note_damage(g, "poison" if hazard(g) == "fog" else "burn", d)
			g.events.append({"type": "enemy_hit", "dmg": d, "poison": hazard(g) == "fog", "burning": hazard(g) == "heat"})
		"holy":
			var h := int(g.get_max_hp() * 0.015 * g.heal_mult())
			if h > 0 and g.hero_hp > 0:
				g.hero_hp = mini(g.get_max_hp(), g.hero_hp + h)
		"overgrowth":
			if g.enemy_hp > 0:
				g.enemy_hp = mini(g.enemy_max_hp, g.enemy_hp + int(g.enemy_max_hp * 0.01))
		"leyline":
			for id in g.skill_cds:
				if int(g.skill_cds[id]) > 0 and randf() < 0.35:
					g.skill_cds[id] = int(g.skill_cds[id]) - 1
	return ""

## Arriving on a floor: announce its hazard.
static func on_floor(g: GameState) -> void:
	var hz := hazard(g)
	if hz != "":
		var info: Dictionary = HAZARDS[hz]
		g.say("[color=%s]%s[/color]" % [info["color"], info["text"]])
		g.events.append({"type": "mini_event", "kind": "hazard", "title": String(info["name"]).to_upper(), "sub": String(info["text"]).split(":")[1].strip_edges() if String(info["text"]).contains(":") else ""})
		ClassTree.count(g, "hazard_floors")
	if is_milestone(g.floor_num):
		g.events.append({"type": "mini_event", "kind": "milestone", "title": "MILESTONE FLOOR %d" % g.floor_num, "sub": "A Champion guards a reward chest"})
		g.say("[color=#e8b14a]Milestone floor %d: a Champion waits at the end, guarding a chest.[/color]" % g.floor_num)

# =====================================================================
# Milestone floors
# =====================================================================

## Every 10th floor of a zone that isn't a boss floor (10, 20, 30, 40...).
static func is_milestone(floor_num: int) -> bool:
	return GameData.zone_floor(floor_num) % 10 == 0 and not GameData.is_boss_floor(floor_num)

## The last fight of a milestone floor is a Champion.
static func champion_here(g: GameState) -> bool:
	return is_milestone(g.floor_num) and g.fight == GameData.FIGHTS_PER_FLOOR and not g.enemy_goblin and g.horde_left <= 0 and not g.trial_active

static func make_champion(g: GameState) -> void:
	g._apply_tier(maxi(g.enemy_tier, Monsters.EPIC))
	g.enemy_name = "Champion " + g.enemy_name
	g.enemy_max_hp = int(g.enemy_max_hp * 1.3)
	g.enemy_hp = g.enemy_max_hp
	g.enemy_champion = true

## Beat a Champion: the chest, and a checkpoint you never fall below.
static func champion_reward(g: GameState) -> void:
	var gold := (10 + g.floor_num * 8) * 4
	g._add_gold(gold)
	var r := maxi(3, g._rarity(30 + g._loot_bonus(), GameData.LEGENDARY_CHANCE_BOSS * 1.5))
	g._give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), r, g.floor_num, g._new_id()))
	Economy.give_dust(g, randi_range(Economy.CHAMPION_DUST[0], Economy.CHAMPION_DUST[1]))
	g.potions += 1
	g.checkpoint = maxi(g.checkpoint, g.floor_num)
	g.codex.add("champions")
	g.say("[color=#e8b14a]The Champion falls! Its chest:[/color] +%d gold and a potion." % gold)
	g.events.append({"type": "treasure"})
	g.events.append({"type": "mini_event", "kind": "milestone", "title": "CHAMPION", "sub": "Floor %d milestone" % g.floor_num})

# =====================================================================
# New events between fights
# =====================================================================

const EVENT_PATHS := {
	"altar": {"name": "Blood altar", "text": "Give 20% of your max HP: +30% Attack for 40 turns.", "color": "#e43b44"},
	"chest_open": {"name": "Open the chest", "text": "Epic or better gear... but it might be cursed (-20% Defense for 40 turns). Luck helps.", "color": "#c084fc"},
	"bet": {"name": "Take the bet", "text": "Bet a stack of gold on a coin toss. Luck and Charisma tilt the coin.", "color": "#fbbf24"},
	"well": {"name": "Drink from the well", "text": "Something old lives in this well. It might bless you, or not.", "color": "#2dd4bf"},
	# 0.13+ (Juzo): people in the dark, each with a choice
	"give_potion": {"name": "Give a potion", "text": "Spend one potion. The pilgrim's blessing brings luck (better loot for 40 turns).", "color": "#f472b6"},
	"free_prisoner": {"name": "Break the chains", "text": "Their jailer won't like it (an Epic fight). Freed prisoners pay well.", "color": "#f59e0b"},
	"buy_bundle": {"name": "Buy the bundle", "text": "Pay the smuggler. Inside: anything from junk to a Legendary.", "color": "#a78bfa"},
	"hear_song": {"name": "Pay for a song", "text": "A song of your deeds: +50% XP for 40 turns.", "color": "#c084fc"},
	"follow_scout": {"name": "Follow the scout", "text": "A shortcut one floor down, and what the scout found on the way.", "color": "#4ade80"},
}

## A new event: an altar, a cursed chest, a gambler, a wishing well.
static func start_event(g: GameState) -> void:
	var kind: String = ["altar", "chest", "gambler", "well", "pilgrim", "prisoner", "smuggler", "bard", "scout"].pick_random()
	g.path_wait = 0
	match kind:
		"altar":
			g.path_offer = ["altar", "leave"]
			g.events.append({"type": "mini_event", "kind": "altar", "title": "BLOOD ALTAR", "sub": "Pay in blood for power"})
			g.say("[color=#e43b44]A blood altar hums in the dark.[/color]")
		"chest":
			g.path_offer = ["chest_open", "leave"]
			g.events.append({"type": "mini_event", "kind": "chest", "title": "A CURSED CHEST", "sub": "Great loot... and a curse?"})
			g.say("[color=#c084fc]A chest covered in warding runes.[/color]")
		"gambler":
			g.path_offer = ["bet", "leave"]
			g.events.append({"type": "mini_event", "kind": "gambler", "title": "THE GAMBLER", "sub": "Double or nothing?"})
			g.say("[color=#fbbf24]A grinning gambler flips a coin. \"Double or nothing, friend?\"[/color]")
		"well":
			g.path_offer = ["well", "leave"]
			g.events.append({"type": "mini_event", "kind": "well", "title": "AN OLD WELL", "sub": "Drink?"})
			g.say("[color=#2dd4bf]An old well, and something breathing at the bottom of it.[/color]")
		"pilgrim":
			g.path_offer = ["give_potion", "leave"] if g.potions > 0 else ["leave"]
			g.events.append({"type": "mini_event", "kind": "people", "title": "A LOST PILGRIM", "sub": "\"Please... a potion?\""})
			g.say("[color=#f472b6]A pilgrim sits by a guttering candle, too weak to go on.[/color]")
		"prisoner":
			g.path_offer = ["free_prisoner", "leave"]
			g.events.append({"type": "mini_event", "kind": "people", "title": "A PRISONER", "sub": "Chained to the wall, begging"})
			g.say("[color=#f59e0b]Someone is chained to the wall. Footsteps echo nearby: the jailer.[/color]")
		"smuggler":
			g.path_offer = ["buy_bundle", "leave"]
			g.events.append({"type": "mini_event", "kind": "people", "title": "A SMUGGLER", "sub": "\"No questions, no refunds.\""})
			g.say("[color=#a78bfa]A hooded smuggler pats a lumpy bundle. %d gold, take it or leave it.[/color]" % bundle_price(g))
		"bard":
			g.path_offer = ["hear_song", "leave"]
			g.events.append({"type": "mini_event", "kind": "people", "title": "A WANDERING BARD", "sub": "A song, for a coin?"})
			g.say("[color=#c084fc]A bard tunes a lute in the dark. \"A song of your deeds? %d gold.\"[/color]" % song_price(g))
		"scout":
			g.path_offer = ["follow_scout", "leave"]
			g.events.append({"type": "mini_event", "kind": "people", "title": "A WOUNDED SCOUT", "sub": "\"I know a way down.\""})
			g.say("[color=#4ade80]A wounded scout waves you over. \"There's a crack in the floor. Shortcut.\"[/color]")
	g.codex.bounty_progress("event")

## 0.13+ people events: prices sized to how deep you've been.
static func bundle_price(g: GameState) -> int:
	return g.price((20 + g.best_floor * 10) * 4)

static func song_price(g: GameState) -> int:
	return g.price((20 + g.best_floor * 10) * 2)

## Beat the jailer: the prisoner pays you back.
static func prisoner_reward(g: GameState) -> void:
	if not bool(g.cfight.get("prisoner", false)):
		return
	g.cfight["prisoner"] = false
	var gold := (10 + g.floor_num * 8) * 4
	g._add_gold(gold)
	g._faith(4.0)
	g.codex.add("prisoners_freed")
	g.say("[color=#4ade80]The prisoner is free.[/color] They press %d gold into your hands and vanish into the dark." % gold)
	g.events.append({"type": "mini_event", "kind": "people", "title": "FREED", "sub": "The prisoner thanks you (+%d gold)" % gold})

## How much gold the gambler wants.
static func bet_amount(g: GameState) -> int:
	return mini(g.gold, (20 + g.best_floor * 10) * 3)

## The answer to one of the new events.
static func choose(g: GameState, kind: String) -> void:
	var luck := g.luck_odds() / 100.0
	match kind:
		"give_potion":
			if g.potions > 0:
				g.potions -= 1
				g.luck_turns += 40
				g._faith(3.0)
				g.codex.add("pilgrims_helped")
				g.say("[color=#f472b6]The pilgrim drinks and blesses you.[/color] Luck is with you (better loot for 40 turns).")
				g.events.append({"type": "buff", "name": "Pilgrim's blessing"})
		"free_prisoner":
			g.spawn_enemy()
			g.horde_left = 0
			g.horde_pack = false
			g.enemy_name = "Jailer " + Monsters.name_of(g.enemy_species)
			g._apply_tier(maxi(g.enemy_tier, Monsters.EPIC))
			g.cfight["prisoner"] = true
			g.say("[color=#f59e0b]You break the chains. The jailer comes running![/color]")
		"buy_bundle":
			var bp := bundle_price(g)
			if g.gold < bp:
				g.say("The smuggler laughs at your empty purse.")
			else:
				g.gold -= bp
				var roll := randf() * 100.0
				var r := 0 if roll < 25.0 else (2 if roll < 60.0 else (3 if roll < 92.0 else GameData.LEGENDARY))
				var it := GameData.make_item(GameData.SLOT_ORDER.pick_random(), r, maxi(g.floor_num, g.best_floor), g._new_id())
				if r == GameData.LEGENDARY and not it.has("effect"):
					GameData.add_legendary_effect(it)
				g._give_item(it)
				g.codex.add("bundles")
				g.say(("[color=#f87171]Junk.[/color] The smuggler is long gone." if r == 0 else "[color=#a78bfa]Not bad.[/color] The bundle held %s." % GameData.display_name(it)))
		"hear_song":
			var sp := song_price(g)
			if g.gold < sp:
				g.say("The bard shrugs. \"No coin, no song.\"")
			else:
				g.gold -= sp
				g.song_xp_turns = 40
				g.say("[color=#c084fc]The bard sings of you, louder than you deserve.[/color] +50%% XP for 40 turns.")
				g.events.append({"type": "buff", "name": "A song of your deeds"})
		"follow_scout":
			var sg := (10 + g.floor_num * 6) * 2
			g._add_gold(sg)
			g._give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), 2, g.floor_num, g._new_id()))
			g._next_floor()
			g.fight = 1
			g.say("[color=#4ade80]You squeeze through the crack after the scout.[/color] One floor down, and they share what they found (+%d gold)." % sg)
		"altar":
			var cost := int(g.get_max_hp() * 0.2)
			g.hero_hp = maxi(1, g.hero_hp - cost)
			g.elixirs["altar"] = 40
			g.say("[color=#e43b44]You bleed on the altar.[/color] +30% Attack for 40 turns.")
			g.events.append({"type": "buff", "name": "Blood altar"})
			g._faith(-2.0)
		"chest_open":
			var r := maxi(2, g._rarity(25 + g._loot_bonus(), GameData.LEGENDARY_CHANCE_BOSS * 2.0))
			g._give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), r, g.floor_num, g._new_id()))
			if randf() < 0.5 - 0.3 * luck:
				g.elixirs["hexed"] = 40
				g.say("[color=#c084fc]The chest was cursed![/color] -20% Defense for 40 turns.")
				g.events.append({"type": "afflicted", "kind": "curse", "name": "Hexed", "color": "#c084fc"})
			else:
				g.say("[color=#4ade80]The wards were only for show.[/color]")
			g.events.append({"type": "treasure"})
		"bet":
			var amt := bet_amount(g)
			var odds := 0.45 + 0.15 * luck + 0.1 * g.dim("CHA", GameData.CHA_DISCOUNT) / 35.0
			if randf() < odds:
				g._add_gold(amt)
				g.say("[color=#4ade80]Heads! The gambler pays up.[/color] +%d gold" % amt)
				g.events.append({"type": "treasure"})
				g.codex.add("gambler_wins")
			else:
				g.gold -= amt
				g.say("[color=#f87171]Tails.[/color] The gambler pockets %d gold and tips his hat." % amt)
		"well":
			var roll := randf() + luck * 0.3
			if roll > 0.75:
				g.stat_points += 2
				g.say("[color=#2dd4bf]The well whispers a secret.[/color] +2 stat points!")
				g.events.append({"type": "buff", "name": "Blessing of the well"})
			elif roll > 0.35:
				g.hero_hp = g.get_max_hp()
				g.skill_cds.clear()
				g.say("[color=#2dd4bf]Cold, clean water.[/color] Fully healed, skills ready.")
				g.events.append({"type": "potion", "amount": g.get_max_hp()})
			else:
				Combat.afflict(g, "poison", 4)
				g.say("[color=#a3e635]The water was bad.[/color] You're poisoned.")
	g._check_codex()
	g.save_game()

# =====================================================================
# Opt-in curses: harder climbs, better loot
# =====================================================================

const CURSES := {
	"vigor": {"name": "Curse of Vigor", "text": "Monsters have +50% HP.", "loot": 12, "gold": 15},
	"fury": {"name": "Curse of Fury", "text": "Monsters hit 30% harder.", "loot": 12, "gold": 15},
	"thirst": {"name": "Curse of Thirst", "text": "Potions heal half as much.", "loot": 8, "gold": 10},
	"frailty": {"name": "Curse of Frailty", "text": "No regeneration of any kind.", "loot": 8, "gold": 10},
	"swarm": {"name": "Curse of the Swarm", "text": "More rare monsters, and they get an extra modifier.", "loot": 15, "gold": 20},
}
const CURSE_ORDER := ["vigor", "fury", "thirst", "frailty", "swarm"]
const CURSE_UNLOCK := 20   # best floor before you can take curses

static func curses_unlocked(g: GameState) -> bool:
	return g.best_floor >= CURSE_UNLOCK

static func has_curse(g: GameState, id: String) -> bool:
	return g.curses.has(id)

static func toggle_curse(g: GameState, id: String) -> void:
	if g.curses.has(id):
		g.curses.erase(id)
	else:
		g.curses[id] = true
	g.save_game()

static func curse_loot(g: GameState) -> int:
	var t := 0
	for id in g.curses:
		t += int(CURSES.get(id, {}).get("loot", 0))
	return t

static func curse_gold(g: GameState) -> float:
	var t := 0.0
	for id in g.curses:
		t += float(CURSES.get(id, {}).get("gold", 0))
	return t

# =====================================================================
# Companions: a pet that fights beside you and evolves with you.
# 0.12: only classes where a pet fits keep one (Ranger, Knight, Mage, Wanderer, Bard).
# =====================================================================

const PET_LEVEL := 5           # you meet your companion at this level
const PET_POWER := [0.12, 0.2, 0.3, 0.45]   # x your Attack every turn, by stage
const PETS := {
	"Knight": {"stages": ["Gryphon Chick", "Young Gryphon", "Gryphon", "Royal Gryphon"], "kind": "bird", "color": "#e8b14a", "perk": "guard", "text": "Guards you: blocks some damage each turn."},
	"Wanderer": {"stages": ["Spirit Fox", "Two-Tailed Fox", "Five-Tailed Fox", "Nine-Tailed Fox"], "kind": "fox", "color": "#fb923c", "perk": "fire", "text": "Fox fire: its attacks burn."},
	"Mage": {"stages": ["Spark Familiar", "Elemental Mote", "Elemental", "Primal Elemental"], "kind": "mote", "color": "#8b5cf6", "perk": "element", "text": "Hits with a random element, so it finds weaknesses."},
	"Ranger": {"stages": ["Hawk", "Falcon", "Storm Falcon", "Thunderbird"], "kind": "bird", "color": "#38bdf8", "perk": "first", "text": "Strikes first: it hits before you every new fight."},
	"Bard": {"stages": ["Songbird", "Nightingale", "Phoenix Chick", "Phoenix"], "kind": "bird", "color": "#f472b6", "perk": "song", "text": "Its song keeps a small Attack buff on you."},
}

static func pet_info(g: GameState) -> Dictionary:
	return PETS.get(g.hero_class, {})

static func pet_stage(g: GameState) -> int:
	if g.hero_class == "" or g.level < PET_LEVEL or not PETS.has(g.hero_class):
		return -1
	return clampi(g.class_path.size() + (1 if g.god_class != "" else 0), 0, 3)

static func pet_name(g: GameState) -> String:
	var st := pet_stage(g)
	if st < 0:
		return ""
	if g.pet_name != "":
		return g.pet_name
	return String(pet_info(g)["stages"][st])

static func pet_species(g: GameState) -> String:
	var st := pet_stage(g)
	return String(pet_info(g)["stages"][st]) if st >= 0 else ""

## Called on level ups and evolutions: meet or evolve your companion.
static func check_pet(g: GameState) -> void:
	var st := pet_stage(g)
	if st < 0 or not g.pet_on:
		return
	if st > g.pet_seen:
		var was := g.pet_seen
		g.pet_seen = st
		if was < 0:
			g.say("[color=%s]A %s starts following you![/color] It fights beside you and evolves when you do. %s" % [pet_info(g)["color"], pet_species(g), pet_info(g)["text"]])
			g.events.append({"type": "mini_event", "kind": "pet", "title": "A COMPANION!", "sub": "%s joins you" % pet_species(g)})
			g.tip("pet", "Your companion fights every turn and evolves at levels 15, 35 and 75 with you. Charisma makes it stronger. See it in Character > Party.")
		else:
			g.say("[color=%s]Your companion evolves into a %s![/color]" % [pet_info(g)["color"], pet_species(g)])
			g.events.append({"type": "mini_event", "kind": "pet", "title": "%s EVOLVES!" % pet_species(g).to_upper(), "sub": String(pet_info(g)["text"])})

## The pet's turn. Returns its damage (0 if it didn't attack).
static func pet_turn(g: GameState) -> int:
	var st := pet_stage(g)
	if st < 0 or not g.pet_on or g.enemy_hp <= 0:
		return 0
	var info := pet_info(g)
	var perk := String(info["perk"])
	var power := float(PET_POWER[st]) * g.party_mult()
	if perk == "heal":
		var h := int(g.get_max_hp() * (0.006 + 0.004 * st) * g.heal_mult())
		if g.hero_hp < g.get_max_hp() and h > 0:
			g.hero_hp = mini(g.get_max_hp(), g.hero_hp + h)
			g.events.append({"type": "heal", "amount": h})
		power *= 0.5
	var tags: Array = ["Physical"]
	if perk == "element":
		tags = [["Fire", "Frost", "Storm", "Arcane"].pick_random()]
		if not g.enemy_weak.is_empty() and randf() < 0.5:
			tags = [g.enemy_weak[0]]
	elif perk == "fire":
		tags = ["Fire"]
	g.last_hit = "hit"
	var d := g._damage_enemy(maxi(1, int(g.get_attack() * power)), tags)
	g.events.append({"type": "summon_hit", "dmg": d, "name": pet_name(g)})
	match perk:
		"bite":
			if st >= 3 and randf() < 0.1:
				g.enemy_stun = maxi(g.enemy_stun, 1)
		"fire":
			if g.burn_turns <= 0:
				g.burn_turns = 2
				g.burn_dmg = maxi(g.burn_dmg, int(g.get_attack() * 0.15 * (st + 1)))
				g.burn_tag = "Fire"
		"curse":
			g.enemy_curse = maxi(g.enemy_curse, 2)
		"steal":
			if randf() < 0.15:
				g._add_gold(int((2 + g.floor_num) * (1 + st)))
		"song":
			g.buffs["pet_song"] = {"atk": 1.04 + 0.02 * st, "turns": 2}
	return d

## Knight's gryphon: soaks part of each hit.
static func pet_guard(g: GameState) -> float:
	if pet_stage(g) < 0 or not g.pet_on or String(pet_info(g).get("perk", "")) != "guard":
		return 1.0
	return 1.0 - (0.05 + 0.03 * pet_stage(g))

## The Ranger's hawk hits before you, every new fight.
static func pet_first(g: GameState) -> bool:
	return pet_stage(g) >= 0 and g.pet_on and String(pet_info(g).get("perk", "")) == "first"

# =====================================================================
# The next goal: always something to chase
# =====================================================================

## {"text", "pct" (0..1 or -1), "color"} for the goal line under the fight.
const FIRST_DIVE_FLOORS := 3

## Until a new hero has made it home once: "clear 3 floors", then "head home".
## Only for new heroes (best floor under 15), so veterans never see the tutorial.
static func first_dive_goal(g: GameState) -> Dictionary:
	if g.in_town or g.best_floor >= 15 or g.codex.stat("home_trips") > 0:
		return {}
	var start := int(g.dive.get("floor", 1)) if not g.dive.is_empty() else 1
	var cleared := maxi(0, g.floor_num - start)
	if cleared < FIRST_DIVE_FLOORS:
		var left := FIRST_DIVE_FLOORS - cleared
		return {"text": "First dive: clear %d more floor%s, then head home with your loot" % [left, "" if left == 1 else "s"],
			"pct": float(cleared) / FIRST_DIVE_FLOORS, "color": UI.GOLD}
	return {"text": "Head home to keep what you found: tap Town (gold you carry is lost if you fall)", "pct": 1.0, "color": UI.GREEN}

static func next_goal(g: GameState) -> Dictionary:
	if g.hero_class == "":
		return {"text": "Choose your class", "pct": -1.0, "color": UI.GOLD}
	if ClassTree.pick_tier(g) >= 0:
		return {"text": "Your class can evolve! Choose in Character > Class", "pct": 1.0, "color": UI.GOLD}
	if not g.god_offers.is_empty():
		return {"text": "A God class answers you... see Character > Class", "pct": 1.0, "color": Color(ClassTree.RANK_COLORS["God"])}
	if g.stat_points >= GameData.STAT_POINTS_PER_LEVEL and not g.auto_stats:
		return {"text": "%d stat points to spend (Character > Hero)" % g.stat_points, "pct": -1.0, "color": UI.GOLD}
	if g.upgrade_count() > 0:
		return {"text": "Upgrades in your bag: Items > Gear > Equip Best", "pct": -1.0, "color": UI.GREEN}
	# The first dive teaches the whole game: go down, then get home to keep what you found
	var fd := first_dive_goal(g)
	if not fd.is_empty():
		return fd
	# What you lost when you fell, waiting with your killer
	var gv := Grave.goal(g)
	if not gv.is_empty():
		return gv
	var goals: Array = []
	# The next evolution
	var t := g.class_path.size()
	if g.god_class == "" and g.hidden_class == "" and t < ClassTree.PICK_LEVELS.size():
		var need := int(ClassTree.PICK_LEVELS[t])
		var prev := 1 if t == 0 else int(ClassTree.PICK_LEVELS[t - 1])
		var frac := (float(g.level - prev) + float(g.xp) / maxf(1.0, GameData.xp_to_next(g.level))) / maxf(1.0, need - prev)
		goals.append({"text": "Next evolution at level %d" % need, "pct": clampf(frac, 0.0, 0.999), "color": Color(g.class_info().get("color", "#e8b14a")), "w": 1.0})
	# (Branch-offs stay secret until they open, so they never show up as a goal)
	# The next boss
	var to_boss := 0
	for f in range(g.floor_num, g.floor_num + 26):
		if GameData.is_boss_floor(f):
			to_boss = f - g.floor_num
			if to_boss <= 5:
				goals.append({"text": "Boss on floor %d" % f if to_boss > 0 else "Boss fight!", "pct": -1.0, "color": UI.RED, "w": 3.0 - to_boss * 0.3})
			break
	# The next milestone
	for f in range(g.floor_num + 1, g.floor_num + 11):
		if is_milestone(f) and f > g.checkpoint:
			if f - g.floor_num <= 3:
				goals.append({"text": "Milestone chest on floor %d" % f, "pct": -1.0, "color": UI.GOLD, "w": 1.5})
			break
	# The special stat
	var sn := ClassTree.stat_name(g)
	if sn != "":
		goals.append({"text": "%s %.1f: grows when you %s" % [sn, g.unique_value(sn), ClassTree.grow_text(g)], "pct": g.unique_value(sn) / GameState.UNIQUE_CAP,
			"color": Color(ClassTree.RANK_COLORS[ClassTree.rank_of(ClassTree.unique_class(g))]), "w": 0.8})
	# Weapon mastery
	var wt := Mastery.weapon_type(g)
	var ml := Mastery.level(g, wt)
	if ml < Mastery.MAX_LEVEL:
		var k := Mastery.kills(g, wt)
		var lo := 0 if ml == 0 else int(Mastery.KILLS[ml - 1])
		var hi := int(Mastery.KILLS[ml])
		goals.append({"text": "%s mastery %d: %d / %d kills" % [Mastery.TYPES[wt]["name"], ml + 1, k, hi], "pct": float(k - lo) / maxf(1.0, hi - lo),
			"color": Color("#c0cbdc"), "w": 0.6})
	if goals.is_empty():
		return {"text": "Floor %d: deeper is better loot" % g.floor_num, "pct": -1.0, "color": UI.DIM}
	goals.sort_custom(func(a, b): return float(a["w"]) * (0.5 + maxf(0.0, float(a["pct"]))) > float(b["w"]) * (0.5 + maxf(0.0, float(b["pct"]))))
	return goals[0]

# =====================================================================
# Achievement power
# =====================================================================

const ACH_STEP := 10        # every 10 achievements...
const ACH_BONUS := 0.01     # ...+1% Attack, HP and gold, for every hero
const ACH_MAX := 10         # up to +10%

static func achievement_power(g: GameState) -> int:
	return mini(ACH_MAX, int(g.codex.achievements.size() / ACH_STEP))

static func achievement_bonus(g: GameState) -> Dictionary:
	var n := achievement_power(g)
	if n <= 0:
		return {}
	return {"atk": 1.0 + ACH_BONUS * n, "hp": 1.0 + ACH_BONUS * n, "gold_find": ACH_BONUS * n * 100.0}
