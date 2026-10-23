class_name Mail
extends RefCounted
## The Mailbox: every reward lands here instead of straight in your bag.
## Bounties, deeds and news from the game's maker all arrive as letters.
## Mail is always safe; collect it in town when you have room.
##
## A letter: {"id", "from", "title", "body", "gold", "scrap", "potions",
##            "extra": {other give_reward keys}, "items": [item dicts],
##            "time": unix seconds, "read": bool}

const MAX_LETTERS := 60

## Letters from the maker, shipped with updates (later: pulled from the server).
## Each one reaches every account once. Give each a new, unique id.
## "reward" uses the same keys as bounties: gold, potions, scrap, dust, scroll,
## look, and "item": {"slot", "rarity"} (the item is made for whoever opens it).
const NEWS := [
	{"id": "news-0.12-mailbox", "from": "Juzo", "title": "The Mailbox is open!",
		"body": "From now on every reward comes to your Mailbox: bounties, deeds, and gifts from me. Mail is always safe, so collect it whenever you have room. Here's something to get you started.",
		"reward": {"gold": 300, "potions": 3}},
]

static func _letter(g: GameState, from: String, title: String, body: String) -> Dictionary:
	return {"id": "m%d" % g._new_id(), "from": from, "title": title, "body": body,
		"gold": 0, "scrap": 0, "potions": 0, "extra": {}, "items": [],
		"time": int(Time.get_unix_time_from_system()), "read": false}

## Turns a reward like {"gold": 100, "item": {"slot", "rarity"}} into a letter
## and puts it in the mailbox. Gold and scrap are sized to your depth now.
static func post(g: GameState, from: String, title: String, body: String, r: Dictionary) -> Dictionary:
	var l := _letter(g, from, title, body)
	for k in r:
		match String(k):
			"gold":
				l["gold"] = int(float(r["gold"]) * (1.0 + g.best_floor / 25.0))
			"scrap":
				l["scrap"] = int(float(r["scrap"]) * (1.0 + g.best_floor / 50.0))
			"potions":
				l["potions"] = int(r["potions"])
			"item":
				var it: Dictionary = r["item"]
				(l["items"] as Array).append(Town.reward_item(g, String(it["slot"]), int(it["rarity"])))
			"items":
				for it in r["items"]:
					(l["items"] as Array).append(it)
			_:
				l["extra"][k] = r[k]
	g.mail.append(l)
	while g.mail.size() > MAX_LETTERS:
		# Drop the oldest letter that has nothing left in it
		var dropped := false
		for i in g.mail.size():
			if is_empty(g.mail[i]):
				g.mail.remove_at(i)
				dropped = true
				break
		if not dropped:
			break
	g.events.append({"type": "toast", "text": "New mail: %s" % title})
	return l

static func is_empty(l: Dictionary) -> bool:
	return int(l["gold"]) == 0 and int(l["scrap"]) == 0 and int(l["potions"]) == 0 \
		and (l["extra"] as Dictionary).is_empty() and (l["items"] as Array).is_empty()

static func unread(g: GameState) -> int:
	var n := 0
	for l in g.mail:
		if not l.get("read", false):
			n += 1
	return n

## Letters that still hold something to collect.
static func waiting(g: GameState) -> int:
	var n := 0
	for l in g.mail:
		if not is_empty(l):
			n += 1
	return n

static func find(g: GameState, id: String) -> Dictionary:
	for l in g.mail:
		if l["id"] == id:
			return l
	return {}

## What's in a letter, in a few words.
static func summary(l: Dictionary) -> String:
	var parts: Array = []
	if int(l["gold"]) > 0:
		parts.append("%d gold" % int(l["gold"]))
	if int(l["potions"]) > 0:
		parts.append("%d potions" % int(l["potions"]))
	if int(l["scrap"]) > 0:
		parts.append("%d scrap" % int(l["scrap"]))
	for k in l["extra"]:
		match String(k):
			"dust", "mats":  # "mats": a 2.0 letter, paid as dust
				parts.append("%d dust" % int(l["extra"][k]))
			"scroll":
				parts.append("a scroll")
			"look":
				parts.append("a new look")
			"egg":
				parts.append("an egg")
			_:
				parts.append(String(k))
	var n: int = (l["items"] as Array).size()
	if n > 0:
		parts.append("%d item%s" % [n, "" if n == 1 else "s"])
	return ", ".join(parts)

## Takes everything out of a letter that fits. Items that don't fit stay in it.
## Returns what you got ("" if nothing).
static func collect(g: GameState, id: String) -> String:
	var l := find(g, id)
	if l.is_empty():
		return ""
	l["read"] = true
	var parts: Array = []
	if int(l["gold"]) > 0:
		g._add_gold(int(l["gold"]))
		parts.append("+%d gold" % int(l["gold"]))
		l["gold"] = 0
	if int(l["scrap"]) > 0:
		g.scrap += int(l["scrap"])
		parts.append("+%d scrap" % int(l["scrap"]))
		l["scrap"] = 0
	if int(l["potions"]) > 0:
		g.potions += int(l["potions"])
		parts.append("+%d potions" % int(l["potions"]))
		l["potions"] = 0
	if not (l["extra"] as Dictionary).is_empty():
		var t := g.give_reward(l["extra"])
		if t != "":
			parts.append(t)
		l["extra"] = {}
	var items: Array = l["items"]
	while not items.is_empty() and not g.bag_full():
		var item: Dictionary = items.pop_front()
		g.add_to_wardrobe(item)
		g.codex.found_item(item)
		g.bag.append(item)
		g.bag_version += 1
		g.events.append({"type": "loot", "name": GameData.display_name(item), "rarity": int(item["rarity"]), "up": g.compare_pct(item)})
		parts.append(g._tag(item))
	if not items.is_empty():
		g.say("Your bag is full: %d item%s stayed in the letter." % [items.size(), "" if items.size() == 1 else "s"])
	if not parts.is_empty():
		g.say("[color=#fbbf24]Collected:[/color] %s" % ", ".join(parts))
	g.save_game()
	return ", ".join(parts)

static func collect_all(g: GameState) -> int:
	var n := 0
	for l in g.mail.duplicate():
		if not is_empty(l) and collect(g, l["id"]) != "":
			n += 1
	return n

static func delete(g: GameState, id: String) -> bool:
	var l := find(g, id)
	if l.is_empty() or not is_empty(l):
		return false
	g.mail.erase(l)
	g.save_game()
	return true

static func delete_empty(g: GameState) -> int:
	var keep: Array = []
	for l in g.mail:
		if not is_empty(l):
			keep.append(l)
	var n: int = g.mail.size() - keep.size()
	g.mail = keep
	if n > 0:
		g.save_game()
	return n

## Delivers news letters this account hasn't had yet, and turns any old
## unclaimed Guild Hall deeds into mail. Call when a hero starts playing.
static func sync(g: GameState, p: Profile) -> void:
	var changed := false
	for n in NEWS:
		if String(n["id"]) in p.mail_seen:
			continue
		p.mail_seen.append(String(n["id"]))
		post(g, String(n["from"]), String(n["title"]), String(n["body"]), n.get("reward", {}))
		changed = true
	if changed:
		p.save()
	for id in g.codex.deeds.duplicate():
		Town.claim_deed(g, String(id))
	if changed:
		g.save_game()
