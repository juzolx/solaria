extends SceneTree
## Fight layout at phone size (fable monsters r3, item 11; the face-off staging, Juzo Oct 26): the real BattleView in the real main
## scene at 430x932 and 375x667 (iPhone SE), with the monsters that broke before: commons, a pack,
## two wide bosses and the tallest Calamities. Checks the one pixel scale, plates under the feet,
## the boss stage room, plates that stay put while the hero lunges, the boss chip column and the
## menagerie pet beside the hero plate.
const TestHero := preload("res://tests/test_hero.gd")
const Shot := preload("res://tests/_monster_shot.gd")
const KEYS := ["kobold", "imp", "rune_hound", "wolpertinger", "halo_wisp", "umibozu", "chimera", "barghest+pack", "garmr+pack", "boss_grendel", "boss_charybdis",
	"boss_surtr", "boss_forgemaster_brann",
	"calamity_0", "calamity_1", "calamity_2", "calamity_3", "calamity_4", "calamity_5", "calamity_6", "calamity_7", "calamity_8", "calamity_9"]
const SIZES := [Vector2i(430, 932), Vector2i(375, 667)]
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		if fails <= 40:
			print("FAIL: ", m)

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
			main.play_slot(1)
			await process_frame
	main.timer.stop()
	main.codex.stats["guide_skip"] = 1
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	var st: GameState = main.state
	st.in_town = false
	main.nav_page = 0
	main._apply_nav()
	var bv = main.battle
	for wsz in SIZES:
		root.size = wsz
		# headless never applies the stretch: give the fight the phone's (504 design px wide)
		if DisplayServer.get_name() == "headless":
			BattleView.test_scale = minf(wsz.x / 504.0, wsz.y / 896.0)
		for i in 6:  # the stretch and main's fit settle over a few frames
			await process_frame
		for arg in KEYS:
			_fight(main, st, arg)
			await process_frame
			await process_frame
			_check_fight(bv, st, arg, wsz)
			if arg in ["boss_grendel", "boss_charybdis", "calamity_2"]:
				await _check_chips(bv, st, arg, wsz)
			if arg == "calamity_2":
				await _check_death(main, bv, st, arg, wsz)
		for arg in ["kobold", "boss_grendel", "calamity_2"]:
			await _check_party(main, bv, st, arg, wsz)
		await _check_box(main, bv, st, wsz)
		await _check_bestiary(main, wsz)
	# (f) Epic, Legendary and Mythic are told apart by their pips too
	check(BattleView.tier_pips(3) != BattleView.tier_pips(4) and BattleView.tier_pips(4) != BattleView.tier_pips(5), "tiers 3-5 wear the same pips")
	print("STAGE6 MONSTER LAYOUT TESTS DONE, failures: %d" % fails)
	quit(1 if fails > 0 else 0)

func _fight(main, st: GameState, arg: String) -> void:
	var pack := arg.ends_with("+pack")
	var key := arg.trim_suffix("+pack")
	st.spawn_enemy()
	st.enemy_variant = ""
	st.enemy_tier = 0
	st.enemy_mods.clear()
	st.enemy_elite = false
	st.enemy_calamity = 0
	st.horde_left = 3 if pack else 0
	st.horde_total = 3 if pack else 0
	st.horde_pack = pack
	st.enemy_species = key.trim_prefix("boss_")
	st.enemy_name = Monsters.name_of(st.enemy_species)
	st.enemy_art = key
	st.enemy_is_boss = key.begins_with("boss_")
	if key.begins_with("calamity_"):
		st.enemy_calamity = int(key.trim_prefix("calamity_")) + 1
	main.refresh()

