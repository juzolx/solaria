# First-person room textures

z0-z9 walls, floors, ceilings, doors and torches, and z1 chest, altar and statue: made for Solaria with PixelLab (pixellab.ai, Juzo's subscription), then snapped to art/palette.gpl with hard alpha.

portal.png (the champion's gate that replaces the middle door) was made the same way.

door.png was drawn for Solaria (CC0). It is the fallback for zones without their own door.

Fable dungeon round 1 edits (original to Solaria, CC0):
- every door and portal.png sit on one 32x56 canvas (middle rows repeated, narrow doors centred); portal_1.png is portal.png one step brighter on the violet ramp (the gate's flicker frame).
- z1_wall.png and z7_wall.png are 64x64: the original tile in one quarter, plain variants (skulls, pipes painted out) in the other three, so the pattern doesn't repeat every 2 units.
- z5_wall.png was recoloured to the Hushwood greens; z9_floor.png is z3_floor recoloured to hellstone.
- rift_0..2, z0_root, z3_crack, z4_eye, z5_wisp, z6_crystal and z9_spikes were drawn in code by tools/draw_hall_bits.py.

Fable dungeon round 2 (original to Solaria, CC0, all by tools/draw_hall_bits.py):
- z5_floor.png redrawn as leaf-littered flagstones (the PixelLab tile had only 2 colours).
- z5_wall.png and z6_floor.png got a top light and bottom shade on their main stone (5+ colours).
- z2_pool_0/1.png (the Flooded Vaults pool, two frames), z7_pipe.png (brass pipe) and z8_pillar.png (gilded pillar).
