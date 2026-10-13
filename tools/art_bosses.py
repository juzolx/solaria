"""Boss sprites (48x48), facing left. Same letters and rules as art_monsters.py."""
from art_enemies import add

# Hel: queen of the dead. Half her face alive, half a bare skull. Iron crown,
# black hair, a ghostly gown, and a staff topped with a skull.
add("boss_hel", {"s": "#f2dcc8", "d": "#b8c4d8", "h": "#262b44", "u": "#8b9bb4", "c": "#3a2a52", "v": "#7fe0ff", "x": "#5d3a2c"}, [
    #         1111111111222222222233333333334444444444
    # 012345678901234567890123456789012345678901234567
    "................................................",  # 0
    "................................................",  # 1
    "................................................",  # 2
    "................................................",  # 3
    "...............u..u..u..u.......................",  # 4
    "...............uu.uu.uu.uu......................",  # 5
    "...............uuuuuuuuuuu......................",  # 6
    "..............hhhhhhhhhhhhh.....................",  # 7
    ".............hhhhhhhhhhhhhhh....................",  # 8
    "............hhhssssssdddddhhh...................",  # 9
    "............hhssssssddddddhhhH..................",  # 10
    "....dd......hsskbsssdkbdddhhhH..................",  # 11
    "...dddd.....hssssssddddddddhhHH.................",  # 12
    "...dkkd.....hsssssddddddddhhhHH.................",  # 13
    "...dddd.....hhssrrdoododddhhhHH.................",  # 14
    "....dd......hhhsssddddddhhhhhHHH................",  # 15
    "....xx.....hhhhhhsssdddhhhhhhHHH................",  # 16
    "....xx....hhhhhhcccccccchhhhhhHHH...............",  # 17
    "....xx...hhhhhccccvvvvccccchhhhHHH..............",  # 18
    "....xx..hhhhcccccccvvccccccchhhHHHH.............",  # 19
    "....xxsssccccccccccvvcccccccchhhHHHH............",  # 20
    "....xxsssccccccccccvvccccccccchhHHHH............",  # 21
    "....xx...cccccccccccccccccccccchHHHH............",  # 22
    "....xx...cccccccccccccccccccccdddHHH............",  # 23
    "....xx...ccccccccccccccccccccddkddHH............",  # 24
    "....xx..ccccccccccccccccccccccdddd..............",  # 25
    "....xx..vvvvvvvvvvvvvvvvvvvvvvvvC...............",  # 26
    "....xx..cccccccccccccccccccccccCC...............",  # 27
    "....xx..ccccccccccccccccccccccCCC...............",  # 28
    "....xx..cccccccccccccccccccccCCCC...............",  # 29
    "....xx.cccccccccccccccccccccCCCCC...............",  # 30
    "....xx.ccccccccccccccccccccCCCCCC...............",  # 31
    "....xx.cccccccccccccccccccCCCCCCC...............",  # 32
    "....xx.ccccccccccccccccccCCCCCCCC...............",  # 33
    "....xxcccccccccccccccccCCCCCCCCCC...............",  # 34
    "....xxccccccccccccccccCCCCCCCCCCC...............",  # 35
    "....xxcccccccccccccccCCCCCCCCCCCCC..............",  # 36
    "....xcccccccccccccccCCCCCCCCCCCCCC..............",  # 37
    "....ccccccccccccccCCCCCCCCCCCCCCCCC.............",  # 38
    "...ccccccccccccccCCCCCCCCCCCCCCCCCC.............",  # 39
    "...vcvvcvvcvvcvvcvvCvvCvvCvvCvvCvvC.............",  # 40
    "...v..v..v..v..v..v..v..v..v..v..v..............",  # 41
    "................................................",  # 42
    "................................................",  # 43
    "................................................",  # 44
    "................................................",  # 45
    "................................................",  # 46
    "................................................",  # 47
])

