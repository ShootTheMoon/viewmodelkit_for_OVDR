# -*- coding: utf-8 -*-
# Maxico_Arms_v1.fbx : 팔 6 + 마쿠아후이틀(재질별로 쪼갬) + 금색 판 5, 40프레임 자세, 한 파일.
#   - 색별로 미리 쪼개 둔다 (임포트 후 스플릿 작업 없음). 파츠 이름 = 무엇인지 바로 알 수 있게.
#   - 오버데어 한도 30,000(삼각형)에 맞춰 칼의 무거운 재질만 줄인다 (이 사본에서만).
#   - 원본 : 사용자 작업 파일의 사본 Macuahuitl_GoldGlow5_lowpoly.blend (판 저폴리 적용본)
import bpy, bmesh, os, json, math
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

D    = r"C:\Users\banav\AppData\Local\Temp\claude\C--Users-banav\905740d1-b7fc-4e67-87d7-0ecd64213ee4\scratchpad"
REF  = r"C:\Users\banav\Documents\카카오톡 받은 파일\Japan1_Block.blend"
SRC  = r"C:\Users\banav\Downloads\Macuahuitl_GoldGlow5_lowpoly.blend"
OUT  = r"C:\Users\banav\Desktop\Viewmodel_WIP\Export\멕시코\Maxico_Arms_v1.fbx"
BLEND_OUT = r"C:\Users\banav\Downloads\Maxico_Arms_v1_export.blend"
META = os.path.join(D, "maxico_arms_v1_meta.json")
BASE = 40
LIMIT = 30000

ARMS = ['R_UpperArm', 'R_LowerArm', 'R_Hand', 'L_UpperArm', 'L_LowerArm', 'L_Hand']
PLATES = ["MAC_Glow_%d" % i for i in range(1, 6)]
# 재질 -> 파츠 이름, 줄이는 비율
WEAPON = {
    'MAC_Jade_edge':           ('Macuahuitl_Edge',    0.075),
    'MAC_Jade_handle':         ('Macuahuitl_Handle',  0.5),
    'MAC_Jade_handle_copper':  ('Macuahuitl_Copper',  0.5),
    'MAC_Jade_handle_leather': ('Macuahuitl_Leather', 1.0),
    'MAC_Jade_handle_jade':    ('Macuahuitl_Jade',    1.0),
    'MAC_Jade_body':           ('Macuahuitl_Body',    1.0),   # S1~S4 도 여기로 합친다
}

def lin2srgb(c):
    c = max(0.0, min(1.0, c))
    s = 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055
    return int(round(s * 255))

def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)

bpy.ops.wm.open_mainfile(filepath=REF)
bpy.context.scene.frame_set(10); bpy.context.view_layer.update()
CAMREF = bpy.data.objects["FakeFPSCamera"].matrix_world.copy()

bpy.ops.wm.open_mainfile(filepath=SRC)
scn = bpy.context.scene; vl = bpy.context.view_layer
scn.frame_set(BASE); vl.update()
T = CAMREF @ bpy.data.objects["FakeFPSCamera"].matrix_world.inverted()
dT = max(abs(T[i][j] - (1.0 if i == j else 0.0)) for i in range(4) for j in range(4))
print("카메라 차이 %.6f" % dT)

MOVERS = ARMS + ['Macuahuitl'] + PLATES
KEEP = {n: (T @ bpy.data.objects[n].matrix_world).copy() for n in MOVERS}
for o in list(bpy.data.objects):
    o.animation_data_clear()
    for c in list(o.constraints):
        o.constraints.remove(c)
for n in MOVERS:
    bpy.data.objects[n].parent = None
vl.update()
for n in MOVERS:
    bpy.data.objects[n].matrix_world = KEEP[n]
vl.update()
# 칼 원본 표면 (줄인 뒤 오차 재기용, 월드 좌표)
W0 = bpy.data.objects['Macuahuitl']
orig_bvh = {}

# 칼몸 S1~S4 -> MAC_Jade_body 하나로 (같은 텍스처, 이름만 다름)
body = bpy.data.materials['MAC_Jade_body']
body_idx = [i for i, s in enumerate(W0.material_slots) if s.material.name == 'MAC_Jade_body'][0]
merge = {i for i, s in enumerate(W0.material_slots) if s.material.name.startswith('MAC_Jade_body_S')}
for p in W0.data.polygons:
    if p.material_index in merge:
        p.material_index = body_idx   # 면을 칼몸 칸 하나로 모은다 (쪼갤 때 한 조각이 되게)

