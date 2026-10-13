"""Hero body templates (32x32, facing right, standing in a fighting stance).

Region letters (the game recolors these):
  o outline        s skin         d skin shadow     e eye (iris)  w eye white
  m mouth          t shirt        T shirt shadow    l pants       L pants shadow
  f shoe           F shoe shadow  b belt
Hand positions (used to place weapons and off-hands):
  WEAPON_HAND = (24, 19)  front hand
  OFF_HAND    = (8, 20)   back hand
"""

WEAPON_HAND = (24, 19)
OFF_HAND = (8, 20)

MASC = [
    "................................",  # 0
    "................................",  # 1
    "................................",  # 2
    "............oooooo..............",  # 3
    "..........oossssssoo............",  # 4
    ".........osssssssssso...........",  # 5
    ".........osssssssssso...........",  # 6
    ".........odsssssswesso..........",  # 7
    ".........odsssssswesso..........",  # 8
    ".........oddssssssssso..........",  # 9
    "..........oddssssssmo...........",  # 10
    "...........oddsssssoo...........",  # 11
    "............oodddoo.............",  # 12
    "...........ootdddtoo............",  # 13
    ".........ootttttttttoo..........",  # 14
    "........oTtttttttttttto.........",  # 15
    "........oTTttttttttttsso........",  # 16
    "........osTttttttttttdsso.......",  # 17
    "........osTTtttttttttoddsso.....",  # 18
    "........ossTTtttttttto.oossso...",  # 19
    ".........oobbbbbbbbbbo...oooo...",  # 20
    "..........oLlllllllllo..........",  # 21
    "..........oLLlllollllo..........",  # 22
    "..........oLLllo.oLlllo.........",  # 23
    "..........oLLlo...oLlllo........",  # 24
    "..........oLLlo....oLllo........",  # 25
    ".........oLLlo.....oLllo........",  # 26
    ".........oLLlo......oLllo.......",  # 27
    ".........oLllo......oLllo.......",  # 28
    "........oFfffo......oFffffo.....",  # 29
    "........oFffffo.....oFfffffo....",  # 30
    "........ooooooo.....oooooooo....",  # 31
]

FEM = [
    "................................",  # 0
    "................................",  # 1
    "................................",  # 2
    "............oooooo..............",  # 3
    "..........oossssssoo............",  # 4
    ".........osssssssssso...........",  # 5
    ".........osssssssssso...........",  # 6
    ".........odssssssweso...........",  # 7
    ".........odsssssswesso..........",  # 8
    ".........oddssssssssso..........",  # 9
    "..........oddsssssmso...........",  # 10
    "...........oodsssssoo...........",  # 11
    "............oodddoo.............",  # 12
    "............otdddto.............",  # 13
    "..........ootttttttoo...........",  # 14
    ".........oTttttttttttoo.........",  # 15
    ".........oTTtttttttttsso........",  # 16
    ".........osTTtttttttodsso.......",  # 17
    ".........osTTttttttto.odsso.....",  # 18
    ".........ossTtttttto...oossso...",  # 19
    "..........oobbbbbbbbo....oooo...",  # 20
    ".........oLllllllllllo..........",  # 21
    ".........oLLlllllollllo.........",  # 22
    ".........oLLllllo.oLlllo........",  # 23
    "..........oLLllo...oLlllo.......",  # 24
    "..........oLLlo.....oLllo.......",  # 25
    "..........oLLlo.....oLllo.......",  # 26
    "..........oLlo.......oLlo.......",  # 27
    "..........oLlo.......oLlo.......",  # 28
    ".........oFffo.......oFffo......",  # 29
    ".........oFfffo......oFfffo.....",  # 30
    ".........oooooo......oooooo.....",  # 31
]
