# Fable review: INTERFACE, round 1 of 5 (Oct 25 2026)

Reviewed: pictures ingame/03-23 (430x932 unless noted), claude/research/ui-research.md (the spec), style-bible.md, and the code on big-update (ui.gd, ui_skin.gd, main.gd, overlay.gd, *_tab.gd, settings_menu.gd, death_screen.gd, item_popup.gd, item_grid.gd). wt/interface is BEHIND big-update (no commits ahead); its uncommitted work (battle_view, character_creator, class_tab, gear_tab, main, title_screen, wheel_tab) matches pictures 20-23 and was looked at only through those pictures.
Not counted (being fixed elsewhere): death-card OK cut off at 375x667, creator/title touch targets, Change-look Cancel, title idle crash.

Scale facts used below: the phone layout is 504 design px wide (main.gd:9, `_fit_layout` main.gd:817-826, CONTENT_SCALE_ASPECT_EXPAND). On a 430-wide phone 1 design px = 0.853 pt; on 375x667 it is 0.744 pt. So 44 design px = 37.5 pt (430) / 32.7 pt (375), and the 44 pt Apple floor is 52 design px (430) or 59 (375): the brief's "56" is right.

## Problems, worst first

1. **Almost all text is 15 design px, which is 12.8 pt on a 430 phone and 11.2 pt on a 375 phone; and 15/16/26 are not whole Pixelify pixels.**
   Where: ui.gd:47-50 (`FONT_CAPTION 15, BODY 16, TITLE 20, DISPLAY 26`); `UI.label()`/`rich()`/`wrap()` default to FONT_CAPTION (ui.gd:90, 97, 200); grep: 381 uses of FONT_CAPTION vs 7 of FONT_BODY and 3 of FONT_TITLE. Every body paragraph in pictures 03, 05, 11, 13, 15 is caption size. ui-research.md Round 9/10 (the spec the UI was built to) says Pixelify's pixel = size/10, so only 20/30/40 sit on the 2x grid; 15 draws 1.5-px strokes (visible as uneven stems in 03 "Faith +0..." and 15 "Defeat every kind...").
   Fix: FONT_BODY = 20 and make it the default of label/rich/wrap; FONT_CAPTION = 15 only for badges and chips (max 3 per screen); FONT_TITLE = 30, FONT_DISPLAY = 40; delete 16/26. Then cut words (item 12) so it still fits. Check 375x667 after: body must be >= 14 pt there.

2. **Every button and tab is under the 44 pt floor on a phone.**
   Where: ui.gd:60-61 `TAP = 44`, `BUTTON_H = 42` (the comment itself admits "~36 pt"); SubTabs margins 13+13 ui.gd:384-388 (~44 design px); item_popup.gd:43 buttons 40; skills_tab.gd:173 signature button 34; Overlay "Close" is a plain UI.button (overlay.gd:42) = 42; OptionButtons (bag_tab.gd:50-60, skills_tab.gd:50) have no minimum at all (~36 design px = 31 pt in picture 07). Pictures: 06 "Bring along"/"More" 34 pt tall, 03 the Hero/Class/Race row 36 pt, 16 all toggles 36 pt.
   Fix: TAP = 56, BUTTON_H = 52, SubTabs content_margin_top/bottom = 17, OptionButton custom_minimum_size.y = BUTTON_H in the theme (or a `UI.pick()` helper), Overlay Close = TAP. Keep the 64 px nav. Height not width: the rows already span.

3. **Every popup builds a brand-new Theme, and its Close button scrolls away.**
   Where: overlay.gd:15 `theme = UI.make_theme()` runs on every `open()`: item tap (item_popup.gd:14), confirm, settings, autoplay, odds, craft... `make_theme()` (ui.gd:330-399) allocates ~35 StyleBoxes, a FontVariation lookup and 12 frame/bevel duplicates each time. Also overlay.gd:36-42: the title row with Close is the first child of `content`, which lives inside `scroll`, so on a long popup (picture 16 Menu, 15+ rows) the only way out after scrolling is to scroll back up; the last row is cut off with no scroll hint.
   Fix: `static var _theme` in UI, build once (`UI.theme()`), or set no theme and inherit main's; put the title/Close hbox in `box` above `scroll` (sticky header); add a bottom "Close" when `content` is taller than `max_h` (overlay.gd:53).