# 재질별로 쪼개기
bpy.ops.object.select_all(action='DESELECT')
W0.select_set(True); vl.objects.active = W0
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.separate(type='MATERIAL')
bpy.ops.object.mode_set(mode='OBJECT')
pieces = [x for x in bpy.data.objects if x.type == 'MESH' and x.name.split('.')[0] == 'Macuahuitl']
for ob in pieces:
    used = sorted({p.material_index for p in ob.data.polygons})
    if not used:
        bpy.data.objects.remove(ob); continue
    if len(used) != 1:
        raise SystemExit("[FAIL] %s 재질 %d개" % (ob.name, len(used)))
    mat = ob.material_slots[used[0]].material
    name, ratio = WEAPON[mat.name]
    # 쓰는 재질 하나만 남기기
    ob.data.materials.clear(); ob.data.materials.append(mat)
    for p in ob.data.polygons: p.material_index = 0
    ob.name = name; ob.data.name = name
    ob["ratio"] = ratio
vl.update()

# 판 이름
for i, n in enumerate(PLATES, 1):
    o = bpy.data.objects[n]; o.name = "Macuahuitl_Glow_%d" % i; o.data.name = o.name

# 스케일 적용 (월드 모양 그대로, 파츠 스케일 1)
parts = ARMS + [WEAPON[k][0] for k in WEAPON] + ["Macuahuitl_Glow_%d" % i for i in range(1, 6)]
bpy.ops.object.select_all(action='DESELECT')
for n in parts:
    bpy.data.objects[n].select_set(True)
vl.objects.active = bpy.data.objects[parts[0]]
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

# 줄이기 + 오차 재기
print("=== 칼 줄이기 ===")
for key, (name, ratio) in WEAPON.items():
    o = bpy.data.objects[name]
    t0 = tris(o)
    bm0 = bmesh.new(); bm0.from_mesh(o.data); bm0.transform(o.matrix_world)
    bvh = BVHTree.FromBMesh(bm0); bm0.free()
    if ratio < 1.0:
        md = o.modifiers.new("dec", 'DECIMATE'); md.decimate_type = 'COLLAPSE'; md.ratio = ratio
        md.use_collapse_triangulate = True
        vl.objects.active = o
        bpy.ops.object.modifier_apply(modifier=md.name)
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.to_mesh(o.data); bm.free()
    err = 0.0
    for v in o.data.vertices:
        p = o.matrix_world @ v.co
        loc, nrm, idx, d = bvh.find_nearest(p)
        err = max(err, d)
    print("  %-20s 삼각형 %6d -> %6d   최대 오차 %.2f mm" % (name, t0, tris(o), err * 1000))

# 색 (레벨 Color 용 sRGB). 텍스처 재질은 텍스처 평균색
def part_rgb(o):
    m = o.material_slots[0].material
    b = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bc = b.inputs['Base Color']
    if bc.is_linked:
        img = bc.links[0].from_node.image
        px = np.array(img.pixels[:]).reshape(-1, 4)[:, :3].mean(0)
        return [int(round(x * 255)) for x in px], "텍스처 평균(" + img.name + ")"
    c = bc.default_value
    return [lin2srgb(c[0]), lin2srgb(c[1]), lin2srgb(c[2])], "단색"

meta = {"T": [list(r) for r in T], "frame": BASE, "parts": {}}
total = 0
bpy.ops.object.select_all(action='DESELECT')
print("=== 파츠 ===")
for n in parts:
    o = bpy.data.objects[n]
    rgb, how = part_rgb(o)
    P = [o.matrix_world @ v.co for v in o.data.vertices]
    ctr = sum(P, Vector()) / len(P)
    follow = n if n in ARMS else "Macuahuitl_Body"
    meta["parts"][n] = {"rgb": rgb, "center": list(ctr), "follow": follow, "material": o.material_slots[0].material.name}
    total += tris(o)
    print("  %-20s 삼각형 %6d  RGB %-16s %s" % (n, tris(o), tuple(rgb), how))
    o.select_set(True); vl.objects.active = o
print("합계 삼각형 %d (한도 %d)" % (total, LIMIT))
if total >= LIMIT:
    raise SystemExit("[FAIL] 한도 초과")

extra = [x.name for x in bpy.data.objects if x.type == 'MESH' and x.name not in parts]
if extra:
    raise SystemExit("[FAIL] 모르는 메시 %s" % extra)

os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True,
    object_types={'MESH'}, add_leaf_bones=False, bake_anim=False,
    mesh_smooth_type='FACE', use_mesh_modifiers=False,
    path_mode='COPY', embed_textures=True)
open(META, 'w').write(json.dumps(meta, indent=1, ensure_ascii=False))
bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT, copy=True)
print("파츠 %d개 -> %s  %d bytes" % (len(parts), OUT, os.path.getsize(OUT)))
print("확인용 블렌드 ->", BLEND_OUT)