## A party of two (pets r5): each companion's bar no wider than their body, DOWN on a knocked-out
## one's plate, and the Team Strike line just over the hero plate, clear of the monster's bar and
## name, the companions' names and the monster itself.
func _check_party(main, bv, st: GameState, arg: String, wsz: Vector2i) -> void:
	_fight(main, st, arg)
	if arg == "boss_grendel":
		st.enemy_mods = ["Swift", "Armored"]
	st.party = Shot._party()
	main.refresh()
	await process_frame
	await process_frame
	var tag := "%s with a party at %dx%d" % [arg, wsz.x, wsz.y]
	var font := UI.game_font()
	var keep: Array = []   # [rect, what] the strip must stay off
	var bar: Rect2 = bv._boss_bar()
	keep.append([Rect2(bar.position, Vector2(bar.size.x, bar.size.y + bv.BOSS_NAME)), "the monster's bar and name"])
	for i in st.party.members.size():
		var m = st.party.members[i]
		var b: Rect2 = bv._member_bar(i)
		var c: Rect2 = bv._member_canvas(i)
		var u := c.size.x / Sprites.CANVAS
		var art := Sprites.hero_back_of(m.hero)
		var body := 32.0 * Sprites.HD * u
		if art.has("anims"):
			body = float((art["anims"]["combat_idle"]["tex"][0] as Texture2D).get_image().get_used_rect().size.x) * u
		check(b.size.x <= body + 8.0, "%s: %s's bar %.0f wide over a %.0f body" % [tag, m.name, b.size.x, body])
		var tw := font.get_string_size(m.name, HORIZONTAL_ALIGNMENT_LEFT, -1, bv.NAME_FS).x
		keep.append([Rect2(b.get_center().x - tw / 2.0, b.position.y - 4.0 - bv.NAME_FS, tw, bv.NAME_FS + 4.0 + b.size.y), m.name + "'s name and bar"])
	# the face-off has no strip rows (lead, Oct 26: option A), only the Team Strike line over the hero plate
	var boxes: Array = bv._team_strip_rects(st.party.size() + 1)
	check(boxes.size() == 1, "%s: %d strip boxes on the face-off, only the Team Strike line" % [tag, boxes.size()])
	var plate: Rect2 = bv._bar_rect(bv._hero_rect())
	keep.append([plate, "the hero plate"])
	var sb: Rect2 = boxes[-1]
	check(sb.end.y <= plate.position.y and plate.position.y - sb.end.y <= 8.0, "%s: Team Strike %s not just over the hero plate %s" % [tag, sb, plate])
	check(Rect2(Vector2.ZERO, bv.size).encloses(sb), "%s: Team Strike %s off the stage" % [tag, sb])
	# a knocked-out companion's plate says DOWN
	st.party.members[0].knocked_out = true
	check(BattleView.member_label(st.party.members[0]) == "DOWN", "%s: a knocked-out companion's plate says %s" % [tag, BattleView.member_label(st.party.members[0])])
	st.party.members[0].knocked_out = false
	var er: Rect2 = bv._enemy_rect(st.enemy_is_boss)
	var art: Dictionary = bv._enemy_art(st.enemy_is_boss)
	for box in boxes:
		for k in keep:
			check(not (box as Rect2).intersects(k[0]), "%s: Team Strike %s covers %s %s" % [tag, box, k[1], k[0]])
		check(not _touches(er, art, box), "%s: Team Strike %s covers the monster" % [tag, box])
	st.party = null
	main.refresh()
	await process_frame

## Every monster's solid pixels stay inside Room3D.MONSTER_BOX (the dungeon keeps its props out
## of it; dungeon r5: the Cyclops's hand reached 0.87 w, over a brazier).
func _check_box(main, bv, st: GameState, wsz: Vector2i) -> void:
	var box: Rect2 = Room3D.MONSTER_BOX
	var worst := [1.0, 0.0, 0.0, ""]   # least left, most right, lowest bottom, who
	for f in DirAccess.get_files_at("res://art/enemies"):
		if not f.ends_with(".png"):
			continue
		var key := f.get_basename()
		_fight(main, st, key)
		await process_frame
		var art: Dictionary = bv._enemy_art(st.enemy_is_boss)
		if art.is_empty() or not bv._boss_stage():
			continue
		var er: Rect2 = bv._enemy_rect(st.enemy_is_boss)
		var ub := Rect2((art["img"] as Image).get_used_rect())
		var k: Vector2 = er.size / (art["size"] as Vector2)
		var so := Rect2(er.position + ub.position * k, ub.size * k)
		var l: float = so.position.x / bv.size.x
		var r: float = so.end.x / bv.size.x
		var b: float = so.end.y / bv.size.y
		if l < worst[0] or r > worst[1] or b > worst[2]:
			worst = [minf(l, worst[0]), maxf(r, worst[1]), maxf(b, worst[2]), key]
		check(l >= box.position.x - 0.002 and r <= box.end.x + 0.002 and b <= box.end.y + 0.002,
			"%s at %dx%d: solid pixels x %.3f-%.3f, down to %.3f h, outside the monster box %s" % [key, wsz.x, wsz.y, l, r, b, box])
	print("monster box at %dx%d: solid pixels span x %.3f-%.3f, down to %.3f h (last widest: %s)" % [wsz.x, wsz.y, worst[0], worst[1], worst[2], worst[3]])

