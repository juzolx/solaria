class_name GameState
extends RefCounted
## Everything that happens in the game: combat, loot, bag, gold, shop,
## crafting and saving. No UI code lives here.

const SAVE_PATH := "user://save.dat"
const BACKUP_PATH := "user://save.bak"
const TEMP_PATH := "user://save.tmp"
const HC_SAVE_PATH := "user://save_hc.dat"
const HC_BACKUP_PATH := "user://save_hc.bak"
const HC_TEMP_PATH := "user://save_hc.tmp"
const SLOT_PATH := "user://hero_%d.dat"   # one save per hero slot (1-3)
const SLOT_BACKUP := "user://hero_%d.bak"
const SLOT_TEMP := "user://hero_%d.tmp"
const BASE_ATTACK := 10
const BASE_HP := 100
const UNIQUE_CAP := 300.0   # special stats from actions: they slow down near this
const UNIQUE_SOFT := 300.0

# ---------- Mode ----------
var hardcore := false   # Hardcore hero: separate save, deleted when it dies
var run_over := false   # a Hardcore hero that just died
var needs_creator := false  # older saves pick a look and race once

# ---------- Progress ----------
var autosave := true  # tests turn this off so simulations run fast
var floor_num := 1
var fight := 1
var best_floor := 1
var hero_hp := BASE_HP

# ---------- Hero ----------
var hero_class := ""  # one of Classes.ORDER ("" until picked)
var in_town := false     # in town (town.gd): no fighting until you leave
var contracts: Array = []  # Bounty Board contracts, posted and taken (town.gd)
var board_day := ""
var mail: Array = []      # the Mailbox: letters holding rewards (mail.gd)
var shop_zone := -1      # the zone the shop's wares came from (they follow where you are)
var level := 1
var xp := 0
var auto_ability := true
var burn_turns := 0     # Mage Fireball burn
var burn_dmg := 0
var burn_tag := "Fire"  # the element the burn carries (Blood skills make it bleed)
var pierce_carry := 0   # Archer Piercing Shot overkill, hits the next enemy
var stats := {"STR": 0, "VIT": 0, "AGI": 0, "DEX": 0, "INT": 0, "WIS": 0, "LUK": 0, "CHA": 0}
var stat_points := 0    # unspent points
var auto_stats := false # spend new points on your class's recommended build by itself
var respec_tomes := 0   # Tomes of Forgetting: a free respec each
var builds: Array = [{}, {}, {}]  # saved builds: stats, skills and gear
# ---------- Skills (ability stones) ----------
var skill_book := {}    # skill id -> rank (1-5): every skill you own
var dust := 0           # from stones of maxed skills; crafts any skill
var active_slots: Array = ["", "", ""]          # equipped active skills
var passive_slots: Array = ["", "", "", "", ""] # equipped passive skills
var skill_cds := {}     # skill id -> turns until ready
var sig_slot := ""      # the signature skill in the 4th slot (signatures.gd)
var stones_since := 0   # kills since the last stone (pity)
var buffs := {}         # skill id -> {"atk"/"def" multipliers, "crit"/"dodge" adds, "turns"}
var shield_hp := 0      # soaks damage first
var summon_turns := 0   # a helper (skeleton, wolf) hits every turn
var summon_power := 0.0
var summon_name := ""
var song_turns := 0     # healing over time
var song_regen := 0.0
var confuse_turns := 0  # the monster hits itself
# ---------- Paths (the Evolution Tree: rules in class_tree.gd) ----------
var faith := 0.0        # -100 evil .. +100 good: decides which classes you may take
var class_path: Array[String] = []  # the classes you picked at levels 15, 35 and 60 (node ids)
var class_branch := ""  # a branch-off unique class you took (ends the tree)
var class_items: Array[String] = []  # the Wanderer's special items
var class_auto := false # pick classes automatically (simulations)
var class_encounter := ""  # a Wanderer item encounter waiting for your answer
var class_told := -1    # the last pick tier we told you about
var ctrack := {}        # what you've done, for branch-offs (counters)
var cfight := {}        # notes about the current fight
var unique := {}        # special stats from actions (unique and hidden classes)
var trial_active := false
var trial_return := 1   # floor to go back to after a trial
var kill_streak := 0    # kills without drinking a potion
# ---------- Party ----------
var party_slots: Array = []  # hero slots fighting with you (Regular heroes only)
# Lineage: race power and awakening, transformations, reputation (rules in lineage.gd)
var race_power := 0.0       # racial power from actions
var race_power_points := 0  # stat points put into racial power (0.1 each)
var awaken := 0             # awakening rank (0 = not awakened)
var race_keys: Array[String] = []  # key items held (awakening keys, Phylactery, Silver Moonbloom)
var form := ""              # "", "Vampire", "Werewolf", "Fallen Angel", "Lich"
var lycan_pending := false  # bitten by a werewolf: turns at the next full moon
var cure_active := false
var cure_kills := 0
var phylactery_used := false  # Lich: the once-per-floor save
var rep := {}               # race -> standing, -100..100
var feats := {}             # counters for hidden-class unlocks
var realm_order: Array = [] # the realms in the order you chose them
var hidden := {}            # hidden classes unlocked: id -> true
var hidden_class := ""      # the hidden class you're using ("" = none)
var hidden_stage := {}      # id -> stage reached (1..3)
var trial_kind := "god"     # what the current trial is for: god, race, cure, hidden
var encounter := {}         # someone you met on the road (realms)
var quest := {}             # the camp quest board's current job
var merchant_who := ""      # "" = the wandering merchant, otherwise a race's merchant
var trial_data := {}
var party: Party = null      # loaded companions (main sets this up)
var enemy_stun := 0     # Earthshatter
var enemy_weaken := 1.0 # Frost Nova
var enemy_weaken_turns := 0
var materials := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]  # boss materials, one per zone and realm
var appearance := {"body": "masc", "skin": 1, "hair": "Short", "hair_color": 1, "eyes": 0, "race": "Human"}
var wardrobe := {}      # every look you've found: key -> look (for transmog)
var transmog := {}      # slot -> look to show instead of the real item ("hide" = show nothing)
var discovered := {}    # class names you've reached (specs and evolutions show ??? until then)
var dev_mode := false
var volume := 0.8       # sound effects volume, 0..1
var music_volume := 0.5 # music volume, 0..1
var fullscreen := false
var restored_backup := false  # true if the main save was damaged and the backup was used
var _upgrade_key := ""
var _upgrade_cache := {}

# ---------- Resources ----------
var gold := 0
var scrap := 0
var potions := GameData.START_POTIONS
var bag_level := 0
var next_id := 1

# ---------- Settings ----------
var auto_potion := true
var autoplay := true      # the fight runs by itself; off = you take every turn (Attack / tap the enemy)
var auto_paths := true    # forks pick a room by themselves after a few turns
var auto_salvage := -1  # -1 = off, otherwise salvage new drops of this rarity and below
var fast_mode := false
var tips_seen := {}  # tips already shown once
var bosses_since_unique := 0  # pity counter: raises the unique chance
var sound_on := true

# ---------- Items ----------
var bag: Array[Dictionary] = []
var equipped := {}  # slot name -> item
var shop: Array[Dictionary] = []
var featured := {}      # the shop's featured deal (Epic or better)
var elixirs := {}       # active elixir id -> turns left
var path_offer: Array = []  # room choices waiting for you ("fight", "treasure", "rest", "elite")
var path_rooms_on := true   # off = never offer room choices
var enemy_elite := false
var path_wait := 0
var path_hold := false  # "Wait for me": the fork doesn't pick by itself

# ---------- Current enemy ----------
var enemy_name := ""
var enemy_hp := 0
var enemy_max_hp := 0
var enemy_attack := 0
var enemy_is_boss := false
var enemy_shape := "humanoid"
var enemy_color := "#ffffff"
var enemy_species := ""     # the creature's plain name ("Kobold"), for the Bestiary and loot
var enemy_art := ""         # sprite key in art/enemies/
var enemy_tier := 0         # Monsters.TIERS: 0 Common .. 5 Mythic
var enemy_mods: Array = []  # Monsters.MODS names
var enemy_shield := 0       # Shielded: soaks damage first
var enemy_base_hp := 0      # before tier multipliers (so a tier can be re-applied)
var enemy_base_atk := 0
var enemy_boss_kind := ""   # "mid", "zone" or ""
var enemy_goblin := false   # the treasure goblin: doesn't fight back, runs away
var enemy_people := ""      # the race this monster belongs to (realm natives), or ""
var enemy_illusion := false # Glimmer Court: only an illusion
var last_hit := ""          # what dealt the last blow: "hit", "skill", "burn"
var enemy_weak: Array = []    # elements it takes extra damage from (combat.gd)
var enemy_resist: Array = []  # elements it shrugs off
var enemy_chill := 0          # status effects on the monster (turns left)
var enemy_frozen := 0
var enemy_curse := 0
var enemy_poison_turns := 0
var enemy_poison_dmg := 0
var boss_mechanics: Array = []  # "shield", "enrage", "minions", "breath"
var boss_phase := {}
var boss_minions := 0
var minion_hp := 0
var hero_status := {}         # statuses on you: "poison" / "burn" / "chill" -> turns left
var last_death := {}          # the death recap (combat.gd)
var enemy_champion := false   # a milestone floor's Champion (world.gd)
var checkpoint := 0           # the highest milestone floor beaten: you never fall below it
var curses := {}              # opt-in curses: id -> true (world.gd)
var pet_on := true            # your companion fights with you
var pet_name := ""            # "" = its species name
var pet_seen := -1            # the companion stage we've told you about
var auto_potion_at := 0.3     # auto-potion when HP drops below this
var skill_priority: Array = []  # active skills in the order Auto should use them
var skill_auto_off := {}      # active skills Auto never uses (you press them yourself)
var goblin_turns := 0

# ---------- Zones, events and the codex ----------
var hero_name := ""
var slot := 1               # which hero save slot (1-3)
var boss_ready_at := {}     # boss floor (as text) -> unix time it can be fought again by travel
var floors_since_event := 0
var deaths_here := 0        # deaths in a row on this floor (3 = step back a floor to get stronger)
var horde_left := 0         # monster horde: fights left
var horde_total := 0
var curse_turns := 0        # cursed shrine: tougher monsters, better loot
var luck_turns := 0         # Scroll of Luck
var hunt_spawns := 0        # Hunter's Scroll: next monsters are more often rare
var merchant: Array = []    # the wandering merchant's stock while you're with them
var loadouts: Array = [{}, {}, {}]  # saved gear sets: slot -> item id
var loot_filter := {"slots": {}, "weaker": false}  # extra auto-salvage rules (Common-Rare only)
var codex := Codex.new()    # account-wide bestiary, stats, achievements (main swaps in the saved one)
var stash_ok := false       # Regular heroes can use the shared stash
var dev_always_win := false # Dev Mode: the wheel always wins

# ---------- For the UI ----------
var messages: Array[String] = []  # new combat log lines, read by the UI
var events: Array[Dictionary] = []  # what just happened, for the battle animations
var bag_version := 0   # goes up whenever the bag list changes
var shop_version := 0  # goes up whenever the shop stock changes

# =====================================================================
# Stats
# =====================================================================

func stat_total(stat: String) -> int:
	var total := 0
	for slot in equipped:
		var item: Dictionary = equipped[slot]
		if item["stat"] == stat:
			total += GameData.item_power(item)
	return total

func class_info() -> Dictionary:
	return Classes.info(hero_class)

func _class_mult(key: String) -> float:
	return float(class_info().get(key, 1.0))

## Active buffs from skills: multipliers (atk, def) multiply, the rest add up.
func _buff(key: String, default: float) -> float:
	var v := default
	for id in buffs:
		var b: Dictionary = buffs[id]
		if b.has(key):
			v = v * float(b[key]) if default == 1.0 else v + float(b[key])
	return v

func get_attack() -> int:
	var base := BASE_ATTACK + (level - 1) * GameData.LEVEL_ATTACK + stat("STR") * GameData.STR_ATTACK + stat_total("Attack")
	var chill := Combat.HERO_CHILL_ATK if hero_status.has("chill") else 1.0
	return int(base * _class_mult("atk") * _mult("atk") * _buff("atk", 1.0) * _elixir("atk", 1.0) * _mastery() * chill)

func get_defense() -> int:
	var base := (level - 1) * GameData.LEVEL_DEFENSE + stat("VIT") * GameData.VIT_DEFENSE + stat_total("Defense")
	return int(base * _class_mult("def") * _mult("def") * _buff("def", 1.0) * _elixir("def", 1.0) * _mastery())

func get_max_hp() -> int:
	var base := BASE_HP + (level - 1) * GameData.LEVEL_HP + stat("STR") * GameData.STR_HP + stat("VIT") * GameData.VIT_HP + stat_total("HP")
	return int(base * _class_mult("hp") * _mult("hp") * _mastery())

## Every level makes you a little stronger all round.
func _mastery() -> float:
	return 1.0 + (level - 1) * GameData.LEVEL_MASTERY

# =====================================================================
# Stats and specializations
# =====================================================================

func _elixir(key: String, default: float) -> float:
	var v := default
	for id in elixirs:
		var info: Dictionary = GameData.ELIXIRS[id]
		if info.has(key):
			v = v * float(info[key]) if default == 1.0 else v + float(info[key])
	return v

## A stat's total: your points, plus your race and form.
func stat(stat_name: String) -> int:
	return int(stats.get(stat_name, 0)) + bonus_stat(stat_name)

## The part of a stat that comes from your race and form (not from points).
func bonus_stat(stat_name: String) -> int:
	var v := int(race_info()["stats"].get(stat_name, 0))
	if form != "":
		v += int(Races.FORMS[form].get("stats", {}).get(stat_name, 0))
	return v

## A stat's diminishing-returns value (see GameData.diminishing).
func dim(stat_name: String, curve: Array) -> float:
	return GameData.diminishing(stat(stat_name), curve)

# ---------- What the stats do ----------

## Crits do 2x, plus Luck and any crit damage bonuses.
func crit_mult() -> float:
	return 2.0 + dim("LUK", GameData.LUK_CRIT_DMG) / 100.0 + _flat("crit_dmg") / 100.0

## Heals, potions and songs are this much stronger (Wisdom).
func heal_mult() -> float:
	return 1.0 + (dim("WIS", GameData.WIS_HEAL) + _flat("heal")) / 100.0

## Burns, poison, chill and curses on you do this much (Wisdom lowers it).
func status_mult() -> float:
	return clampf(1.0 - (dim("WIS", GameData.WIS_RESIST) + _flat("resist")) / 100.0, 0.2, 1.0)

## Chance (%) of an extra attack each turn (Agility).
func haste_chance() -> float:
	if World.hazard(self) == "flood":
		return 0.0
	return dim("AGI", GameData.AGI_HASTE) + _flat("haste")

## Chance (%) to strike first when a fight starts (Agility).
func first_strike_chance() -> float:
	return dim("AGI", GameData.AGI_FIRST) + _flat("first")

## Extra odds (%) of events, encounters and signature drops (Luck).
func luck_odds() -> float:
	return dim("LUK", GameData.LUK_EVENTS)

## Shop and merchant price after your Charisma discount.
func price(base: int) -> int:
	return maxi(1, int(round(base * (1.0 - dim("CHA", GameData.CHA_DISCOUNT) / 100.0))))

## What an item sells for (Charisma gets better prices).
func sell_price(item: Dictionary) -> int:
	return int(GameData.sell_value(item) * (1.0 + dim("CHA", GameData.CHA_SELL) / 100.0))

## Chance (%) a monster is charmed and skips its attack (Charisma and charm classes).
func charm_total() -> float:
	return dim("CHA", GameData.CHA_CHARM) + ClassTree.charm_chance(self) + _flat("charm")

## Companions hit this much harder (Charisma).
func party_mult() -> float:
	return 1.0 + dim("CHA", GameData.CHA_PARTY) / 100.0

func race() -> String:
	var r: String = appearance.get("race", "Human")
	return r if GameData.RACE_INFO.has(r) else "Human"

func race_info() -> Dictionary:
	return GameData.RACE_INFO[race()]

## The stat your specialization is based on: your highest, ties go to your class's natural stat.
func spec_stat() -> String:
	if hero_class == "":
		return ""
	var order: Array = Classes.stat_order(hero_class)
	var best: String = order[0]
	for st in order:
		if stat(st) > stat(best):
			best = st
	return best

# ---------- Paths: faith, the Wanderer's two roads, Mage schools ----------

## Special stats this hero has (only special classes get them).
func unique_stats() -> Array:
	var out: Array = []
	var c := ClassTree.stat_name(self)
	if c != "":
		out.append(c)
	var h := Hidden.stat_name(self)
	if h != "":
		out.append(h)
	return out

## A special stat's strength. It only grows from actions, and slows down as it gets
## high (UNIQUE_SOFT points is about 63% of the way to the cap).
func unique_value(n: String) -> float:
	var raw := float(unique.get(n, 0.0))
	return UNIQUE_CAP * (1.0 - exp(-raw / UNIQUE_SOFT))

func _grow_unique(n: String, amount: float) -> void:
	if not n in unique_stats() or amount <= 0.0:
		return
	unique[n] = float(unique.get(n, 0.0)) + amount

## Good vs Evil. Every hero has it: it decides which classes you can take.
func _faith(amount: float) -> void:
	faith = clampf(faith + amount, -100.0, 100.0)
	Lineage.gain(self, "good" if amount > 0.0 else "evil", absf(amount))
	Lineage.on_faith(self)

## Your most-used skill tag (equipped skills, weighted by rank; actives count double).
func top_tag() -> String:
	var counts := {}
	for id in active_slots:
		if id != "":
			for t in SkillData.info(id).get("tags", []):
				counts[t] = float(counts.get(t, 0.0)) + 2.0 * skill_rank(id)
	for id in passive_slots:
		if id != "":
			for t in SkillData.info(id).get("tags", []):
				counts[t] = float(counts.get(t, 0.0)) + skill_rank(id)
	var cls_tags: Array = class_info().get("tags", ["Blade"])
	var best: String = cls_tags[0]
	for t in counts:
		if float(counts[t]) > float(counts.get(best, 0.0)):
			best = t
	return best

## Your class name: the last class on your path (or your branch-off).
func title() -> String:
	return ClassTree.title(self)

## Specializations and evolutions stay hidden until you reach them (or Dev Mode is on).
func is_discovered(class_title: String) -> bool:
	return dev_mode or discovered.has(class_title)

## Passive skills as bonus dicts (atk/hp/def/skill become multipliers).
func _passive_sources() -> Array:
	var out: Array = []
	for i in passive_slot_count():
		var id: String = passive_slots[i]
		if id == "" or not skill_book.has(id):
			continue
		var s := SkillData.info(id)
		var r := skill_rank(id)
		var d := {}
		for k in s:
			if k in ["atk", "hp", "def", "skill"]:
				d[k] = 1.0 + float(s[k]) * r
			elif k in ["crit", "dodge", "lifesteal", "regen", "thorns", "gold_find", "double_strike", "cdr", "xp", "stone_find", "boss", "execute", "rage", "potion"]:
				d[k] = float(s[k]) * r
		out.append(d)
	return out

## All active passive bonuses: race, specialization, evolution, sets, passive skills, special stats.
func _bonus_sources() -> Array:
	var out: Array = []
	if form == "" or not Races.FORMS[form].get("replaces", false):
		out.append(race_info()["passive"])
	out.append_array(Lineage.bonus_sources(self))
	out.append_array(Hidden.bonus_sources(self))
	out.append_array(ClassTree.bonus_sources(self))
	out.append_array(set_bonuses())
	out.append_array(_passive_sources())
	var mb := Mastery.bonus(self)
	if not mb.is_empty():
		out.append(mb)
	var ab := World.achievement_bonus(self)
	if not ab.is_empty():
		out.append(ab)
	return out

