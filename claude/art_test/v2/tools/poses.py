"""Small chibi OpenPose skeletons (COCO-18) for the style test v2. Usage: poses.py"""
import math
from PIL import Image, ImageDraw
LIMBS = [(1,2),(1,5),(2,3),(3,4),(5,6),(6,7),(1,8),(8,9),(9,10),(1,11),(11,12),(12,13),(1,0),(0,14),(14,16),(0,15),(15,17)]
COLS = [(255,0,0),(255,85,0),(255,170,0),(255,255,0),(170,255,0),(85,255,0),(0,255,0),(0,255,85),(0,255,170),
        (0,255,255),(0,170,255),(0,85,255),(0,0,255),(85,0,255),(170,0,255),(255,0,255),(255,0,170),(255,0,85)]
def draw(k, out, off=(412, 430), sc=1.0, w=4, r=4):
    img = Image.new("RGB", (1024, 1024), "black"); d = ImageDraw.Draw(img)
    P = {i: (off[0] + p[0] * sc, off[1] + p[1] * sc) if p else None for i, p in k.items()}
    for i, (a, b) in enumerate(LIMBS):
        if P.get(a) is None or P.get(b) is None: continue
        (x1, y1), (x2, y2) = P[a], P[b]
        L = math.hypot(x2-x1, y2-y1); ang = math.atan2(y2-y1, x2-x1); pts = []
        for t in range(0, 360, 10):
            rr = math.radians(t); px, py = (L/2)*math.cos(rr), w*math.sin(rr)
            pts.append(((x1+x2)/2 + px*math.cos(ang) - py*math.sin(ang), (y1+y2)/2 + px*math.sin(ang) + py*math.cos(ang)))
        d.polygon(pts, fill=tuple(int(c*0.6) for c in COLS[i]))
    for i, p in P.items():
        if p: d.ellipse([p[0]-r, p[1]-r, p[0]+r, p[1]+r], fill=COLS[i])
    img.save(out)
# back three-quarter, facing up-right, weapon (right) hand raised forward; chibi: big head
BACK = {0: None, 1: (100, 84), 2: (134, 86), 3: (156, 106), 4: (166, 84), 5: (64, 94), 6: (52, 124), 7: (60, 150),
        8: (116, 160), 9: (134, 200), 10: (142, 238), 11: (82, 163), 12: (72, 206), 13: (60, 248),
        14: None, 15: None, 16: (126, 50), 17: (80, 54)}
# front, facing viewer (for portraits), relaxed battle stance
FRONT = {0: (100, 52), 1: (100, 84), 2: (66, 90), 3: (56, 124), 4: (60, 152), 5: (134, 90), 6: (144, 124), 7: (140, 152),
         8: (82, 160), 9: (78, 204), 10: (74, 246), 11: (118, 160), 12: (122, 204), 13: (126, 246),
         14: (92, 44), 15: (108, 44), 16: (80, 50), 17: (120, 50)}
if __name__ == "__main__":
    draw(BACK, r"C:\ai\art_work2\pose_back.png")
    draw(FRONT, r"C:\ai\art_work2\pose_front.png")
    print("ok")
