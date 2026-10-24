"""Hand pixel edits on baked layer grids.

paint(layer, y, x0, mats, shades): writes a row segment. mats: one char per pixel ('.' clears,
' ' leaves as is); shades: digits ('-' or ' ' keeps the existing shade).
"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hero


class Layer:
    def __init__(self, name):
        self.name = name
        p = os.path.join(hero.LAY, name)
        self.m = [list(r.rstrip("\n").ljust(hero.W, ".")) for r in open(p + ".txt")][:hero.H]
        while len(self.m) < hero.H:
            self.m.append(["."] * hero.W)
        ps = p + ".shade.txt"
        if os.path.exists(ps):
            self.s = [list(r.rstrip("\n").ljust(hero.W, ".")) for r in open(ps)][:hero.H]
        else:
            self.s = [["."] * hero.W for _ in range(hero.H)]
        while len(self.s) < hero.H:
            self.s.append(["."] * hero.W)

    def paint(self, y, x0, mats, shades=""):
        for i, c in enumerate(mats):
            x = x0 + i
            if c == " ":
                pass
            elif c == ".":
                self.m[y][x] = "."; self.s[y][x] = "."
            else:
                self.m[y][x] = c
            if i < len(shades) and shades[i] not in " -" and self.m[y][x] != ".":
                self.s[y][x] = shades[i]
        return self

    def clear(self, y0, y1, x0, x1):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.m[y][x] = "."; self.s[y][x] = "."
        return self

    def save(self, name=None):
        p = os.path.join(hero.LAY, name or self.name)
        open(p + ".txt", "w").write("\n".join("".join(r) for r in self.m) + "\n")
        open(p + ".shade.txt", "w").write("\n".join("".join(r) for r in self.s) + "\n")
        return self
