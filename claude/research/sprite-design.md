# Sprite design guide: races, monsters, gear visuals

For: the Art Director (heroes, monsters, gear art). Read with `claude/research/art-critique.md`
(Juzo's direction) and `claude/research/art-pipeline.md` (SDXL pipeline, layers, rig, cleanup).
Code read, not edited: `races.gd`, `lpc.gd`, `sprites.gd`, `art_info.gd`, `art_style.gd`,
`item_pool.gd`, `game_data.gd`, `realms.gd`, `wardrobe.gd`, `game_state.gd hero_looks()`.
Tags: **[S]** backed by a source in section 12, **[C]** read in our code, **[M]** measured in this
research, **[D]** design call made here (Juzo can overrule), **[Q]** open question with a default.

---

## 0. The short version
1. **Three read channels, in this order: build (silhouette), head, colour.** Every race must be
   identifiable from any two of the three. [D]
2. **Six body builds, not three.** Today all races except Orc/Golem use the same human body [C]. A goblin
   head on a human body reads as "a deformed human", and a bearded human reads as a dwarf, so both end up
   the same thing. Builds: Tiny (Fairy), Small-thin (Goblin), Short-wide (Dwarf), Standard (most), Large
   (Orc), Block (Golem). [S Polycount goblin critique, MEO "fireplugs"; D]
3. **One signature feature per race, exaggerated and on the outer edge of the silhouette**, so it survives
   the back view and helmets: goblin ears sideways, elf ears up-back, dwarf beard past the jaw, orc
   shoulders above the ears, demon horns forward, dragonkin horns back. [S silhouette sources; D]
4. **Skin hue families never overlap between look-alike races.** Goblin = yellow-green, Orc = blue-green
   moss / brown / war-red, Dwarf = ruddy human tones only. Today a goblin can be tan and a dwarf green. [C]
5. **The back view gets the most care.** Signatures sit in the outer 2 px ring of the back-3/4
   silhouette. [critique; D]
6. **Gear never hides the race.** Signature parts draw ABOVE the helmet, and helmets get notches. Daggerfall
   masks hair under helmets and Stardew remaps hairstyles under hats. We do both, but the signature is
   never masked. [S; D]
7. **Monsters: a zone is one family (material ramp + motif + accent colour), and each monster is distinct
   by silhouette class + size + posture.** No two monsters in a zone share both class and size.
   Monsters built from a hero race keep the build but get a corrupted colour family. [S; D]
8. **Gear: Weapon, Off Hand, Helmet and Chest change the shape; Legs and Feet change colour only.** [D]
9. **Four visual tiers from the ten rarities: Plain, Fine, Ornate, Mythic.** Each step adds a cue that is
   not colour: detail, then a new silhouette, then glow, then motion. [S D2, HotS, RuneScape, colour-blind
   practice; D]
10. **The material ramp comes from the item's zone and the trim colour from its rarity**, both through the
    existing key-colour recolour, so variety costs almost nothing. [C; S Moonlighter, D3; D]
11. **Glow and particles are code**, local to the item, with hard alpha steps and a dark core. Capes and
    the whole-hero aura are already used for class prestige. [C; critique]
12. **Every sheet passes the checklist in section 10 at 1x on a real battle background** before Juzo sees it.

---

## 1. Why goblins look like dwarves today [C]
| Problem | Where | Effect |
|---|---|---|
| Dwarf = human head + `beard_winter` on the standard `male` body | `lpc.gd RACES`, `spec()` | Human height and width; only a beard differs |
| Female dwarf drops the beard | `spec()`: `extras.erase("beard_winter:hair")` | Pixel-identical to a female human |
| Goblin = LPC `head_goblin` on the standard body | `lpc.gd RACES` | Human-height goblin; the head carries everything |
| Bodies: `female`, else `muscular` (Orc, Golem), else `male` | `spec()` | 3 bodies for 12 races |
| Skin options overlap | `races.gd`: Goblin [6,2,3], Orc [6,3,4,7]; races without a list get 0-7 (incl. green 6) | Tan goblin = dwarf colours; green dwarf = goblin colours |
| Race extras drawn before gear | `spec()` part order | A helm or hood covers goblin and elf ears |
| Elf vs Human = ears only | `RACES["Elf"]` | A hooded elf is a human |
| Orc and Golem share the muscular body | `spec()` | Only head and colour separate them |
| Orb and tome have no parts | `GEAR "orb": [], "tome": []` | Casters' off-hand is invisible |
| Rarity = trim colour; glow only from the weapon at Legendary+ | `gear_look()`, `_hero_lpc()` | Common and Epic armour look the same at battle size |
| Hero is 1x LPC next to 2x monsters | `HERO_PIXEL := 1` | Critique item 1; new 2x heroes are planned |

The new 2x heroes (art-pipeline section 7) are the moment to fix all of this. Sections 3-4 are the brief
for the build mannequins (`rig_<build>_<view>.json`).

---

## 2. Principles for small sprites
### 2.1 What the sources agree on
- **Silhouette first.** Block the figure in one flat colour. If it does not read, shading will not save
  it. Squint, and zoom out to game scale often. [S sprite-ai 16x16 guide; Wayline; bugnet]
- **Similar silhouettes are hard to tell apart.** "When two objects have a similar silhouette, they become
  difficult to tell apart." Many Gen 1 silhouettes looked alike, and early sketches were changed for
  silhouette reasons. [S Smogon]
- **Simple base shapes and exaggerated edges.** Gen 3 built on spheres and ovals, and jagged fur edges read
  better than realistic fur. Designs used about 4 major colours, with the extra palette spent on shading
  and one small accent. [S Game Developer]
- **Families share shape language and motifs** (rings, eye masks, zigzags), so a line of creatures reads
  as one. [S Game Developer]
- **Exaggerate body types so they read at a distance.** MEO built its dwarves "like fireplugs" because the
  team wanted "a body type distinction discernable at distance". Warcraft reads well because of broad
  silhouettes and exaggerated physiques. [S GameBanshee MEO diary; Warcraft commentary]
- **A goblin head on a standard human body clashes.** Goblins need a crooked body and posture. [S Polycount
  critique (via search summary; the page returns 403), goblin-drawing essay]
- **Chibi is about 1:2 head to height**, which gives a 32 px chibi a 16 px head with room for a face. Hair
  is "where a chibi character becomes a specific character": silhouette first, colour second. [S sprite-ai
  anime guide; convention]
- **Use few colours, each with a job, and hard value steps.** [S sprite-ai]
- **In third person the player mostly sees the back**, so make the back interesting with capes, belts and
  asymmetry. [S hitem3d; rule of thumb]
- **Blackout test:** fill the figure with black. Identity and action must still read. [S hitem3d;
  silhouette lesson]
- **Shape language:** circles read friendly, squares sturdy, triangles dangerous. Mix them, but give each
  design one dominant shape. [S rocketbrush, 21-draw, 3dsense]
- **Back sprites in creature battlers were drawn larger than the front sprites** (Gen 3 about 40% larger,
  by one modder's count) to sell the camera being close. Our hero should never look smaller than the
  monster it faces. [S PokeCommunity, low confidence]

### 2.2 Our pixel budget [C art_style, art-pipeline]
- The hero window is 40x42 art px on the 2x grid. A Standard build is about 38 art px tall, and the chibi
  head is about 40% of that (look C), so about 15 px. A monster body is 32x32 art px (68x68 file); giants
  are 32x64.
- A feature under 2 art px disappears on a phone (the critique's "2 px minimum" for weapon lines). A race
  signature needs at least 3 px of protrusion past the head or body outline, or a colour block of at least
  3x3. [D]
- One outline (`#0e0812`), a 74-colour palette, OKLab nearest. [C]

---

## 3. Race silhouette sheets
H = Standard height (about 38 art px). Head % = head height / total height.

### 3.1 Builds
| Build | Races | Height | Shoulders | Head % | Dominant shape | Posture |
|---|---|---|---|---|---|---|
| Tiny | Fairy | 0.70 H, floats 3-4 px above the foot row | 0.8x | 50% | circle + two wing ovals | bobbing hover |
| Small-thin | Goblin | 0.78 H (plus ears) | 0.85x, sloped | 48% | inverted triangle on sticks | hunched, head forward of the chest, knees bent |
| Short-wide | Dwarf | 0.80 H | 1.2x | 38% | square / barrel | upright, chest out, feet wide |
| Standard | Human, Elf, Angel, Demon, Undead, Beastkin, Dragonkin | H | 1.0x | 40% | per race | per race |
| Large | Orc (and Werewolf form) | 1.08 H | 1.35x, top above the ear line | 32% | trapezoid, wide on top | leans forward from the hips, long arms |
| Block | Golem | 1.10 H | 1.45x, arms thicker than legs | 28% | stacked blocks | rigid, head sunk |

Art-pipeline 7.2 plans one `short` build (80% height, 108% width) for both dwarf and goblin. Split it:
the dwarf is wider (1.2x), and the goblin is narrower (0.85x) with a bigger head. The two must be
opposite shapes. Weapons are not scaled per build: a goblin with a full-size axe reads well and has
character. [D] Each build is drawn masculine and feminine where the race has both (section 8.7 counts
seven bodies: Standard m and f plus the five others with feminine detail layers). [D]

### 3.2 Per race (front = portrait, back = battle back-3/4)
**Human** (the unmarked baseline)
- Rounded square, round head, small flush ears; skin 0-4; the widest choice of hair.
- From the back, the hair shape is the whole identity. Rule: no protrusions. If a human needs a feature to
  read, the other races are under-designed.

**Elf**
- Standard height, 0.9x shoulders, neck 1 px longer: a tall, narrow vertical.
- Signature: long ears pointing UP and BACK (about 45 degrees), 4-5 px past the skull, so from behind they
  show as two spikes above the hair line. The LPC `ears_elven` part points sideways; redraw it. Hair
  straight, long or tied high.
- Front: narrow chin, cool pale skin. Back: ear spikes, slim waist, upright.
- Vs Goblin: elf ears go UP and are thin. Goblin ears go SIDEWAYS, wide and drooping.

**Fairy**
- Tiny build; the wings double the silhouette's width; never touches the ground (hover bob over a soft
  shadow).
- Signature: wings drawn as 2-3 opaque palette steps (no soft alpha) with dark outlines; tiny pointed
  ears; a 50% head.
- Ranks use `wings_big` [C]. Keep the wings in the back-addon layer so the body still reads in front of
  them.

**Angel**
- Standard body, feathered wings folded HIGH (tops above the head), and a halo.
- From the back: two wing tops frame the head, with a scalloped lower edge; the halo is a 1 px bar 2 px
  above the head. Ranks add wing pairs (wings2, wings3) [C]. Each pair must widen the silhouette, not just
  add pixels.
- Wings go off-white to grey, never pure white (white vanishes in zone 8 [critique]).

**Demon**
- Standard body in triangle language: thin horns curving FORWARD and up (3-4 px each) and a thin tail
  with a spade tip, out to one side. The rank look is `horns_big` [C].
- Skin: red (7), plus new ash-purple and charcoal-red ramps; glowing eyes.
- Vs Dragonkin: demon horns are thin and point forward; dragonkin horns are thick and swept BACK with
  frills. A demon tail is thin with a spade; a dragonkin tail is thick and tapers.

**Dwarf** (must never look like a goblin)
- Short-wide barrel: flat-topped head, chest as wide as it is tall, legs about 25% of the height, feet
  planted wide, upright with the chest out. The SQUARE is the read.
- Signature: a beard mass spilling 2 px past the cheek line on both sides, which shows from behind as
  beard edges beside the neck; plus the width.
- Female dwarves [Q1]: by default, the same build with thick side braids that frame the face (visible
  from the back) and an optional beard in the creator. Never fall back to the human look.
- Skin 1-4 (ruddy human), with a 1-2 px red nose or cheek rule pixel; broad round nose; ears hidden by
  hair.

**Goblin** (must never look like a dwarf)
- Small-thin: a big head on a skinny body, thin limbs, big hands and feet, hunched with the head pushed
  FORWARD and the knees bent. The INVERTED TRIANGLE is the read.
- Signature: huge ears sticking out SIDEWAYS, 4-6 px past the skull on each side and drooping slightly,
  wider than the shoulders. From behind they are two horizontal flags. Portrait: long pointed nose, wide
  grin with 1 px teeth, yellow or red eyes.
- Skin: yellow-green family only (6, plus new ochre-olive and sickly yellow-green ramps). Never tan, never
  orc moss.
- No beard ever. Sparse hair (tufts, a topknot) so the ears dominate.

**Beastkin**
- Standard body (digitigrade legs optional), fur all over [C FUR].
- Signature: animal ears on TOP of the head (vertical triangles, visible from behind), a bushy tail to the
  side, and a muzzle in portraits.

**Dragonkin**
- Standard body, leaning slightly forward, with a thick tail as a counterweight.
- Signature: swept-back horns or frills (the crest choices [C]), a scale band down the spine (back view),
  and a snout.
- Scale hues (ember, teal, bronze, violet) with a lighter belly.

**Undead**
- Standard body 1 px thinner, slumped shoulders, tilted head, torn hems (a ragged clothing outline).
- Signature: light bone pixels on dark (ribs, jaw, knuckles) and sunken glowing eyes (`#a8ca58`
  [C race_eyes]).
- Skin 8 or 9 only (grey-green, lavender-grey); desaturated cloth.
- Vs Goblin: undead green is GREY and desaturated, while goblin lime is saturated. Undead are Standard
  height.

**Orc**
- Large trapezoid: shoulders above the ear line ("no neck"), a small head (32%), arms reaching mid-thigh,
  leaning forward from the hips.
- Signature: lower tusks (2 light px on each side; in back-3/4 a light dot at the jaw corner), a heavy jaw
  and a topknot or mohawk. From behind, the shoulder hump is wider than any race except Golem.
- Skin: a new deep moss ramp (blue-green, at least 2 ramp steps darker than goblin), browns 3-4, war-red 7.

**Golem**
- Block: stacked rectangles, a small sunken head, arms thicker than legs, 1 px seams between the plates.
- Signature: glowing rune lines and eyes (`#7fe9ff` [C]); crystal or moss growths on the shoulders break
  the outline; stone crests only [C GOLEM_HAIR].
- Skin 10 (stone grey) or 11 (sandstone).

### 3.3 What to check from behind
| Race | Head outline | Shoulder line | Back add-on | Colour cue |
|---|---|---|---|---|
| Human | hair only | normal | long hair / cape | - |
| Elf | 2 ear spikes, up-back | narrow | long straight hair | cool pale nape |
| Fairy | big round head | narrow, floating | 2 large wings | wing tint |
| Angel | halo bar | normal | 2 wing tops above the head | off-white feathers |
| Demon | 2 forward horns | normal | spade tail | red skin at nape and hands |
| Dwarf | flat top, beard edges beside the neck | very wide | braids / beard | ruddy |
| Goblin | 2 sideways ear flags | narrow, sloped | - | lime/olive ears |
| Beastkin | 2 top ears | normal | bushy tail | fur |
| Dragonkin | swept horns/frills | normal | thick tail + spine band | scales |
| Undead | tilted head | slumped | torn cloth | grey-green |
| Orc | small head under the hump | widest after Golem | topknot | moss / brown |
| Golem | sunken head | widest | crystals | stone + rune glow |

### 3.4 Forms [C FORMS, art_info forms]
| Form | Change | Read from behind |
|---|---|---|
| Vampire | skin 12, red eyes, fangs; add a high collar | collar points beside the head |
| Werewolf | Large build, wolf head and tail, hunched | bigger than any Beastkin |
| Fallen Angel | bat wings, broken halo, red eyes | jagged wing edge instead of scalloped |
| Lich | skeleton head, crown, skin 13, cyan eyes | crown points + eye glow |

### 3.5 Confusion pairs (test on every sheet)
Goblin/Dwarf, Goblin/Orc, Goblin/Undead, Elf/Human, Elf/Goblin, Demon/Dragonkin, Orc/Golem,
Beastkin/Werewolf, Angel/Fallen Angel, Human/Vampire, Fairy/Angel.

---

## 4. Skin colour families [C art_info skins; D assignments]
| Race | Allowed ramps (`art_info` skins index) | New ramp to add |
|---|---|---|
| Human | 0-4 | - |
| Elf | 0, 1, 5 (pale blue) | moon-grey |
| Fairy | 0, 1, 5, 7 (rose) | lilac |
| Angel | 0, 1, 2, 11 (gold) | - |
| Demon | 7 (red) | ash-purple, charcoal-red |
| Dwarf | 1-4 | - (red nose/cheek rule pixel) |
| Goblin | 6 (lime `#a8ca58` family) | ochre-olive, sickly yellow-green |
| Orc | 3, 4, 7 | deep moss (about `#3e8948` to `#193c3e`, blue-green) |
| Beastkin | FUR ramps | - |
| Dragonkin | scale ramps | - |
| Undead | 8, 9 | - |
| Golem | 10, 11 | - |

Code change for the expert: give every race an explicit `skins` list in `races.gd` (six races currently
fall back to 0-7). Goblin and Orc greens must differ in hue (yellow side vs blue side) AND in value (at
least 2 ramp steps). All new ramps must snap to the 74-colour palette (it already has `#d0da91`,
`#a8ca58`, `#75a743`, `#3e8948`, `#265c42`, `#193c3e`, `#7f9478`, `#566a56`). [C; D]

---

## 5. Portraits (front)
- The face lives here: the nose (goblin long and pointed, dwarf round and broad, orc flat with tusks,
  human straight), brows, beard or braids, eye colour and ears.
- Portraits show gear tier best (helmet crest and gem, collar, pauldrons, trim colour). Put a trim-key
  band on every helmet front and chest collar so the portrait shows rarity.
- Keep the battle sprite's proportions: a goblin portrait still has the huge head and thin neck.

---

## 6. Monster families
### 6.1 Family recipe [S Game Developer; variant sources; D]
- **Shared across a zone:** material ramp, one motif (rings, runes, moss tufts, cracks, barnacles), one
  accent/eye colour, outline weight and light direction.
- **Distinct per monster:** silhouette class, size, posture and one signature feature.
- **Palette swaps only for rank variants** (Elder, Ancient, Primordial [C RANK_PREFIXES]), and always with
  an added part (horns, crown, extra limbs, armour) so the swap is a new shape. Swapping heads to make
  variants is a known cheap trick. [S Underground Monkey page; Zelda sprite project]

### 6.2 Silhouette classes (our `shape` field [C])
humanoid (upright, two arms), brute (wide, heavy top), beast (horizontal, on legs), serpent (S-curve or
coil), spirit (no feet, tapering bottom). In a 7-monster zone, use at least 4 classes. Two monsters of
the same class differ in size by at least 25%, or in posture (upright, crouched, rearing, floating). [D]

### 6.3 Worked example: Mossy Hollows [C zone list; D]
Kobold, Redcap and Hobyah are all small humanoid folk creatures. Unless they are forced apart, they will
collapse into one goblin blob, and into the Goblin hero.
| Monster | Class | Size | Posture / signature |
|---|---|---|---|
| Kobold | humanoid | small | dog-lizard snout (horizontal head), tail, crouched, candle on the head |
| Redcap | humanoid | medium | tall blood-red pointed cap (a vertical spike), iron boots, pike held high |
| Hobyah | beast-like humanoid | medium | long arms, bounding on all fours, ragged mane |
| Boggart | brute | medium | pot belly, sack over the shoulder, wide stance |
| Jack-in-Irons | brute | large | a giant with chains and trophies at the belt; tallest in the zone |
| Will-o'-Wisp | spirit | small | flame with a dark core and a lantern face; fills at least 24x24 |
| Barghest | beast | medium-large | black dog, horizontal, chain collar, glowing eyes |

Zone family: moss green and bark brown ramp, moss-tuft motif, wisp teal as the accent eye colour. No
monster uses the Goblin hero's lime skin.

### 6.4 Zone families (all 10 zones) [C zone lists, realms.gd; D]
| Zone | Material ramp | Motif | Accent | Watch-outs |
|---|---|---|---|---|
| Mossy Hollows | moss green, bark brown | moss tufts, mushrooms | wisp teal | Kobold/Redcap/Hobyah (6.3); no goblin-lime skin |
| Sunken Catacombs | bone, teal-grey (house-style bar) | grave cloth, candles | sickly teal | Ghoul/Strigoi/Bog Body are all humanoid: crouched / tall and caped / slumped. Three spirits: armoured and crowned / streaming hair / hooded with a scythe |
| Flooded Depths | sea blue-green, coral | barnacles, fins, kelp | pale cyan eyes | Kelpie redraw (critique); Umibozu needs rim light |
| Ember Halls | ember, black iron | cracks with core light | molten yellow | flames need dark cores (critique) |
| The Shadow Deep | deep violet, ink | masks, extra eyes | magenta | 3 serpents: Lamia (woman torso), Gorgon (snake-hair coil), Bakunawa (sky dragon) |
| The Hushwood (elf realm) | dead bark, grey moss | hollow eyes, antlers | pale gold | Hollow Sentinel and Mourning Dryad vs the Elf hero (6.5) |
| The Glimmer Court (fairy realm) | deep violet night, jewel tones | moth wings, thorns | jewel pink | critique: deep violet, not lavender; Pixie Swarm fills at least 24x24 |
| The Ironroot Deeps (dwarf realm) | soot, iron, rune cyan | runes, rivets | rune cyan | Cinder Miner (bearded, muscular) vs the Dwarf hero; Ash Raider (orc head [C]) vs the Orc hero; constructs not mecha |
| The Gilded Spire (angel realm) | tarnished gold, dark bronze (critique) | halos, eyes, feathers | dull gold | never bright pastel; white monsters vanish |
| The Cinder Abyss (demon realm) | crimson, ash, obsidian | chains, brands | ember | Imp too small (critique) |

### 6.5 Hostile kin
Realm zones contain monsters built from hero races (Ironroot miners are dwarves, raiders are orcs,
Hushwood wardens are elves, the Treasure Goblin is a goblin). Keep the race BUILD so the lore reads, but
change the colour family and add a corruption mark so a player never takes one for a hero: ash-grey or
soot skin, eyes glowing in the zone accent, and one mutation (crystal growth, bark skin, chains). [D]

### 6.6 Family rules by type
| Family | Shape language | Motif | Palette | Avoid |
|---|---|---|---|---|
| Beasts | horizontal masses, low heads, jagged fur edges | scars, fur clumps, extra horns/eyes | earth + one eye colour | realistic animals; make them mythic |
| Undead | vertical, thin, sagging, ragged edges | exposed bone, grave cloth, teal glow | bone/teal-grey (zone 1 bar) | grey mush; keep 3 value steps |
| Demons | triangles, horns, spikes, wide stance | brands, cracks with ember light | ember/black, crimson | pastel, white |
| Constructs | rectangles, symmetry, visible joints | rivets, runes, seams | stone/bronze + rune glow | mecha/sci-fi (critique: Forge Sentry, Stoneguard) |
| Fae | circles + thin lines, asymmetry, floating | leaves, petals, moth-wing eyes | moss + one jewel tone | tiny wisps (fill at least 24x24) |
| Dragons/serpents | S-curves, triangle wings | scale bands, frills, light belly | scale ramp | bodies under 3 px thick |
| Spirits | no feet, tapering, glowing core | wisps, chains, veils | dark core, light rim | soft alpha (use FX_ALPHA steps) |

---

## 7. Gear visuals: how other games do it [S]
| Game | Method | Lesson for us |
|---|---|---|
| Diablo II | Body split into components (head, torso, legs, arms, hands, shield, shoulders); each has 3 graphics (light, medium, heavy), and each armour picks one per component | Many items, few drawn tiers |
| Diablo III | Base armour looks change by level band (16 tiers + 2); legendaries have unique art; transmog unlocks looks | Item level drives the look; specials get their own art |
| Shattered Pixel Dungeon | Whole hero sprite swapped by armour tier 0-6 (`Hero.tier()`, 6 = class armour); the weapon is not shown | At tiny sizes, one sprite row per tier is enough |
| Stardew Valley | 16x32 farmer; layers base, pants, shirt, accessories, hair, hat, arms; palette-key recolour; some hats remap the hairstyle | Layer order; remap hair under hats |
| Daggerfall | Paper doll with 8 variants per item (4 races x 2 sexes); per-item draw order; cloaks split into an interior (behind the body) and exterior; a mask hides hair under helmets | Body variants multiply art; split capes; hair masks |
| Soulbound (pixel MMO) | Layered head/chest/legs/back/weapon; the weapon type changes the chest animation; frame counts locked early | Lock the rig before drawing gear |
| Final Fantasy Tactics | 16-colour palettes; factions by palette | Palette = cheap identity |
| Heroes of the Storm | Skin rarity: Rare = simple recolour, Epic = advanced recolour, sometimes a small outfit change, Legendary = a complete outfit change | A higher tier means a bigger SHAPE change |
| Moonlighter | Upgraded armour takes "a different aesthetic associated with the dungeon" and a new icon | Zone theme as the material |
| RuneScape | Loot beams in 4 tiers, each larger and more complex | Effect size scales with value |
| Diablo / Terraria / Borderlands 2 | Rarity colour on names; Borderlands adds colour-blind palettes and rarity text | Never colour alone |
| Pixel weapon guide | 45 degrees up-right; axes and hammers vertical; at 32 px a blade is 4-5 px; starter vs legendary must differ "in silhouette alone, with the palette turned off"; one accent | Ornate = a new silhouette |

---

## 8. Recommended gear-visual system for Solaria [D]
### 8.1 Which slots change the sprite
| Slot | Battle (back-3/4) | Portrait (front) | Drawn variants |
|---|---|---|---|
| Weapon | own `weapon_arm` layer on the near (screen-right) side, always visible; type = silhouette | in hand / over the shoulder | 7 types x 2 shapes (base, ornate) + fine overlay + emissive mask |
| Off Hand | far (screen-left) arm. Shield: we see its back, straps and RIM. Orb floats beside the off hand. Tome floats open or hangs at the hip | yes | 5 types x 2 shapes + overlays |
| Helmet | head outline (the biggest change from behind) | biggest | 4 types x 2 shapes x 3 head-size classes |
| Chest | torso silhouette (tunic / plate / robe) + shoulders | yes | 3 types x 2 shapes x 7 bodies |
| Legs | material recolour of the lower body; silhouette only for robe skirt and greaves | small | recolour |
| Feet | material recolour (2-3 px) | - | recolour |

Legs and feet are 4-6 px tall at battle size. Drawing their shapes costs as much as a chest and nobody
would see it. Their material colour still changes, so upgrades still show.

### 8.2 Four visual tiers
| Tier | Rarities [C RARITY_NAMES] | Shape | Colour | Effect (code) |
|---|---|---|---|---|
| Plain | Common, Uncommon | base shape | zone material; trim grey (Common) or green (Uncommon) on 1 band | none |
| Fine | Rare, Epic | base + detail overlay: rim, rivets, pauldron edge, blade fuller, shield boss | Rare: trim on 1 band. Epic: 2 bands + one 2x2 gem pixel | none |
| Ornate | Legendary, Unique, Set, Signature | NEW silhouette: crest or plume, larger pauldrons, flared blade, winged axe, spiked rim, tabard tail | uniques, sets and signatures keep their own palettes [C UNIQUE_STYLES, SET_STYLES, sigs] | 1 px rim glow, slow pulse |
| Mythic | Mythic, Unique Mythic | Ornate shape + emissive pixels (runes, cracks, eyes) | own palette + emissive key | glow + a few particles; Unique Mythic adds a ground sigil |

**Why four.** D2 (3 graphics per component) and SPD (7 for the whole body) show that players read a
handful of looks. HotS shows each step up must change shape, not just colour. RuneScape scales effect
size with value. Ten distinct looks per item would be invisible at 40 px. [S; D]

**Why Rare and Epic need the band/gem step.** Simulating Machado (2009) colour-vision deficiency on our
`RARITY_COLORS`, Rare `#60a5fa` and Epic `#c084fc` are nearly identical for deuteranopes (OKLab distance
0.013; the next closest pair is 0.060) and close for protanopes (0.051). The other close pairs
(Uncommon/Legendary, Set/Signature, Common/Signature) sit in different tiers, so shape already separates
them. [M]

### 8.3 Where colour goes
- **Material** (yellow key [C]) comes from the item's zone of origin (`item.floor`, stored by `make_item`
  [C]). Example ramps: Mossy Hollows bronze/leather, Catacombs bone/iron, Flooded Depths sea/coral, Ember
  Halls ember/dark, Shadow Deep dark/scale; realm zones their own. Today the material is fixed per type
  (`TYPE_MATERIAL`) [C]. [Q4]
- **Trim** (magenta key [C]) is the rarity colour [C RARITY_COLORS], placed where the back view sees it:
  the helmet's back band and crest, pauldron tops, belt, blade edge, axe rim, shield rim, staff head. Add
  a front collar band for portraits. Never put it only on the chest front.
- **Emissive** (a new key, e.g. pure cyan (0,255,255)) marks Mythic rune and crack pixels, drawn at full
  brightness and pulsed by code.

### 8.4 Glow and particles (code, as in the critique's "code adds glow")
- **Ornate:** a 1 px outline per layer in the trim colour, stepping alpha 64 to 128 to 64 over about
  1.5 s, only around that item's pixels, never the whole hero. Build it from the layer alpha at cache time
  (as `_silhouette` does). No shader is needed, which fits the art_style rule (offline, no shaders). [C; D]
- **Mythic:** Ornate glow plus 3-6 particles (2x2 art px motes or embers in 2-3 palette steps at FX_ALPHA
  alphas) rising from the item, and the emissive pixels pulse. Only the highest-tier item on a hero emits
  particles, so a full Mythic kit does not turn into noise.
- **Unique Mythic:** adds a hard-edged rune ring on the floor under the feet. It is visible from the back
  camera and never covers the sprite.
- Every glow keeps a dark core (critique rule).

### 8.5 Capes and auras are already used for class prestige
`hero_looks()` [C game_state] gives unique classes a cape (class colour, rank-coloured trim) and God-rank
classes a golden whole-hero aura. So gear effects stay ITEM-LOCAL, and the Unique Mythic floor ring must
look nothing like the God aura (a hard rune ring on the floor vs a soft gold body halo). The cape is the
largest surface in the back view, so keep the rank trim on its edge. Split capes into an inner part
(behind the body) and an outer part, as Daggerfall does.

### 8.6 Weapon and off-hand silhouettes (lines at least 2 px, with a highlight on the lit edge [critique])
| Type | Base silhouette | Ornate change | Rest pose (back-3/4) |
|---|---|---|---|
| sword | straight blade 3-4 px wide, crossguard 5-7 px | flared or wavy blade, winged guard, gem pommel | diagonal up-right |
| axe | haft + one-sided head mass at the top | double or winged head, spike | vertical, heavy end up |
| mace | short haft + round or flanged head | spiked head, crown flanges | vertical |
| spear | the longest weapon (taller than the hero), thin point | leaf or trident head, banner ribbon | diagonal, past the head |
| bow | thin vertical curve in the far hand | recurve tips, horn or antler limbs | vertical, on the off side |
| staff | tall shaft with a head ornament | crook or branch head with a floating gem | vertical, top above the head |
| dagger | short blade, often in reverse grip | curved or serrated; a second dagger shows | low at the hip |
| shield | heater shape; from behind, straps + rim | spiked or winged rim, boss | far arm, rim visible |
| buckler | small and round | spiked boss | far fist |
| tower | tall rectangle that hides the far side | crenellated top | far side, touching the ground |
| orb | 6-8 px sphere at the far hand, light core | orbiting ring or shards | hovering, bobs 1 px |
| tome | book open beside the far hand, light pages | chain + clasp, floating glyph | hovering |

Pivot and size data are already in `art_info.gd weapons/offhands` [C]. Orb and tome need new parts that
do not come from LPC.

### 8.7 Helmets and race fit
- Head-size classes: small (Goblin, Fairy, Orc's small head), standard, large (Golem, Werewolf). That is
  3 drawings per helmet shape, not 12.
- Signature parts draw ABOVE helmets: elf, goblin and beastkin ears, demon and dragonkin horns, the
  dwarf beard, the halo. Each helmet has a notch mask (pixels removed where ears or horns pass). Hair is
  still hidden or remapped for `helm`/`hood` (`hides_hair` [C], the Stardew remap, the Daggerfall mask).
- A hood on a goblin: the ears poke out through slits (a strong, funny read). A crown on a dwarf sits on
  the hair.

### 8.8 Per-build anchors
Every body build gets a small anchor file (an extension of `rig_<build>_<view>.json`, art-pipeline 7.5):
`hand`, `off_hand` (today one pair for every body: `hand [41,47]`, `off_hand [24,46]` [C]), `head_top`,
`ear_l`/`ear_r`, `shoulder_l`/`shoulder_r`, `back`, `belt` and `foot_row`. Weapons, off-hands, helmets
and Ornate add-ons attach to anchors, so one weapon drawing fits all seven bodies.

### 8.9 Asset count (one view; double it for back-3/4 + front)
- Weapons: 7 x 2 shapes + 7 fine overlays + 7 emissive masks = 28 (independent of build).
- Off-hands: 5 x 2 + 5 + 5 = 20.
- Helmets: 4 x 2 x 3 head classes = 24 (fine and emissive overlays are small add-ons).
- Chests: 3 types x 2 shapes x 7 bodies (Standard m/f, Short-wide, Small-thin, Large, Block, Tiny) = 42.
- Legs/Feet: recolour of the lower body; robe-skirt and greaves silhouettes per body = 14.
- Total: about 130 per view, about 260 for both. The puppet rig then animates them (art-pipeline 7.5).
- To cut work, make the Ornate chest parts **socket add-ons** (pauldrons, crest, tabard) attached at
  anchors and drawn once per size class instead of per body. That brings chests down to 21 base drawings
  plus about 12 add-ons.

### 8.10 Transmog
`wardrobe.gd` shows the look of another found item while stats come from the real one [C]. Default [Q2]:
the look (shape tier, palette, glow) follows the transmog source, but Mythic particles appear only if the
real item is Mythic, so particles keep meaning power.

---

## 9. Pipeline fit (AI + code)
- **Bodies per build:** SDXL G3 on new mannequins per build (art-pipeline 7.2). The guide image carries
  the build. Prompts alone will not make SDXL draw a 1.2x dwarf, so paint the section 3.1 proportions into
  the guide (art-pipeline 4.2 rule).
- **Prompt words per race** (head and body only; style words come from art-pipeline 5.2):

| Race | Add | Negative |
|---|---|---|
| Goblin | goblin, huge pointed ears sticking out sideways, long pointed nose, big head, skinny limbs, hunched, yellow-green skin, sharp grin | beard, stocky, broad shoulders, human proportions |
| Dwarf | dwarf, very wide stocky body, broad shoulders, short legs, big thick beard (or side braids), ruddy skin, round nose | pointed ears, green skin, thin, hunched |
| Orc | orc, huge shoulders, no neck, small head, lower tusks, heavy jaw, moss green skin, long arms | lime skin, big ears, skinny |
| Elf | elf, long ears pointing up and back, slender, long straight hair, pale skin | big nose, sideways ears, stocky |
| Golem | living stone golem, blocky stone plates, glowing runes, small sunken head | hair, skin, cloth |
| Undead | undead, gaunt, grey-green skin, exposed bone, glowing sunken eyes, torn clothes | healthy skin, bright colours |

- **Rule pixels** (art-pipeline 4.2 item 5) per race, added after palette mapping: goblin ear tips and
  teeth, orc tusks, dwarf nose/cheek, elf ear tips, eye glints.
- **Outfits:** generated on the bald body of each build in grey values, cut to layers, then ramp-snapped
  to the key colours (material = yellow, trim = magenta) [C keys; art-pipeline 6.2]. If the AI does not
  place trim well, paint the trim pixels in code from a rule (e.g. "top 1 px band of the pauldrons", "rim
  of the shield").
- **Weapons and off-hands:** one sheet per type at density, diagonal or vertical as in 8.6, cleaned,
  key-snapped.
- **Runtime:** CPU recolour + cache, as today (`Lpc._recolor`, `Sprites._recolor`) [C]. If that ever gets
  slow, the common Godot alternative is a palette-lookup shader (e.g. KoBeWi's MIT palette addon, or a
  red/green-indexed lookup). [S GodotShaders, Godot asset library]

---

## 10. Readability checklist
Run at 1x (and 3x for detail) on the real battle background, next to the 3 anchor monsters.
1. **Blackout line-up:** all 12 races + 4 forms filled with `#0e0812`, back-3/4, in one row. A tester
   names each. Pass: at least 11/12 right, and no confusion pair (3.5) mixed up.
2. **Squint/blur:** blur about 1.5 art px, or view at 25%. Pass: build and head shape still separate
   Goblin, Dwarf, Orc and Human.
3. **Side-by-side pairs:** every confusion pair in the same pose and gear. Pass: they differ in silhouette
   with colour off.
4. **Helmet stress test:** every race in `helm` and in `hood`. Pass: the race still reads.
5. **Silhouette fill:** monsters fill at least 24x24 of 32x32; heroes fill their build box; nothing under
   2 px wide except deliberate 1 px rule pixels.
6. **Value check:** greyscale. Pass: skin, cloth, metal and hair have different values (art-pipeline 4.2).
7. **Zone line-up:** all monsters of a zone in one row. Pass: same family at a glance; no two share class
   + size; none uses a hero race's skin family (6.5).
8. **Gear tier ladder:** one hero with sword + helm + plate in Plain, Fine (Rare and Epic), Ornate and
   Mythic. Pass: each step is visible at 1x in greyscale (shape) and in a deuteranopia simulation.
9. **Weapon line-up:** 7 weapons + 5 off-hands in silhouette. Pass: every type gets named.
10. **Portrait line-up:** 12 race portraits at 64 px. Pass: nose, ears, beard and tusks readable.
11. **Animation check:** signature parts stay attached through slash, thrust and cast (no popping ears).
12. **Scale check:** the hero never reads smaller than a standard 32x32 monster beside it.

---

## 11. Open questions for Juzo (defaults in use)
- Q1 Female dwarves: side braids by default + an optional beard (default) / always bearded / never.
- Q2 Transmog and effects: the look follows the source; particles only from real Mythics (default).
- Q3 Goblin weapon scale: full-size weapons (default) or scaled down.
- Q4 Gear material by zone of origin (default) or fixed per type (today).
- Q5 Fine tier: OK that Rare and Epic share a shape and differ by trim bands + gem (default yes)?

---

## 12. Sources
Silhouette, proportions, small sprites
- Smogon, "The Evolution of Pokemon Art over the Years": https://www.smogon.com/articles/pokemon-art-through-ages
- Game Developer, "Evolution Of Pokemon Designs - Generation 3": https://www.gamedeveloper.com/design/evolution-of-pokemon-designs-generation-3
- sprite-ai, pixel art anime / chibi guide: https://www.sprite-ai.art/gallery/anime
- sprite-ai, 16x16 guide: https://www.sprite-ai.art/guides/how-to-create-16x16-pixel-art
- sprite-ai, pixel art weapons: https://www.sprite-ai.art/gallery/weapons
- Wayline, Pixel Art for Games lesson 5: https://www.wayline.io/learn/pixel-art/4
- bugnet, how to make pixel art that reads clearly: https://bugnet.io/blog/how-to-make-pixel-art-that-reads-clearly
- GameBanshee, Middle-earth Online developer diary (dwarves "built like fireplugs"): https://www.gamebanshee.com/kp399
- Polycount goblin critique (403 when fetched; used via search summary): https://polycount.com/discussion/191016/goblin
- Samwise Didier / Warcraft style: https://archania.org/p/individuals/game-developers/samwise-didier
- Shape language: https://rocketbrush.com/blog/shape-language-in-game-character-design-how-to-make-characters-readable-and-consistent ; https://3dsense.net/blogs/shape-language-in-character-design-communicating-through-geometry
- Back-view / blackout test (blog, rule of thumb): https://www.hitem3d.ai/blog/Game-Character-Design-Principles-Process-and-Tips-for-2026
- Back sprite sizes (community, low confidence): https://www.pokecommunity.com/goto/post?id=5032024 ; https://bulbapedia.bulbagarden.net/wiki/Pokémon_sprite
- Dwarf proportions (forum): https://polycount.com/discussion/comment/1307857/

Monster families and variants
- Underground Monkey (variants by feature/element/size): https://tropedia.fandom.com/wiki/Underground_Monkey
- Solarus forum, recoloured LttP enemies / head swaps: https://forum.solarus-games.org/en/index.php/topic,904.0.html
- Slime (Dragon Quest) family: https://en.wikipedia.org/wiki/Slime_(Dragon_Quest)

Gear visuals
- Diablo II component versions LIT/MED/HVY: https://m.cafe.daum.net/rpgguild/ISk/30 ; https://d2runewizard.com/game-files/guide.html ; https://bnetdocs.org/document/18/chat-statstrings
- Diablo III gear sets / looks by tier: https://diablowiki.net/Gear_set ; transmog: https://di.diablowiki.net/Transmog
- Shattered Pixel Dungeon source (HeroSprite, Hero.tier()): https://github.com/00-Evan/shattered-pixel-dungeon
- Stardew Valley farmer sprite layers: https://wiki.stardewvalley.net/Modding:Farmer_sprite
- Daggerfall Workshop, Items Part 3 - Paper Doll: https://www.dfworkshop.net/items-part-3-paper-doll/
- Soulbound, pixel art character and cosmetic system: https://soulbound.game/news/how-we-built-a-pixel-art-character-and-cosmetic-system/
- Chains on Sand modular paper dolls: https://tabulagames.itch.io/chains-on-sand/devlog/931183/devlog-5-visuals-overhaul-modular-paperdolls
- FFT palettes: https://automaton-media.com/en/news/final-fantasy-tactics-the-ivalice-chronicles-alternative-character-color-schemes-were-only-possible-due-to-a-clever-workaround-from-the-original-games-graphic-system/
- Heroes of the Storm rarity (skins by tier): https://heroesofthestorm.fandom.com/wiki/Rarity
- Moonlighter More Stock update (dungeon-themed armour looks): https://www.dualshockers.com/moonlighter-more-stock-update-pc-ps4-xb1/
- RuneScape loot beam tiers: https://runescape.wiki/w/Loot_beam
- Colour-coded loot history: https://en.wikipedia.org/wiki/Loot_(video_games)
- Accessibility, distinguishing this from that: https://accessible.games/accessible-player-experiences/access-patterns/distinguish-this-from-that/
- Borderlands 2 colour-blind mode: https://www.co-optimus.com/article/11338/borderlands-2-to-receive-colorblind-mode.html
- Godot palette swapping: https://godotshaders.com/shader/palette-swap-no-recolor-recolor/ ; https://godotshaders.com/shader/advanced-palette-godot-4/

Colour-vision simulation: Machado, Oliveira and Fernandes (2009) severity-1.0 matrices, applied to linear
RGB and compared in OKLab (script in the research scratchpad; easy to redo in the art audit tool).

---

## Round log
- R1: Read the workflow, critique, pipeline and races/lpc/sprites/art_info/item_pool. Found the root cause
  in code (shared body, overlapping skins, beardless female dwarf). Searched silhouettes, paper dolls, D2,
  SPD, Stardew, rarity colour.
- R2: Checked SPD tiers in source (0-6), the Stardew layer order on the wiki mirror, D2 light/medium/heavy
  via modding posts; added HotS skin tiers and colour-blind redundancy. Wrote v1.
- R3: Checked R2. The MEO "fireplugs" quote is confirmed. The Toriyama "one distinctive feature" quote was
  NOT found, so it was dropped. The Polycount goblin page returns 403, so it is cited via the search
  summary. Added Godot palette options, the weapon-silhouette guide and back-sprite notes.
- R4: Read the zone monster lists; added the Mossy Hollows worked example (Kobold/Redcap/Hobyah collision);
  D3 level-band looks; items store `floor`, which enables zone material; found the wardrobe transmog.
- R5: Confirmed Daggerfall (8 variants, cloak split, hair mask), RuneScape's 4 beam tiers and the weapon
  guide quotes. Full rewrite (v2).
- R6: Confirmed the Moonlighter quote and HotS tiers (second source); listed LPC head/ear parts. Simulated
  colour-blindness on RARITY_COLORS: Rare/Epic collide for deuteranopes, so added the band/gem rule.
- R7: Added zone families for all 10 zones (realm mapping checked in realms.gd), the hostile-kin rule,
  per-build anchors, and the capes/auras conflict found in `hero_looks()`.
- R8: Checked R7. Ash Raider is an orc head, not a dwarf, so it was corrected. Re-checked the Machado
  matrices. Confirmed the Smogon and sprite-ai quotes.
- R9: Added prompt words per race, rule pixels, the scale check and the back-sprite size note (low
  confidence).
- R10: Full rewrite. Merged all edits, added Q5 and the source list, cut duplicated text.

## Juzo's answers (Oct 23 2026)
- Q1 Female dwarves: NO beard (braids; still short and wide so they read as dwarves).
- Q2 Glow/particles only on real Mythic gear: yes.
- Q3 Goblin weapons: not answered, default full-size.
- Q4 Gear colour does NOT follow the zone: colour comes from RARITY only.
- Q5 Rare and Epic share a shape, differ by trim bands + gem: yes.