## Multiplier bonuses (atk, hp, def, skill) multiply together.
func _mult(key: String) -> float:
	var m := 1.0
	for d in _bonus_sources():
		m *= float(d.get(key, 1.0))
	return m

## Effect bonuses (crit, dodge, lifesteal...) add up.
func _flat(key: String) -> float:
	var t := 0.0
	for d in _bonus_sources():
		t += float(d.get(key, 0.0))
	if key in GameData.ITEM_BONUS_EFFECTS:
		for slot in equipped:
			if equipped[slot].get("effect", "") == key:
				t += float(equipped[slot]["effect_value"])
			if equipped[slot].get("effect2", "") == key:
				t += float(equipped[slot].get("effect2_value", 0))
	return t

## Extra power for a skill from its tags: class affinity, spec/evolution, passive skills.
func tag_power(tags: Array) -> float:
	var p := 0.0
	var rtp: Dictionary = race_info().get("tag_power", {})
	for t in tags:
		p += float(rtp.get(t, 0.0))
	var cls_tags: Array = class_info().get("tags", [])
	for t in tags:
		if t in cls_tags:
			p += Classes.AFFINITY_POWER
			break
	if "Song" in tags:
		p += dim("CHA", GameData.CHA_SONG) / 100.0
	for b in set_bonuses():
		var tg: Dictionary = b.get("tag", {})
		for t in tags:
			p += float(tg.get(t, 0.0))
	p += World.hazard_tag_power(self, tags)
	p += ClassTree.tag_power(self, tags)
	for i in passive_slot_count():
		var id: String = passive_slots[i]
		if id == "" or not skill_book.has(id):
			continue
		var tg: Dictionary = SkillData.info(id).get("tag", {})
		for t in tags:
			p += float(tg.get(t, 0.0)) * skill_rank(id)
	return p

# ---------- Sets ----------

func set_counts() -> Dictionary:
	var counts := {}
	for slot in equipped:
		var set_name: String = equipped[slot].get("set", "")
		if set_name != "":
			counts[set_name] = int(counts.get(set_name, 0)) + 1
	return counts

func set_bonuses() -> Array:
	var out := []
	var counts := set_counts()
	for set_name in counts:
		var info: Dictionary = GameData.set_info(set_name)
		if info.is_empty():
			continue
		if counts[set_name] >= 2:
			out.append(info["bonus2"])
		if counts[set_name] >= 3:
			out.append(info["bonus3"])
	return out

# ---------- Skill book (ability stones) ----------

func skill_rank(id: String) -> int:
	if Signatures.is_signature(id):
		return Signatures.rank(id) if id in Signatures.owned(self) else 0
	return int(skill_book.get(id, 0))

func active_slot_count() -> int:
	var n := 0
	for need in SkillData.ACTIVE_SLOTS_AT:
		if level >= int(need):
			n += 1
	return n

func passive_slot_count() -> int:
	var n := 0
	for need in SkillData.PASSIVE_SLOTS_AT:
		if level >= int(need):
			n += 1
	return n

## Active skills you can use right now (in unlocked slots).
func equipped_actives() -> Array:
	var out: Array = []
	for i in active_slot_count():
		if active_slots[i] != "" and skill_book.has(active_slots[i]):
			out.append(active_slots[i])
	if sig_slot != "" and sig_slot in Signatures.owned(self):
		out.append(sig_slot)
	return out

## Puts one of your signature skills in the signature slot.
func set_signature(id: String) -> void:
	if id in Signatures.owned(self):
		sig_slot = id
		save_game()

func is_skill_equipped(id: String) -> bool:
	return id in active_slots or id in passive_slots

## Puts a skill in a slot (slot -1 = the first open one). Returns false if there's no room.
func equip_skill(id: String, slot := -1) -> bool:
	if not skill_book.has(id):
		return false
	var active := SkillData.is_active(id)
	var slots: Array = active_slots if active else passive_slots
	var open := active_slot_count() if active else passive_slot_count()
	if slot < 0:
		if id in slots:
			return true
		for i in open:
			if slots[i] == "":
				slot = i
				break
		if slot < 0:
			say("All your %s skill slots are full. Unequip one first." % ("active" if active else "passive"))
			return false
	if slot >= open:
		return false
	var old_at := slots.find(id)
	if old_at >= 0:
		slots[old_at] = slots[slot]
	slots[slot] = id
	_check_spec()
	hero_hp = mini(hero_hp, get_max_hp())
	save_game()
	return true

func unequip_skill(id: String) -> void:
	for slots in [active_slots, passive_slots]:
		var i: int = slots.find(id)
		if i >= 0:
			slots[i] = ""
	buffs.erase(id)
	_check_spec()
	hero_hp = mini(hero_hp, get_max_hp())
	save_game()

## A stone dropped: a new skill, a rank up, or dust if it's maxed.
func gain_stone(id: String, from_text := "") -> void:
	var s := SkillData.info(id)
	var r := skill_rank(id)
	var name_tag := "[color=%s]%s[/color]" % [SkillData.RARITY_COLORS[int(s["rarity"])], s["name"]]
	codex.add("stones")
	if r <= 0:
		skill_book[id] = 1
		say("[color=#c4b5fd]Ability stone%s:[/color] you learned %s!" % [from_text, name_tag])
		events.append({"type": "stone", "name": s["name"], "rarity": int(s["rarity"]), "new": true})
		tip("stones", "An ability stone! New skills go in your Skill Book (Character > Skills). Equip up to 3 active and 5 passive skills.")
		_page("skills")
		if equip_skill(id) and SkillData.is_active(id):
			say("%s is equipped." % s["name"])
	elif r < SkillData.MAX_RANK:
		skill_book[id] = r + 1
		say("[color=#c4b5fd]Ability stone%s:[/color] %s rank %d!" % [from_text, name_tag, r + 1])
		events.append({"type": "stone", "name": "%s %d" % [s["name"], r + 1], "rarity": int(s["rarity"]), "new": false})
	else:
		var d: int = SkillData.DUST_PER_EXTRA[int(s["rarity"])]
		dust += d
		say("[color=#c4b5fd]Ability stone%s:[/color] %s is maxed, so it becomes %d dust." % [from_text, name_tag, d])
	_check_spec()

## Crafts a skill with dust: learns it, or ranks it up.
func craft_skill(id: String) -> bool:
	if not SkillData.SKILLS.has(id):
		return false
	var r := skill_rank(id)
	if r >= SkillData.MAX_RANK:
		say("%s is already max rank." % SkillData.skill_name(id))
		return false
	var cost := SkillData.craft_cost(id, r)
	if dust < cost:
		say("Not enough dust (need %d)." % cost)
		return false
	dust -= cost
	skill_book[id] = r + 1
	say("[color=#c4b5fd]Crafted %s%s.[/color]" % [SkillData.skill_name(id), "" if r == 0 else " rank %d" % (r + 1)])
	if r == 0:
		equip_skill(id)
	_check_spec()
	save_game()
	return true

## How much a skill hits for, as a multiplier (INT, skill bonuses, tags, rank).
func skill_mult(id: String) -> float:
	var s := SkillData.info(id)
	return (1.0 + stat("INT") * GameData.INT_ABILITY_DMG) * _mult("skill") * (1.0 + tag_power(s.get("tags", []))) * SkillData.rank_mult(skill_rank(id))

func _reduce_cd(cd: int) -> int:
	var cdr := GameData.diminishing(stat("INT"), GameData.INT_COOLDOWN) / 100.0
	return maxi(1, int(round(cd * (1.0 - cdr))) - int(floor(_flat("cdr"))))

func skill_cd(id: String) -> int:
	return _reduce_cd(int(SkillData.info(id).get("cd", 5)))

func skill_ready(id: String) -> bool:
	return hero_class != "" and id in equipped_actives() and int(skill_cds.get(id, 0)) <= 0

func spend_point(stat_name: String, amount := 1) -> void:
	amount = mini(amount, stat_points)
	if amount <= 0 or not stat_name in GameData.STAT_ORDER:
		return
	stats[stat_name] = int(stats.get(stat_name, 0)) + amount
	stat_points -= amount
	_check_spec()
	save_game()

## Spends every unspent point on your class's recommended build, keeping the
## spread as close to it as possible.
func auto_spend() -> void:
	if stat_points <= 0 or hero_class == "":
		return
	var b := Classes.build(hero_class)
	var total_w := 0.0
	for st in b:
		total_w += float(b[st])
	while stat_points > 0:
		# The stat furthest below its share of the points you've put in
		var spent := 1.0
		for st in b:
			spent += float(stats.get(st, 0))
		var pick := ""
		var worst := INF
		for st in Classes.stat_order(hero_class):
			if not b.has(st):
				continue
			var share := float(stats.get(st, 0)) / spent - float(b[st]) / total_w
			if share < worst:
				worst = share
				pick = st
		stats[pick] = int(stats.get(pick, 0)) + 1
		stat_points -= 1
	_check_spec()

func respec_cost() -> int:
	return 0 if respec_tomes > 0 else 25 * level

## Gives back every stat point for gold (or a Tome of Forgetting), so you can try a different build.
func respec() -> void:
	var cost := respec_cost()
	if gold < cost:
		say("Not enough gold to respec (need %d)." % cost)
		return
	var total := 0
	for st in GameData.STAT_ORDER:
		total += int(stats.get(st, 0))
		stats[st] = 0
	if respec_tomes > 0:
		respec_tomes -= 1
	else:
		gold -= cost
	stat_points += total
	hero_hp = mini(hero_hp, get_max_hp())
	say("Stats reset! You have %d points to spend." % stat_points)
	_check_spec()
	save_game()

## A new class pick is open (levels 15, 35, 60): pick it automatically
## (simulations) or tell the player once.
func _check_spec() -> void:
	var t := ClassTree.pick_tier(self)
	if t < 0:
		return
	if class_auto:
		ClassTree.auto_pick(self)
		return
	if class_told != t:
		class_told = t
		events.append({"type": "class_pick", "tier": t})
		say("[color=#e8b14a]Level %d: choose your next class in the Class tab![/color]" % int(ClassTree.PICK_LEVELS[t]))
		tip("class_pick_%d" % t, "Your class can evolve! Open Character > Class and choose where your Evolution Tree goes.")

## What a stat would be if this item were worn instead of the current one.
func stat_if_equipped(item: Dictionary) -> int:
	var slot: String = item["slot"]
	var had := equipped.has(slot)
	var old = equipped.get(slot)
	equipped[slot] = item
	var value := stat_value(item["stat"])
	if had:
		equipped[slot] = old
	else:
		equipped.erase(slot)
	return value

func stat_value(stat: String) -> int:
	match stat:
		"Attack":
			return get_attack()
		"Defense":
			return get_defense()
	return get_max_hp()

## An effect's total as a decimal (regen can be fractional).
func effect_value(effect: String) -> float:
	var total := 0.0
	for slot in equipped:
		var item: Dictionary = equipped[slot]
		if item["effect"] == effect:
			total += float(item["effect_value"])
		if item.get("effect2", "") == effect:
			total += float(item.get("effect2_value", 0))
	if effect == "dodge":
		total += float(class_info().get("dodge", 0))
		total += dim("AGI", GameData.AGI_DODGE)
		total += _buff("dodge", 0.0)
	elif effect == "crit":
		total += dim("DEX", GameData.DEX_CRIT)
		total += _buff("crit", 0.0)
	elif effect == "double_strike":
		total += dim("DEX", GameData.DEX_DOUBLE)
	elif effect == "gold_find":
		total += _elixir("gold_find", 0.0)
		total += dim("LUK", GameData.LUK_GOLD)
	elif effect == "regen":
		total += dim("WIS", GameData.WIS_REGEN)
	total += _flat(effect)
	if effect == "regen" and (form == "Vampire" or curses.has("frailty")):
		total = minf(total, 0.0)
	if effect == "crit":
		total = minf(total, GameData.CRIT_CAP)
	elif effect == "dodge":
		total = minf(total, GameData.DODGE_CAP)
	return total

func effect_total(effect: String) -> int:
	return int(round(effect_value(effect)))

## Defense reduces damage by a percentage: equal Defense and enemy Attack halves it.
func damage_taken() -> int:
	var atk := float(enemy_attack) * Lineage.enemy_attack_mult(self) * Realms.damage_mult(self)
	# Bestiary mastery: you know this monster's moves (half your kill bonus as less damage)
	atk *= 1.0 - Monsters.milestone_bonus(codex.kills(enemy_species)) / 200.0
	return maxi(1, int(round(atk * atk / (atk + get_defense()))))

## Chance (%) the next boss drops a unique. Goes up after every boss without one.
func unique_chance() -> float:
	return minf(100.0, GameData.UNIQUE_DROP_CHANCE + GameData.UNIQUE_PITY_STEP * bosses_since_unique)

func bag_capacity() -> int:
	return GameData.BAG_START + bag_level * GameData.BAG_STEP

func bag_full() -> bool:
	return bag.size() >= bag_capacity()

func say(msg: String) -> void:
	messages.append(msg)

## Shows a helpful tip the first time something happens, then never again.
func tip(key: String, text: String) -> void:
	if tips_seen.has(key):
		return
	tips_seen[key] = true
	events.append({"type": "tip", "text": text})

func shop_unlocked() -> bool:
	return best_floor >= GameData.SHOP_UNLOCK_FLOOR

func craft_unlocked() -> bool:
	return best_floor >= GameData.CRAFT_UNLOCK_FLOOR

## True if the bag holds something stronger than what's worn in that slot.
## A rough "how strong is this build" number: damage you deal x damage you can take.
## Counts every stat, special effect and set bonus, so Equip Best can compare them.
func build_score() -> float:
	var crit := effect_total("crit") / 100.0
	var dbl := effect_total("double_strike") / 100.0
	var offense := get_attack() * (1.0 + crit) * (1.0 + dbl) * (1.0 + _ability_share())
	offense *= 1.0 + effect_total("lifesteal") / 200.0
	var ea := maxf(1.0, enemy_attack)
	var hit := ea * ea / (ea + get_defense())
	var dodge := minf(0.9, effect_total("dodge") / 100.0)
	var thorns := effect_total("thorns") / 100.0
	var ehp := get_max_hp() / maxf(1.0, hit * (1.0 - dodge))
	ehp *= 1.0 + effect_total("regen") * 0.08
	return offense * (1.0 + thorns * 0.3) * ehp * (1.0 + effect_total("gold_find") / 400.0)

func _ability_share() -> float:
	var share := 0.0
	for id in equipped_actives():
		var s := SkillData.info(id)
		share += float(s.get("power", 0.0)) * int(s.get("hits", 1)) * skill_mult(id) / maxf(1.0, skill_cd(id))
	return share

## Score if this bag item were worn instead of what's in its slot.
func score_with(item: Dictionary) -> float:
	var slot: String = item["slot"]
	var had := equipped.has(slot)
	var old = equipped.get(slot)
	equipped[slot] = item
	var sc := build_score()
	if had:
		equipped[slot] = old
	else:
		equipped.erase(slot)
	return sc

## The best item in the bag for a slot, by whole-build score, or {} if nothing beats what you wear.
func best_for_slot(slot: String) -> Dictionary:
	var best := {}
	var best_score := build_score() * 1.001
	for item in bag:
		if item["slot"] != slot or not Races.can_wear(self, item):
			continue
		var sc := score_with(item)
		if sc > best_score:
			best_score = sc
			best = item
	return best

func _refresh_upgrade_cache() -> void:
	var key := "%d|%d|%d|%d|%s|%s" % [bag_version, level, stat_points, floor_num, str(active_slots), str(passive_slots)]
	if key == _upgrade_key:
		return
	_upgrade_key = key
	_upgrade_cache.clear()
	for slot in GameData.SLOT_ORDER:
		_upgrade_cache[slot] = not best_for_slot(slot).is_empty()

## True if the bag holds something that would make your build stronger in that slot.
func has_upgrade(slot: String) -> bool:
	_refresh_upgrade_cache()
	return bool(_upgrade_cache.get(slot, false))

func upgrade_count() -> int:
	var n := 0
	for slot in GameData.SLOT_ORDER:
		if has_upgrade(slot):
			n += 1
	return n

func _new_id() -> int:
	next_id += 1
	return next_id - 1

func _tag(item: Dictionary) -> String:
	return "[color=%s]%s[/color]" % [GameData.color_of(item["rarity"]), GameData.display_name(item)]

# =====================================================================
# Combat
# =====================================================================

func new_game() -> void:
	hero_hp = get_max_hp()
	restock_shop()
	spawn_enemy()
	_page("welcome")
	tip("tap", "Your hero fights on their own. Tap the enemy to hit it yourself for bonus damage!")

func choose_class(class_name_picked: String) -> void:
	hero_class = class_name_picked
	var info := class_info()
	for id in info.get("start", []):
		if not skill_book.has(id):
			skill_book[id] = 1
		equip_skill(id)
	hero_hp = get_max_hp()
	say("You are a [color=%s]%s[/color]!" % [info["color"], hero_class])
	var first: String = info["start"][0]
	tip("ability", "%s is your first skill: %s Press it when it's ready, or leave Auto on. Monsters drop ability stones with more skills." % [SkillData.skill_name(first), SkillData.info(first)["text"]])
	_page("abilities")
	save_game()

## Kept for older code: is the first equipped skill ready?
func ability_ready(_id := "main") -> bool:
	var acts := equipped_actives()
	return not acts.is_empty() and skill_ready(acts[0])

