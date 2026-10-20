class_name Store
extends RefCounted
## Stage 4: real-money purchases through Apple's App Store (StoreKit), SWITCHED OFF.
## Only two kinds of things are ever sold: hero slots 6-9 and looks (never power,
## never random items). With ENABLED false nothing shows to players and nothing
## talks to the App Store.
##
## Turning it on later (needs the Apple Developer membership):
## 1. Add Godot's iOS "InAppStore" plugin (godot-ios-plugins) to the iOS export.
## 2. Create the products below in App Store Connect with the same ids (all non-consumable).
## 3. Set ENABLED = true (and GameData.SLOT_LOCKS_ON = true so slots 6-9 need buying).

const ENABLED := false
const SINGLETON := "InAppStore"

## id -> {name, text, kind}. kind "slot" = one more hero slot (6-9), "looks" = the supporter pack.
const PRODUCTS := {
	"solaria.heroslot6": {"name": "Hero Slot 6", "text": "One more hero in every town.", "kind": "slot"},
	"solaria.heroslot7": {"name": "Hero Slot 7", "text": "One more hero in every town.", "kind": "slot"},
	"solaria.heroslot8": {"name": "Hero Slot 8", "text": "One more hero in every town.", "kind": "slot"},
	"solaria.heroslot9": {"name": "Hero Slot 9", "text": "One more hero in every town.", "kind": "slot"},
	"solaria.supporter": {"name": "Supporter's Looks", "text": "The Eclipse name color, the Black Sun frame and the title Keeper of the Flame. Looks only.", "kind": "looks"},
}
## What the supporter pack unlocks (Cosmetics keys; the entries have need "store")
const SUPPORTER_KEYS := ["color:eclipse", "frame:blacksun", "title:keeper"]

static var prices := {}       # product id -> localized price text from the App Store
static var busy := false      # a purchase or restore is waiting for Apple
static var last_message := "" # what happened last, for the screen

static func available() -> bool:
	return ENABLED and Engine.has_singleton(SINGLETON)

static func _api() -> Object:
	return Engine.get_singleton(SINGLETON) if available() else null

## Asks Apple for the prices (once, when the store screen opens).
static func request_prices() -> void:
	var api := _api()
	if api == null:
		return
	api.call("request_product_info", {"product_ids": PackedStringArray(PRODUCTS.keys())})

static func buy(id: String) -> bool:
	var api := _api()
	if api == null or not PRODUCTS.has(id) or busy:
		return false
	busy = true
	last_message = "Waiting for the App Store..."
	return int(api.call("purchase", {"product_id": id})) == OK

## Apple requires this button: gives back everything bought on this Apple account.
static func restore() -> bool:
	var api := _api()
	if api == null or busy:
		return false
	busy = true
	last_message = "Restoring your purchases..."
	return int(api.call("restore_purchases")) == OK

## Call every frame or so while the game runs; hands out what Apple confirms.
static func poll(profile: Profile, codex: Codex) -> void:
	var api := _api()
	if api == null:
		return
	while int(api.call("get_pending_event_count")) > 0:
		handle(api.call("pop_pending_event"), profile, codex)

## One event from the plugin: {type, result, product_id, ...}. Split out so tests can feed it.
static func handle(ev: Dictionary, profile: Profile, codex: Codex) -> void:
	var type := String(ev.get("type", ""))
	var result := String(ev.get("result", ""))
	if type == "product_info":
		var ids: Array = ev.get("ids", [])
		var texts: Array = ev.get("localized_prices", [])
		for i in mini(ids.size(), texts.size()):
			prices[String(ids[i])] = String(texts[i])
		return
	if type == "purchase" or type == "restore":
		if result == "ok" or result == "completed" or result == "restored":
			var id := String(ev.get("product_id", ""))
			if grant(id, profile, codex):
				last_message = "Thank you! %s is yours." % PRODUCTS[id]["name"]
			var api := _api()
			if api != null and api.has_method("finish_transaction"):
				api.call("finish_transaction", id)
		else:
			last_message = "The App Store said no this time (nothing was charged)."
		busy = false

## Gives a product. Safe to call twice (restores do): returns false if unknown.
static func grant(id: String, profile: Profile, codex: Codex) -> bool:
	if not PRODUCTS.has(id):
		return false
	if not id in profile.owned_products:
		profile.owned_products.append(id)
	if PRODUCTS[id]["kind"] == "slot":
		var n := 0
		for p in profile.owned_products:
			if PRODUCTS.has(p) and PRODUCTS[p]["kind"] == "slot":
				n += 1
		profile.paid_slots = mini(n, GameData.PAID_SLOTS)
	else:
		for k in SUPPORTER_KEYS:
			if not k in codex.bought:
				codex.bought.append(k)
		if not "Keeper of the Flame" in codex.extra_titles:
			codex.extra_titles.append("Keeper of the Flame")
		codex.save()
	profile.save()
	return true

static func owns(profile: Profile, id: String) -> bool:
	return id in profile.owned_products