# Charybdis: the sea-swallowing maw. A great round mouth of teeth spinning in a whirlpool.
add("boss_charybdis", {"a": "#2e7896", "t": "#e8e4d8", "m": "#68386c", "v": "#4fb0c6", "c": "#a4dddb"}, [
    "................................................",  # 0
    "................................................",  # 1
    "................................................",  # 2
    "................................................",  # 3
    "................................................",  # 4
    "...............aaaaaaaaaaaaaaa..................",  # 5
    ".............aaaaaaaaaaaaaaaaaaa................",  # 6
    "...........aaaaaaaaaaaaaaaaaaaaaaa..............",  # 7
    "..........aaayyaaaaaaaaaaaaaaayyaaaA............",  # 8
    ".........aaayrkaaaaaaaaaaaaaaayrkaaAA...........",  # 9
    "........aaaaaaaaaaaaaaaaaaaaaaaaaaaAAA..........",  # 10
    "........aaaaaatttttttttttttttttaaaaAAA..........",  # 11
    ".......aaaaattmmmmmmmmmmmmmmmmmttaaaAAA.........",  # 12
    ".......aaaattmmtmmtmmtmmtmmtmmmmttaaAAA.........",  # 13
    ".......aaaatmmmmmmmmmmmmmmmmmmmmmtaaAAA.........",  # 14
    ".......aaatmmmtkkkkkkkkkkkkkkkmmmmtaAAA.........",  # 15
    ".......aaatmmkkkkkkkkkkkkkkkkkkkmmtaAAA.........",  # 16
    ".......aaatmmkkkkkkvvvvvvkkkkkkkmmtaAAA.........",  # 17
    ".......aaatmtkkkkkvvkkkkvvkkkkkktmtaAAA.........",  # 18
    ".......aaatmmkkkkvvkkcckkvvkkkkkmmtaAAA.........",  # 19
    ".......aaatmmkkkkvkkcckkkkvkkkkkmmtaAAA.........",  # 20
    ".......aaatmtkkkkvvkkkkkkvvkkkkktmtaAAA.........",  # 21
    ".......aaatmmkkkkkvvvvvvvvkkkkkkmmtaAAA.........",  # 22
    ".......aaatmmkkkkkkkkkkkkkkkkkkkmmtaAAA.........",  # 23
    ".......aaaatmmmtkkkkkkkkkkkkkkkmmmtaAAA.........",  # 24
    ".......aaaatmmmmmmmmmmmmmmmmmmmmmtaaAAA.........",  # 25
    "........aaaattmmtmmtmmtmmtmmtmmttaaAAA..........",  # 26
    "........aaaaattttttttttttttttttaaaaAAA..........",  # 27
    ".........aaaaaaaaaaaaaaaaaaaaaaaaaAAA...........",  # 28
    "..........AAaaaaaaaaaaaaaaaaaaaaAAAA............",  # 29
    "...aa.......AAAaaaaaaaaaaaaaAAAAA........aa.....",  # 30
    "..aaaa........AAAAAAAAAAAAAAAA..........aaaa....",  # 31
    "..aaaaa...............................aaaaa.....",  # 32
    "...aaaaa............................aaaaa.......",  # 33
    ".....aaaaa.......................aaaaaa.........",  # 34
    ".......aaaaaa.................aaaaaa............",  # 35
    "..vvv....aaaaaaaa.........aaaaaaa......vvv......",  # 36
    ".vvvvvv.....aaaaaaaaaaaaaaaaaa......vvvvvvv.....",  # 37
    "vvvcvvvvvvv.......aaaaaa........vvvvvvcvvvvv....",  # 38
    "vvvvvvvcvvvvvvvvvvvvvvvvvvvvvvvvvvcvvvvvvvvvvv..",  # 39
    "vvcvvvvvvvvvcvvvvvvvcvvvvvvvcvvvvvvvvvvvcvvvvvv.",  # 40
    "VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",  # 41
    "................................................",  # 42
    "................................................",  # 43
    "................................................",  # 44
    "................................................",  # 45
    "................................................",  # 46
    "................................................",  # 47
])

# Surtr: the fire giant of Muspelheim, horned, molten-skinned, with a burning sword.
add("boss_surtr", {"s": "#a8342a", "f": "#feae34", "q": "#fee761", "a": "#3a3046", "m": "#262b44", "h": "#5a3f35"}, [
    "................................................",  # 0
    "................................................",  # 1
    "................................................",  # 2
    "...........f.....f.....f........................",  # 3
    "..........fqf...fqf...fqf.......................",  # 4
    ".........hhffffffffffffffhh.....................",  # 5
    "........hh.ssssssssssssss.hh....................",  # 6
    ".......hh.ssssssssssssssssS.hh..................",  # 7
    "..........sssyysssssyyssssSS....................",  # 8
    "..........sssyqssssssyqsssSS....................",  # 9
    "..........ssssssssssssssssSS....................",  # 10
    "..........sssooooooooossssSS....................",  # 11
    "..........sssofffffffossssS.....................",  # 12
    "...........ssooooooooosssSS.....................",  # 13
    "............ssssssssssssSS......................",  # 14
    "......f...aaaassssssssaaaaa.....................",  # 15
    ".....fqf.aaaaaaaaaaaaaaaaaaaA...................",  # 16
    ".....fqf.aaaaaaaaaaaaaaaaaaaaAA.................",  # 17
    ".....fqf.aaasssaaaaaaaaaasssaAAA................",  # 18
    ".....fqf.aasssssaaaaaaaasssssaAAA...............",  # 19
    ".....fqf.aasssfsaaaaaaaasfsssaaAA...............",  # 20
    ".....fqf..ssssssaaaafaaassssssaAA...............",  # 21
    ".....fqf..sssssaaaaaaaaaaassssssAA..............",  # 22
    ".....fqf..ssss.aaaaaaaaaaa.sssssSS..............",  # 23
    "....mmmmm.sss..aaaaaaaaaaa..ssssSS..............",  # 24
    "......m..ssss..mmmmmmmmmmm..sssSSS..............",  # 25
    "......m.ssss...aaaaaaaaaaa...ssSSS..............",  # 26
    "......msss.....aaaaaaaaaaaa...sSSS..............",  # 27
    "......mss......aaaaa.aaaaaa....SS...............",  # 28
    "...............aaaaa..aaaaaA....................",  # 29
    "...............ssss...sssSSS....................",  # 30
    "...............ssss....ssSSS....................",  # 31
    "...............ssss....ssSSS....................",  # 32
    "..............sssss....sssSSS...................",  # 33
    "..............ssfss....ssfSSS...................",  # 34
    "..............sssss....sssSSS...................",  # 35
    ".............mmmmmm....mmmmMMM..................",  # 36
    "............mmmmmmm....mmmmmMMM.................",  # 37
    "...........mmmmmmmm....mmmmmmMMM................",  # 38
    "................................................",  # 39
    "................................................",  # 40
    "................................................",  # 41
    "................................................",  # 42
    "................................................",  # 43
    "................................................",  # 44
    "................................................",  # 45
    "................................................",  # 46
    "................................................",  # 47
])