## Fires a skill right away. Returns false if it isn't ready.
func use_skill(id: String) -> bool:
	if not skill_ready(id) or enemy_hp <= 0 or hero_hp <= 0 or run_over:
		return false
	var s := SkillData.info(id)
	var tags: Array = s.get("tags", [])
	var rk := SkillData.rank_mult(skill_rank(id))
	skill_cds[id] = skill_cd(id)
	codex.add("skills_used")
	var mult := skill_mult(id)
	var maxhp := get_max_hp()
	var parts: Array = []
	if s.has("hp_cost"):
		hero_hp = maxi(1, hero_hp - int(maxhp * float(s["hp_cost"]) / 100.0))
	if s.get("wild", false):
		s = _wild_card(s)
	var total := 0
	var crit_hit := false
	if s.has("power"):
		var crit_any := false
		var combo_mult := Combat.before_skill(self, tags, true)
		for _i in int(s.get("hits", 1)):
			var d := (get_attack() * float(s["power"]) * mult + get_defense() * float(s.get("def_scale", 0.0)) * rk) * combo_mult
			if s.get("always_crit", false) or randf() * 100.0 < effect_value("crit") or _frozen_crit():
				d *= crit_mult()
				crit_any = true
			total += int(d)
		if s.has("execute") and enemy_hp < enemy_max_hp * 0.3:
			total = int(total * (1.0 + float(s["execute"])))
		last_hit = "skill"
		total = _damage_enemy(total, tags)
		crit_hit = crit_any
		parts.append("%d damage%s" % [total, " (crit!)" if crit_any else ""])
		if Combat.try_stagger(self) != "":
			parts.append("[color=#4ade80]staggered its crushing blow[/color]")
	events.append({"type": "ability", "name": s["name"], "dmg": total, "class": hero_class, "tag": tags[0] if not tags.is_empty() else "",
		"color": Classes.tag_color(tags[0] if not tags.is_empty() else "")})
	var heal := int(maxhp * float(s.get("heal", 0)) * rk / 100.0 * heal_mult()) + int(total * float(s.get("drain", 0)) / 100.0)
	if heal > 0:
		hero_hp = mini(hero_hp + heal, maxhp)
		events.append({"type": "heal", "amount": heal})
		parts.append("+%d HP" % heal)
	if float(s.get("burn", 0.0)) > 0.0 and not ("Nature" in tags or "Shadow" in tags):
		burn_turns = GameData.BURN_TURNS
		burn_dmg = maxi(1, int(get_attack() * float(s["burn"]) * mult))
		burn_tag = "Blood" if "Blood" in tags else "Fire"
	Combat.after_skill(self, tags, s, mult)
	if s.get("carry", false) and enemy_hp < 0:
		pierce_carry = -enemy_hp
	if s.has("stun"):
		enemy_stun = int(s["stun"])
		parts.append("stunned")
	if s.has("weaken"):
		enemy_weaken = float(s["weaken"])
		enemy_weaken_turns = int(s["turns"])
	if s.has("buff"):
		var b: Dictionary = (s["buff"] as Dictionary).duplicate()
		b["turns"] = int(b["turns"]) + ClassTree.extra(self, "buff_turns")
		if b.has("atk"):
			b["atk"] = 1.0 + (float(b["atk"]) - 1.0) * rk
		if b.has("def"):
			b["def"] = 1.0 + (float(b["def"]) - 1.0) * rk
		buffs[id] = b
		events.append({"type": "buff", "name": s["name"]})
	if s.has("shield"):
		shield_hp += int(maxhp * float(s["shield"]) * rk / 100.0)
		parts.append("shield %d" % shield_hp)
		events.append({"type": "buff", "name": s["name"]})
	if s.has("summon"):
		var sm: Dictionary = s["summon"]
		summon_turns = int(sm["turns"]) + ClassTree.extra(self, "summon_turns")
		summon_power = float(sm["power"]) * mult
		summon_name = "Skeleton" if "Shadow" in tags else "Wolf"
		events.append({"type": "summon", "name": summon_name})
	if s.has("song"):
		var sg: Dictionary = s["song"]
		song_turns = int(sg["turns"]) + ClassTree.extra(self, "buff_turns")
		song_regen = float(sg["regen"]) * rk * heal_mult()
		events.append({"type": "buff", "name": s["name"]})
	if s.has("confuse"):
		confuse_turns = int(s["confuse"]) + ClassTree.extra(self, "confuse")
		parts.append("confused")
	if s.has("steal"):
		var g := int((2 + floor_num) * float(s["steal"]) * rk * (1.0 + effect_value("gold_find") / 100.0))
		_add_gold(g)
		parts.append("stole %d gold" % g)
		if randf() < 0.1:
			_give_item(GameData.make_item(_drop_slot(enemy_species), GameData.roll_rarity(_loot_bonus(), GameData.LEGENDARY_CHANCE_NORMAL), floor_num, _new_id()))
	if s.get("reset", false):
		for other in skill_cds:
			if other != id:
				skill_cds[other] = 0
		parts.append("cooldowns reset")
	# Paths: what you use shapes who you become
	for t in tags:
		Lineage.gain(self, "skill:" + t)
	if heal > 0:
		Lineage.gain(self, "heal")
	if s.has("confuse"):
		Lineage.gain(self, "confuse")
		Hidden.count(self, "confuses")
	ClassTree.on_skill(self, id, tags, s)
	if total > 0:
		ClassTree.on_big_hit(self, total, crit_hit)
	if heal > 0:
		ClassTree.on_heal(self, "drain" if s.has("drain") else "heal", heal)
	if "Holy" in tags:
		_faith(Classes.FAITH["holy_skill"])
	if "Shadow" in tags or "Blood" in tags:
		_faith(Classes.FAITH["shadow_skill"])
	say("[color=%s]%s![/color] %s" % [Classes.tag_color(tags[0] if not tags.is_empty() else ""), s["name"], ", ".join(parts)])
	if enemy_hp <= 0:
		_enemy_defeated()
	return true

## Trickster's Wild Card: a random effect, usually good.
func _wild_card(s: Dictionary) -> Dictionary:
	var out := s.duplicate()
	var roll := randi() % 6
	match roll:
		0:
			out["power"] = 5.0
			out["name"] = "Wild Card: Jackpot"
		1:
			out["heal"] = 30
			out["name"] = "Wild Card: Second Wind"
		2:
			out["power"] = 1.0
			out["stun"] = 2
			out["name"] = "Wild Card: Bonk"
		3:
			out["steal"] = 6.0
			out["power"] = 1.0
			out["name"] = "Wild Card: Pickpocket"
		4:
			out["confuse"] = 3
			out["power"] = 0.5
			out["name"] = "Wild Card: Confetti"
		_:
			out["power"] = 0.2
			out["name"] = "Wild Card: Oops"
	return out

## Auto: picks the best skill to use right now.
func _auto_skill() -> void:
	var maxhp := get_max_hp()
	var best := ""
	var best_cd := -1
	for id in auto_order():
		if not skill_ready(id) or skill_auto_off.has(id):
			continue
		var s := SkillData.info(id)
		var useful := true
		if s.has("buff") and buffs.has(id):
			useful = false
		if s.has("shield") and shield_hp > 0:
			useful = false
		if s.has("summon") and summon_turns > 0:
			useful = false
		if s.has("song") and song_turns > 0 and hero_hp > maxhp * 0.5:
			useful = false
		if not s.has("power") and s.has("heal") and hero_hp > maxhp * 0.7:
			useful = false
		if s.has("stun") and not s.has("power") and enemy_stun > 0:
			useful = false
		if s.has("power") and not s.has("heal") and Combat.element_mult(self, s.get("tags", []))[1] == "resist":
			# Don't waste a big skill on a monster that resists it if something else is ready
			if auto_order().any(func(o): return o != id and skill_ready(o) and not skill_auto_off.has(o) and Combat.element_mult(self, SkillData.info(o).get("tags", []))[1] != "resist" and SkillData.info(o).has("power")):
				useful = false
		if useful and (not skill_priority.is_empty() or int(s["cd"]) > best_cd):
			best = id
			best_cd = int(s["cd"])
			if not skill_priority.is_empty():
				break
	if best != "":
		use_skill(best)

## Equipped active skills in the order Auto tries them: your priority list
## first, then the rest (biggest cooldown first).
func auto_order() -> Array:
	var acts := equipped_actives()
	acts.sort_custom(func(a, b):
		var ia := skill_priority.find(a)
		var ib := skill_priority.find(b)
		if ia < 0:
			ia = 99
		if ib < 0:
			ib = 99
		if ia != ib:
			return ia < ib
		return int(SkillData.info(a).get("cd", 0)) > int(SkillData.info(b).get("cd", 0)))
	return acts

## Moves a skill up (-1) or down (+1) in Auto's order.
func move_priority(id: String, dir: int) -> void:
	var order := auto_order()
	var i := order.find(id)
	var j := i + dir
	if i < 0 or j < 0 or j >= order.size():
		return
	order[i] = order[j]
	order[j] = id
	skill_priority = order
	save_game()

func toggle_skill_auto(id: String) -> void:
	if skill_auto_off.has(id):
		skill_auto_off.erase(id)
	else:
		skill_auto_off[id] = true
	save_game()

func gain_xp(amount: int) -> void:
	xp += int(amount * float(race_info().get("xp", 1.0)) * (1.0 + _flat("xp") / 100.0))
	while xp >= GameData.xp_to_next(level):
		xp -= GameData.xp_to_next(level)
		level += 1
		stat_points += GameData.STAT_POINTS_PER_LEVEL
		hero_hp = get_max_hp()
		events.append({"type": "level_up", "level": level})
		say("[color=#fbbf24]LEVEL UP! You're now level %d.[/color] +%d stat points" % [level, GameData.STAT_POINTS_PER_LEVEL])
		World.check_pet(self)
		if auto_stats:
			auto_spend()
		else:
			tip("level", "Level up! You got %d stat points. Spend them in Character > Hero, or turn on Auto to follow your class's build." % GameData.STAT_POINTS_PER_LEVEL)
		if level in SkillData.ACTIVE_SLOTS_AT or level in SkillData.PASSIVE_SLOTS_AT:
			var kind := "active" if level in SkillData.ACTIVE_SLOTS_AT else "passive"
			say("[color=#c4b5fd]A new %s skill slot is open![/color]" % kind)
			tip("slot_%d" % level, "Level %d: a new %s skill slot! Equip another skill in Character > Skills." % [level, kind])
			_fill_empty_slots()
		if level == 2:
			_page("stats")
		if level >= 5:
			_page("paths")
		if level >= Classes.SPEC_LEVEL - 5:
			_page("specs")
		if level == Classes.SPEC_LEVEL - 5:
			tip("spec_soon", "At level %d you choose your first class branch. Check the Class tab to see the tree." % Classes.SPEC_LEVEL)
		_check_spec()

## New slots get filled with skills you own but aren't using.
func _fill_empty_slots() -> void:
	for id in skill_book:
		if not is_skill_equipped(id):
			var slots: Array = active_slots if SkillData.is_active(id) else passive_slots
			var open := active_slot_count() if SkillData.is_active(id) else passive_slot_count()
			for i in open:
				if slots[i] == "":
					slots[i] = id
					break

## A hit from tapping the enemy. Returns false if nothing happened.
func tap_attack() -> bool:
	if enemy_hp <= 0 or hero_hp <= 0 or run_over:
		return false
	last_hit = "hit"
	var dmg := _damage_enemy(maxi(1, int(get_attack() * GameData.TAP_DAMAGE)))
	codex.add("taps")
	events.append({"type": "tap_hit", "dmg": dmg})
	if enemy_hp <= 0:
		say("You finished off the %s yourself!" % enemy_name)
		_enemy_defeated()
	return true

## Deals damage to the monster after its modifiers and your Bestiary bonus.
## Returns how much actually hit its health.
func _damage_enemy(dmg: int, tags: Array = []) -> int:
	var d := float(dmg) * (1.0 + Monsters.milestone_bonus(codex.kills(enemy_species)) / 100.0)
	if not tags.is_empty():
		var em := Combat.element_mult(self, tags)
		d *= float(em[0])
		if em[1] != "" and dmg > 0:
			events.append({"type": "element", "kind": em[1], "element": Combat.elements_of(tags)[0]})
			if em[1] == "weak":
				ClassTree.count(self, "weak_hits")
	if enemy_hp < enemy_max_hp * 0.3:
		d *= 1.0 + _flat("execute") / 100.0
	if enemy_is_boss:
		d *= 1.0 + _flat("boss") / 100.0
	var rage := _flat("rage")
	if rage > 0.0:
		d *= 1.0 + rage / 100.0 * (1.0 - clampf(float(hero_hp) / maxf(1.0, get_max_hp()), 0.0, 1.0))
	if "Armored" in enemy_mods:
		d *= 0.75
	var dealt := maxi(1, int(d))
	if boss_minions > 0:
		dealt = Combat.soak_minions(self, dealt)
		if dealt <= 0:
			return 0
	if enemy_shield > 0:
		var soak := mini(enemy_shield, dealt)
		enemy_shield -= soak
		dealt -= soak
		if enemy_shield <= 0:
			events.append({"type": "shield_break"})
			ClassTree.count(self, "shield_break")
	enemy_hp -= dealt
	codex.add("damage", dealt)
	codex.at_least("best_hit", dealt)
	return dealt

func has_mod(mod: String) -> bool:
	return mod in enemy_mods

## Frozen monsters take a crit from every hit.
func _frozen_crit() -> bool:
	return enemy_frozen > 0

func spawn_enemy() -> void:
	enemy_boss_kind = GameData.boss_kind(floor_num)
	enemy_is_boss = enemy_boss_kind != ""
	enemy_tier = 0
	enemy_mods = []
	enemy_shield = 0
	var growth := pow(GameData.ENEMY_GROWTH, floor_num - 1)
	var hp := int((15 + floor_num * 15) * growth)
	var atk := int((3 + floor_num * 2) * growth)
	var def: Dictionary
	if enemy_is_boss:
		enemy_goblin = false
		def = GameData.boss_for_floor(floor_num)
		enemy_name = GameData.boss_name(floor_num)
		enemy_species = def["name"]
		enemy_art = def.get("art", "boss_" + GameData.art_key(def["name"]))
		hp = int(hp * (GameData.ZONE_BOSS_HP if enemy_boss_kind == "zone" else GameData.MID_BOSS_HP))
		atk = int(atk * GameData.BOSS_ATK)
	elif enemy_goblin:
		def = {"name": "Treasure Goblin", "shape": "humanoid", "color": "#fbbf24"}
		enemy_name = "Treasure Goblin"
		enemy_species = "Treasure Goblin"
		enemy_art = "treasure_goblin"
		hp = int(hp * 2.5)
		atk = 0
		goblin_turns = GameData.GOBLIN_TURNS
	else:
		def = GameData.pick_monster(floor_num)
		enemy_species = def["name"]
		enemy_name = GameData.rank_prefix(floor_num) + enemy_species
		enemy_art = GameData.art_key(enemy_species)
		var boost := 1.0
		if hunt_spawns > 0:
			hunt_spawns -= 1
			boost = GameData.HUNT_RARE_BOOST
		enemy_tier = Monsters.roll_tier(hardcore, boost * (1.6 if curses.has("swarm") else 1.0))
		if horde_left > 0:
			hp = int(hp * GameData.HORDE_HP)
			enemy_tier = mini(enemy_tier, 1)
	if curse_turns > 0 and not enemy_goblin:
		hp = int(hp * GameData.CURSE_POWER)
		atk = int(atk * GameData.CURSE_POWER)
	if not enemy_goblin:
		if curses.has("vigor"):
			hp = int(hp * 1.5)
		if curses.has("fury"):
			atk = int(atk * 1.3)
	if party != null and party.size() > 0 and not enemy_goblin:
		hp = int(hp * party.hp_mult())
		atk = int(atk * party.atk_mult())
	enemy_people = Realms.zone_race(GameData.zone_index(floor_num)) if def.get("people", false) and not enemy_goblin else ""
	enemy_shape = def["shape"]
	enemy_color = def["color"]
	enemy_max_hp = hp
	enemy_hp = hp
	enemy_attack = atk
	enemy_base_hp = hp
	enemy_base_atk = atk
	burn_turns = 0
	enemy_champion = false
	_apply_tier(enemy_tier)
	if curses.has("swarm") and enemy_tier > 0 and not enemy_is_boss:
		var extra := Monsters.roll_mods(1)
		if not extra.is_empty() and not extra[0] in enemy_mods:
			enemy_mods.append(extra[0])
	if World.champion_here(self) and not enemy_is_boss:
		World.make_champion(self)
	enemy_illusion = Realms.roll_illusion(self)
	Realms.maybe_spirit(self)
	var realm_here := GameData.realm_of(floor_num)
	if enemy_is_boss and realm_here != "" and not codex.seen(enemy_species):
		events.append({"type": "boss_intro", "name": enemy_name, "lore": Monsters.info(enemy_species).get("lore", ""), "color": enemy_color,
			"sub": ("Ruler of " if enemy_boss_kind == "zone" else "Guardian of ") + Realms.realm_name(realm_here)})
	if not enemy_goblin:
		codex.meet(enemy_species)
	if enemy_tier >= 1:
		_page("monster_tiers")
	ClassTree.on_fight_start(self)
	_setup_fight()
	if pierce_carry > 0:
		var carried := mini(pierce_carry, enemy_hp - 1)
		enemy_hp -= carried
		pierce_carry = 0
		if carried > 0:
			events.append({"type": "pierce", "dmg": carried})

## A new monster: clear the old one's statuses, read its elements, wake up boss mechanics.
func _setup_fight() -> void:
	enemy_chill = 0
	enemy_frozen = 0
	enemy_curse = 0
	enemy_poison_turns = 0
	enemy_poison_dmg = 0
	boss_mechanics = []
	boss_phase = {}
	boss_minions = 0
	var p := Combat.profile(self)
	enemy_weak = p["weak"]
	enemy_resist = p["resist"]
	if enemy_is_boss:
		Combat.start_boss(self)

## Makes the current monster a tier: tougher, with modifiers. Call right after spawning.
func _apply_tier(tier: int) -> void:
	enemy_tier = tier
	if tier <= 0 or enemy_is_boss or enemy_goblin:
		return
	var t: Dictionary = Monsters.TIERS[tier]
	enemy_mods = Monsters.roll_mods(int(t["mods"]))
	var hp := float(enemy_base_hp) * float(t["hp"])
	if has_mod("Giant"):
		hp *= 1.5
	enemy_max_hp = int(hp)
	enemy_hp = enemy_max_hp
	enemy_attack = int(enemy_base_atk * float(t["atk"]))
	enemy_shield = 0
	if has_mod("Shielded"):
		enemy_shield = int(enemy_max_hp * 0.25)
	if tier >= Monsters.EPIC:
		events.append({"type": "rare_monster", "tier": tier, "name": enemy_name, "mods": enemy_mods.duplicate()})
		say("[color=%s]%s %s appears![/color] %s" % [Monsters.tier_color(tier), Monsters.tier_name(tier), enemy_name, ", ".join(enemy_mods)])

## The size the monster is drawn at (rarer = bigger).
func enemy_scale() -> float:
	var s := float(Monsters.TIERS[clampi(enemy_tier, 0, 5)]["scale"])
	if has_mod("Giant"):
		s *= 1.12
	return s

