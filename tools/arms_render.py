import bpy, math
from mathutils import Vector
bpy.ops.wm.read_factory_settings(use_empty=True)
sc=bpy.context.scene
bpy.ops.import_scene.fbx(filepath=r"C:\Work\Downloads\Mixamo_For_OVDR.fbx")
for o in list(bpy.data.objects):
    if o.type=="MESH": o.color=(0.7,0.7,0.7,1.0); o.name="ORIG_"+o.name
    else: o.name="ORIG_"+o.name
bpy.ops.import_scene.fbx(filepath=r"C:\Work\Downloads\Mixamo_For_OVDR_Arms.fbx")
for o in bpy.data.objects:
    if o.type=="MESH" and not o.name.startswith("ORIG_"): o.color=(1.0,0.1,0.1,1.0)
    if o.type=="ARMATURE" and not o.name.startswith("ORIG_"):
        # show result bones as small red spheres via empties -> use bone heads as UV spheres
        for b in o.data.bones:
            bpy.ops.mesh.primitive_uv_sphere_add(radius=0.012, location=o.matrix_world @ b.head_local)
            s=bpy.context.object; s.color=(0.1,0.3,1.0,1.0); s.name="BONE_"+b.name
sc.render.engine="BLENDER_WORKBENCH"; sh=sc.display.shading
sh.light="STUDIO"; sh.color_type="OBJECT"; sh.show_object_outline=True
sc.render.resolution_x=900; sc.render.resolution_y=1100
cam=bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera=cam
cam.data.type="ORTHO"; cam.data.ortho_scale=1.9
cam.location=(0,-5,0.85); cam.rotation_euler=(math.radians(90),0,0)
sc.render.filepath=r"C:\Work\blender\ovdr_export\arms_check_front.png"; bpy.ops.render.render(write_still=True)
cam.location=(-5,0,0.85); cam.rotation_euler=(math.radians(90),0,math.radians(-90))
sc.render.filepath=r"C:\Work\blender\ovdr_export\arms_check_side.png"; bpy.ops.render.render(write_still=True)
print("RENDER DONE")