## True when a solid pixel of the monster's picture (drawn in er) falls inside the prop's rect r.
func _touches(er: Rect2, art: Dictionary, r: Rect2) -> bool:
	var hit := er.intersection(r)
	if hit.size.x <= 0.0 or hit.size.y <= 0.0:
		return false
	var img: Image = art["img"]
	var k: Vector2 = (art["size"] as Vector2) / er.size
	var a := ((hit.position - er.position) * k).floor()
	var b := ((hit.end - er.position) * k).ceil()
	for y in range(maxi(0, int(a.y)), mini(img.get_height(), int(b.y))):
		for x in range(maxi(0, int(a.x)), mini(img.get_width(), int(b.x))):
			if img.get_pixel(x, y).a > 0.1:
				return true
	return false

## The screen rects of every standing prop a fight room can hold at this stage size: 3D props of
## 10 zones x 6 rooms per fight event, and the current room's 2D decor. [[rect, name], ...]
var _props := {}
func _prop_rects(bv, st: GameState) -> Array:
	var halls: HallsScene = bv.halls
	var scr := HallsScene.screen_scale(bv)
	halls.build(st, bv.size, scr)
	var k := "%s|%s" % [bv.size, halls.room_key]
	if _props.has(k):
		return _props[k]
	var out: Array = []
	for z in 10:
		for s in 6:
			for ev in Room3D.FIGHT_EVENTS:
				var r := Room3D.new()
				r.rebuild(z, 2000 + s * 7919, {"light": HallsScene.MOODS[z]["light"], "amb": HallsScene.ambient(z),
					"accent": HallsScene.MOODS[z]["accent"], "kind": HallsScene.MOODS[z]["kind"], "dark": 0.4,
					"gate": ev == "gate", "small": halls.small, "event": ev})
				for sp in r.standing_props():
					var x: float = sp["x"]
					var w: float = sp["w"]
					var a := halls.proj(x - w / 2.0, HallsScene.FLOOR_Y + float(sp["h"]), float(sp["z"]))
					var b := halls.proj(x + w / 2.0, HallsScene.FLOOR_Y, float(sp["z"]))
					out.append([Rect2(a, b - a), "z%d %s %s" % [z, r.kind, sp["art"]]])
				r.free()
	for dc in halls.decor:
		var tex: Texture2D = load("res://art/dungeon/%s.png" % String(dc["art"]))
		if tex:
			out.append([halls.sprite_rect(tex, float(dc["x"]), float(dc["z"]), float(dc["h"]), scr), "2D " + String(dc["art"])])
	_props[k] = out
	return out

