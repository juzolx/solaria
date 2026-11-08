extends SceneTree
## The new dark-fantasy weapon icons (art/icons/weapons): every weapon type has a 32x32 drawing, uniques and
## set pieces have their own, the six uniques that used to be one plain sword now differ, rarity is a code halo
## (never new art), and a weapon icon keeps one pixel size on every screen.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _hash(t: Texture2D) -> int:
	return t.get_image().get_data().hex_encode().hash()

func _initialize() -> void:
	for t in Sprites.WEAPON_TYPES:
		var im := Sprites._img("icons/weapons/%s.png" % t)
		check(im != null and im.get_width() == 32 and im.get_height() == 32, "%s has a 32x32 drawing" % t)
		if im != null:
			var used := im.get_used_rect()
			check(maxi(used.size.x, used.size.y) >= 24, "%s fills most of its canvas (%s)" % [t, used.size])
		var ic := Sprites.item_icon({"slot": "Weapon", "type": t, "rarity": 2})
		check(ic != null and ic.get_width() == ArtStyle.ICON_FRAME and ic.get_height() == ArtStyle.ICON_FRAME, "%s icon is the shared frame" % t)
		# one pixel size: the bag box and the detail box never double it, the big shop box doubles every weapon
		var b1 := UiIcons.big(ic, 44)
		var b2 := UiIcons.big(ic, 56)
		var b3 := UiIcons.big(ic, 76)
		check(b1.get_width() == b2.get_width() and b1.get_height() == b2.get_height(), "%s: same size in the bag (44) and the detail box (56)" % t)
		check(b3.get_width() == b1.get_width() * 2, "%s: doubled only in the big shop box" % t)
	# rarity is a halo in code, not a new drawing
	var r0 := Sprites.item_icon({"slot": "Weapon", "type": "axe", "rarity": 0})
	var r4 := Sprites.item_icon({"slot": "Weapon", "type": "axe", "rarity": 4})
	var r8 := Sprites.item_icon({"slot": "Weapon", "type": "axe", "rarity": 8})
	check(_hash(r0) != _hash(r4) and _hash(r4) != _hash(r8), "rarity shows (halo) on the same axe")
	# every unique weapon and set weapon has its own drawing, all different
	var seen := {}
	var n := 0
	for zi in GameData.ZONES.size():
		for u in GameData.zone_uniques(zi):
			if String(u["slot"]) == "Weapon":
				var it := GameData.make_unique(u, 50, 1)
				var h := _hash(Sprites.item_icon(it))
				check(not seen.has(h), "unique weapon %s is not a copy of %s" % [u["id"], seen.get(h, "")])
				seen[h] = u["id"]
				check(Sprites.weapon_art(it) != null and ResourceLoader.exists("res://art/icons/weapons/u_%s.png" % u["id"]), "unique %s has its own drawing" % u["id"])
				n += 1
	check(n == 11, "11 unique weapons (%d)" % n)
	for sid in GameData.SETS:
		if GameData.SETS[sid]["pieces"].has("Weapon"):
			check(ResourceLoader.exists("res://art/icons/weapons/set_%s_weapon.png" % sid), "set %s weapon has its own drawing" % sid)
	# anything without its own drawing falls back to the type's, never to nothing
	for t in Sprites.WEAPON_TYPES:
		check(Sprites.item_icon({"slot": "Weapon", "type": t, "rarity": 7, "art": "s_nobody"}) != null, "%s signature without art falls back to the type" % t)
	check(Sprites.item_icon({"slot": "Weapon", "rarity": 1}) != null, "a weapon with no type still has an icon")
	# type fixes
	check(ItemPool.SPECIAL_TYPES.get("branns_hammer", "") == "mace" and ItemPool.SPECIAL_TYPES.get("wardens_last_arrow", "") == "bow", "the realm uniques have real types")
	# the hero's held sword is a visible blade now
	var sw := Image.load_from_file(ProjectSettings.globalize_path("res://art/heroes/m/weapon_sword.png"))
	var used := sw.get_region(Rect2i(0, 0, 128, 128)).get_used_rect()
	check(used.size.x >= 3, "the held sword is at least 3 px wide (%s)" % used.size)
	print("WEAPON ICONS DONE, failures: ", fails)
	quit()