func take_turn() -> void:
	if run_over or in_town:
		return
	if not path_offer.is_empty():
		# Waiting for you to pick a room; after a few turns it picks the first choice by itself
		if not path_hold and auto_paths and autoplay:
			path_wait += 1
		if path_wait >= GameData.PATH_WAIT_TURNS:
			choose_path(auto_path())
		return
	codex.add("turns")
	ClassTree.on_turn(self)
	if auto_potion and potions > 0 and hero_hp < get_max_hp() * auto_potion_at and not (trial_active and trial_data.get("no_potions", false)):
		use_potion()
	elif potions == 0 and hero_hp < get_max_hp() * auto_potion_at and shop_unlocked():
		tip("potions", "Low on health! Potions from the Shop heal you automatically when HP gets low.")

	# Abilities: count down, then Auto fires the best one that's ready
	for id in skill_cds:
		if int(skill_cds[id]) > 0:
			skill_cds[id] = int(skill_cds[id]) - 1
	if auto_ability:
		_auto_skill()
	if enemy_hp <= 0 or hero_hp <= 0:
		return

	# Burns and poison on the monster
	if (burn_turns > 0 or enemy_poison_turns > 0) and enemy_hp > 0:
		last_hit = "burn"
		Combat.tick_enemy(self)
		if enemy_hp <= 0:
			say("The %s burns away!" % enemy_name)
			_enemy_defeated()
			return
	else:
		Combat.tick_enemy(self)
	if has_mod("Regenerating") and enemy_hp > 0:
		enemy_hp = mini(enemy_max_hp, enemy_hp + int(enemy_max_hp * 0.03))

	# Hero attacks (Agility: sometimes first, sometimes twice)
	var line := ""
	if int(cfight.get("turns", 0)) <= 1 and World.pet_first(self) and not cfight.get("pet_first", false):
		cfight["pet_first"] = true
		World.pet_turn(self)
	var my_swings := 1
	if bool(cfight.get("first", false)) and int(cfight.get("turns", 0)) <= 1 and randf() * 100.0 < first_strike_chance():
		my_swings += 1
		events.append({"type": "first_strike"})
		line = "You strike first! "
	elif randf() * 100.0 < haste_chance():
		my_swings += 1
		events.append({"type": "haste"})
	for sw in my_swings:
		if enemy_hp <= 0:
			break
		var r := _basic_attack()
		line += String(r["line"])
		if r.get("illusion", false):
			return
		if sw < my_swings - 1:
			line += ", then "

	for id in buffs.keys():
		buffs[id]["turns"] = int(buffs[id]["turns"]) - 1
		if int(buffs[id]["turns"]) <= 0:
			buffs.erase(id)
	# A summoned helper (skeleton, wolf) attacks too
	if summon_turns > 0 and enemy_hp > 0:
		summon_turns -= 1
		last_hit = "hit"
		var sd := _damage_enemy(maxi(1, int(get_attack() * summon_power)))
		events.append({"type": "summon_hit", "dmg": sd, "name": summon_name})
	if enemy_hp > 0:
		World.pet_turn(self)
	var pal := Hidden.companion_power(self)
	if pal > 0.0 and enemy_hp > 0:
		last_hit = "hit"
		var bd := _damage_enemy(maxi(1, int(get_attack() * pal)))
		events.append({"type": "summon_hit", "dmg": bd, "name": "Beast friend"})
	for id in elixirs.keys():
		elixirs[id] = int(elixirs[id]) - 1
		if int(elixirs[id]) <= 0:
			elixirs.erase(id)
			say("%s wore off." % GameData.ELIXIRS[id]["name"])
	if luck_turns > 0:
		luck_turns -= 1
		if luck_turns == 0:
			say("Your Scroll of Luck fades.")
	if curse_turns > 0:
		curse_turns -= 1
		if curse_turns == 0:
			say("[color=#c084fc]The shrine's curse lifts.[/color]")

	# Your companions attack and use their skills
	if party != null and party.size() > 0 and enemy_hp > 0:
		last_hit = "hit"
		line += party.act(self)

	if enemy_hp <= 0:
		say(line + ".")
		_enemy_defeated()
		return

	# The treasure goblin never fights back. It just runs.
	if enemy_goblin:
		goblin_turns -= 1
		if goblin_turns <= 0:
			say(line + ". [color=#fbbf24]The treasure goblin escapes with its loot![/color]")
			events.append({"type": "goblin_escaped"})
			enemy_goblin = false
			spawn_enemy()
			save_game()
			return
		say(line + ". The goblin scurries around (%d turns left)." % goblin_turns)
		return

	# Bosses: shields, minions, the enrage clock
	line += Combat.boss_turn(self)
	# Enemy attacks
	if enemy_frozen > 0:
		enemy_frozen -= 1
		line += ". The %s is frozen solid!" % enemy_name
		events.append({"type": "stunned"})
	elif enemy_stun > 0:
		enemy_stun -= 1
		line += ". The %s is stunned!" % enemy_name
		events.append({"type": "stunned"})
	elif charm_total() > 0.0 and randf() * 100.0 < charm_total():
		line += ". The %s is charmed and forgets to attack" % enemy_name
		ClassTree.grow(self, "charm")
		events.append({"type": "stunned"})
	elif confuse_turns > 0:
		confuse_turns -= 1
		var self_hit := maxi(1, int(damage_taken() * 1.5))
		enemy_hp -= self_hit
		line += ". The confused %s hits itself for %d!" % [enemy_name, self_hit]
		events.append({"type": "confused", "dmg": self_hit})
	else:
		var swings := 2 if has_mod("Swift") and randf() < 0.3 else 1
		for _s in swings:
			if party != null and party.size() > 0:
				var target = party.pick_target(self)
				if target != null:
					line += party.hit_member(self, target)
					continue
			if randf() * 100.0 < effect_total("dodge"):
				line += ". You dodge the %s's attack" % enemy_name
				events.append({"type": "dodge"})
				Lineage.gain(self, "dodge")
				ClassTree.on_dodge(self)
				continue
			if Realms.misses(self):
				line += ". The %s swings blind in the mist" % enemy_name
				continue
			var damage := int(damage_taken() * Combat.enrage_mult(self) * World.pet_guard(self) * Combat.crush_mult(self))
			if enemy_weaken_turns > 0:
				damage = maxi(1, int(damage * enemy_weaken))
			if enemy_curse > 0:
				damage = maxi(1, int(damage * 0.85))
			if has_mod("Enraged") and enemy_hp * 2 < enemy_max_hp:
				damage = int(damage * 1.4)
			var shielded := shield_hp > 0 or buffs.has("frozen_armor")
			if shield_hp > 0:
				var soak := mini(shield_hp, damage)
				shield_hp -= soak
				damage -= soak
				if soak > 0:
					events.append({"type": "shield_soak", "dmg": soak})
			hero_hp -= damage
			Combat.note_damage(self, "hits", damage)
			Combat.on_enemy_hit(self, damage)
			ClassTree.on_hit_taken(self, damage, shielded)
			line += ". The %s hits you for %d" % [enemy_name, damage]
			events.append({"type": "enemy_hit", "dmg": damage})
			Lineage.on_hit(self)
			if has_mod("Vampiric"):
				enemy_hp = mini(enemy_max_hp, enemy_hp + int(damage * 0.3))
			var thorns := int(damage * effect_total("thorns") / 100.0)
			if thorns > 0:
				enemy_hp -= thorns
				events.append({"type": "thorns", "dmg": thorns})
		if enemy_weaken_turns > 0:
			enemy_weaken_turns -= 1
		line += "."
	if has_mod("Burning"):
		var burn := maxi(1, int(get_max_hp() * 0.02 * status_mult()))
		hero_hp -= burn
		Combat.note_damage(self, "burning", burn)
		events.append({"type": "enemy_hit", "dmg": burn, "burning": true})

	# Poison, burns and chill on you, and the floor's hazard
	Combat.tick_hero(self)
	World.hazard_turn(self)
	# The realm itself (forge heat, hellfire, the angels' judgement)
	line += Realms.on_turn(self)
	# Regeneration (gear, skills, songs)
	var regen_pct := effect_value("regen")
	if song_turns > 0:
		song_turns -= 1
		regen_pct += song_regen
	var regen := int(get_max_hp() * regen_pct / 100.0)
	if regen > 0 and hero_hp > 0:
		hero_hp = mini(hero_hp + regen, get_max_hp())
		ClassTree.on_heal(self, "regen", regen)
		events.append({"type": "heal", "amount": regen})

	say(line)
	if hero_hp <= 0 and Lineage.save_from_death(self):
		ClassTree.on_death_save(self)
	if hero_hp <= 0:
		_hero_died()
	elif enemy_hp <= 0:
		_enemy_defeated()

## One basic attack: double strike, crits, lifesteal, the monster's tricks.
## Returns {"line", "dealt", "illusion"}.
func _basic_attack() -> Dictionary:
	if has_mod("Teleporting") and randf() < 0.2:
		events.append({"type": "blink"})
		return {"line": "The %s blinks away from your attack" % enemy_name, "dealt": 0}
	if Realms.misses(self):
		events.append({"type": "blink"})
		return {"line": "Your attack is lost in the mist", "dealt": 0}
	if World.dark_miss(self):
		events.append({"type": "blink"})
		return {"line": "You swing at shadows", "dealt": 0}
	var hits := 2 if randf() * 100.0 < effect_total("double_strike") else 1
	var total_dmg := 0
	var crit := false
	for _h in hits:
		var dmg := float(get_attack())
		if randf() * 100.0 < effect_total("crit") or _frozen_crit():
			dmg *= crit_mult()
			crit = true
			Lineage.gain(self, "crit")
		total_dmg += int(dmg)
	last_hit = "hit"
	total_dmg = _damage_enemy(total_dmg, ["Physical"])
	ClassTree.on_hero_hit(self, crit, hits > 1)
	ClassTree.on_big_hit(self, total_dmg, crit)
	events.append({"type": "hero_hit", "dmg": total_dmg, "crit": crit, "double": hits > 1})
	if enemy_illusion:
		say("[color=#f9a8d4]Your blow passes right through the %s. It was only an illusion![/color]" % enemy_name)
		ClassTree.count(self, "illusions")
		events.append({"type": "illusion"})
		Lineage._move_on(self)
		return {"line": "", "dealt": total_dmg, "illusion": true}
	var steal := int(total_dmg * effect_total("lifesteal") / 100.0 * Realms.lifesteal_mult(self))
	if steal > 0:
		hero_hp = mini(hero_hp + steal, get_max_hp())
		ClassTree.on_heal(self, "lifesteal", steal)
		events.append({"type": "heal", "amount": steal})
	if has_mod("Thorny"):
		var back := maxi(1, int(total_dmg * 0.1))
		hero_hp = maxi(1, hero_hp - back)
		events.append({"type": "enemy_hit", "dmg": back, "thorny": true})
	var line := "You hit for %d" % total_dmg
	if hits > 1:
		line += " (double strike)"
	if crit:
		line += " (crit!)"
	return {"line": line, "dealt": total_dmg}

## Loot rarity bonus right now (events, scrolls, the shrine's curse).
func _loot_bonus() -> int:
	var b := int(GameData.event_bonus("rarity", 0.0)) + int(dim("LUK", GameData.LUK_LOOT))
	if luck_turns > 0:
		b += GameData.LUCK_BONUS
	b += Realms.loot_bonus(self)
	if curse_turns > 0:
		b += GameData.CURSE_LOOT
	b += World.curse_loot(self)
	return b

## Which slot a monster's drop goes in: it favors its own 2 slots.
func _drop_slot(monster: String) -> String:
	var fav: Array = Monsters.info(monster).get("drops", [])
	if not fav.is_empty() and randf() < GameData.FAVORED_SLOT_CHANCE:
		return fav.pick_random()
	return GameData.SLOT_ORDER.pick_random()

func _give_materials(count: int, zone_i := -1) -> void:
	if count <= 0:
		return
	var m := GameData.zone_index(floor_num) if zone_i < 0 else zone_i
	materials[m] = int(materials[m]) + count
	ClassTree.count(self, "materials", count)
	say("[color=#2dd4bf]+%d %s[/color]" % [count, GameData.MATERIALS[m]])
	tip("materials", "Materials! Use them in the Craft tab to make Set items and bigger bags.")

func _enemy_defeated() -> void:
	var was_boss := enemy_is_boss
	var was_goblin := enemy_goblin
	var tier := enemy_tier
	var species := enemy_species
	var zone_i := GameData.zone_index(floor_num)
	events.append({"type": "enemy_dead", "shape": enemy_shape, "color": enemy_color, "boss": was_boss, "name": enemy_name,
		"art": enemy_art, "tier": tier, "scale": enemy_scale()})
	if not was_boss:
		Combat.on_enemy_death(self)
	if enemy_boss_kind == "trial":
		_finish_trial()
		return
	Town.on_kill(self, species, tier, was_boss, zone_i)
	ClassTree.on_kill(self, was_boss, tier, was_goblin)
	if not was_goblin:
		Mastery.on_kill(self)
		_feed_souls(was_boss)
		if hero_class != "" and level >= Classes.SPEC_LEVEL and randf() * 100.0 < (GameData.EVO_SET_BOSS_CHANCE if was_boss else (GameData.EVO_SET_ELITE_CHANCE if tier >= Monsters.EPIC else 0.0)):
			_give_item(_roll_evo_piece())
	burn_turns = 0
	enemy_stun = 0
	enemy_weaken_turns = 0
	enemy_elite = false
	enemy_goblin = false
	var t: Dictionary = Monsters.TIERS[tier]
	var bonus_pct := Monsters.milestone_bonus(codex.kills(species))
	Lineage.on_kill(self, species, tier, enemy_boss_kind, was_goblin)
	Realms.quest_kill(self)
	Realms.on_spirit_kill(self)
	if was_boss and randf() * 100.0 < Races.RACE_GEAR_BOSS_CHANCE and not Races.gear_for(race()).is_empty():
		_give_item(Races.make_race_gear(Races.gear_for(race()).pick_random(), floor_num, _new_id()))
	Hidden.on_kill(self, species, tier, enemy_boss_kind, was_goblin)
	if not was_goblin:
		codex.record_kill(species, tier, enemy_boss_kind)
		codex.bounty_progress("kill", {"monster": species, "zone": zone_i, "tier": tier})
	var xp_gain := int(GameData.xp_for_kill(floor_num, was_boss) * float(t["xp"]) * GameData.event_bonus("xp"))
	gain_xp(xp_gain)
	if party != null:
		party.on_kill(xp_gain)
	var gold_gain := (2 + floor_num) * (10 if was_boss else 1)
	gold_gain = int(gold_gain * float(t["gold"]) * (1.0 + (effect_total("gold_find") + bonus_pct + World.curse_gold(self)) / 100.0) * GameData.event_bonus("gold"))
	if curse_turns > 0:
		gold_gain *= 2
	if was_goblin:
		gold_gain = (2 + floor_num) * GameData.GOBLIN_GOLD
	_add_gold(gold_gain)

	# Ability stones: rare, but rarer monsters and bosses drop them more
	stones_since += 1
	var stone_chance := SkillData.STONE_CHANCE * float(SkillData.STONE_TIER_MULT[tier]) * (1.0 + _flat("stone_find") / 100.0)
	if hero_class != "" and (was_boss or stones_since >= SkillData.STONE_PITY or randf() * 100.0 < stone_chance):
		stones_since = 0
		gain_stone(SkillData.roll_stone(was_boss), " (boss)" if was_boss else "")

	# Paths: how you fight shapes who you become
	kill_streak += 1
	if kill_streak >= 50:
		kill_streak = 0
		Lineage.gain(self, "streak")
	if was_boss:
		_faith(Classes.FAITH["boss"])
	if was_goblin:
		_faith(Classes.FAITH["goblin"])

	if was_boss:
		say("[color=#fbbf24]You defeated %s![/color] +%d gold" % [enemy_name, gold_gain])
		_give_materials(randi_range(GameData.BOSS_MATERIAL_DROP[0], GameData.BOSS_MATERIAL_DROP[1]))
		for _i in GameData.BOSS_LOOT_DROPS:
			var slot: String = GameData.SLOT_ORDER.pick_random()
			_give_item(GameData.make_item(slot, GameData.roll_rarity(GameData.BOSS_RARITY_BONUS + _loot_bonus(), GameData.LEGENDARY_CHANCE_BOSS), floor_num, _new_id()))
		if randf() * 100.0 < unique_chance():
			var uniques: Array = GameData.boss_for_floor(floor_num)["uniques"]
			var def: Dictionary = uniques.pick_random()
			say("[color=#fbbf24]*** UNIQUE DROP! ***[/color]")
			bosses_since_unique = 0
			_give_item(GameData.make_unique(def, floor_num, _new_id()))
		else:
			bosses_since_unique += 1
			say("No unique this time. Next boss: %d%% unique chance." % int(unique_chance()))
		checkpoint = maxi(checkpoint, floor_num)
		boss_ready_at[str(floor_num)] = Time.get_unix_time_from_system() + float(GameData.BOSS_COOLDOWN[enemy_boss_kind])
		restock_shop()
		merchant = []
		say("The shop has new stock.")
		codex.bounty_progress("boss")
		_page("uniques")
	elif was_goblin:
		say("[color=#fbbf24]You caught the treasure goblin![/color] +%d gold" % gold_gain)
		for _i in GameData.GOBLIN_ITEMS:
			var r := maxi(2, GameData.roll_rarity(GameData.GOBLIN_RARITY + _loot_bonus(), GameData.LEGENDARY_CHANCE_BOSS))
			_give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), r, floor_num, _new_id()))
		_give_materials(randi_range(1, 2))
		codex.add("goblins")
		codex.bounty_progress("event")
		events.append({"type": "treasure"})
	else:
		var tier_txt := "" if tier == 0 else "[color=%s]%s[/color] " % [Monsters.tier_color(tier), Monsters.tier_name(tier)]
		say("[color=#4ade80]Defeated the[/color] %s[color=#4ade80]%s.[/color] +%d gold" % [tier_txt, enemy_name, gold_gain])
		var drops := 1 + int(t["extra"])
		var leg := GameData.LEGENDARY_CHANCE_NORMAL if tier < Monsters.EPIC else GameData.LEGENDARY_CHANCE_BOSS
		for i in drops:
			var r := GameData.roll_rarity(int(t["loot"]) + _loot_bonus(), leg)
			if i > 0:
				r = maxi(r, 2)
			_give_item(GameData.make_item(_drop_slot(species), r, floor_num, _new_id()))
		if party != null:
			for _m in party.size():
				if randf() < Party.LOOT_PER_MEMBER:
					_give_item(GameData.make_item(_drop_slot(species), GameData.roll_rarity(int(t["loot"]) + _loot_bonus(), leg), floor_num, _new_id()))
		var mats: Array = t["mats"]
		if int(mats[1]) > 0:
			_give_materials(randi_range(int(mats[0]), int(mats[1])))
		if Monsters.has_signature(species) and randf() * Monsters.SIGNATURE_CHANCE < 1.0 + luck_odds() / 100.0:
			_give_signature(species)

	if enemy_champion:
		enemy_champion = false
		World.champion_reward(self)
	hero_hp = mini(hero_hp + int(get_max_hp() * 0.15 * (0.0 if curses.has("frailty") else 1.0)), get_max_hp())

	# Move on (horde fights and the goblin don't count toward the floor's 3 fights)
	if horde_left > 0 and not was_boss and not was_goblin:
		horde_left -= 1
		if horde_left == 0:
			_finish_horde()
		else:
			say("[color=#f87171]Horde: %d left![/color]" % horde_left)
	elif not was_goblin:
		fight += 1
	if was_boss or fight > GameData.FIGHTS_PER_FLOOR:
		_next_floor()
	spawn_enemy()
	_check_codex()
	save_game()

## Living items: kills while worn fill their soul (bosses count 5).
func _feed_souls(boss: bool) -> void:
	for slot in equipped:
		var it: Dictionary = equipped[slot]
		if not GameData.is_living(it):
			continue
		var before := GameData.soul_level(it)
		it["soul"] = int(it.get("soul", 0)) + (5 if boss else 1)
		var after := GameData.soul_level(it)
		if after > before:
			bag_version += 1
			if after >= GameData.SOUL_MAX and String(it.get("effect2", "")) == "":
				var pool := GameData.LEGENDARY_EFFECTS.filter(func(fx): return fx["effect"] != it.get("effect", ""))
				var fx: Dictionary = pool.pick_random()
				it["effect2"] = fx["effect"]
				it["effect2_value"] = maxi(1, int(round(float(fx["value"]) * 0.6)))
				say("[color=#fde047]*** %s AWAKENS! ***[/color] Hidden effect: %s" % [it["name"], GameData.effect_text(it["effect2"], int(it["effect2_value"]))])
				events.append({"type": "mini_event", "kind": "awaken_item", "title": "%s AWAKENS!" % String(it["name"]).to_upper(), "sub": GameData.effect_text(it["effect2"], int(it["effect2_value"]))})
			else:
				say("[color=#fbbf24]%s grows stronger: soul level %d (+%d%% power).[/color]" % [it["name"], after, int(after * GameData.SOUL_POWER * 100)])
				events.append({"type": "mastery", "name": "%s: soul level %d" % [it["name"], after]})

## An evolution set piece, usually from a set that fits your class.
func _roll_evo_piece() -> Dictionary:
	var mine: Array = []
	var tags: Array = (class_info().get("tags", []) as Array).duplicate()
	for n in ClassTree.path_nodes(self):
		tags.append_array(n.get("tags", []))
	for sn in GameData.EVO_SET_ORDER:
		for t in GameData.EVO_SETS[sn]["tags"]:
			if t in tags and not sn in mine:
				mine.append(sn)
	var set_name: String = mine.pick_random() if (not mine.is_empty() and randf() < GameData.EVO_SET_FIT) else GameData.EVO_SET_ORDER.pick_random()
	var slot: String = (GameData.EVO_SETS[set_name]["pieces"] as Dictionary).keys().pick_random()
	tip("evo_sets", "An evolution set piece! Wear 2 or 3 pieces of the same set for big bonuses. Each set fits a family of classes.")
	return GameData.make_evo_piece(set_name, slot, floor_num, _new_id())