func _check_fight(bv, st: GameState, arg: String, wsz: Vector2i) -> void:
	var tag := "%s at %dx%d" % [arg, wsz.x, wsz.y]
	var big: bool = bv._boss_stage()   # bosses, Calamities and, on a short screen, tall commons
	var art: Dictionary = bv._enemy_art(st.enemy_is_boss)
	check(not art.is_empty(), tag + ": no art")
	if art.is_empty():
		return
	var sc: float = bv._scr()
	var unit: int = bv._unit()
	check(unit == ArtStyle.unit(sc), "%s: pixel unit %d, the phone's is %d" % [tag, unit, ArtStyle.unit(sc)])
	if arg == "kobold":
		# the stage's height moves every layout rule (fable r5: interface round 1's 618 / 400 went unnoticed)
		print("%s: stretch %.3f, stage %s, team %.0f, ground %.0f, floor %.0f" % [tag, sc, bv.size, bv._team_ground(), bv._enemy_ground(), bv._floor_line()])
	var er: Rect2 = bv._enemy_rect(st.enemy_is_boss)
	var ui := er.size.x / (art["size"] as Vector2).x * sc
	check(absf(ui - roundf(ui)) < 0.01, "%s: monster pixel %.2f screen px, not whole" % [tag, ui])
	check(big, "%s: not on the face-off stage on a phone" % tag)
	if big:
		# The face-off (Juzo, Oct 26): the monster further back on the hall's floor, the hero in front
		check(roundf(ui) <= bv._hero_unit(), "%s: monster pixel %d over the hero's %d" % [tag, roundf(ui), bv._hero_unit()])
		var feet_y := er.position.y + (float(art["foot"]) + 1.0) * er.size.y / (art["size"] as Vector2).y   # the lowest solid row
		check(feet_y >= bv._floor_line() - 1.0 / sc, "%s: feet %.0f over the floor line %.0f (on the wall)" % [tag, feet_y, bv._floor_line()])
		check(feet_y < bv._team_ground() - 0.5, "%s: feet %.0f not behind the hero's %.0f" % [tag, feet_y, bv._team_ground()])
		# its head and upper body show above the hero's head (the hero may cover its lower legs)
		var shown: float = (bv._hero_rest_top() - er.position.y) / er.size.y
		# commons size up until FACE_VISIBLE shows; bosses keep Juzo's size (opt2) and show at least 35%
		var least: float = 0.35 if (st.enemy_is_boss or st.enemy_calamity > 0) else bv.FACE_VISIBLE
		check(shown >= least - 0.01, "%s: %d%% shows above the hero, under %d%%" % [tag, roundi(shown * 100.0), roundi(least * 100.0)])
		check(er.position.y >= bv._boss_bar().end.y + bv.BOSS_GAP - 0.5, "%s: top %.0f over the bar, name and chip row" % [tag, er.position.y])
		check(er.size.y <= bv.size.y * 0.6, "%s: %.0f of the stage's %.0f, it fills the stage" % [tag, er.size.y, bv.size.y])
		# every monster centred between the doors, guarding them (Juzo, Oct 26)
		check(absf(er.get_center().x - bv.size.x * 0.5) < 1.0, "%s: off the centre between the doors" % tag)
		# it never meets a standing prop: the 3D rooms' (any fight room of any zone) and Low graphics' 2D decor
		# (Juzo, Oct 26: the grotto's mushrooms touched the imp and the rune hound)
		var met := {}
		for pr in _prop_rects(bv, st):
			if not met.has(pr[1]) and _touches(er, art, pr[0]):
				met[pr[1]] = true
				check(false, "%s: monster %s meets %s at %s" % [tag, er, pr[1], pr[0]])
		if st.horde_pack:
			# a pack shows one monster; the badge says which of the pack it is
			var badge: String = BattleView._pack_badge(Vector2i(st.horde_total - st.horde_left + 1, st.horde_total))
			check(badge == "%d of %d" % [st.horde_total - st.horde_left + 1, st.horde_total], "%s: badge %s with %d of %d left" % [tag, badge, st.horde_left, st.horde_total])
		# the monster stays put while the hero lunges or recoils (fable r3 item 1)
		var keep := [bv.hero_lunge, bv.recoil]
		for lr in [[1.4, 0.0], [0.0, 1.0], [1.4, 1.0]]:
			bv.hero_lunge = lr[0]
			bv.recoil = lr[1]
			check(bv._enemy_rect(st.enemy_is_boss) == er, "%s: monster moves with lunge %s recoil %s" % [tag, lr[0], lr[1]])
		bv.hero_lunge = keep[0]
		bv.recoil = keep[1]
		# (b) a banner sits clear of the boss bar and its name
		var bl: Rect2 = bv._banner_line()
		var band := Rect2(bl.position.x, bl.position.y - 26.0, bl.size.x, 26.0 + bl.size.y + 4.0)
		check(not band.intersects(Rect2(bv._boss_bar().position.x, 14.0, bv._boss_bar().size.x, bv.BOSS_NAME + 20.0)), "%s: banner %s on the boss name" % [tag, band])
		if arg in ["boss_grendel", "imp", "garmr+pack"]:
			# fable r5: the banner over the chest, not the face (the top 35%)
			var face := Rect2(er.position, Vector2(er.size.x, er.size.y * 0.35))
			check(not Rect2(0.0, bl.position.y - 22.0, bv.size.x, 22.0).intersects(face), "%s: banner at %.0f on the face %s" % [tag, bl.position.y, face])
	# no pet (companion or menagerie, placed by team_layout) under the hero's plate
	var w: float = 32.0 * bv._u()
	var hp: Rect2 = bv._bar_rect(bv._hero_rect())
	var lay: Dictionary = bv.team_layout()
	for k in lay:
		var body := Rect2(float(lay[k]) + w * 0.2, bv._team_ground() - w, w * 0.6, w)
		check(not body.intersects(hp), "%s: pet %s at %s under the hero plate %s" % [tag, k, body, hp])