4. **OFF settings look exactly like disabled buttons.**
   Where: settings_menu.gd:362 OFF = `bevel(UI.PANEL #181425, UI.EMPTY)` + DIM text; the theme's disabled button is `bevel(#1f1d24, EMPTY)` + #5a6988 text (ui.gd:342, 355). Picture 16: "Battery saver: OFF", "Damage numbers: OFF", "Fullscreen: OFF" are indistinguishable from the genuinely disabled "Back up all heroes" / "Restore from cloud"; "Graphics: Normal" and "Interface size: Normal" (cycle buttons) borrow the ON look without being on.
   Fix: a `UI.toggle(label, on)` control: normal slate face in both states, bone text in both, a 12x12 pixel box at the left (gold fill + check when on, empty when off); cycle buttons get "‹ Normal ›" arrows; disabled keeps the dim face. Colour is never the only signal (research rule 6).

5. **Four different section-heading styles on the same screens.**
   Where: `UI.heading` = "◆ TITLE" caps in GOLD_DULL (ui.gd:127-130); `UI.section` = caps in GOLD + rule line, no diamond (ui.gd:221-233), both used in class_tab (lines 120 and 248), pet_tab (35 vs none), party_tab (`UI.label("YOUR PARTY", 15, GOLD)` line 30 + `UI.heading("Bring along")` line 55); wheel_tab.gd:109 `"FORTUNE'S WHEEL", 18, GOLD`; skills_tab.gd:42 `"ACTIVE"` DIM caps; death_screen.gd:94 its own `_head`. Worse, whole sentences are shouted in caps: craft_tab.gd:61 "YOUR SCRAP AND DUST - SCRAP COMES FROM SALVAGING, DUST FROM BOSSES, RARE MONSTERS AND MAXED SKILLS" (3 lines in picture 11), craft_tab:86, 126, 141; shop_tab:64, 137.
   Fix: one `UI.heading(title, note := "")`: the research's cut-corner slate title plate with the title in gold (<= 3 words), and the note as a sentence-case DIM line under it. Make `UI.section` call it, delete the ad-hoc labels, and grep for `to_upper()` on anything longer than 24 characters.

6. **Codex and Town sub-tab rows overflow and rely on Godot's default 12 px tab-scroll arrows.**
   Where: picture 15 top right "◀ ▶" beside "Rewards"; main.gd:862-868 `_group()` never sets `clip_tabs`/a TabBar scroll, and Codex has 8 pages, Town 9 (main.gd:1885-1905). The arrows are ~10 pt tap targets and the hidden pages (Bestiary, Achievements...) are invisible until you find them.
   Fix: icon tabs (12-16 px glyphs on the grid, research round 10) so 8 fit at 504; or `clip_tabs = false` with the TabBar inside a horizontal ScrollContainer with drag; or two rows of 4. Hide the arrows either way.

7. **The hero's name is "Thorin Lv 30..." on every single screen.**
   Where: pictures 03-19 top-left. main.gd:880-888: `class_label` has OVERRUN_TRIM_ELLIPSIS, the hero vbox has no minimum width, while `mid` is EXPAND_FILL (main.gd:898) and the Risk/Bank pill and Menu take ~140 px; `xp_bar` 100 px (main.gd:862). A 6-letter name is already cut.
   Fix: on phones show "Thorin · 30" (level only, class is on the Hero tab) with `hero.custom_minimum_size.x = 140`; or put the level on the XP bar as "30" at its right end. Never ellipsize the player's own name.

8. **Bag header and item badges collide with the content.**
   Where: picture 07: "BAG 14/10 (4 over: sell to use them)" wraps to 3 red lines in a 60 px column (bag_tab.gd:44-47 `custom_minimum_size = Vector2(60,0)`, title text bag_tab.gd:298) beside two OptionButtons + Select. Badges "+100%"/"OVER" (item_grid.gd:61-62) ask for 10/11 px but `UI.label` clamps to 15 (ui.gd:93), so a 15 px label covers a third of each 54 px cell and the icon.
   Fix: row 1 = "Bag 14/10" + a red chip "4 over" (tip: "sell to use them"); row 2 = Sort | Slot | Select. Badges: a 3x3 corner stud in green (better) / red (over) / gold (locked), numbers only in the detail box; keep "LOCK" as a small padlock glyph.