## How much stronger (+) or weaker (-) your build gets with this item on, in %.
func compare_pct(item: Dictionary) -> float:
	if not equipped.has(item["slot"]) and item.has("slot"):
		return 100.0
	var base := build_score()
	if base <= 0.0:
		return 0.0
	return (score_with(item) / base - 1.0) * 100.0

func _give_signature(monster: String) -> void:
	var item := GameData.make_signature(monster, floor_num, _new_id())
	say("[color=#ff6b9d]*** SIGNATURE DROP! *** The %s dropped %s![/color]" % [monster, item["name"]])
	events.append({"type": "signature", "name": item["name"], "monster": monster})
	_give_item(item)

func _add_gold(amount: int) -> void:
	gold += amount
	codex.add("gold_earned", amount)
	ClassTree.count(self, "gold_earned", amount)
	ClassTree.grow(self, "gold", float(amount) / (2.0 + floor_num))

func _finish_horde() -> void:
	var g := (5 + floor_num * 6) * GameData.HORDE_CHEST_GOLD
	_add_gold(g)
	say("[color=#fbbf24]The horde is beaten! You find their chest.[/color] +%d gold" % g)
	var r := maxi(2, GameData.roll_rarity(GameData.HORDE_RARITY + _loot_bonus(), GameData.LEGENDARY_CHANCE_BOSS))
	_give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), r, floor_num, _new_id()))
	_give_materials(randi_range(1, 2))
	codex.add("hordes")
	codex.bounty_progress("event")
	events.append({"type": "treasure"})

## For lineage.gd and realms.gd.
func next_floor() -> void:
	_next_floor()

func _next_floor() -> void:
	floor_num += 1
	deaths_here = 0
	Lineage.gain(self, "floor")
	Lineage.on_floor(self)
	if party != null and party.size() > 0:
		party.on_floor()
		if autosave:
			party.save_all()
	fight = 1
	best_floor = maxi(best_floor, floor_num)
	floors_since_event += 1
	codex.bounty_progress("floor")
	var portal_pending := Realms.is_realm_start(floor_num) and GameData.realm_slot(floor_num) >= realm_order.size()
	if GameData.zone_floor(floor_num) == 1 and not portal_pending:
		say("[color=#e8b14a]You enter %s.[/color]" % GameData.zone_for_floor(floor_num)["name"])
	elif (GameData.zone_floor(floor_num) - 1) % GameData.SUB_FLOORS == 0 and not portal_pending:
		say("[color=#e8b14a]You reach %s.[/color]" % GameData.sub_name(floor_num))
	if GameData.is_boss_floor(floor_num):
		say("[color=#f87171]A powerful presence waits on floor %d...[/color]" % floor_num)
		tip("boss", "Boss fight! Bosses hit hard but drop 3 items, materials, and sometimes a rare unique.")
	if best_floor >= GameData.SHOP_UNLOCK_FLOOR:
		tip("shop", "The Shop is open! Spend gold on potions, gear and a bigger bag.")
		_page("shop")
	if best_floor >= GameData.CRAFT_UNLOCK_FLOOR:
		tip("craft", "Crafting unlocked! Sell or salvage spare gear for scrap, then upgrade and reroll your best items.")
		_page("craft")
	if floor_num >= 5:
		_page("zones")
	if floor_num >= 8:
		_page("bounties")
	if floor_num >= 4:
		_page("elements")
	if floor_num >= 10 or best_floor >= World.CURSE_UNLOCK:
		_page("milestones")
	if level >= World.PET_LEVEL:
		_page("pets")
	if floor_num >= 3:
		_page("escape")
	if level >= 8:
		_page("races")
	if best_floor >= GameData.GAMBLE_UNLOCK_FLOOR:
		_page("wheel")
	if best_floor >= GameData.SLOT_UNLOCKS[1]:
		_page("heroes")
		_page("party")
	Realms.on_floor(self)
	if Realms.is_realm_start(floor_num) and GameData.realm_slot(floor_num) >= realm_order.size():
		Realms.offer_portals(self)
	elif GameData.realm_of(floor_num) != "" and GameData.zone_floor(floor_num - 1) == GameData.MID_BOSS_FLOOR:
		Realms.offer_camp(self)
	elif GameData.zone_floor(floor_num - 1) in [GameData.MID_BOSS_FLOOR, GameData.ZONE_FLOORS]:
		_offer_merchant()
	else:
		_maybe_offer_path()
	Realms.note_seen(self)
	if path_offer.is_empty():
		_maybe_start_event()
	World.on_floor(self)

func _hero_died() -> void:
	last_death = Combat.recap(self)
	events.append({"type": "death_recap"})
	hero_status.clear()
	codex.add("deaths")
	ClassTree.on_death(self)
	Lineage.gain(self, "death")
	Hidden.on_death(self)
	_page("death")
	if hardcore:
		run_over = true
		hero_hp = 0
		events.append({"type": "hero_dead", "final": true})
		say("[color=#f87171]Your Hardcore hero has fallen on floor %d.[/color]" % floor_num)
		codex.save()
		return
	events.append({"type": "hero_dead"})
	if party != null:
		party.on_wipe()
	if trial_active:
		trial_active = false
		trial_kind = "god"
		trial_data = {}
		class_encounter = ""
		say("[color=#f87171]%s was too strong. Train harder and try the trial again.[/color]" % enemy_name)
		hero_hp = get_max_hp()
		floor_num = trial_return
		fight = 1
		spawn_enemy()
		save_game()
		return
	pierce_carry = 0
	buffs.clear()
	shield_hp = 0
	summon_turns = 0
	song_turns = 0
	confuse_turns = 0
	kill_streak = 0
	enemy_stun = 0
	enemy_weaken_turns = 0
	horde_left = 0
	enemy_goblin = false
	if enemy_is_boss:
		boss_ready_at[str(floor_num)] = Time.get_unix_time_from_system() + float(GameData.BOSS_COOLDOWN[enemy_boss_kind])
		var back := maxi(GameData.sub_start(floor_num), mini(checkpoint, floor_num - 1))
		say("[color=#f87171]%s was too strong! You're pushed back to floor %d.[/color]" % [enemy_name, back])
		floor_num = back
	else:
		deaths_here += 1
		if deaths_here >= 3 and floor_num > 1 and floor_num - 1 >= checkpoint:
			deaths_here = 0
			floor_num -= 1
			say("[color=#f87171]Defeated again. You fall back to floor %d to get stronger.[/color]" % floor_num)
		else:
			say("[color=#f87171]You were defeated on floor %d. Try again![/color]" % floor_num)
	tip("death", "Defeated, but you keep everything! Better gear and upgrades will get you further.")
	hero_hp = get_max_hp()
	fight = 1
	spawn_enemy()
	save_game()

## Seconds until you can travel to fight this boss floor again (0 = ready).
func boss_cooldown(f: int) -> int:
	var at := float(boss_ready_at.get(str(f), 0.0))
	return maxi(0, ceili(at - Time.get_unix_time_from_system()))

## Travel to any floor you've already reached (boss floors too, to farm uniques).
## Returns false if you can't go (a boss is still resting).
func go_to_floor(target: int) -> bool:
	target = clampi(target, 1, best_floor)
	if target == floor_num and fight == 1:
		return true
	if GameData.is_boss_floor(target) and boss_cooldown(target) > 0:
		say("%s is still recovering. Ready in %d seconds." % [GameData.boss_name(target), boss_cooldown(target)])
		return false
	floor_num = target
	fight = 1
	pierce_carry = 0
	horde_left = 0
	enemy_goblin = false
	path_offer = []
	spawn_enemy()
	Realms.note_seen(self)
	if enemy_is_boss:
		say("You travel to floor %d. [color=#f87171]%s awaits![/color]" % [floor_num, enemy_name])
	else:
		say("You travel to floor %d (%s)." % [floor_num, GameData.sub_name(floor_num)])
	save_game()
	return true

## Kept for older code: step back one floor.
func retreat() -> void:
	go_to_floor(floor_num - 1)

func use_potion() -> void:
	if potions <= 0:
		say("You're out of potions.")
		return
	if trial_active and trial_data.get("no_potions", false):
		say("The hermit's rules: no potions in this fight.")
		return
	ClassTree.on_potion(self)
	potions -= 1
	codex.add("potions_used")
	Hidden.on_potion(self)
	kill_streak = 0
	var heal := int(get_max_hp() * GameData.POTION_HEAL * (1.0 + _flat("potion") / 100.0) * heal_mult() * (0.5 if curses.has("thirst") else 1.0))
	hero_hp = mini(hero_hp + heal, get_max_hp())
	say("[color=#f472b6]Drank a potion (+%d HP).[/color]" % heal)
	events.append({"type": "potion", "amount": heal})
	save_game()

# =====================================================================
# Loot and bag
# =====================================================================

## True if the loot filter wants this new drop turned into scrap.
func filter_salvages(item: Dictionary) -> bool:
	var r := int(item["rarity"])
	if r > 3 or item.get("locked", false):
		return false  # Legendary and better are always kept
	if r <= auto_salvage:
		return true
	if r <= 2:
		if bool(loot_filter.get("slots", {}).get(item["slot"], false)):
			return true
		if bool(loot_filter.get("weaker", false)) and equipped.has(item["slot"]) and GameData.item_power(item) <= GameData.item_power(equipped[item["slot"]]) and not is_upgrade(item):
			return true
	return false

func _give_item(item: Dictionary) -> void:
	add_to_wardrobe(item)
	codex.found_item(item)
	var r := int(item["rarity"])
	codex.bounty_progress("item", {"rarity": r})
	events.append({"type": "loot", "name": GameData.display_name(item), "rarity": r, "up": compare_pct(item)})
	_page("gear")
	var keep := r in [GameData.UNIQUE, GameData.SIGNATURE]
	if not keep and filter_salvages(item):
		var s := GameData.scrap_value(item)
		scrap += s
		say("Auto-salvaged %s (+%d scrap)" % [_tag(item), s])
	elif bag_full() and not keep:
		var s := GameData.scrap_value(item)
		scrap += s
		say("Bag full! Salvaged %s (+%d scrap)" % [_tag(item), s])
		tip("bag_full", "Your bag is full, so new drops turn into scrap. Sell or salvage items in the Bag tab to make room.")
	else:
		if keep:
			item["locked"] = true  # never lose a unique by accident
		bag.append(item)
		bag_version += 1
		say("Found %s (+%d %s)" % [_tag(item), GameData.item_power(item), item["stat"]])
		if r == GameData.LEGENDARY:
			tip("legendary", "A Legendary! Every Legendary has a special effect. Check it in the Bag or Gear tab.")
		if has_upgrade(item["slot"]):
			tip("first_upgrade", "That's an upgrade! Press Equip Best in the Gear tab to put it on.")

# =====================================================================
# Codex: achievements and guide pages
# =====================================================================

func _page(id: String) -> void:
	if codex.unlock_page(id):
		events.append({"type": "guide", "id": id})

## Updates records and hands out any achievement rewards that were just earned.
func _check_codex() -> void:
	codex.at_least("best_floor", best_floor)
	codex.at_least("best_level", level)
	codex.at_least("wardrobe", wardrobe.size())
	if hardcore:
		codex.at_least("hc_floor", best_floor)
	for a in codex.check(self):
		# The reward goes to the Mailbox (mail.gd)
		Mail.post(self, "The Guild Hall", "Deed: %s" % a["name"], "%s. Well done! Here is your reward." % a["text"], Town.deed_reward(a))
		var line := "[color=#fbbf24]Achievement: %s![/color] Your reward is in the Mailbox in town." % a["name"]
		if a.has("title"):
			line += "  New title: [color=#e8b14a]%s[/color]" % a["title"]
		say(line)
		events.append({"type": "achievement", "name": a["name"], "text": a["text"], "title": a.get("title", "")})
	if codex.dirty and autosave:
		codex.save()

## Gives a reward like {"gold": 500} or {"scroll": "luck"}. Returns a short description.
func give_reward(r: Dictionary) -> String:
	var parts: Array = []
	if r.has("gold"):
		var g := int(float(r["gold"]) * (1.0 + best_floor / 25.0))
		_add_gold(g)
		parts.append("+%d gold" % g)
	if r.has("potions"):
		potions += int(r["potions"])
		parts.append("+%d potions" % int(r["potions"]))
	if r.has("scrap"):
		var sc := int(float(r["scrap"]) * (1.0 + best_floor / 50.0))
		scrap += sc
		parts.append("+%d scrap" % sc)
	if r.has("mats"):
		var m := GameData.zone_index(best_floor)
		materials[m] = int(materials[m]) + int(r["mats"])
		parts.append("+%d %s" % [int(r["mats"]), GameData.MATERIALS[m]])
	if r.has("scroll"):
		parts.append(use_scroll(str(r["scroll"])))
	if r.has("look"):
		var cd: Dictionary = Realms.COSMETICS.get(r["look"], {})
		if not cd.is_empty():
			wardrobe["c_" + str(r["look"])] = {"slot": cd["slot"], "type": cd["type"], "rarity": GameData.UNIQUE, "art": "c_" + str(r["look"]), "set": "", "name": cd["name"]}
			parts.append("a new look: %s" % cd["name"])
	return ", ".join(parts)

## Returns {"where": "bag"/"equipped", "index" or "slot", "item"}, or {} if not found.
func find_item(id: int) -> Dictionary:
	for i in bag.size():
		if int(bag[i]["id"]) == id:
			return {"where": "bag", "index": i, "item": bag[i]}
	for slot in equipped:
		var item: Dictionary = equipped[slot]
		if int(item["id"]) == id:
			return {"where": "equipped", "slot": slot, "item": item}
	return {}

func equip(id: int) -> void:
	var found := find_item(id)
	if found.is_empty() or found["where"] != "bag":
		return
	var item: Dictionary = found["item"]
	if not Races.can_wear(self, item):
		say("Only a %s can wear %s." % [item.get("race_only", ""), _tag(item)])
		return
	var idx: int = found["index"]
	var slot: String = item["slot"]
	add_to_wardrobe(item)
	bag.remove_at(idx)
	if equipped.has(slot):
		bag.insert(idx, equipped[slot])
	equipped[slot] = item
	hero_hp = mini(hero_hp, get_max_hp())
	bag_version += 1
	say("Equipped %s." % _tag(item))
	save_game()

## Puts on the strongest item from the bag in every slot.
func equip_best() -> void:
	var changed := 0
	for _pass in 2:  # twice, so set bonuses that need two pieces can click into place
		for slot in GameData.SLOT_ORDER:
			var pick := best_for_slot(slot)
			if not pick.is_empty():
				equip(int(pick["id"]))
				changed += 1
	if changed == 0:
		say("You're already wearing your best gear.")

func unequip(id: int) -> void:
	var found := find_item(id)
	if found.is_empty() or found["where"] != "equipped":
		return
	if bag_full():
		say("Your bag is full.")
		return
	var item: Dictionary = found["item"]
	equipped.erase(found["slot"])
	bag.append(item)
	hero_hp = mini(hero_hp, get_max_hp())
	bag_version += 1
	say("Unequipped %s." % _tag(item))
	save_game()

func sell(id: int) -> void:
	var found := find_item(id)
	if found.is_empty() or found["where"] != "bag":
		return
	var item: Dictionary = found["item"]
	if item.get("locked", false):
		say("%s is locked. Unlock it first." % _tag(item))
		return
	var value := sell_price(item)
	gold += value
	ClassTree.count(self, "sold")
	bag.remove_at(int(found["index"]))
	bag_version += 1
	say("Sold %s for %d gold." % [_tag(item), value])
	save_game()

## Salvaging bonus: Dwarves, and the dwarven forge's heat.
func scrap_mult() -> float:
	return (1.0 + _flat("scrap") / 100.0) * Realms.scrap_mult(self)

func salvage(id: int) -> void:
	var found := find_item(id)
	if found.is_empty() or found["where"] != "bag":
		return
	var item: Dictionary = found["item"]
	if item.get("locked", false):
		say("%s is locked. Unlock it first." % _tag(item))
		return
	var value := int(GameData.scrap_value(item) * scrap_mult())
	scrap += value
	Lineage.gain(self, "craft")
	ClassTree.count(self, "scrapped")
	ClassTree.grow(self, "craft")
	bag.remove_at(int(found["index"]))
	bag_version += 1
	say("Salvaged %s for %d scrap." % [_tag(item), value])
	_salvage_materials(item)
	save_game()

func upgrade(id: int) -> void:
	var found := find_item(id)
	if found.is_empty():
		return
	var item: Dictionary = found["item"]
	if int(item["level"]) >= GameData.MAX_UPGRADE:
		say("%s is already max level." % _tag(item))
		return
	var cost := GameData.upgrade_cost(item)
	if scrap < cost:
		say("Not enough scrap (need %d)." % cost)
		return
	scrap -= cost
	ClassTree.grow(self, "craft")
	item["level"] = int(item["level"]) + 1
	codex.at_least("max_upgrade", int(item["level"]))
	bag_version += 1
	say("Upgraded to %s! (+%d %s)" % [_tag(item), GameData.item_power(item), item["stat"]])
	save_game()

func reroll(id: int) -> void:
	var found := find_item(id)
	if found.is_empty():
		return
	var item: Dictionary = found["item"]
	if not GameData.can_reroll(item):
		say("%s can't be rerolled." % _tag(item))
		return
	var cost := GameData.reroll_cost(item)
	if scrap < cost:
		say("Not enough scrap (need %d)." % cost)
		return
	scrap -= cost
	if randi_range(1, 100) <= GameData.reroll_chance(item):
		var new_rarity := int(item["rarity"]) + 1
		item["rarity"] = new_rarity
		item["name"] = GameData.item_name(item)
		item["bonus"] = maxi(1, int(GameData.base_bonus(item["slot"], int(item["floor"])) * float(GameData.RARITY_MULTS[new_rarity])))
		if new_rarity == GameData.LEGENDARY:
			GameData.add_legendary_effect(item)
		say("[color=#4ade80]Reroll success![/color] It's now %s." % _tag(item))
		codex.add("rerolls_won")
	else:
		say("[color=#f87171]Reroll failed.[/color] %s stays the same." % _tag(item))
	hero_hp = mini(hero_hp, get_max_hp())
	bag_version += 1
	save_game()

## Epic and Legendary gear gives back some of its zone's material when salvaged.
func _salvage_materials(item: Dictionary) -> void:
	var r := int(item["rarity"])
	if GameData.SALVAGE_MATERIALS.has(r):
		_give_materials(int(GameData.SALVAGE_MATERIALS[r]), GameData.zone_index(int(item["floor"])))

func cycle_auto_salvage() -> void:
	auto_salvage += 1
	if auto_salvage > 3:
		auto_salvage = -1
	save_game()

## True if this bag item is stronger than what's worn in its slot.
func is_upgrade(item: Dictionary) -> bool:
	return score_with(item) > build_score() * 1.001

## How many bag items of this rarity "Salvage all" would scrap (upgrades are kept).
func toggle_lock(id: int) -> void:
	var found := find_item(id)
	if found.is_empty():
		return
	var item: Dictionary = found["item"]
	item["locked"] = not item.get("locked", false)
	bag_version += 1
	say("%s %s." % [_tag(item), "locked: it can't be sold or salvaged" if item["locked"] else "unlocked"])
	save_game()

