# -*- coding: utf-8 -*-
# maxico 막기 2클립. 블렌더 Macuahuitl_BLOCK.blend (30fps).
#   실측 : f10 = f40 = 인게임 대기자세 (0.00cm), f25 = 막기 자세 (31.46cm)
#   Maxico1BlockIn  : f10 -> f25  (막기 들어가기. 끝 자세에서 멈춰 유지된다)
#   Maxico1BlockOut : f25 -> f40  (막기 풀기)
#   ★ BlockHold 클립은 만들지 않는다. 컨트롤러는 그게 없으면 BlockIn 의 마지막 자세를 그대로 유지한다.
import bpy, os, math, json
from mathutils import Vector, Matrix
BLEND = r"C:\Users\banav\Downloads\Macuahuitl_BLOCK.blend"
OUTD  = r"C:\Users\banav\AppData\Local\Temp\claude\C--Users-banav\905740d1-b7fc-4e67-87d7-0ecd64213ee4\scratchpad"
REST_F = 10
O = Vector((0.0274, -0.1984, 1.1279))
SEGS = [("Maxico1BlockIn", 10, 25), ("Maxico1BlockOut", 25, 40)]
meta = json.load(open(os.path.join(OUTD, "maxico_arms_v1_meta.json")))
T = Matrix(meta["T"])
ARMS = ['R_UpperArm', 'R_LowerArm', 'R_Hand', 'L_UpperArm', 'L_LowerArm', 'L_Hand']
MOVERS = ARMS + ['Macuahuitl']
names = ARMS + sorted(n for n in meta["parts"] if n not in ARMS)
OUTP = [(n, n if n in ARMS else 'Macuahuitl') for n in names]
M = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))
M4, M4I = M.to_4x4(), M.to_4x4().inverted()
bpy.ops.wm.open_mainfile(filepath=BLEND)
scn = bpy.context.scene; vl = bpy.context.view_layer
FPS = scn.render.fps
pose = {}
for f in range(10, 41):
    scn.frame_set(f); vl.update()
    pose[f] = {n: (T @ bpy.data.objects[n].matrix_world).copy() for n in MOVERS}
def vmean(o, mat):
    pts = [mat @ v.co for v in o.data.vertices]
    return sum(pts, Vector()) / len(pts)
print("f%d 팔 <-> 게임 모델 : 최대 %.4f cm" % (REST_F, max(
    (vmean(bpy.data.objects[n], pose[REST_F][n]) - Vector(meta["parts"][n]["center"])).length * 100 for n in ARMS)))
TOI = Matrix.Translation(-O)
PRINV = {n: (TOI @ pose[REST_F][n]).inverted() for n in MOVERS}
def row(f):
    c = {}
    for n in MOVERS:
        D = (TOI @ pose[f][n]) @ PRINV[n]
        DL = M4 @ D @ M4I
        p = DL.to_translation(); q = DL.to_quaternion()
        if q.w < 0: q = -q
        c[n] = (p.x, p.y, p.z, q.w, q.x, q.y, q.z)
    return c
for NAME, LO, HI in SEGS:
    rows = []
    for i, f in enumerate(range(LO, HI + 1)):
        c = row(f)
        vals = ["%.4f" % (i / FPS)]
        for _, src in OUTP:
            for v in c[src]:
                vals.append("%.4f" % (0.0 if abs(v) < 5e-5 else v))
        rows.append("{" + ",".join(vals) + "}")
    FULL = (HI - LO) / FPS
    note = ("--   막기 들어가기. 마지막 자세(블렌더 25프레임)에서 멈춰 유지된다 (BlockHold 클립은 안 쓴다)."
            if NAME.endswith("In") else
            "--   막기 풀기. 마지막 행이 단위행렬이라 대기자세로 그대로 이어진다.")
    body = ["-- %s : 마쿠아후이틀(maxico) 막기. 블렌더 %s %d~%d 프레임 (%dfps)" % (NAME, os.path.basename(BLEND), LO, HI, FPS),
            note,
            "--   기준(rest) = f%d = 인게임 대기자세 (실측 0.00cm)." % REST_F,
            "--   피벗 O = (%.4f, %.4f, %.4f)." % tuple(O),
            "return {", "\tfull = %.4f," % FULL, "\tduration = %.4f," % FULL, "\tcut = nil,",
            "\tposScale = 240,", "\tparts = {"]
    for i in range(0, len(names), 6):
        body.append("\t\t" + ", ".join('"%s"' % n for n in names[i:i+6]) + ",")
    body += ["\t},", "\tframes = {"] + [r + "," for r in rows] + ["\t},", "}"]
    p = os.path.join(OUTD, NAME + ".lua")
    open(p, 'w', encoding='utf-8').write("\n".join(body) + "\n")
    ident = ",".join(["0.0000","0.0000","0.0000","1.0000","0.0000","0.0000","0.0000"] * len(names)) + "}"
    tag = "마지막=대기자세" if rows[-1].split(",", 1)[1] == ident else ("첫행=대기자세" if rows[0].split(",", 1)[1] == ident else "-")
    print("%-18s %2d행  %.4f초  %s" % (NAME, len(rows), FULL, tag))