# Typhon: father of monsters. A giant with a hundred serpent heads for hair
# (well, five) and a coiled serpent body instead of legs.
add("boss_typhon", {"s": "#6a4fa8", "n": "#3fa266", "m": "#a8ca58", "u": "#feae34", "c": "#3e2731"}, [
    "................................................",  # 0
    "................................................",  # 1
    "....nn.......nn.......nn........................",  # 2
    "...nykn.....nykn.....nykn.......................",  # 3
    "...nnnn.....nnnn.....nnnn.......................",  # 4
    "....nn..nn...nn...nn..nn........................",  # 5
    ".....n.nykn..nn..nykn.n.........................",  # 6
    ".....nnnnnnn.nn.nnnnnnn.........................",  # 7
    "......nn.nn..nn..nn.nn..........................",  # 8
    ".......nnnnnnnnnnnnnnn..........................",  # 9
    "........nsssssssssssnN..........................",  # 10
    ".......nssssssssssssSNN.........................",  # 11
    ".......nsyysssssyyssSNN.........................",  # 12
    ".......nsyrsssssyrssSSN.........................",  # 13
    ".......nssssssssssssSSN.........................",  # 14
    ".......nnsoooooooossSNN.........................",  # 15
    "........nsowowowowsSNN..........................",  # 16
    ".........ssssssssssSS...........................",  # 17
    ".......sssssssssssssSSSS........................",  # 18
    ".....sssssssssssssssssSSSS......................",  # 19
    "....ssssssssuuuuuussssSSSSS.....................",  # 20
    "...sssss.sssssussssss.SSSSSS....................",  # 21
    "..ssss...sssssssssssss..SSSSS...................",  # 22
    "..sss....ssssssssssssS...SSSS...................",  # 23
    ".ssss....ssssssssssssS....SSSS..................",  # 24
    ".s.s.s...sssssssssssSS....s.s.s.................",  # 25
    ".........ccccccccccccCC.........................",  # 26
    ".........nnnnnnnnnnnnNN.........................",  # 27
    ".........nnmnnmnnmnnnNN.........................",  # 28
    "..........nnnnnnnnnnnnNN........................",  # 29
    "...........nnnnnnnnnnnnNN.......................",  # 30
    "............nnnnnnnnnnnnNN......................",  # 31
    ".............nnnnnnnnnnnnNNN....................",  # 32
    "..............nnmnnmnnmnnnNNN...................",  # 33
    ".......nnnnnnnnnnnnnnnnnnnnNNN..................",  # 34
    ".....nnnnnnnnnnnnnnnnnnnnnnnNNN.................",  # 35
    "....nnnmnnmnnmnnmnnmnnmnnnnNNNN.......nnn.......",  # 36
    "...nnnnnnnnnnnnnnnnnnnnnnnnnNNNN....nnnnNN......",  # 37
    "...nnnnnnnnnnnnnnnnnnnnnnnnnNNNNNnnnnnNN........",  # 38
    "....NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN..........",  # 39
    "................................................",  # 40
    "................................................",  # 41
    "................................................",  # 42
    "................................................",  # 43
    "................................................",  # 44
    "................................................",  # 45
    "................................................",  # 46
    "................................................",  # 47
])