func salvage_all_count(rarity: int) -> int:
	var n := 0
	for item in bag:
		if int(item["rarity"]) == rarity and not item.get("locked", false) and not is_upgrade(item):
			n += 1
	return n

## Salvages every bag item of one rarity, except ones that would be upgrades.
func salvage_all(rarity: int) -> void:
	var count := 0
	var total := 0
	for item in bag.duplicate():
		if int(item["rarity"]) == rarity and not item.get("locked", false) and not is_upgrade(item):
			total += GameData.scrap_value(item)
			bag.erase(item)
			count += 1
	if count == 0:
		return
	scrap += total
	ClassTree.count(self, "scrapped", count)
	bag_version += 1
	say("Salvaged %d %s items for %d scrap." % [count, GameData.RARITY_NAMES[rarity], total])
	if GameData.SALVAGE_MATERIALS.has(rarity):
		var m := GameData.zone_index(best_floor)
		var n := count * int(GameData.SALVAGE_MATERIALS[rarity])
		materials[m] = int(materials[m]) + n
		say("[color=#2dd4bf]+%d %s[/color]" % [n, GameData.MATERIALS[m]])
	save_game()

# =====================================================================
# Gold: shop, potions, bag upgrades
# =====================================================================

func potion_cost() -> int:
	return price(GameData.POTION_GOLD)

func greater_potion_cost() -> int:
	return price(GameData.GREATER_POTION_GOLD)

func restock_cost() -> int:
	return price(GameData.SHOP_RESTOCK_GOLD)

func elixir_cost(id: String) -> int:
	return price(int(GameData.ELIXIRS[id]["gold"]))

func shop_cost(item: Dictionary) -> int:
	return price(GameData.shop_price(item))

func buy_potion() -> void:
	if gold < potion_cost():
		say("Not enough gold.")
		return
	gold -= potion_cost()
	potions += 1
	say("Bought a potion. You have %d." % potions)
	save_game()

func next_bag_cost() -> int:
	return GameData.bag_cost(bag_level)

func buy_bag_upgrade() -> void:
	if bag_level >= GameData.BAG_MAX_LEVEL:
		say("Your bag is already as big as it gets.")
		return
	var cost := next_bag_cost()
	if gold < cost:
		say("Not enough gold (need %d)." % cost)
		return
	gold -= cost
	bag_level += 1
	say("Bag upgraded to %d slots!" % bag_capacity())
	save_game()

func restock_shop() -> void:
	var feat_rarity := GameData.LEGENDARY if randf() * 100.0 < GameData.FEATURED_LEGENDARY_CHANCE else 3
	var feat_slot: String = GameData.SLOT_ORDER.pick_random()
	featured = Town.local_goods(self, GameData.make_item(feat_slot, feat_rarity, best_floor, _new_id()))
	shop.clear()
	for _i in GameData.SHOP_SIZE:
		var slot: String = GameData.SLOT_ORDER.pick_random()
		shop.append(Town.local_goods(self, GameData.make_item(slot, GameData.roll_rarity(GameData.SHOP_RARITY_BONUS, GameData.LEGENDARY_CHANCE_SHOP), best_floor, _new_id())))
	shop_zone = GameData.zone_index(maxi(1, floor_num))
	shop_version += 1

func featured_price() -> int:
	return shop_cost(featured) * GameData.FEATURED_PRICE_MULT if not featured.is_empty() else 0

func buy_featured() -> bool:
	if featured.is_empty():
		return false
	var price := featured_price()
	if gold < price:
		say("Not enough gold (need %d)." % price)
		return false
	if bag_full():
		say("Your bag is full.")
		return false
	gold -= price
	var item := featured
	featured = {}
	bag.append(item)
	bag_version += 1
	shop_version += 1
	say("Bought the featured %s for %d gold!" % [_tag(item), price])
	events.append({"type": "loot", "name": item["name"], "rarity": int(item["rarity"])})
	save_game()
	return true

func buy_greater_potion() -> void:
	if gold < greater_potion_cost():
		say("Not enough gold.")
		return
	gold -= greater_potion_cost()
	var heal := get_max_hp() - hero_hp
	hero_hp = get_max_hp()
	events.append({"type": "potion", "amount": heal})
	say("[color=#f472b6]Greater Potion! Fully healed.[/color]")
	save_game()

func buy_elixir(id: String) -> void:
	var info: Dictionary = GameData.ELIXIRS[id]
	if gold < elixir_cost(id):
		say("Not enough gold.")
		return
	gold -= elixir_cost(id)
	elixirs[id] = int(info["turns"])
	events.append({"type": "buff", "name": info["name"]})
	say("[color=#c4b5fd]%s![/color] %s" % [info["name"], info["text"]])
	save_game()

## Sells every bag item of a rarity, keeping locked items and upgrades.
func sell_all(rarity: int) -> void:
	var count := 0
	var total := 0
	for item in bag.duplicate():
		if int(item["rarity"]) == rarity and not item.get("locked", false) and not is_upgrade(item):
			total += sell_price(item)
			bag.erase(item)
			count += 1
	if count == 0:
		return
	gold += total
	ClassTree.count(self, "sold", count)
	bag_version += 1
	say("Sold %d %s items for %d gold." % [count, GameData.RARITY_NAMES[rarity], total])
	save_game()

func paid_restock() -> void:
	if gold < restock_cost():
		say("Not enough gold.")
		return
	gold -= restock_cost()
	restock_shop()
	say("The shop has new stock.")
	save_game()

func buy_shop(index: int) -> bool:
	if index < 0 or index >= shop.size():
		return false
	var item: Dictionary = shop[index]
	var price := shop_cost(item)
	if gold < price:
		say("Not enough gold (need %d)." % price)
		return false
	if bag_full():
		say("Your bag is full.")
		return false
	gold -= price
	shop.remove_at(index)
	shop_version += 1
	bag.append(item)
	bag_version += 1
	say("Bought %s for %d gold." % [_tag(item), price])
	save_game()
	return true

# =====================================================================
# Crafting (scrap)
# =====================================================================

func craft_potion() -> void:
	if scrap < GameData.POTION_SCRAP:
		say("Not enough scrap.")
		return
	scrap -= GameData.POTION_SCRAP
	potions += 1
	Hidden.on_craft_potion(self)
	say("Crafted a potion. You have %d." % potions)
	save_game()

# ---------- Dev Mode tools ----------

func dev_grant(kind: String) -> void:
	if not dev_mode:
		return
	match kind:
		"level":
			for _i in 5:
				gain_xp(GameData.xp_to_next(level) - xp)
		"gold":
			gold += 10000
		"scrap":
			scrap += 1000
		"materials":
			for i in materials.size():
				materials[i] = int(materials[i]) + 10
		"floor_up":
			floor_num += 10
			horde_left = 0
			best_floor = maxi(best_floor, floor_num)
			fight = 1
			spawn_enemy()
		"floor_down":
			floor_num = maxi(1, floor_num - 10)
			fight = 1
			spawn_enemy()
		"legendary":
			var slot: String = GameData.SLOT_ORDER.pick_random()
			var item := GameData.make_item(slot, GameData.LEGENDARY, best_floor, _new_id())
			bag.append(item)
			bag_version += 1
		"unique":
			var uniques := GameData.zone_uniques(GameData.zone_index(floor_num))
			var item := GameData.make_unique(uniques.pick_random(), best_floor, _new_id())
			item["locked"] = true
			bag.append(item)
			bag_version += 1
		"heal":
			hero_hp = get_max_hp()
			potions += 10
		"signature":
			_give_signature(GameData.pick_monster(floor_num)["name"])
		"rare":
			_apply_tier(mini(Monsters.MYTHIC, maxi(enemy_tier + 1, Monsters.EPIC)))
		"event":
			start_event(["goblin", "horde", "shrine"].pick_random())
		"merchant":
			path_offer = ["fight", "merchant"]
			path_wait = 0
		"goblin", "horde", "shrine":
			start_event(kind)
			if kind == "goblin":
				spawn_enemy()
		"tier_0", "tier_1", "tier_2", "tier_3", "tier_4", "tier_5":
			if not enemy_is_boss:
				enemy_goblin = false
				_apply_tier(int(kind.substr(5)))
		"mid_boss", "zone_boss":
			var zf := GameData.MID_BOSS_FLOOR if kind == "mid_boss" else GameData.ZONE_FLOORS
			var target := floor_num - GameData.zone_floor(floor_num) + zf
			if target < floor_num:
				target += GameData.ZONE_FLOORS
			best_floor = maxi(best_floor, target)
			boss_ready_at.erase(str(target))
			go_to_floor(target)
		"next_area":
			var nxt := GameData.sub_start(floor_num) + GameData.SUB_FLOORS
			best_floor = maxi(best_floor, nxt)
			go_to_floor(nxt)
		"kills100":
			var e := codex.entry(enemy_species)
			e["kills"] = int(e["kills"]) + 100
			codex.add("kills", 100)
		"bounties":
			for list_name in ["daily", "weekly"]:
				for b in codex.bounties.get(list_name, []):
					b["have"] = b["need"]
					b["done"] = true
		"pages":
			for pg in Guide.PAGES:
				codex.guide[pg["id"]] = true
		"cooldowns":
			boss_ready_at.clear()
		"always_win":
			dev_always_win = not dev_always_win
		"fill_bag":
			while not bag_full():
				var it := GameData.make_item(GameData.SLOT_ORDER.pick_random(), randi() % 4, best_floor, _new_id())
				add_to_wardrobe(it)
				bag.append(it)
			bag_version += 1
		"box":
			say(use_scroll("box"))
		"race_power":
			race_power += 50.0
		"awaken":
			if not Lineage.next_rank(self).is_empty():
				Lineage._rank_up(self)
		"race_key":
			var nk: Dictionary = Lineage.next_rank(self).get("key", {})
			if nk.has("item"):
				Lineage._give_key(self, nk["item"])
		"phylactery":
			Lineage._give_key(self, "Phylactery")
		"form_Vampire", "form_Werewolf", "form_Fallen Angel", "form_Lich":
			Lineage.transform(self, kind.substr(5))
		"form_none":
			if form != "":
				Lineage.cured(self)
			lycan_pending = false
		"rep_up", "rep_down":
			for r in Races.ORDER:
				Lineage.change_rep(self, r, 25.0 if kind == "rep_up" else -25.0, false)
		"rep_exalted":
			var rr := Realms.zone_race(GameData.zone_index(floor_num))
			if rr != "":
				rep[rr] = 100.0
		"realms":
			best_floor = maxi(best_floor, Realms.FIRST_FLOOR)
			floor_num = Realms.FIRST_FLOOR - 1
			fight = GameData.FIGHTS_PER_FLOOR + 1
			_next_floor()
			spawn_enemy()
		"next_realm":
			var nr := floor_num - GameData.zone_floor(floor_num) + GameData.ZONE_FLOORS + 1
			best_floor = maxi(best_floor, nr)
			floor_num = nr - 1
			_next_floor()
			spawn_enemy()
		"encounter":
			if GameData.realm_of(floor_num) != "":
				Realms.start_encounter(self)
		"realm_event":
			if GameData.realm_of(floor_num) != "":
				Realms.start_realm_event(self)
		"camp":
			if GameData.realm_of(floor_num) != "":
				Realms.offer_camp(self)
		"portals":
			if not realm_order.is_empty():
				realm_order.pop_back()
				GameData.realm_order = realm_order
			Realms.offer_portals(self)
		"hidden_all":
			for id in Hidden.ORDER:
				if not hidden.has(id):
					Hidden.unlock(self, id)
		"hidden_stage":
			if hidden_class != "":
				hidden_stage[hidden_class] = mini(int(hidden_stage.get(hidden_class, 1)) + 1, Hidden.info(hidden_class)["stages"].size())
		"hidden_stat":
			if hidden_class != "":
				var hs: String = Hidden.info(hidden_class)["stat"]
				unique[hs] = float(unique.get(hs, 0.0)) + 50.0
	say("[color=#f472b6][DEV][/color] %s" % kind)
	_check_codex()
	save_game()

func material_total() -> int:
	var t := 0
	for m in materials:
		t += int(m)
	return t

## Why a set piece can't be crafted right now, or "".
func set_block_reason(set_name: String) -> String:
	var mat: int = GameData.SETS[set_name]["material"]
	if int(materials[mat]) < GameData.SET_PIECE_MATERIALS:
		return "Need %d %s" % [GameData.SET_PIECE_MATERIALS, GameData.MATERIALS[mat]]
	if scrap < GameData.SET_PIECE_SCRAP:
		return "Need %d scrap" % GameData.SET_PIECE_SCRAP
	if bag_full():
		return "Bag is full"
	return ""

func craft_set_piece(set_name: String, slot: String) -> void:
	if set_block_reason(set_name) != "":
		say("Can't craft that yet: %s." % set_block_reason(set_name))
		return
	var mat: int = GameData.SETS[set_name]["material"]
	materials[mat] = int(materials[mat]) - GameData.SET_PIECE_MATERIALS
	scrap -= GameData.SET_PIECE_SCRAP
	var item := GameData.make_set_item(set_name, slot, best_floor, _new_id())
	codex.add("sets_crafted")
	codex.found_item(item)
	add_to_wardrobe(item)
	bag.append(item)
	bag_version += 1
	say("Crafted %s (+%d %s)!" % [_tag(item), GameData.item_power(item), item["stat"]])
	events.append({"type": "loot", "name": item["name"], "rarity": GameData.SET_RARITY})
	tip("sets", "Set items get bonuses when you wear 2 or 3 pieces of the same set.")
	save_game()

func bag_craft_block_reason() -> String:
	if bag_level >= GameData.BAG_MAX_LEVEL:
		return "Bag is fully upgraded"
	if material_total() < GameData.bag_craft_materials(bag_level):
		return "Need %d boss materials" % GameData.bag_craft_materials(bag_level)
	if scrap < GameData.bag_craft_scrap(bag_level):
		return "Need %d scrap" % GameData.bag_craft_scrap(bag_level)
	return ""

## Sews a bigger bag from any boss materials (uses your biggest stacks first).
func craft_bag() -> void:
	if bag_craft_block_reason() != "":
		say("Can't craft a bag yet: %s." % bag_craft_block_reason())
		return
	var need := GameData.bag_craft_materials(bag_level)
	scrap -= GameData.bag_craft_scrap(bag_level)
	while need > 0:
		var biggest := 0
		for i in materials.size():
			if int(materials[i]) > int(materials[biggest]):
				biggest = i
		materials[biggest] = int(materials[biggest]) - 1
		need -= 1
	bag_level += 1
	say("Crafted a bigger bag: %d slots!" % bag_capacity())
	save_game()

func craft_gear(slot: String) -> void:
	if scrap < GameData.CRAFT_GEAR_SCRAP:
		say("Not enough scrap (need %d)." % GameData.CRAFT_GEAR_SCRAP)
		return
	if bag_full():
		say("Your bag is full.")
		return
	scrap -= GameData.CRAFT_GEAR_SCRAP
	var item := GameData.make_item(slot, GameData.roll_rarity(GameData.CRAFT_RARITY_BONUS, GameData.LEGENDARY_CHANCE_CRAFT), best_floor, _new_id())
	bag.append(item)
	bag_version += 1
	say("Crafted %s (+%d %s)." % [_tag(item), GameData.item_power(item), item["stat"]])
	save_game()

# =====================================================================
# Saving
# =====================================================================

func save_game() -> void:
	if not autosave:
		return
	var data := {
		"version": GameData.SAVE_VERSION,
		"floor": floor_num,
		"fight": fight,
		"best_floor": best_floor,
		"hero_hp": hero_hp,
		"gold": gold,
		"scrap": scrap,
		"potions": potions,
		"bag_level": bag_level,
		"next_id": next_id,
		"auto_potion": auto_potion,
		"autoplay": autoplay,
		"auto_paths": auto_paths,
		"auto_salvage": auto_salvage,
		"fast_mode": fast_mode,
		"tips_seen": tips_seen,
		"bosses_since_unique": bosses_since_unique,
		"sound_on": sound_on,
		"hero_class": hero_class,
		"level": level,
		"xp": xp,
		"auto_ability": auto_ability,
		"in_town": in_town,
		"contracts": contracts,
		"board_day": board_day,
		"mail": mail,
		"shop_zone": shop_zone,
		"stats": stats,
		"stat_points": stat_points,
		"stat_ver": 2,
		"auto_stats": auto_stats,
		"auto_potion_at": auto_potion_at,
		"checkpoint": checkpoint,
		"curses": curses,
		"pet_on": pet_on,
		"pet_name": pet_name,
		"pet_seen": pet_seen,
		"skill_priority": skill_priority,
		"skill_auto_off": skill_auto_off,
		"last_death": last_death,
		"respec_tomes": respec_tomes,
		"builds": builds,
		"skill_book": skill_book,
		"dust": dust,
		"active_slots": active_slots,
		"sig_slot": sig_slot,
		"hero_status": hero_status,
		"passive_slots": passive_slots,
		"stones_since": stones_since,
		"faith": faith,
		"unique": unique,
		"class_tree": ClassTree.to_save(self),
		"kill_streak": kill_streak,
		"party_slots": party_slots,
		"materials": materials,
		"discovered": discovered,
		"featured": featured,
		"elixirs": elixirs,
		"dev_mode": dev_mode,
		"volume": volume,
		"music_volume": music_volume,
		"fullscreen": fullscreen,
		"bag": bag,
		"equipped": equipped,
		"shop": shop,
		"hardcore": hardcore,
		"appearance": appearance,
		"wardrobe": wardrobe,
		"transmog": transmog,
		"hero_name": hero_name,
		"boss_ready_at": boss_ready_at,
		"floors_since_event": floors_since_event,
		"horde_left": horde_left,
		"curse_turns": curse_turns,
		"luck_turns": luck_turns,
		"hunt_spawns": hunt_spawns,
		"merchant": merchant,
		"loadouts": loadouts,
		"loot_filter": loot_filter,
		"enemy_goblin": enemy_goblin,
		"lineage": Lineage.to_save(self),
		"meta": meta(),
	}
	# Write to a temp file first, keep the last good save as a backup, then swap.
	# If the game crashes mid-save, the old save or the backup is still intact.
	if codex.dirty:
		codex.save()
	if run_over:
		return
	var paths := save_paths()
	var file := FileAccess.open(paths[2], FileAccess.WRITE)
	if file == null:
		return
	file.store_var(data)
	file.close()
	var main_path := ProjectSettings.globalize_path(paths[0])
	if FileAccess.file_exists(paths[0]):
		var backup_path := ProjectSettings.globalize_path(paths[1])
		if FileAccess.file_exists(paths[1]):
			DirAccess.remove_absolute(backup_path)
		DirAccess.rename_absolute(main_path, backup_path)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(paths[2]), main_path)

## A short summary of this hero for the title screen.
func meta() -> Dictionary:
	return {"name": hero_name, "title": title() if hero_class != "" else "New hero", "class": hero_class, "level": level,
		"floor": floor_num, "best": best_floor, "hardcore": hardcore, "appearance": appearance.duplicate(),
		"zone": GameData.zone_for_floor(floor_num)["name"], "date": Time.get_date_string_from_system()}

## [save, backup, temp] for this hero's slot.
func save_paths() -> Array:
	return slot_paths(slot)

static func slot_paths(n: int) -> Array:
	return [SLOT_PATH % n, SLOT_BACKUP % n, SLOT_TEMP % n]

## Deletes only this hero's save (a fallen Hardcore hero, or Delete hero).
func delete_own_saves() -> void:
	delete_slot(slot)

static func delete_slot(n: int) -> void:
	for path in slot_paths(n):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func has_slot(n: int) -> bool:
	var paths := slot_paths(n)
	return FileAccess.file_exists(paths[0]) or FileAccess.file_exists(paths[1])