## (c) statuses and mods on the boss stage stay off the boss (rows under its plate).
func _check_chips(bv, st: GameState, arg: String, wsz: Vector2i) -> void:
	var tag := "%s at %dx%d with chips" % [arg, wsz.x, wsz.y]
	var er0: Rect2 = bv._enemy_rect(st.enemy_is_boss)
	st.burn_turns = 3
	st.enemy_poison_turns = 2
	st.cfight["windup"] = 1
	st.enemy_mods = ["Swift", "Armored", "Giant"]
	await process_frame
	await process_frame
	var er: Rect2 = bv._enemy_rect(st.enemy_is_boss)
	# fable r5: chips never move the boss (one row is always kept for them)
	check(er == er0, "%s: the boss moved from %s to %s" % [tag, er0, er])
	var lay: Array = bv._boss_chip_layout()
	check(lay.size() >= 4, "%s: %d chips laid out, not 4+" % [tag, lay.size()])
	for it in lay:
		check(absf((it[1] as Rect2).position.y - (lay[0][1] as Rect2).position.y) < 0.5, "%s: chips in more than one row" % tag)
	var squeezed: bool = er.position.y < bv._boss_bar().end.y + bv.BOSS_NAME + bv._boss_chip_room()
	for it in lay:
		var box: Rect2 = it[1]
		check(box.position.y >= bv._boss_bar().end.y + bv.BOSS_NAME, "%s: chip %s on the boss name" % [tag, it[0][0]])
		check(box.position.x >= 0.0 and box.end.x <= bv.size.x, "%s: chip %s off screen" % [tag, it[0][0]])
		if not squeezed:   # only the tallest Calamity on a short screen can't leave room
			check(not box.intersects(er), "%s: chip %s on the boss" % [tag, it[0][0]])
	var bl: Rect2 = bv._banner_line()
	check(bl.position.y - 26.0 >= (lay[-1][1] as Rect2).end.y, "%s: banner over the chips" % tag)
	st.burn_turns = 0
	st.enemy_poison_turns = 0
	st.cfight.erase("windup")
	st.enemy_mods.clear()
	await process_frame

## (a) a Calamity's death keeps its size, place and crimson edge (its state flag is cleared
## before the view gets the event: Calamity.on_slain).
func _check_death(main, bv, st: GameState, arg: String, wsz: Vector2i) -> void:
	var tag := "%s at %dx%d dying" % [arg, wsz.x, wsz.y]
	st.burn_turns = 3   # its chips go with it (fable r5: the corpse jumped by their room)
	var er: Rect2 = bv._enemy_rect(false)
	st.enemy_calamity = 0   # what Calamity.on_slain does first
	var ev: Array[Dictionary] = [{"type": "enemy_dead", "shape": st.enemy_shape, "color": st.enemy_color, "boss": false,
		"name": st.enemy_name, "art": st.enemy_art, "tier": 0, "calamity": true}]
	bv.play(ev)
	st.burn_turns = 0
	check(not bv.dying.is_empty(), tag + ": no dying monster")
	if not bv.dying.is_empty():
		check(bv._dying_rect() == er, "%s: corpse %s, it stood at %s" % [tag, bv._dying_rect(), er])
		check(String(bv.dying["edge"]) == "e43b44", "%s: burn edge %s, not crimson" % [tag, bv.dying["edge"]])
	# the burn, then the next one's walk-in, play out before the next fight is measured
	await create_timer(1.4).timeout
	check(bv.walk_in == 0.0 and bv.enemy_alpha == 1.0, "%s: the next monster never finished stepping in" % tag)
	bv.dying = {}
	await process_frame

## (d) the Bestiary shows commons and bosses at one scale: 2 screen px per art px on a phone,
## Charybdis (126 px, the widest boss) included, on the SE too.
func _check_bestiary(main, wsz: Vector2i) -> void:
	var cx: Codex = main.codex
	for id in ["kobold", "grendel", "charybdis"]:
		cx.entry(id)["kills"] = maxi(1, int(cx.entry(id)["kills"]))
	main.state._check_codex()
	main.show_tab(3, 0)
	var bt = main.bestiary_tab
	for id in ["kobold", "grendel", "charybdis"]:
		bt.selected = id
		bt.shown = ""
		main.refresh()
		for i in 3:
			await process_frame
		var sc: float = bt._screen_scale()
		var k: float = bt.pic.size.x * sc / maxf(1.0, bt.pic_size.x)
		check(absf(k - 2.0) < 0.05, "Bestiary %s at %dx%d: %.2f screen px per art px, not 2" % [id, wsz.x, wsz.y, k])
	main.nav_page = 0
	main._apply_nav()
	for i in 3:
		await process_frame

