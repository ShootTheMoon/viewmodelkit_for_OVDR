# 뷰모델 킷 팔 : Mixamo_For_OVDR_Arms_armbones.fbx -> 뼈대 제거, 팔 6조각 강체
#   파일에 들어있는 T자세(포즈 적용 상태) 그대로 굽는다.
#   조각 배정 : 면의 버텍스들이 가장 많이 속한 버텍스 그룹(각 버텍스는 가중치 최대 그룹)
#   피벗 : 해당 뼈 시작점(관절)   계층 : Hand -> LowerArm -> UpperArm
import bpy, bmesh
from mathutils import Matrix
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r"C:\Users\banav\Downloads\Mixamo_For_OVDR_Arms_armbones.fbx")
arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
dg = bpy.context.evaluated_depsgraph_get()
MAP = {"RightUpperArm": "R_UpperArm", "RightLowerArm": "R_LowerArm", "RightHand": "R_Hand",
       "LeftUpperArm": "L_UpperArm", "LeftLowerArm": "L_LowerArm", "LeftHand": "L_Hand"}
mat = bpy.data.materials.new("Viewmodel_Suit"); mat.use_nodes = True
bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
bsdf.inputs["Base Color"].default_value = (63 / 255, 63 / 255, 69 / 255, 1)
bsdf.inputs["Roughness"].default_value = 0.7
parts, PIV = {}, {}
for src in [o for o in bpy.data.objects if o.type == 'MESH']:
    ev = src.evaluated_get(dg); me = ev.to_mesh()
    names = {g.index: g.name for g in src.vertex_groups}
    dom = {v.index: (names[max(v.groups, key=lambda x: x.weight).group] if v.groups else None) for v in src.data.vertices}
    for bone in sorted(set(d for d in dom.values() if d)):
        bm = bmesh.new(); bm.from_mesh(me); bm.transform(src.matrix_world)
        bm.verts.ensure_lookup_table()
        kill = []
        for f in bm.faces:
            c = {}
            for v in f.verts:
                c[dom[v.index]] = c.get(dom[v.index], 0) + 1
            if max(c, key=c.get) != bone:
                kill.append(f)
        bmesh.ops.delete(bm, geom=kill, context='FACES')
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
        pivot = (arm.matrix_world @ arm.pose.bones[bone].head).copy()
        bm.transform(Matrix.Translation(-pivot))
        name = MAP[bone]
        m = bpy.data.meshes.new(name); bm.to_mesh(m); bm.free()
        m.materials.append(mat)
        ob = bpy.data.objects.new(name, m)
        bpy.context.scene.collection.objects.link(ob)
        parts[name] = ob; PIV[name] = pivot
    ev.to_mesh_clear()
for o in list(bpy.data.objects):
    if o.name not in parts:
        bpy.data.objects.remove(o)
for m in [m for m in bpy.data.meshes if m.users == 0]:
    bpy.data.meshes.remove(m)
for n, ob in parts.items():
    ob.location = PIV[n]
for side in "RL":
    chain = [side + "_UpperArm", side + "_LowerArm", side + "_Hand"]
    for par, child in zip(chain, chain[1:]):
        c = parts[child]
        c.parent = parts[par]
        c.matrix_parent_inverse = Matrix.Identity(4)
        c.location = PIV[child] - PIV[par]
bpy.context.view_layer.update()
tot = 0
for n in sorted(parts):
    o = parts[n]; tris = sum(len(p.vertices) - 2 for p in o.data.polygons); tot += tris
    ws = [o.matrix_world @ v.co for v in o.data.vertices]
    print("PART %-11s 부모 %-11s 피벗 (%.3f %.3f %.3f)  x[%.3f..%.3f]  버텍스 %d  삼각형 %d" % (
        n, o.parent.name if o.parent else "-", *o.matrix_world.translation,
        min(p.x for p in ws), max(p.x for p in ws), len(o.data.vertices), tris))
print("TOTAL tris", tot)
K = r"C:\Users\banav\Desktop\Viewmodel_WIP\viewmodelkit_for_OVDR\blender"
bpy.ops.wm.save_as_mainfile(filepath=K + r"\VMKit_Arms.blend")
bpy.ops.export_scene.fbx(filepath=K + r"\VMKit_Arms.fbx", object_types={'MESH'}, apply_unit_scale=True, bake_anim=False)
print("SAVED")