## The title-screen summary of the hero in a slot ({} if empty).
static func slot_meta(n: int) -> Dictionary:
	if not has_slot(n):
		return {}
	var paths := slot_paths(n)
	var data = _read_save(paths[0])
	if data == null:
		data = _read_save(paths[1])
	if data == null:
		return {}
	var d: Dictionary = data
	var m: Dictionary = d.get("meta", {})
	if m.is_empty():
		m = {"name": d.get("hero_name", ""), "title": d.get("hero_class", "Hero"), "class": d.get("hero_class", ""), "level": d.get("level", 1),
			"floor": d.get("floor", 1), "best": d.get("best_floor", 1), "hardcore": d.get("hardcore", false), "appearance": d.get("appearance", {}),
			"zone": GameData.zone_for_floor(int(d.get("floor", 1)))["name"], "date": ""}
	return m

## Older versions had one Regular and one Hardcore save. Moves them into hero slots.
## Returns the slots they went to.
static func migrate_legacy() -> Array:
	var moved: Array = []
	for pair in [[SAVE_PATH, BACKUP_PATH], [HC_SAVE_PATH, HC_BACKUP_PATH]]:
		if not (FileAccess.file_exists(pair[0]) or FileAccess.file_exists(pair[1])):
			continue
		var n := 1
		while n <= GameData.MAX_HEROES and has_slot(n):
			n += 1
		if n > GameData.MAX_HEROES:
			break
		var to := slot_paths(n)
		for i in 2:
			if FileAccess.file_exists(pair[i]):
				DirAccess.rename_absolute(ProjectSettings.globalize_path(pair[i]), ProjectSettings.globalize_path(to[i]))
		moved.append(n)
	return moved

