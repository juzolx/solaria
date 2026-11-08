class_name Calamity
extends RefCounted
## Calamities (0.12): the rarest encounter in the game. One per 100-floor
## region, each a named monster tuned far above the game's own endgame.
##  - When one appears you choose: fight, or try to run.
##  - Losing never counts as a death: you pass out (the screen goes black) and
##    wake on the same floor with everything you had.
##  - Killing one is forever. It gives a gear piece for every slot (Mythic and
##    Soulbound; one Unique Mythic that is Account-bound), its pet, a title and
##    max friendliness with every race.
## Online (later) the server decides "gone for everyone", the Hall of Fame and
## the 365-day challenge. Until then a kill is recorded on this account only.

const CHANCE := 0.005          # % per fight (about 1 in 20,000)
const RUN_CHANCE := 50.0       # % to get away when you choose to run
const POWER_FLOOR := 2000      # tuned like a floor this deep...
const HP_MULT := 60.0          # ...and far tougher than its bosses
const ATK_MULT := 12.0
const CAP := 1.0e17            # QA r2 #20: HP and Attack (always reached), far enough under the int64 edge for any multiplier
const ITEM_FLOOR := 2000       # its gear is made as if from this floor

## [name, art, color, lore, title, pet, unique item slot, unique item name]
## The art key (calamity_0...) is also the calamity's permanent id; its pet's id is
## that plus "_pet" (pet_id()). Names are only for showing.
const LIST := [
	["The Hollow Saint", "calamity_0", "#e2e8f0", "It walked out of a church that was never built, wearing the bones of everyone who prayed there.", "Saintbreaker", "Hollow Acolyte", "Weapon", "The Last Rite"],
	["Ashmaw, the Burning Hunger", "calamity_1", "#f97316", "It has eaten seven kingdoms. It is still hungry.", "Ashwalker", "Ember Whelp", "Chest", "Heart of the Hunger"],
	["Nidhogg, Root-Gnawer", "calamity_2", "#65a30d", "It chews at the roots of the world. One day it will finish.", "Rootkeeper", "Root Grub", "Off Hand", "The Gnawed Root"],
	["The Pale Tide", "calamity_3", "#7dd3fc", "When the water goes out and doesn't come back, it is already here.", "Tidebreaker", "Drowned Pup", "Helmet", "Crown of the Low Tide"],
	["Morrowgrave", "calamity_4", "#a78bfa", "It rides tomorrow's dead to today's funerals.", "Gravewarden", "Morrow Foal", "Legs", "Tomorrow's Shroud"],
	["The Thousand-Eyed", "calamity_5", "#fde047", "Every eye has seen you die. Most of them twice.", "Unseen", "Blinking Mote", "Helmet", "The Last Eye"],
	["Skorvald, the Endless Winter", "calamity_6", "#bae6fd", "Spring was a rumor it ate.", "Thawbringer", "Frostling", "Feet", "Treads of the Long Thaw"],
	["The Weeping Colossus", "calamity_7", "#94a3b8", "It cries molten stone for the city it was built to guard.", "Colossus-Felled", "Pebble Golem", "Off Hand", "The Last Tear"],
	["Vhal'gor, Eater of Stars", "calamity_8", "#c084fc", "There were more stars once.", "Starkeeper", "Star Wyrmling", "Weapon", "Vhal'gor's Fang"],
	["The Last Night", "calamity_9", "#1e1b4b", "Every night is shorter than the one before it. This one is not.", "Dawnbringer", "Nightling", "Chest", "The Final Dawn"],
]

## The permanent species id of a calamity's pet.
static func pet_id(c: Array) -> String:
	return String(c[1]) + "_pet"

static func region_index(f: int) -> int:
	return clampi(GameData.region_of(f) - 1, 0, LIST.size() - 1)

static func info(i: int) -> Array:
	return LIST[clampi(i, 0, LIST.size() - 1)]

## Slain ones never come back (on this account, until the server owns it).
static func slain(p: Profile, i: int) -> bool:
	return p != null and p.calamities.has(str(i))

## Called after a normal monster spawns. Rarely turns it into this region's Calamity.
static func maybe_appear(g: GameState, p: Profile, force := false) -> bool:
	if not force:
		if g.enemy_is_boss or g.enemy_goblin or g.horde_left > 0 or g.trial_active or g.in_town:
			return false
		if randf() * 100.0 >= CHANCE:
			return false
	var i := region_index(g.floor_num)
	if slain(p, i):
		return false
	appear(g, i)
	return true

