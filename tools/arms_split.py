# Mixamo_For_OVDR.fbx (전신 6메시 + 뼈 22) -> 팔만 남긴 FBX
#   팔 메시 2개(LeftArm_Geo·RightArm_Geo)와 스켈레톤을 바인드 포즈 그대로 보존한다.
#   몸통·다리·머리 메시만 지우고, 트랜스폼·포즈·웨이트는 건드리지 않는다.
#
# 실행 : blender -b --python arms_split.py -- SRC.fbx OUT_DIR [--separate] [--arm-bones-only] [--scale-mode NONE|ALL]
#   (기본)            OUT_DIR/Mixamo_For_OVDR_Arms.fbx          뼈 22개 전부 유지
#   --arm-bones-only  OUT_DIR/Mixamo_For_OVDR_Arms_armbones.fbx 팔 체인 + 몸통 연결선 12개만 (build_vmkit.py 입력)
#   --separate        왼팔/오른팔 두 파일로
import bpy, sys, os
argv = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
pos = [a for a in argv if not a.startswith("--") and a not in ("NONE", "ALL")]
SRC = pos[0] if len(pos) > 0 else r"C:\Users\HSP\Downloads\Mixamo_For_OVDR.fbx"
OUT_DIR = pos[1] if len(pos) > 1 else os.path.dirname(SRC)
SEPARATE = "--separate" in argv
ARM_BONES_ONLY = "--arm-bones-only" in argv
SCALE_MODE = argv[argv.index("--scale-mode")+1] if "--scale-mode" in argv else "NONE"

KEEP = {"LeftArm_Geo", "RightArm_Geo"}
ARM_BONES = {"Root", "LowerTorso", "UpperTorso01", "UpperTorso02",
             "LeftUpperArm", "LeftLowerArm", "LeftHand", "LeftHand001",
             "RightUpperArm", "RightLowerArm", "RightHand", "RightHand001"}

def load():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=SRC)
    return next(o for o in bpy.data.objects if o.type == "ARMATURE")

def strip(arm, keep):
    for o in list(bpy.data.objects):
        if o.type == "MESH" and o.name not in keep:
            me = o.data
            bpy.data.objects.remove(o, do_unlink=True)
            if me.users == 0:
                bpy.data.meshes.remove(me)
    if ARM_BONES_ONLY:
        bpy.context.view_layer.objects.active = arm
        bpy.ops.object.mode_set(mode="EDIT")
        for b in list(arm.data.edit_bones):
            if b.name not in ARM_BONES:
                arm.data.edit_bones.remove(b)
        bpy.ops.object.mode_set(mode="OBJECT")

def export(path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in bpy.data.objects:
        o.select_set(True)
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True,
        object_types={"ARMATURE", "MESH"}, add_leaf_bones=False, bake_anim=False,
        use_mesh_modifiers=False, mesh_smooth_type="FACE",
        apply_scale_options="FBX_SCALE_" + SCALE_MODE, apply_unit_scale=True,
        use_armature_deform_only=False, path_mode="AUTO")
    print("EXPORTED", path, os.path.getsize(path))

suffix = "_armbones" if ARM_BONES_ONLY else ""
if SEPARATE:
    for side in ("Left", "Right"):
        arm = load(); strip(arm, {f"{side}Arm_Geo"})
        export(os.path.join(OUT_DIR, f"Mixamo_For_OVDR_{side}Arm{suffix}.fbx"))
else:
    arm = load(); strip(arm, KEEP)
    export(os.path.join(OUT_DIR, f"Mixamo_For_OVDR_Arms{suffix}.fbx"))
