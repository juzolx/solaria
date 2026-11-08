extends SceneTree
## Weapon icon audit (read-only): writes every weapon item's icon (exactly as Sprites.item_icon makes it)
## as a PNG, plus manifest.tsv, into a folder outside the project.
##   godot --headless --path . -s tests/_weapon_icons_dump.gd -- --out=C:/some/folder
## Needs override.cfg in the project folder (it redirects user data away from the real saves).

var _out := ""
var _rows: Array = []
var _n := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6).trim_suffix("/") + "/"
	if _out == "":
		print("need --out=")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out + "icons")
	# 1. the 7 weapon types x every rarity that changes the look
	for t in ItemPool.TYPES["Weapon"]:
		for r in [0, 1, 2, 3, 4, 8]:
			_add("type", "%s r%d (%s)" % [t, r, GameData.RARITY_NAMES[r]], {"slot": "Weapon", "type": t, "rarity": r}, "")
	# 2. the hand-named drops in every zone
	for zi in ItemPool.ZONES.size():
		for e in ItemPool.ZONES[zi]["Weapon"]:
			_add("zone%d" % zi, String(e[0]), {"slot": "Weapon", "type": e[1], "rarity": 2}, "")
	# 3. uniques
	for zi in GameData.ZONES.size():
		for u in GameData.zone_uniques(zi):
			if String(u["slot"]) == "Weapon":
				var it := GameData.make_unique(u, 50, 1)
				_add("unique z%d" % zi, String(u["name"]), it, "")
	# 4. set pieces and evolution sets
	for sid in GameData.SETS:
		if GameData.SETS[sid]["pieces"].has("Weapon"):
			_add("set", String(GameData.SETS[sid]["pieces"]["Weapon"]), GameData.make_set_item(sid, "Weapon", 50, 1), "")
	for sid in GameData.EVO_SETS:
		var es: Dictionary = GameData.EVO_SETS[sid]
		if es["pieces"].has("Weapon"):
			var it := {"slot": "Weapon", "type": es["types"]["Weapon"], "rarity": GameData.SET_RARITY, "set": sid, "name": es["pieces"]["Weapon"]}
			_add("evo set", String(es["pieces"]["Weapon"]), it, "")
	# 5. monster signatures
	for table in Monsters.all_info():
		for m in table:
			var s: Dictionary = table[m].get("sig", {})
			if s.get("slot", "") == "Weapon":
				_add("signature", String(s["name"]), GameData.make_signature(String(m), 50, 1), String(m))
	# 6. race gear
	for race in Races.RACE_GEAR:
		for d in Races.RACE_GEAR[race]:
			if d["slot"] == "Weapon":
				_add("race " + String(race), String(d["name"]), Races.make_race_gear(d, 50, 1), "")
	# 7. cosmetics
	for k in Realms.COSMETICS:
		if Realms.COSMETICS[k]["slot"] == "Weapon":
			print("cosmetic weapon: ", k)
	# 8. the raw layers
	var f := FileAccess.open(_out + "manifest.tsv", FileAccess.WRITE)
	f.store_line("idx\tgroup\tname\ttype\trarity\tart\tset\tmat\ttrim\tglow\tused_w\tused_h\tcolors\thash\tbig44_w\tbig44_h")
	for r in _rows:
		f.store_line("\t".join(PackedStringArray(r)))
	f.close()
	print("WEAPON ICONS written: ", _rows.size())
	quit()

func _add(group: String, label: String, item: Dictionary, _note: String) -> void:
	var tex: ImageTexture = Sprites.item_icon(item)
	var lk := Sprites.gear_look(item)
	var idx := "%03d" % _n
	_n += 1
	if tex == null:
		_rows.append([idx, group, label, item.get("type", ""), item.get("rarity", 0), item.get("art", ""), item.get("set", ""), lk["mat"], lk["trim"].to_html(false), lk["glow"], 0, 0, 0, "MISSING", 0, 0])
		return
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.save_png(_out + "icons/%s.png" % idx)
	var used := img.get_used_rect()
	var cols := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.01:
				cols[c.to_html(false)] = true
	var big := UiIcons.big(tex, 44)
	var bimg := big.get_image()
	bimg.save_png(_out + "icons/%s_big44.png" % idx)
	_rows.append([idx, group, label, item.get("type", ""), item.get("rarity", 0), item.get("art", ""), item.get("set", ""), lk["mat"], lk["trim"].to_html(false), lk["glow"], used.size.x, used.size.y, cols.size(), str(img.get_data().hex_encode().hash()), bimg.get_width(), bimg.get_height()])
