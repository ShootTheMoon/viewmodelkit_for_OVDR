# arms_split.py 결과 검증 : 원본과 결과를 각각 임포트해 뼈·메시·포즈를 대조한다.
#   실행 : blender -b --python arms_verify.py -- ORIG.fbx RESULT.fbx
#   VERDICT OK 조건 : 결과의 모든 뼈가 원본과 같은 부모·head·tail, 팔 메시 2개의 verts/faces/vgroup/모디파이어/치수 일치,
#                    포즈 본 월드 위치·회전 일치. (뼈를 줄인 armbones 는 몸통 뼈 tail 이 달라져 FAIL 로 뜨는데, tail 은 FBX 에 저장되지 않는 표시값이라 무시해도 된다)
import bpy, sys
argv = sys.argv[sys.argv.index("--")+1:]
SRC, RES = argv[0], argv[1]

def dump(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=path)
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    r3 = lambda v: tuple(round(x, 3) for x in v)
    bones = {b.name: (b.parent.name if b.parent else None, r3(b.head_local), r3(b.tail_local)) for b in arm.data.bones}
    pose = {pb.name: (r3((arm.matrix_world @ pb.matrix).translation), tuple(round(x, 2) for x in pb.rotation_quaternion)) for pb in arm.pose.bones}
    meshes = {o.name: (len(o.data.vertices), len(o.data.polygons), [vg.name for vg in o.vertex_groups], [m.type for m in o.modifiers],
                       r3(o.matrix_world.translation), tuple(round(x, 2) for x in o.dimensions)) for o in bpy.data.objects if o.type == "MESH"}
    return tuple(round(x, 4) for x in arm.scale), bones, pose, meshes

a = dump(SRC); b = dump(RES)
print("ARM scale orig", a[0], "res", b[0])
print("BONES orig", len(a[1]), "res", len(b[1]))
bad = [n for n in b[1] if n not in a[1] or a[1][n] != b[1][n]]
print("BONE MISMATCH:", bad)
for n in bad: print("   ", n, "orig", a[1].get(n), "res", b[1][n])
badp = [n for n in b[2] if a[2].get(n) != b[2][n]]
print("POSE MISMATCH:", badp)
print("MESHES res:", list(b[3]))
for n, v in b[3].items():
    print("   ", n, "MATCH" if a[3].get(n) == v else f"DIFF orig={a[3].get(n)} res={v}")
ok = not bad and not badp and all(a[3].get(n) == v for n, v in b[3].items())
print("VERDICT:", "OK" if ok else "FAIL")
