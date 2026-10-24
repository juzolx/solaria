# Solaria UI review (UX & Onboarding expert, Oct 24 2026)

Method: every screen captured at phone size (`tools/check.sh shots`, 430x932 window, 504x896
design layout), then a structured critique (first impression, usability, hierarchy,
consistency, accessibility) and a WCAG 2.1 AA pass (contrast, text size, touch targets,
colour-blind safety) on the key screens. Before/after: `shots/ui_before`, `shots/ui_after`
(all before shots: `shots/ui_before_all`).

Scale note: the phone layout is 504 design px wide, shown on a ~430 pt screen (x0.85).
Old minimum text (13 design px) was ~11 pt on the phone; the new minimum (15) is ~13 pt.

## Ranked findings (all screens)

| # | Finding | Severity | Status |
|---|---------|----------|--------|
| 1 | Text too small almost everywhere: 11-13 px captions, top bar 11 px, item popup 11 px, skill cards 11 px, nav labels 13 px. Below a comfortable phone size. | Critical | Fixed: type scale, MIN_FONT 15 |
| 2 | Screens wider than the phone: Shop needed 515 px of 504 (sell-all row), so the whole page, nav bar and Menu button were cut off on the right. The tour now names the widest control when this happens. | Critical | Fixed (Shop, Gear, Bag, Town bar, item popup) |
| 3 | Rainbow: 8 stat cards in 8 colours, teal/green/blue/pink main buttons, a red class frame on the Hero card. Nothing reads as "important" because everything is coloured. | Major | Fixed: one gold accent, neutral cards, gold edge = suggested |
| 4 | Skill icons nearly invisible: soft, half-transparent glow frames on a dark panel, shown at non-integer sizes (22, 26, 34 px). | Major | Fixed: solid pixels, 1 px dark outline, stone plate, native 32 px |
| 5 | Bottom bar icons are thin 1-px strokes (sword), unlike the chunky outlined pixel art. | Major | Fixed: 14x14 filled shapes + 1 px outline, shown 2x |
| 6 | Top bar Risk/Bank pill: two lines of 11 px text in a cramped pill; zone name ellipsised to "MOSSY HOLLO..." and repeated in the battle view. | Major | Fixed: 15 px, tighter pill; zone hidden on phones (battle view shows it) |
| 7 | Codex: monsters you haven't met are near-black blobs (modulate 0.32) that vanish on the dark list. | Moderate | Softened (0.5 grey-violet). Keeping them hidden is a design call: open question |
| 8 | Generic frames: flat rounded rectangles of mixed radius (6-10) and edge widths next to the iron frames. | Moderate | Partly: cards now 6 px radius, 1 px iron edge; more in "Next" |
| 9 | Town map: "Into the dungeon" + Mail + status line overflowed once text grew. | Moderate | Fixed: status line wraps |
| 10 | Menu: "Fullscreen" toggle shown on phones (meaningless); "Delete this hero" looks like every other button. | Minor | Fixed: hidden on mobile; red label |
| 11 | Copy: Hero tab says "Stats marked SUGGESTED" but the cards show a star. | Minor | Fixed |
| 12 | Battle view overlay text (weakness tag, HP numbers, unit names) is drawn in battle_view.gd at ~11 px. | Moderate | Open (battle_view is owned by the juice/art sessions; flagged) |
| 13 | Fight skill buttons and some `refresh()` code build new StyleBoxFlat objects every tick. Cheap, but avoidable. | Minor | Open (perf note) |

Contrast check (WCAG 1.4.3): bone text #e2dac6 on panel #15142a 12.9:1; dust #a89d84 on inset
7.1:1; gold #e8b14a on panel 9.3:1; green/red/blue state text 6.9-10.9:1: all pass. Fails: disabled
button text #5a5670 on #13121f 2.7:1 (allowed for disabled controls, but it reads as broken; consider
#6e6a86). Button edge #7a7493 on stone 3.6:1 passes 1.4.11.