9. **Shop featured deal is a text wall squeezed between a picture and a Buy button.**
   Where: picture 12 (8 wrapped lines, "Red berries keep the wicked off. Mostly." next to a Buy button mid-paragraph); shop_tab.gd:69-83: hbox = 64 px pic + rich text + 130 px Buy, leaving ~230 px for the text on a 504 layout. "Your gold 9480" (shop_tab gold_label) repeats the top bar's "Gold 9480".
   Fix: phones stack: [pic 64 | name (rarity colour) + "+81 HP · Score 361"] then one line "HP 989 → 1089 (+18%)", then a full-width primary "Buy · 1626 gold"; flavour text and the long compare go to the tap popup. Drop the duplicate gold line.

10. **Dead grey buttons with no reason on them: "Build" and the 8 Mystery-gear slots.**
    Where: pictures 11, 12, 13: "Build" is `UI.primary` (building_bar.gd:29) but disabled, so a gold main action renders as a grey block beside a 3-line cost paragraph; picture 11 bottom: 8 disabled slot buttons (craft_tab.gd:131-137) with no price and a separate "Costs: 0 / 20 scrap each" line.
    Fix: a disabled main action must carry its reason: "Build · 1800g + 60 scrap" (red cost when short), paragraph cut to "Lv 2: upgrades cost 5% less scrap"; Mystery gear = one primary "Roll · 20 scrap" + a slot OptionButton (or chips), hidden until you have scrap.

11. **The Class tab rebuilds its whole page on changes that have nothing to do with it.**
    Where: class_tab.gd:26-41: the refresh key includes `kills/25`, `enemy_is_boss`, `trial_active`, `hidden_offer`; when it changes, `OnlineUI.clear(box)` then 7 builders re-create ~40 RichTextLabels, 2 portraits (`Sprites.portrait`, class_tab.gd:58) and 10 frame/bevel styleboxes (each `UiSkin.frame/bevel` returns a `.duplicate()`, ui_skin.gd:27, 62). hero_tab does the same with 11 bevel calls per refresh. On a phone this is the lag you feel when the Hero tab opens mid-fight.
    Fix: build the page once in `setup`, keep node references and set `.text`/`.visible` in refresh; keep a rebuild only for the pick panel (key: class, path, level, offers). Same for hero_tab's stat tiles.

12. **Too many words before the first action.**
    Where: picture 03 Class: ~190 words above the Choose buttons (Faith paragraph class_tab.gd:94-96 is 33 words, "Whispers" 30 words, "Your path" 20 words); picture 05 Party: ~140 words and no action at all; picture 13 Wheel: 60 words (wheel_tab.gd:110-124) before the wheel; picture 06 Pets: 35-word intro. The research rule is "numbers + icons over words".
    Fix: the pattern already in party_tab.gd:46-48 (one line + `UI.tip` for the rest) everywhere: Faith → a chip "Faith +0 · Neutral" with a tip; Whispers → one quote line; Wheel → "Win: +1 rarity. Lose: gone." + an Odds button (it exists); Pets intro → one line.

13. **Skills tab: labels that look truncated, a stock dropdown, and a 60%-empty page with three disabled buttons at the bottom.**
    Where: picture 04: "Autoplay..." and "Craft..." (skills_tab.gd:38-39 have literal dots, while the top-bar name is ellipsized for real: the player cannot tell which is which); the filter is a bare `OptionButton` spanning the width (skills_tab.gd:50-56); Equip / Rank up / Sell are disabled with nothing selected and the book (2 cards) leaves the middle empty.
    Fix: "Autoplay" / "Craft" without dots (dots only for truncation, system-wide); filter as a chip row (All · Blade · Blood ...); actions move into the tap popup like items (item_popup), so the page is slots + book; the help line becomes an empty-state note only when the book is empty.