static func _read_save(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var data = file.get_var()
	if typeof(data) != TYPE_DICTIONARY or not (data as Dictionary).has("floor"):
		return null
	return data

## Deletes every save file (used by "Reset save").
static func delete_saves() -> void:
	for path in [SAVE_PATH, BACKUP_PATH, TEMP_PATH, HC_SAVE_PATH, HC_BACKUP_PATH, HC_TEMP_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for n in range(1, GameData.MAX_HEROES + 1):
		delete_slot(n)

## Returns true if a save was found and loaded. Falls back to the backup if the main save is damaged.
func load_game() -> bool:
	var paths := save_paths()
	var data = _read_save(paths[0])
	if data == null:
		for fallback in [paths[1], paths[2]]:
			data = _read_save(fallback)
			if data != null:
				restored_backup = FileAccess.file_exists(paths[0])
				break
	if data == null:
		return false
	# Choices waiting on screen belong to whoever was playing before
	path_offer = []
	path_wait = 0
	class_encounter = ""
	if int(data.get("version", 1)) < GameData.SAVE_VERSION:
		_convert_old_save(data)
		return true

	floor_num = int(data.get("floor", 1))
	fight = int(data.get("fight", 1))
	best_floor = int(data.get("best_floor", 1))
	gold = int(data.get("gold", 0))
	scrap = int(data.get("scrap", 0))
	potions = int(data.get("potions", GameData.START_POTIONS))
	bag_level = int(data.get("bag_level", 0))
	next_id = int(data.get("next_id", 1))
	auto_potion = bool(data.get("auto_potion", true))
	autoplay = bool(data.get("autoplay", true))
	auto_paths = bool(data.get("auto_paths", true))
	auto_salvage = int(data.get("auto_salvage", -1))
	fast_mode = bool(data.get("fast_mode", false))
	tips_seen = data.get("tips_seen", {})
	bosses_since_unique = int(data.get("bosses_since_unique", 0))
	sound_on = bool(data.get("sound_on", true))
	hero_class = str(data.get("hero_class", ""))
	level = int(data.get("level", 1))
	xp = int(data.get("xp", 0))
	auto_ability = bool(data.get("auto_ability", true))
	in_town = bool(data.get("in_town", false))
	contracts = data.get("contracts", [])
	board_day = str(data.get("board_day", ""))
	mail = data.get("mail", [])
	shop_zone = int(data.get("shop_zone", -1))
	var saved_stats: Dictionary = data.get("stats", {})
	for st in GameData.STAT_ORDER:
		stats[st] = int(saved_stats.get(st, 0))
	# Saves from before stat points get the points for the levels they already earned
	stat_points = int(data.get("stat_points", (level - 1) * GameData.STAT_POINTS_PER_LEVEL))
	skill_book = data.get("skill_book", {})
	dust = int(data.get("dust", 0))
	var sa: Array = data.get("active_slots", ["", "", ""])
	var sp_slots: Array = data.get("passive_slots", ["", "", "", "", ""])
	for i in 3:
		active_slots[i] = str(sa[i]) if i < sa.size() else ""
	for i in 5:
		passive_slots[i] = str(sp_slots[i]) if i < sp_slots.size() else ""
	stones_since = int(data.get("stones_since", 0))
	faith = float(data.get("faith", 0.0))
	unique = data.get("unique", {})
	auto_stats = bool(data.get("auto_stats", false))
	auto_potion_at = float(data.get("auto_potion_at", GameData.AUTO_POTION_AT))
	checkpoint = int(data.get("checkpoint", 0))
	curses = data.get("curses", {})
	pet_on = bool(data.get("pet_on", true))
	pet_name = str(data.get("pet_name", ""))
	pet_seen = int(data.get("pet_seen", -1))
	skill_priority = data.get("skill_priority", [])
	skill_auto_off = data.get("skill_auto_off", {})
	last_death = data.get("last_death", {})
	respec_tomes = int(data.get("respec_tomes", 0))
	var saved_builds: Array = data.get("builds", [])
	for i in mini(saved_builds.size(), builds.size()):
		builds[i] = saved_builds[i]
	unique.erase("Sword Intent")
	unique.erase("Demonic Qi")
	ClassTree.from_save(self, data.get("class_tree", {}))
	sig_slot = str(data.get("sig_slot", ""))
	hero_status = data.get("hero_status", {})
	var sigs := Signatures.owned(self)
	if not sig_slot in sigs:
		sig_slot = sigs[sigs.size() - 1] if not sigs.is_empty() else ""
	kill_streak = int(data.get("kill_streak", 0))
	party_slots = data.get("party_slots", [])
	if hero_class != "" and not data.has("skill_book"):
		_convert_old_skills(data)
	discovered = data.get("discovered", {})
	featured = data.get("featured", {})
	elixirs = data.get("elixirs", {})
	dev_mode = bool(data.get("dev_mode", false))
	volume = float(data.get("volume", 0.8))
	music_volume = float(data.get("music_volume", 0.5))
	fullscreen = bool(data.get("fullscreen", false))
	var saved_mats: Array = data.get("materials", [])
	for i in mini(saved_mats.size(), materials.size()):
		materials[i] = int(saved_mats[i])
	for n in ClassTree.path_nodes(self):
		discovered[n["name"]] = true
	bag.assign(data.get("bag", []))
	equipped = data.get("equipped", {})
	needs_creator = not data.has("appearance")
	var saved_look: Dictionary = data.get("appearance", {})
	for k in saved_look:
		appearance[k] = saved_look[k]
	wardrobe = data.get("wardrobe", {})
	transmog = data.get("transmog", {})
	if wardrobe.is_empty():
		for item in bag:
			add_to_wardrobe(item)
		for slot in equipped:
			add_to_wardrobe(equipped[slot])
	shop.assign(data.get("shop", []))
	hardcore = bool(data.get("hardcore", hardcore))
	hero_name = str(data.get("hero_name", ""))
	boss_ready_at = data.get("boss_ready_at", {})
	floors_since_event = int(data.get("floors_since_event", 0))
	horde_left = int(data.get("horde_left", 0))
	horde_total = maxi(horde_left, GameData.HORDE_SIZE)
	curse_turns = int(data.get("curse_turns", 0))
	luck_turns = int(data.get("luck_turns", 0))
	hunt_spawns = int(data.get("hunt_spawns", 0))
	merchant = data.get("merchant", [])
	var saved_loadouts: Array = data.get("loadouts", [])
	for i in mini(saved_loadouts.size(), loadouts.size()):
		loadouts[i] = saved_loadouts[i]
	loot_filter = data.get("loot_filter", loot_filter)
	enemy_goblin = bool(data.get("enemy_goblin", false))
	Lineage.from_save(self, data.get("lineage", {}))
	GameData.realm_order = realm_order
	_give_old_legendaries_effects()
	if shop.is_empty() or not data.has("featured"):  # older saves get the new shop
		restock_shop()
	if int(data.get("stat_ver", 1)) < 2:
		_convert_stats(data)
	hero_hp = int(data.get("hero_hp", get_max_hp()))
	if hero_hp <= 0 or hero_hp > get_max_hp():
		hero_hp = get_max_hp()
	spawn_enemy()
	return true

## v0.11: 4 stats at 3 points a level became 8 stats at 5 points a level.
## Points scale by 5/3 (so you're exactly as strong), Agility splits into
## Agility and Dexterity, and points put into special stats come back to spend.
## (Older versions also counted your race's bonus again every time you spent
## a point; any points that bug added are taken back here.)
func _convert_stats(data: Dictionary) -> void:
	var old: Dictionary = data.get("stats", {})
	var old_unspent := int(data.get("stat_points", 0))
	var old_unique := 0
	var up: Dictionary = data.get("unique_points", {})
	for k in up:
		old_unique += int(up[k])
		unique[k] = float(unique.get(k, 0.0)) + int(up[k]) * 0.1
	var old_race := race_power_points
	var legit := maxi(0, (level - 1) * GameData.OLD_STAT_POINTS)
	var alloc := 0
	for st in ["STR", "VIT", "AGI", "INT"]:
		alloc += int(old.get(st, 0))
	var room := maxi(0, legit - old_unspent - old_race)
	var f := 1.0 if alloc <= room else float(room) / maxf(1.0, alloc)
	var sc := GameData.STAT_SCALE
	for st in GameData.STAT_ORDER:
		stats[st] = 0
	stats["STR"] = int(round(int(old.get("STR", 0)) * f * sc))
	stats["VIT"] = int(round(int(old.get("VIT", 0)) * f * sc))
	stats["INT"] = int(round(int(old.get("INT", 0)) * f * sc))
	var agi := int(old.get("AGI", 0)) * f * sc
	stats["AGI"] = int(round(agi / 2.0))
	stats["DEX"] = int(round(agi)) - int(stats["AGI"])
	race_power_points = int(round(old_race * sc))
	var total := (level - 1) * GameData.STAT_POINTS_PER_LEVEL
	var used := race_power_points
	for st in GameData.STAT_ORDER:
		used += int(stats[st])
	stat_points = maxi(0, total - used)
	var back := int(round(old_unique * sc))
	if f < 1.0 or back > 0 or stat_points > 0:
		say("[color=#e8b14a]New stats! Agility was split into Agility and Dexterity, and Wisdom, Luck and Charisma are new.[/color] You have %d points to spend in Character > Hero." % stat_points)
	else:
		say("[color=#e8b14a]New stats! Agility was split into Agility and Dexterity, and Wisdom, Luck and Charisma are new.[/color]")

## Legendaries found before they had special effects get one now.
func _give_old_legendaries_effects() -> void:
	var all_items: Array = bag.duplicate()
	all_items.append_array(shop)
	for slot in equipped:
		all_items.append(equipped[slot])
	for item in all_items:
		if int(item["rarity"]) == GameData.LEGENDARY and item["effect"] == "":
			GameData.add_legendary_effect(item)
			bag_version += 1

## Converts a save from the earlier single-file version of the game.
func _convert_old_save(data: Dictionary) -> void:
	floor_num = maxi(1, int(data.get("floor", 1)))
	best_floor = maxi(floor_num, int(data.get("best_floor", 1)))
	var old_items: Array = data.get("inventory", [])
	var old_equipped: Dictionary = data.get("equipped", {})
	var equipped_slot_by_index := {}
	for slot in old_equipped:
		equipped_slot_by_index[int(old_equipped[slot])] = slot

	var sold_gold := 0
	for i in old_items.size():
		var old: Dictionary = old_items[i]
		if not old.has("slot"):
			continue
		var old_name: String = old.get("name", "Item")
		var parts := old_name.split(" ", false, 1)
		var item := {
			"id": _new_id(),
			"base_name": parts[1] if parts.size() > 1 else old_name,
			"name": old_name,
			"slot": old["slot"],
			"stat": old["stat"],
			"rarity": clampi(int(old.get("rarity", 0)), 0, GameData.LEGENDARY),
			"bonus": int(old.get("bonus", 1)),
			"level": 0,
			"floor": int(old.get("floor", 1)),
			"effect": "",
			"effect_value": 0,
		}
		if equipped_slot_by_index.has(i):
			equipped[equipped_slot_by_index[i]] = item
		elif not bag_full():
			bag.append(item)
		else:
			sold_gold += GameData.sell_value(item)
	gold += sold_gold
	hero_hp = get_max_hp()
	restock_shop()
	spawn_enemy()
	bag_version += 1
	say("Your old save was converted. Extra items that didn't fit in the bag were sold for %d gold." % sold_gold)
	save_game()

# =====================================================================
# Looks: wardrobe and transmog
# =====================================================================

## Remembers an item's look so you can wear it later (transmog).
func add_to_wardrobe(item: Dictionary) -> void:
	var t := GameData.item_type(item)
	var key := ""
	if item.get("art", "") != "":
		key = item["art"]
	elif item.get("set", "") != "":
		key = "set:" + str(item["base_name"])
	else:
		key = "%s:%d" % [t, mini(int(item["rarity"]), GameData.LEGENDARY)]
	if wardrobe.has(key):
		return
	var label := str(item["base_name"]) if (item.get("art", "") != "" or item.get("set", "") != "") else "%s %s" % [GameData.RARITY_NAMES[mini(int(item["rarity"]), GameData.LEGENDARY)], t.capitalize()]
	wardrobe[key] = {"slot": item["slot"], "type": t, "rarity": int(item["rarity"]), "art": item.get("art", ""), "set": item.get("set", ""), "name": label}

## What each slot looks like right now (transmog wins over the real item).
func hero_looks() -> Dictionary:
	var out := {}
	for slot in GameData.SLOT_ORDER:
		var tm = transmog.get(slot, "")
		if tm is String and tm == "hide":
			continue
		if tm is String and tm != "" and wardrobe.has(tm):
			out[slot] = Sprites.gear_look(wardrobe[tm])
		elif equipped.has(slot):
			out[slot] = Sprites.gear_look(equipped[slot])
	# A unique class wears a cape: the class's color, trimmed in its rank's color
	var uc := ClassTree.unique_class(self)
	if not uc.is_empty() and transmog.get("Cape", "") != "hide":
		out["Cape"] = {"type": "cape", "mat": "cloth", "ramp": Sprites.ramp_from(Color(class_info().get("color", "#3c5e8b")).darkened(0.15)),
			"trim": Color(ClassTree.RANK_COLORS[ClassTree.rank_of(uc)]), "glow": false}
	# God rank classes shine: a golden aura around the hero
	if not uc.is_empty() and ClassTree.rank_of(uc) == "God" and transmog.get("Aura", "") != "hide":
		out["Aura"] = {"type": "aura", "color": Color(ClassTree.RANK_COLORS["God"])}
	return out

func set_transmog(slot: String, key: String) -> void:
	if key == "":
		transmog.erase(slot)
	else:
		transmog[slot] = key
	save_game()

# =====================================================================
# Online raid rewards
# =====================================================================

## Gives the weekly raid reward. Returns a line describing it.
func raid_reward() -> String:
	var g := (50 + best_floor * 25) * 6
	gold += g
	var zones := mini(GameData.ZONES.size(), GameData.zone_index(mini(best_floor, GameData.ZONE_FLOORS * GameData.ZONES.size())) + 1)
	for i in zones:
		materials[i] = int(materials[i]) + 2
	var rarity := GameData.LEGENDARY if randf() < 0.15 else 3
	var item := GameData.make_item(GameData.SLOT_ORDER.pick_random(), rarity, best_floor, _new_id())
	_give_item(item)
	save_game()
	return "+%d gold, +2 of each boss material you've reached, and %s." % [g, _tag(item)]

# =====================================================================
# Path rooms: sometimes you choose what the next room is
# =====================================================================

func _maybe_offer_path() -> void:
	if not path_rooms_on or GameData.is_boss_floor(floor_num) or floor_num < 4:
		return
	if randf() * 100.0 >= GameData.PATH_CHANCE * GameData.event_bonus("elite"):
		return
	var others := ["treasure", "rest", "elite"]
	others.shuffle()
	path_offer = ["fight", others[0], others[1]]
	path_wait = 0
	path_hold = false
	tip("paths", "A fork in the dungeon! Pick the next room, or it picks Fight on by itself in a few seconds.")

## After every boss the fork has the wandering merchant in it.
func _offer_merchant() -> void:
	if not path_rooms_on:
		return
	var others := ["treasure", "rest"]
	others.shuffle()
	path_offer = ["fight", "merchant", others[0]]
	path_wait = 0
	_page("merchant")

## Every so often something unusual happens on a new floor.
func _maybe_start_event() -> void:
	if floor_num < GameData.EVENT_MIN_FLOOR or GameData.is_boss_floor(floor_num) or horde_left > 0 or enemy_goblin:
		return
	if floors_since_event < GameData.EVENT_GAP:
		return
	if randf() * 100.0 >= (floors_since_event - GameData.EVENT_GAP + 1) * GameData.EVENT_CHANCE_STEP * (1.0 + luck_odds() / 100.0):
		return
	floors_since_event = 0
	var roll := randf() * 100.0
	if GameData.realm_of(floor_num) != "" and path_rooms_on:
		if roll < 35.0:
			Realms.start_encounter(self)
			return
		if roll < 55.0:
			Realms.start_realm_event(self)
			return
		roll = randf() * 100.0
	if roll < 25.0:
		start_event("goblin")
	elif roll < 45.0:
		start_event("horde")
	elif roll < 60.0:
		start_event("shrine")
	elif path_rooms_on:
		World.start_event(self)
	else:
		start_event("goblin")

func start_event(kind: String) -> void:
	_page("events")
	match kind:
		"goblin":
			enemy_goblin = true
			say("[color=#fbbf24]You hear coins jingling... a treasure goblin! Catch it before it gets away![/color]")
			events.append({"type": "mini_event", "kind": "goblin", "title": "TREASURE GOBLIN!", "sub": "Catch it before it runs"})
		"horde":
			horde_left = GameData.HORDE_SIZE
			horde_total = GameData.HORDE_SIZE
			say("[color=#f87171]A monster horde! Beat all %d for their chest.[/color]" % GameData.HORDE_SIZE)
			events.append({"type": "mini_event", "kind": "horde", "title": "MONSTER HORDE!", "sub": "Beat all %d" % GameData.HORDE_SIZE})
		"shrine":
			path_offer = ["shrine", "leave"]
			path_wait = 0
			say("[color=#c084fc]A cursed shrine pulses in the dark.[/color]")
			events.append({"type": "mini_event", "kind": "shrine", "title": "CURSED SHRINE", "sub": "Accept its curse?"})

## What gets picked if you don't choose in time.
func auto_path() -> String:
	for k in ["cenc_yes", "leave", "fight", "pass", "revent_no"]:
		if k in path_offer:
			return k
	return path_offer[0] if not path_offer.is_empty() else "fight"

## Name, text and color of a path choice.
func path_info(kind: String) -> Dictionary:
	if kind.begins_with("cenc_"):
		return ClassTree.path_info(kind, self)
	if World.EVENT_PATHS.has(kind):
		var d: Dictionary = World.EVENT_PATHS[kind].duplicate()
		if kind == "bet":
			d["text"] = "Bet %d gold on a coin toss. Luck and Charisma tilt the coin." % World.bet_amount(self)
		return d
	return GameData.PATHS[kind] if GameData.PATHS.has(kind) else Realms.path_info(self, kind)

func choose_path(kind: String) -> void:
	if path_offer.is_empty():
		return
	path_offer = []
	if kind.begins_with("portal:"):
		Realms.enter(self, kind.substr(7))
		events.append({"type": "portal"})
		return
	match kind:
		"talk", "trade", "attack", "pass":
			Realms.encounter_choice(self, kind)
		"revent_yes", "revent_no":
			Realms.realm_event(self, kind == "revent_yes")
		"cenc_yes", "cenc_no":
			ClassTree.encounter_choice(self, kind == "cenc_yes")
		"camp":
			Realms.camp(self)
		"altar", "chest_open", "bet", "well":
			World.choose(self, kind)
			return
		"treasure":
			var g := (5 + floor_num * 6) * 3
			_add_gold(g)
			var item := GameData.make_item(GameData.SLOT_ORDER.pick_random(), GameData.roll_rarity(20 + _loot_bonus(), GameData.LEGENDARY_CHANCE_BOSS), floor_num, _new_id())
			say("[color=#fbbf24]Treasure![/color] +%d gold" % g)
			_give_item(item)
			events.append({"type": "treasure"})
		"rest":
			hero_hp = get_max_hp()
			skill_cds.clear()
			elixirs["rested"] = int(GameData.ELIXIRS["rested"]["turns"])
			say("[color=#4ade80]You rest by a campfire.[/color] Full health, abilities ready, +15% Attack.")
			events.append({"type": "potion", "amount": get_max_hp()})
		"elite":
			enemy_elite = true
			if not enemy_is_boss and not enemy_goblin:
				_apply_tier(maxi(enemy_tier, Monsters.EPIC))
				say("[color=#f87171]An elite %s blocks the way![/color]" % enemy_name)
			events.append({"type": "elite"})
		"merchant":
			_make_merchant()
			say("[color=#fbbf24]A wandering merchant waves you over.[/color]")
			events.append({"type": "merchant"})
		"shrine":
			ClassTree.count(self, "cursed_shrines")
			Lineage.gain(self, "shrine")
			_faith(Classes.FAITH["shrine"])
			curse_turns = GameData.CURSE_TURNS
			codex.add("shrines")
			codex.bounty_progress("event")
			say("[color=#c084fc]You touch the shrine. Monsters grow stronger... but so does their loot.[/color] (%d turns)" % GameData.CURSE_TURNS)
			spawn_enemy()
		"leave":
			_faith(Classes.FAITH["leave_shrine"])
			say("You leave the shrine alone.")
		_:
			say("You press on.")
	_check_codex()
	save_game()

# =====================================================================
# The wandering merchant and scrolls
# =====================================================================

const SCROLLS := {
	"luck": {"name": "Scroll of Luck", "text": "Better loot for %d turns"},
	"hunt": {"name": "Hunter's Scroll", "text": "The next %d monsters are 3x as likely to be rare"},
	"key": {"name": "Boss Key", "text": "Every boss is ready to fight again right now"},
	"box": {"name": "Mystery Box", "text": "Epic or Legendary gear, gold or materials"},
	"tome": {"name": "Tome of Forgetting", "text": "Your next stat respec is free"},
}

func scroll_text(id: String) -> String:
	match id:
		"luck":
			return SCROLLS[id]["text"] % GameData.LUCK_TURNS
		"hunt":
			return SCROLLS[id]["text"] % GameData.HUNT_SPAWNS
	return SCROLLS[id]["text"]

func _gold_scale() -> int:
	return 30 + best_floor * 12

func _make_merchant() -> void:
	merchant = []
	merchant_who = ""
	for _i in 2:
		var r := GameData.LEGENDARY if randf() * 100.0 < GameData.MERCHANT_LEGENDARY_CHANCE else 3
		var item := GameData.make_item(GameData.SLOT_ORDER.pick_random(), r, best_floor, _new_id())
		merchant.append({"kind": "item", "item": item, "price": price(int(GameData.shop_price(item) * GameData.MERCHANT_PRICE_MULT)), "sold": false})
	merchant.append({"kind": "scroll", "id": "box", "price": price(_gold_scale() * 8), "sold": false})
	var scrolls := ["luck", "hunt", "key", "tome"]
	scrolls.shuffle()
	for id in scrolls.slice(0, 2):
		merchant.append({"kind": "scroll", "id": id, "price": price(_gold_scale() * {"key": 2, "tome": 4}.get(id, 3)), "sold": false})

func buy_merchant(i: int) -> bool:
	if i < 0 or i >= merchant.size():
		return false
	var m: Dictionary = merchant[i]
	if m["sold"]:
		return false
	if gold < int(m["price"]):
		say("Not enough gold (need %d)." % int(m["price"]))
		return false
	if m["kind"] == "item" and bag_full():
		say("Your bag is full.")
		return false
	gold -= int(m["price"])
	m["sold"] = true
	codex.add("merchant_buys")
	if m["kind"] == "item":
		var item: Dictionary = m["item"]
		add_to_wardrobe(item)
		codex.found_item(item)
		bag.append(item)
		bag_version += 1
		say("Bought %s from the merchant." % _tag(item))
		events.append({"type": "loot", "name": GameData.display_name(item), "rarity": int(item["rarity"])})
	else:
		say(use_scroll(m["id"]))
	_check_codex()
	save_game()
	return true

## Uses a scroll (or opens a box) right away. Returns what happened.
func use_scroll(id: String) -> String:
	match id:
		"luck":
			luck_turns += GameData.LUCK_TURNS
			events.append({"type": "buff", "name": "Scroll of Luck"})
			return "[color=#c4b5fd]Scroll of Luck![/color] Better loot for %d turns." % luck_turns
		"hunt":
			hunt_spawns += GameData.HUNT_SPAWNS
			events.append({"type": "buff", "name": "Hunter's Scroll"})
			return "[color=#c4b5fd]Hunter's Scroll![/color] Rare monsters are drawn to you."
		"key":
			boss_ready_at.clear()
			return "[color=#c4b5fd]Boss Key![/color] Every boss is ready to fight again."
		"box":
			return _open_box()
		"tome":
			respec_tomes += 1
			return "[color=#c4b5fd]Tome of Forgetting![/color] Your next respec is free (Character > Hero)."
	return ""

func _open_box() -> String:
	var roll := randf() * 100.0
	if roll < 50.0:
		var item := GameData.make_item(GameData.SLOT_ORDER.pick_random(), 3, best_floor, _new_id())
		_give_item(item)
		return "Mystery Box: %s!" % _tag(item)
	if roll < 70.0:
		var item := GameData.make_item(GameData.SLOT_ORDER.pick_random(), GameData.LEGENDARY, best_floor, _new_id())
		_give_item(item)
		return "[color=#fb923c]Mystery Box: %s![/color]" % _tag(item)
	if roll < 75.0:
		var zi := GameData.zone_index(best_floor)
		var item := GameData.make_unique(GameData.zone_uniques(zi).pick_random(), best_floor, _new_id())
		_give_item(item)
		return "[color=#fbbf24]Mystery Box: a UNIQUE! %s![/color]" % _tag(item)
	if roll < 90.0:
		var g := _gold_scale() * 12
		_add_gold(g)
		return "Mystery Box: +%d gold!" % g
	var m := GameData.zone_index(best_floor)
	materials[m] = int(materials[m]) + 4
	return "Mystery Box: +4 %s!" % GameData.MATERIALS[m]

# =====================================================================
# Stash, loadouts and loot filter
# =====================================================================

## Moves a bag item into the shared stash (Regular heroes only).
func to_stash(id: int, stash: Array, capacity: int) -> bool:
	if not stash_ok or hardcore:
		say("Hardcore heroes can't use the shared stash.")
		return false
	var found := find_item(id)
	if found.is_empty() or found["where"] != "bag":
		return false
	if stash.size() >= capacity:
		say("The stash is full.")
		return false
	var item: Dictionary = found["item"]
	bag.remove_at(int(found["index"]))
	stash.append(item)
	bag_version += 1
	say("Put %s in the stash." % _tag(item))
	save_game()
	return true

## Takes an item out of the shared stash into this hero's bag.
func from_stash(index: int, stash: Array) -> bool:
	if not stash_ok or hardcore or index < 0 or index >= stash.size():
		return false
	if bag_full():
		say("Your bag is full.")
		return false
	var item: Dictionary = stash[index]
	stash.remove_at(index)
	item["id"] = _new_id()
	bag.append(item)
	add_to_wardrobe(item)
	bag_version += 1
	say("Took %s from the stash." % _tag(item))
	save_game()
	return true

func save_loadout(i: int) -> void:
	var set_ids := {}
	for s in equipped:
		set_ids[s] = int(equipped[s]["id"])
	loadouts[i] = set_ids
	say("Saved your gear as loadout %d." % (i + 1))
	save_game()

## Puts on a saved loadout. Items you've sold since are skipped.
func wear_loadout(i: int) -> int:
	var lo: Dictionary = loadouts[i]
	var n := 0
	for s in lo:
		var found := find_item(int(lo[s]))
		if not found.is_empty() and found["where"] == "bag":
			equip(int(lo[s]))
			n += 1
	say("Loadout %d: %d items swapped." % [i + 1, n] if n > 0 else "Loadout %d is already on (or its items are gone)." % (i + 1))
	return n

# ---------- Builds: stats, skills and gear together ----------

## Saves what you're running now (stat spread, equipped skills, worn gear) as build i.
func save_build(i: int, build_name := "") -> void:
	var gear := {}
	for s in equipped:
		gear[s] = int(equipped[s]["id"])
	var old: Dictionary = builds[i]
	builds[i] = {"name": build_name if build_name != "" else String(old.get("name", "Build %d" % (i + 1))),
		"stats": stats.duplicate(), "active": active_slots.duplicate(), "passive": passive_slots.duplicate(), "gear": gear}
	say("Saved build %d: %s." % [i + 1, builds[i]["name"]])
	save_game()

func build_name(i: int) -> String:
	return String((builds[i] as Dictionary).get("name", "Build %d" % (i + 1)))

func build_saved(i: int) -> bool:
	return (builds[i] as Dictionary).has("stats")

## Switches to build i: your points move to its spread (free), its skills go in
## their slots and its gear goes on. Things you no longer own are skipped.
func apply_build(i: int) -> void:
	var b: Dictionary = builds[i]
	if not b.has("stats"):
		return
	var pool := stat_points
	for st in GameData.STAT_ORDER:
		pool += int(stats.get(st, 0))
	var want: Dictionary = b["stats"]
	var want_total := 0
	for st in GameData.STAT_ORDER:
		want_total += int(want.get(st, 0))
	var f := 1.0 if want_total <= pool else float(pool) / maxf(1.0, want_total)
	var used := 0
	for st in GameData.STAT_ORDER:
		stats[st] = int(floor(int(want.get(st, 0)) * f))
		used += int(stats[st])
	stat_points = pool - used
	var acts: Array = b.get("active", [])
	var pas: Array = b.get("passive", [])
	for k in active_slots.size():
		var id: String = String(acts[k]) if k < acts.size() else ""
		active_slots[k] = id if id == "" or skill_book.has(id) else active_slots[k]
	for k in passive_slots.size():
		var id: String = String(pas[k]) if k < pas.size() else ""
		passive_slots[k] = id if id == "" or skill_book.has(id) else passive_slots[k]
	var gear: Dictionary = b.get("gear", {})
	var n := 0
	for s in gear:
		var found := find_item(int(gear[s]))
		if not found.is_empty() and found["where"] == "bag":
			equip(int(gear[s]))
			n += 1
	hero_hp = mini(hero_hp, get_max_hp())
	_check_spec()
	say("Switched to %s." % build_name(i))
	save_game()

## The most pieces of one set you're wearing.
func best_set_count() -> int:
	var best := 0
	var counts := set_counts()
	for k in counts:
		best = maxi(best, int(counts[k]))
	return best

## Hands out a finished bounty's reward. Returns what you got ("" if it can't be claimed).
func claim_bounty(weekly: bool, i: int) -> String:
	var list: Array = codex.bounties.get("weekly" if weekly else "daily", [])
	if i < 0 or i >= list.size():
		return ""
	var b: Dictionary = list[i]
	if not b["done"] or b["claimed"]:
		return ""
	b["claimed"] = true
	codex.add("bounties")
	_faith(Classes.FAITH["bounty"])
	var r := {"gold": 1500, "mats": 6, "scroll": "box"} if weekly else {"gold": 300, "mats": 2}
	var got := give_reward(r)
	say("[color=#fbbf24]Bounty done![/color] %s" % got)
	_check_codex()
	codex.save()
	save_game()
	return got

# =====================================================================
# Fortune's Wheel: bet an item for the next rarity up
# =====================================================================

func gamble_chance(item: Dictionary) -> int:
	if not GameData.can_gamble(item):
		return 0
	return GameData.GAMBLE_CHANCES[int(item["rarity"])]

func gamble_unlocked() -> bool:
	return best_floor >= GameData.GAMBLE_UNLOCK_FLOOR

## Spins the wheel for a bag item. Returns {"ok", "win", "item", "roll", "chance"}.
func gamble(id: int) -> Dictionary:
	var found := find_item(id)
	if found.is_empty() or found["where"] != "bag":
		return {"ok": false}
	var item: Dictionary = found["item"]
	if not GameData.can_gamble(item):
		say("%s can't go on the wheel." % _tag(item))
		return {"ok": false}
	var fee := GameData.gamble_fee(item)
	if gold < fee:
		say("Not enough gold (the wheel costs %d)." % fee)
		return {"ok": false}
	gold -= fee
	var chance := gamble_chance(item)
	var roll := randi_range(1, 100)
	var win := roll <= chance or (dev_mode and dev_always_win)
	codex.add("gambles")
	Lineage.gain(self, "gamble")
	Hidden.on_wheel(self, win)
	if win and int(item["rarity"]) >= 3:
		ClassTree.count(self, "wheel_max_wins")
	if win:
		var new_rarity := int(item["rarity"]) + 1
		item["rarity"] = new_rarity
		item["name"] = GameData.item_name(item)
		item["bonus"] = maxi(1, int(GameData.base_bonus(item["slot"], int(item["floor"])) * float(GameData.RARITY_MULTS[new_rarity])))
		if new_rarity == GameData.LEGENDARY:
			GameData.add_legendary_effect(item)
		add_to_wardrobe(item)
		codex.add("gamble_wins")
		codex.found_item(item)
		bag_version += 1
		say("[color=#4ade80]The wheel smiles![/color] It's now %s." % _tag(item))
	else:
		bag.remove_at(int(found["index"]))
		bag_version += 1
		say("[color=#f87171]The wheel takes %s.[/color] Better luck next spin." % _tag(item))
	_check_codex()
	save_game()
	return {"ok": true, "win": win, "item": item, "roll": roll, "chance": chance}

# =====================================================================
# Wanderer: the god trial
# =====================================================================

## Starts a trial fight against a named foe (god trials, race trials, cures,
## hidden classes). Win it and _finish_trial does the rest; lose and you go back.
## info: {"name", "art", "lore", "hp" (x a boss, default 6), "atk" (default 1.5)}
func start_special_trial(info: Dictionary, kind: String, data: Dictionary) -> bool:
	if enemy_is_boss or trial_active:
		return false
	trial_return = floor_num
	trial_active = true
	trial_kind = kind
	trial_data = data
	path_offer = []
	horde_left = 0
	enemy_goblin = false
	var f := maxi(best_floor, floor_num)
	var growth := pow(GameData.ENEMY_GROWTH, f - 1)
	enemy_boss_kind = "trial"
	enemy_is_boss = true
	enemy_tier = 0
	enemy_mods = []
	enemy_shield = 0
	enemy_people = ""
	enemy_name = info["name"]
	enemy_species = info["name"]
	enemy_art = info["art"]
	enemy_shape = "humanoid"
	enemy_color = "#e8b14a"
	enemy_max_hp = int((15 + f * 15) * growth * float(info.get("hp", 6.0)))
	enemy_hp = enemy_max_hp
	enemy_attack = int((3 + f * 2) * growth * float(info.get("atk", 1.5)))
	enemy_base_hp = enemy_max_hp
	enemy_base_atk = enemy_attack
	burn_turns = 0
	ClassTree.on_fight_start(self)
	_setup_fight()
	say("[color=#e8b14a]The trial begins: %s.[/color] %s" % [info["name"], info.get("lore", "")])
	events.append({"type": "trial", "name": info["name"]})
	return true

func _finish_trial() -> void:
	trial_active = false
	floor_num = trial_return
	fight = 1
	burn_turns = 0
	var g: int = (2 + best_floor) * 200
	_add_gold(g)
	match trial_kind:
		"race":
			Lineage._rank_up(self)
		"cure":
			Lineage.cured(self)
		"hidden":
			Hidden.trial_won(self, trial_data)
		"class_god", "class_item":
			say("[color=#fbbf24]You won the trial![/color] +%d gold" % g)
			ClassTree.trial_won(self, trial_data)
		"god_rotation":
			ClassTree.god_trial_won(self, trial_data)
	trial_kind = "god"
	trial_data = {}
	_check_spec()
	spawn_enemy()
	save_game()

## Race trial for the next awakening rank.
func start_race_trial() -> bool:
	if Lineage.awaken_block(self) != "trial":
		return false
	return start_special_trial(Lineage.next_rank(self)["key"]["trial"], "race", {})

## The monster swings at you once (a failed escape).
func free_hit() -> void:
	if enemy_hp <= 0 or hero_hp <= 0:
		return
	if randf() * 100.0 < effect_total("dodge"):
		events.append({"type": "dodge"})
		say("You dodge the %s's attack." % enemy_name)
		return
	var damage := damage_taken()
	if shield_hp > 0:
		var soak := mini(shield_hp, damage)
		shield_hp -= soak
		damage -= soak
	hero_hp -= damage
	events.append({"type": "enemy_hit", "dmg": damage})
	say("The %s hits you for %d." % [enemy_name, damage])
	Lineage.on_hit(self)
	if hero_hp <= 0:
		Lineage.save_from_death(self)
	if hero_hp <= 0:
		_hero_died()

## Heroes from before ability stones: Archers become Rangers, and every old
## hero gets skills like the ones they had (ranked by level).
func _convert_old_skills(data: Dictionary) -> void:
	var old := hero_class
	hero_class = SkillData.OLD_CLASS_MOVE.get(old, old)
	var ids: Array = SkillData.OLD_CLASS_SKILLS.get(old, class_info().get("start", []))
	var r := clampi(1 + level / 15, 1, 3)
	for id in ids:
		skill_book[id] = r
	for id in class_info().get("start", []):
		if not skill_book.has(id):
			skill_book[id] = 1
	_fill_empty_slots()
	dust += int((data.get("skills", {}) as Dictionary).size()) * 20
	say("[color=#c4b5fd]Skills now come from ability stones![/color] Your old skills were turned into stones in your Skill Book." + (" Archers are now Rangers." if old != hero_class else ""))

# =====================================================================
# Party
# =====================================================================

## Sets who fights with you (other Regular heroes' slots) and loads them.
func set_party(slots: Array) -> void:
	if hardcore:
		party_slots = []
		party = null
		return
	party_slots = slots.slice(0, Party.MAX_COMPANIONS)
	party = Party.new()
	party.load_members(party_slots, self)
	party_slots = party.members.map(func(m): return m.slot)
	spawn_enemy()
	save_game()
