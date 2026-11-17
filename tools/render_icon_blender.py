import bpy, math
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
sc = bpy.context.scene

def mat(name, rgb, emit=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1); b.inputs["Roughness"].default_value = 0.45
    if emit:
        b.inputs["Emission Color"].default_value = (*rgb, 1); b.inputs["Emission Strength"].default_value = emit
    return m

def cube(name, loc, size, m):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object; o.name = name; o.scale = (size[0]/2, size[1]/2, size[2]/2)
    bpy.ops.object.transform_apply(scale=True)
    bev = o.modifiers.new("bev", "BEVEL"); bev.width = 0.08; bev.segments = 3
    o.data.materials.append(m); return o

def srgb(r, g, b): return tuple(((c/255 + 0.055)/1.055)**2.4 for c in (r, g, b))

cols = [(255,89,94),(255,146,76),(255,202,58),(138,201,38),(82,196,160),(25,130,196),(106,76,147)]
cube("Ground", (0, 3, -0.25), (30, 30, 0.5), mat("grass", srgb(99,176,88)))
for i, c in enumerate(cols):
    h = 1.0 + i * 1.3
    cube(f"Wall{i}", (1.5, i * 2.2, h/2), (6, 0.8, h), mat(f"w{i}", srgb(*c)))
    cube(f"Trim{i}", (1.5, i * 2.2, h + 0.08), (6.1, 0.9, 0.16), mat(f"t{i}", (1,1,1), 2.0))

skin, shirt, pants = mat("skin", srgb(255,205,60)), mat("shirt", srgb(30,120,255)), mat("pants", srgb(40,40,60))
cx, cy, cz = -5.2, -2.0, 5.2
S = 1.5
cube("Torso", (cx, cy, cz), (2.0*S, 1.0*S, 2.0*S), shirt)
cube("Head", (cx, cy, cz + 1.65*S), (1.2*S, 1.2*S, 1.2*S), skin)
cube("ArmL", (cx - 1.5*S, cy, cz + 1.4*S), (1.0*S, 1.0*S, 2.0*S), skin)
cube("ArmR", (cx + 1.5*S, cy, cz + 1.4*S), (1.0*S, 1.0*S, 2.0*S), skin)
cube("LegL", (cx - 0.5*S, cy, cz - 1.9*S), (0.95*S, 1.0*S, 1.8*S), pants)
cube("LegR", (cx + 0.5*S, cy, cz - 1.9*S), (0.95*S, 1.0*S, 1.8*S), pants)
bpy.ops.object.text_add(location=(0.4, -3.2, 10.6), rotation=(math.radians(80), 0, 0))
t = bpy.context.object; t.data.body = "+1 JUMP"; t.data.align_x = "CENTER"
t.data.size = 2.6; t.data.extrude = 0.35; t.data.bevel_depth = 0.06; t.data.space_character = 1.05
t.data.materials.append(mat("gold", srgb(255,215,0), 0.4))
bpy.ops.object.text_add(location=(0.4, -3.4, 8.7), rotation=(math.radians(80), 0, 0))
t2 = bpy.context.object; t2.data.body = "EVERY SECOND"; t2.data.align_x = "CENTER"
t2.data.size = 1.05; t2.data.extrude = 0.2; t2.data.bevel_depth = 0.04
t2.data.materials.append(mat("white", (1,1,1), 0.3))

bpy.ops.object.camera_add(location=(0.4, -20, 6.8), rotation=(math.radians(88), 0, 0))
cam = bpy.context.object; cam.data.lens = 38; sc.camera = cam
bpy.ops.object.light_add(type="SUN", rotation=(math.radians(50), math.radians(-20), math.radians(30)))
bpy.context.object.data.energy = 4.0

w = bpy.data.worlds.new("sky"); sc.world = w; w.use_nodes = True
nt = w.node_tree; bg = nt.nodes["Background"]
grad = nt.nodes.new("ShaderNodeTexGradient"); ramp = nt.nodes.new("ShaderNodeValToRGB")
coord = nt.nodes.new("ShaderNodeTexCoord"); mapn = nt.nodes.new("ShaderNodeMapping")
mapn.inputs["Rotation"].default_value = (0, math.radians(-90), 0)
nt.links.new(coord.outputs["Generated"], mapn.inputs["Vector"]); nt.links.new(mapn.outputs["Vector"], grad.inputs["Vector"])
nt.links.new(grad.outputs["Fac"], ramp.inputs["Fac"]); nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
ramp.color_ramp.elements[0].color = (*srgb(120,200,255), 1); ramp.color_ramp.elements[1].color = (*srgb(20,70,200), 1)
bg.inputs["Strength"].default_value = 1.2

sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
sc.render.resolution_x = sc.render.resolution_y = 1024
sc.view_settings.view_transform = "Standard"
sc.render.filepath = "/Users/macbook/Documents/Projects/roblox-plus1jump/icon.png"
bpy.ops.render.render(write_still=True)
for n in ("Torso","Head","ArmL","ArmR","LegL","LegR"):
    pass
print("rendered", sc.render.engine)