Touch targets (2.5.5): most buttons are 42-44 px tall (TAP 44). Sub-tabs are ~30 px tall: below 44.
Skill slots were 34 px when empty (now 46/62 when filled; empty slots still 34). Bag grid cells 44.

Colour-blind: rarity and state are mostly backed by words (UNCOMMON, "+85", Colorblind labels
setting). Stat cards no longer rely on hue at all (gold edge + star). Shop cards keep the rarity word.

## Per screen

### Fight (02)
- Works: the battle scene dominates; the action row is big and thumb-reachable.
- Top bar was the weakest part (11 px Risk/Bank, ellipsised zone, small floor number). Now: floor 20 px,
  zone hidden on phones, Risk/Bank 15 px.
- Open: battle overlay text size (finding 12); "Run" disabled state looks like a broken button.

### Hero (03)
- Rainbow stat grid fixed: neutral iron cards, gold border + gold label + star on the stats your class
  wants. The number is the hero of each card (26 px). Header card uses the iron edge; class colour stays
  in the name. Share/Presets are plain stone buttons (secondary actions).

### Class (04)
- Clear "choose now" path strip. Class rank colours are identity colours like rarity: kept.

### Skills (06)
- Icons now readable and consistent. Passive slots (five across) show icon over name instead of a
  clipped two-line label. Empty slots still small (34 px): open.

### Gear (09) / Bag (10) / Item popup (11)
- Gear hint now wraps (it pushed the screen to 564 px with bigger text). Equip Best is the gold main action.
- Bag: four salvage-all buttons fit by clipping; Loot filter button OK.
- Item popup: on phones the two cards stack (side by side at 15 px left ~200 px per column).

### Codex / Bestiary (12)
- Two-column list + detail works. Unmet monsters were black blobs: softened. The list rows are only
  ~22 px tall: hard to tap precisely on a phone (open: make rows 44 px or the list single column).

### Town map (24) and building pages (25-34)
- Map is the best-looking screen. Labels on buildings are small (drawn in town_view.gd).
- Shop: overflow fixed (two-line sell-all buttons, rarity/slot lines shorten). Three shelf cards per row
  is tight at 15 px; two per row would read better (open, owner call: longer scroll).
- Tavern/Wheel: fine; the "0% win" label under the wheel is small and green-on-red.

### Menu (22)
- Grouping is good. Fullscreen hidden on phones; delete is red.

## The design system (in code: ui.gd header + tokens, ui_skin.gd)
- Palette: ink/stone/iron greys + bone text; GOLD = the one accent ("this matters / tap here / suggested");
  state family GOOD (green) / BAD (red). Rarity colours only on items. BLUE/TEAL/PINK/PURPLE are legacy
  (elements, tags, rarity) and never for buttons, cards or frames.
- Buttons by role: `UI.primary()` gold main action (legacy colours fold into gold via `UI.role_color`);
  `UI.danger()` red for diving, attacking, irreversible; plain stone theme button for everything else.
- Type scale: CAPTION 15 (minimum), BODY 16, TITLE 20, DISPLAY 26 (`UI.FONT_*`); theme defaults follow it.
- Spacing 4/8/12/16 (`UI.SP_*`); touch targets >= `UI.TAP` 44.
- Cards: inset stone, 6 px radius, 1 px iron edge (`UI.CARD_EDGE`); 2 px gold edge when selected/suggested.
- Icons: chunky filled pixel shapes, 1 px near-black outline (`UiSkin.SOOT`), integer scale only.

## Next (not done in this pass)
1. Battle overlay and town-map label text to 15 px (battle_view.gd / town_view.gd owners).
2. Sub-tab and Codex list rows to 44 px tall.
3. Replace remaining flat `UI.style()` panels in building pages with the card rule.
4. Cache fight skill button styles instead of rebuilding each tick.