static func appear(g: GameState, i: int) -> void:
	var c := info(i)
	g.enemy_is_boss = false
	g.enemy_boss_kind = ""
	g.enemy_goblin = false
	g.horde_left = 0
	g.enemy_champion = false
	g.enemy_illusion = false
	g._setup_fight()
	g.enemy_weak = []
	g.enemy_resist = []
	g.enemy_calamity = i + 1
	g.calamity_pending = true
	g.enemy_name = String(c[0])
	g.enemy_species = String(c[1])
	g.enemy_art = String(c[1])
	g.enemy_color = String(c[2])
	g.enemy_people = ""
	g.enemy_tier = 5
	g.enemy_mods = []
	g.enemy_shield = 0
	var growth := pow(GameData.ENEMY_GROWTH, POWER_FLOOR - 1)  # on purpose the old flat curve: Calamities stay near-unkillable (banded growth would be ~1e10x weaker)
	var hp := (15.0 + POWER_FLOOR * 15.0) * growth * GameData.ZONE_BOSS_HP * HP_MULT
	g.enemy_max_hp = int(minf(hp, CAP))
	g.enemy_hp = g.enemy_max_hp
	g.enemy_base_hp = g.enemy_max_hp
	# Insta-kill strength: one blow takes a whole hero, whatever their gear
	var atk := (3.0 + POWER_FLOOR * 2.0) * growth * GameData.BOSS_ATK * ATK_MULT
	g.enemy_attack = int(minf(maxf(atk, g.get_max_hp() * 4.0), CAP))
	g.enemy_base_atk = g.enemy_attack
	g.events.append({"type": "calamity", "id": i, "name": String(c[0]), "lore": String(c[3]), "color": String(c[2])})
	g.say("[color=#e43b44]*** A CALAMITY APPROACHES ***[/color] %s." % c[0])
	g.codex.meet(String(c[1]))

## You chose to fight: the fight goes on.
static func fight(g: GameState) -> void:
	g.calamity_pending = false
	g.say("[color=#e43b44]You stand your ground against %s.[/color]" % g.enemy_name)

## You chose to run. Returns true if you got away; otherwise it catches you.
static func run(g: GameState) -> bool:
	g.calamity_pending = false
	if randf() * 100.0 < RUN_CHANCE:
		g.say("[color=#a3e635]You run, and you don't look back. %s lets you go... this time.[/color]" % g.enemy_name)
		g.enemy_calamity = 0
		g.events.append({"type": "escaped"})
		if Portals.kind(g) == "rift":
			Rifts._next(g)  # QA r2 #21: the rift goes on with its own monster
		else:
			g.spawn_enemy()
		g.save_game()
		return true
	g.say("[color=#f87171]You run. It is already in front of you.[/color]")
	knockout(g)
	return false

## The Calamity wins: you pass out. Never a death; nothing is lost.
static func knockout(g: GameState) -> void:
	var name := g.enemy_name
	g.enemy_calamity = 0
	g.calamity_pending = false
	g.leader_down = false
	g.hero_hp = g.get_max_hp()
	g.buffs.clear()
	g.shield_hp = 0
	g.summon_turns = 0
	g.enemy_stun = 0
	g.enemy_weaken_turns = 0
	if g.party != null:
		g.party.on_wipe()
	g.feats["calamity_knockouts"] = int(g.feats.get("calamity_knockouts", 0)) + 1
	g.events.append({"type": "blackout", "name": name})
	g.say("[color=#94a3b8]Everything goes black.[/color] You wake up on floor %d. %s is gone, and somehow you still have everything you carried. (It doesn't count as a death.)" % [g.floor_num, name])
	g.fight = 1
	g.spawn_enemy()
	g.save_game()

## You killed it. Forever.
static func on_slain(g: GameState, p: Profile) -> void:
	var i := g.enemy_calamity - 1
	if i < 0:
		return
	var c := info(i)
	g.enemy_calamity = 0
	var who := g.hero_name if g.hero_name != "" else g.hero_class
	var today := Time.get_date_string_from_system()
	Trophies.on_calamity(g, i, String(c[0]))  # 2.1: the Trophy Cabin (before the profile saves)
	if p != null:
		p.calamities[str(i)] = {"hero": who, "slot": g.slot, "date": today}
		p.save()
	# Its gear: one piece per slot, all Mythic and Soulbound; one is the Unique Mythic
	var items: Array = []
	for slot in GameData.SLOT_ORDER:
		var unique: bool = String(slot) == String(c[6])
		var it := GameData.make_item(String(slot), GameData.UNIQUE_MYTHIC if unique else GameData.MYTHIC, ITEM_FLOOR, g._new_id())
		it["bound"] = "account" if unique else "soul"
		if unique:
			GameData.add_legendary_effect(it)
			it["effect2"] = it["effect"]
			it["effect2_value"] = int(it["effect_value"])
			GameData.add_legendary_effect(it)
		it["calamity"] = i
		it["name"] = String(c[7]) if unique else "%s's %s" % [String(c[0]).split(",")[0], slot]
		it["history"] = [{"who": who, "what": "slew %s" % c[0], "date": today}]
		if unique:
			it["registered"] = who
		items.append(it)
	Mail.post(g, String(c[0]), "You slew %s" % c[0], "It is gone, forever. What was left of it is yours: a piece for every slot, made from the beast itself. They can never be lost. One of them holds your place in the Hall of Fame.", {"items": items})
	Menagerie.make_pet(g, pet_id(c), String(c[1]), 5, "calamity")
	if not String(c[4]) in g.codex.extra_titles:
		g.codex.extra_titles.append(String(c[4]))
	g.codex.title = String(c[4])
	g.codex.save()
	for race in Races.ORDER:
		Lineage.change_rep(g, race, Races.REP_MAX * 2.0, false)
	g.feats["calamities_slain"] = int(g.feats.get("calamities_slain", 0)) + 1
	g.events.append({"type": "mini_event", "kind": "milestone", "title": "CALAMITY SLAIN", "sub": "%s is gone forever" % c[0]})
	g.say("[color=#fbbf24]*** %s IS SLAIN ***[/color] It will never appear again. Its gear waits in your Mailbox, a %s follows you home, every race now honors you, and you carry the title \"%s\"." % [String(c[0]).to_upper(), c[5], c[4]])
