# -*- coding: utf-8 -*-
# Maxico1Intro : 마쿠아후이틀 리메이크 2타. 블렌더 Macuahuitl_ATTACK2_10_60.blend 10~100 (30fps).
#   기준(rest) = 100프레임 = idle 기본자세 = Maxico_Arms_v2.fbx 를 내보낸 자세.
#   칼 6조각 + 금색 판 5장은 전부 Macuahuitl 오브젝트를 따라간다 (판은 칼의 자식, 칼은 60프레임부터 오른손 Child Of).
#   피벗 O 는 japan 과 같은 블렌더 점. ViewmodelConfig 의 maxico PIVOT 이 이 점을 레벨 좌표로 옮긴 값이라야 한다.
import bpy, os, math, json
from mathutils import Vector, Matrix

BLEND = r"C:\Users\banav\Downloads\Macuahuitl_ATTACK2_10_60.blend"
OUTD  = r"C:\Users\banav\AppData\Local\Temp\claude\C--Users-banav\905740d1-b7fc-4e67-87d7-0ecd64213ee4\scratchpad"
NAME, LO, HI, REST_F = "Maxico1Attack2", 10, 60, 60
O = Vector((0.0274, -0.1984, 1.1279))     # japan 과 같은 점 (레벨 PIVOT 이 이걸 옮긴 값)

meta = json.load(open(os.path.join(OUTD, "maxico_arms_v2_meta.json")))
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
for f in range(LO, HI + 1):
    scn.frame_set(f); vl.update()
    pose[f] = {n: (T @ bpy.data.objects[n].matrix_world).copy() for n in MOVERS}

# 기준 프레임 자세가 내보낸 FBX 와 같은지 (팔로 확인)
scn.frame_set(REST_F); vl.update()
def bbc_obj(o, mat):
    # ★ meta 의 center 와 같은 기준으로 재야 한다 (버텍스 평균).
    #   바운딩박스 중심으로 재면 팔이 1~2cm 어긋난 것처럼 보인다 (2026-09-20 에 이걸로 헛짚었다).
    pts = [mat @ v.co for v in o.data.vertices]
    return sum(pts, Vector()) / len(pts)
worst = max((bbc_obj(bpy.data.objects[n], pose[REST_F][n]) - Vector(meta["parts"][n]["center"])).length * 100 for n in ARMS)
print("%d프레임 팔 <-> 내보낸 FBX : 최대 %.4f cm (0 이어야 한다)" % (REST_F, worst))

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
z = max(math.sqrt(sum(row(REST_F)[n][i] ** 2 for i in range(3))) for n in MOVERS)
print("기준프레임 자기델타 : 최대 %.4f cm (0 이어야 한다)" % (z * 100))
c10 = row(LO)
print("첫 프레임이 기준에서 벗어난 양 : 최대 %.1f cm (화면 기준, 배율 2.4 적용)" % (
    max(math.sqrt(sum(c10[n][i] ** 2 for i in range(3))) for n in MOVERS) * 100 * 2.4))

rows = []
for f in range(LO, HI + 1):
    c = row(f)
    vals = ["%.4f" % ((f - LO) / FPS)]
    for _, src in OUTP:
        for v in c[src]:
            vals.append("%.4f" % (0.0 if abs(v) < 5e-5 else v))
    rows.append("{" + ",".join(vals) + "}")

FULL = (HI - LO) / FPS
body = [
 "-- %s : 마쿠아후이틀 리메이크(maxico) 2타. 블렌더 %s %d~%d 프레임 (%dfps)" % (NAME, os.path.basename(BLEND), LO, HI, FPS),
 "--   기준(rest) = %d프레임 = idle 기본자세 = Maxico_Arms_v2.fbx 를 내보낸 자세." % REST_F,
 "--   그래서 마지막 행이 단위행렬이고, 끝나면 대기자세로 그대로 이어진다.",
 "--   칼 6조각과 금색 판 5장은 전부 Macuahuitl 오브젝트를 따라간다.",
 "--   피벗 O = (%.4f, %.4f, %.4f) — ViewmodelConfig 의 maxico PIVOT 과 같은 점이라야 한다." % tuple(O),
 "return {",
 "\tfull = %.4f," % FULL,
 "\tduration = %.4f," % FULL,
 "\t-- 마쿠아후이틀은 2타로 끝이라 cut 이 없다 (다음 타 예약이 안 걸린다).",
 "\tcut = nil,",
 "\t-- 타격 판정 시점 = 블렌더 25프레임 (칼끝 속도 최고점 1255cm/s).",
 "\thitAt = %.4f," % ((25 - LO) / FPS),
 "\tposScale = 240,",
 "\tparts = {",
]
for i in range(0, len(names), 6):
    body.append("\t\t" + ", ".join('"%s"' % n for n in names[i:i+6]) + ",")
body += ["\t},", "\tframes = {"]
body += [r + "," for r in rows]
body += ["\t},", "}"]
p = os.path.join(OUTD, NAME + ".lua")
open(p, 'w', encoding='utf-8').write("\n".join(body) + "\n")
last = rows[-1].split(",", 1)[1]
ident = ",".join(["0.0000", "0.0000", "0.0000", "1.0000", "0.0000", "0.0000", "0.0000"] * len(names)) + "}"
print("마지막 행이 단위행렬인가 :", "그렇다" if last == ident else "★ 아니다")
print("%s : 파츠 %d개, %d행, %d bytes, full=%.4f초" % (NAME, len(names), len(rows), os.path.getsize(p), FULL))
