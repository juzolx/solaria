# Monster, boss, Calamity and pet art

Dungeon Crawl Stone Soup 32x32 tiles, CC0 (https://opengameart.org/content/dungeon-crawl-32x32-tiles), by the DCSS artists (https://github.com/crawl/tiles/blob/master/ARTISTS.md).
Built by tools/dcss_monsters.py: baked shadows removed, some recolored, rim light, 2x upscale, dark outline.

2.1: tools/bake_art.gd mapped these files to the Solaria palette (art_style.gd, art/palette.gpl), made every pixel solid and gave them one dark outline one art pixel wide, on one 2x grid (68x68 files). The originals are in git history.

## art/pets/32 (Pets 2, Oct 24 2026)
Baby pet art, region eggs and class companions: generated with PixelLab (pixellab.ai, Juzo's subscription) on the Solaria palette (art/palette.gpl), picked and given hard alpha and a 2-frame idle by claude/pets2/tools/export.gd. True size 32x32; `<key>.png` still + `<key>_idle.png` strip. Keys: pet species ids (claude/stable-ids.md), `calamity_N_pet`, `<class>_<stage>`, `egg_<region id>`. Prompts and picks: claude/pets2/ (spec.tsv, picks.txt).
