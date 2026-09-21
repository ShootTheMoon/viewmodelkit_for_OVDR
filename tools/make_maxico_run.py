# -*- coding: utf-8 -*-
# maxico 달리기 3클립. 블렌더 Macuahuitl_RUN_10_85.blend (30fps).
#   사용자 설명 : 0~25 준비자세, 그 뒤로 달리기, 85 다음엔 25 로 되돌아가 반복.
#   실측 : f10 = 인게임 기준자세(0.00cm). f0~f10 도 같은 자세라 시작은 f10 으로 잡는다.
#   Maxico1RunStart : f10 -> f25  (대기 -> 달리기 첫 자세)
#   Maxico1RunLoop  : f25 -> f85  (무한 반복)
#   Maxico1RunStop  : RunStart 를 거꾸로 (달리기 첫 자세 -> 대기). 사용자가 따로 안 만들어서 뒤집어 쓴다.
import bpy, os, math, json
from mathutils import Vector, Matrix

BLEND = r"C:\Users\banav\Downloads\Macuahuitl_RUN_10_85.blend"
OUTD  = r"C:\Users\banav\AppData\Local\Temp\claude\C--Users-banav\905740d1-b7fc-4e67-87d7-0ecd64213ee4\scratchpad"
REST_F = 10                                # 인게임 기준자세와 같은 프레임 (실측 0.00cm)
O = Vector((0.0274, -0.1984, 1.1279))      # japan 과 같은 점 = 레벨 PIVOT 의 원본
SEGS = [("Maxico1RunStart", 10, 25, False),
        ("Maxico1RunLoop", 25, 85, False),
        ("Maxico1RunStop", 10, 25, True)]  # True = 거꾸로

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
LOW = min(s[1] for s in SEGS); HIGH = max(s[2] for s in SEGS)
pose = {}
for f in range(LOW, HIGH + 1):
    scn.frame_set(f); vl.update()
    pose[f] = {n: (T @ bpy.data.objects[n].matrix_world).copy() for n in MOVERS}

def vmean(o, mat):
    pts = [mat @ v.co for v in o.data.vertices]
    return sum(pts, Vector()) / len(pts)
worst = max((vmean(bpy.data.objects[n], pose[REST_F][n]) - Vector(meta["parts"][n]["center"])).length * 100 for n in ARMS)
print("f%d 팔 <-> 게임 모델 자세 : 최대 %.4f cm (0 이어야 한다)" % (REST_F, worst))

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

for NAME, LO, HI, REV in SEGS:
    frames = list(range(LO, HI + 1))
    if REV:
        frames.reverse()
    rows = []
    for i, f in enumerate(frames):
        c = row(f)
        vals = ["%.4f" % (i / FPS)]
        for _, src in OUTP:
            for v in c[src]:
                vals.append("%.4f" % (0.0 if abs(v) < 5e-5 else v))
        rows.append("{" + ",".join(vals) + "}")
    FULL = (len(frames) - 1) / FPS
    note = {
      "Maxico1RunStart": "--   대기자세(f10) -> 달리기 첫 자세(f25). 끝나면 바로 RunLoop 로 넘어간다.",
      "Maxico1RunLoop":  "--   무한 반복 (f25 -> f85 -> 다시 f25).",
      "Maxico1RunStop":  "--   RunStart 를 거꾸로 재생한 것 (달리기 자세 -> 대기자세). 멈출 때 뚝 끊기지 않게.",
    }[NAME]
    body = [
     "-- %s : 마쿠아후이틀(maxico) 달리기. 블렌더 %s %d~%d 프레임 (%dfps)%s"
        % (NAME, os.path.basename(BLEND), LO, HI, FPS, " 역재생" if REV else ""),
     note,
     "--   기준(rest) = f%d = 인게임 대기자세 (실측 0.00cm)." % REST_F,
     "--   피벗 O = (%.4f, %.4f, %.4f) — ViewmodelConfig 의 maxico PIVOT 과 같은 점." % tuple(O),
     "return {",
     "\tfull = %.4f," % FULL,
     "\tduration = %.4f," % FULL,
     "\tcut = nil,",
     "\tposScale = 240,",
     "\tparts = {",
    ]
    for i in range(0, len(names), 6):
        body.append("\t\t" + ", ".join('"%s"' % n for n in names[i:i+6]) + ",")
    body += ["\t},", "\tframes = {"] + [r + "," for r in rows] + ["\t},", "}"]
    p = os.path.join(OUTD, NAME + ".lua")
    open(p, 'w', encoding='utf-8').write("\n".join(body) + "\n")
    # 이음새 검사
    first = rows[0].split(",", 1)[1]; last = rows[-1].split(",", 1)[1]
    gap = ""
    if NAME == "Maxico1RunLoop":
        a = [float(x) for x in rows[0].strip("{}").split(",")[1:]]
        b = [float(x) for x in rows[-1].strip("{}").split(",")[1:]]
        d = max(math.sqrt(sum((a[i * 7 + j] - b[i * 7 + j]) ** 2 for j in range(3))) for i in range(len(names)))
        gap = "   루프 이음새 %.2f cm (화면 기준 %.2f cm)" % (d * 100, d * 100 * 2.4)
    print("%-18s %2d행  %.4f초%s" % (NAME, len(rows), FULL, gap))