14. **Item popup: "THIS ITEM" and "(you average 0)" are labels nobody asked for, and its buttons are below the button floor.**
    Where: picture 09; item_popup.gd:18 `_card(state, item, "THIS ITEM")`, 41 `"WEARING NOW"`; buttons `custom_minimum_size = Vector2(0, 40)` (item_popup.gd:43) with font forced to caption; the second card is "You're not wearing anything in this slot." in a bordered box.
    Fix: no caption on the first card (the popup title is the name); "Wearing now" only when there is one; one compare row "Defense 24 → 68 (+88)" in two columns Now/With; buttons at TAP; drop "(you average 0)" until there is an average.

15. **Regular death card sits on top of a still-live fight UI.**
    Where: picture 18: the red card is inside the battle panel; the action row (Cleave!, Auto, Potion, Run, More), the HP plate and the "New mail" toast stay fully lit under it; nothing dims. death_screen.gd:11-66 builds a PanelContainer only, main places it; the hardcore version (picture 19) correctly uses an Overlay with dim.
    Fix: show the regular card through `Overlay.open(..., border #a22633)` like hardcore (dim + input block), or dim the battle panel to 40% and hide the action row while the card is up.

16. **Settings is one 900 px column of 23 same-looking buttons.**
    Where: picture 16; settings_menu.gd: 9 `UI.heading` groups in one scroll, mixed toggles, cycles ("Graphics: Normal") and actions ("Test sound", "Copy debug info") all in the same slate block; the bottom row is cut with no scrollbar visible; no Close at the bottom (see item 3).
    Fix: 3 sub-tabs (Game · Sound · Access) or at least actions as plain buttons, toggles as item 4's toggle control, cycles as "‹ ›" steppers; Hero actions (Title screen, Change look, Wardrobe) at the top as 3 big_buttons with icons.

17. **Class path strip: four 100 px cards that do nothing, with green "Choose now!" fighting the gold Choose buttons.**
    Where: pictures 03, 20 (2nd and 4th shots); class_tab.gd:250-285: 4 cards (Start / Level 18 / Level 38 / Level 78) with 15 px text, "›" arrows at 18 px, and `UI.GREEN` for "Choose now!" while the research's rule is gold = tap here, green = good state. In picture 20 the "???" cards show a hair-only silhouette that reads as a bug.
    Fix: one horizontal line of 4 nodes (6 px dots on a 2 px line, level numbers under, the current node gold), class name under the reached nodes; the "choose now" state is the gold frame on the pick panel, not a second colour. A proper "?" silhouette (dark hero outline) for unknown stages.

18. **Top bar carries three text colours and a two-line pill in a one-line bar.**
    Where: every picture: red hero name (danger colour for a name), gold "Floor 30", a gold-edged pill with "Risk 9000 / Bank 0" on two lines (main.gd:1688 `two`), and "Menu" at ~34 pt; the pips next to the floor are 10 px decoration (main.gd:908).
    Fix: bone name, gold only on Floor; one line "◆ 9000 · bank 0" (coin glyph) in the pill; Menu at TAP with the ≡ glyph; keep pips but 12 px with a 2 px gap.

## Also noticed (not scored)
- The 21b "after" (wheel at 375 wide) fixes the nav push-off; the three-button row there is 36 pt tall (item 2 applies).
- Picture 22/23 creator: colour swatch rows are 44 px squares with 6 px gaps: fine once TAP is raised; the hair "◀ Long 18 of 37 ▶" stepper is the right pattern for item 4's cycles.
- Safe area (main.gd:832-838) is only applied on mobile and only top/bottom: correct.

## Score: 5 / 10
The chrome (ink frames, slate bevels, gold studs, rarity edges) is now coherent and on the pixel grid, the nav bar is right, and the death/creator/class cards are close to the mockups. What holds it back is systemic, not per-screen: the type scale and tap sizes were set for a 648-wide layout and never re-derived for 504-on-a-phone, so every screen is small and dense, and the "fewer words" rule was applied to one tab only.

## Biggest opportunity
Change five numbers and one default (FONT_BODY 20 as the label default, TITLE 30, DISPLAY 40, TAP 56, BUTTON_H 52, SubTabs margin 17) and cache the overlay theme: that alone fixes items 1-3 across all 30 tabs in one commit, and makes the word-cutting (items 5, 9, 12, 13) unavoidable rather than optional.
