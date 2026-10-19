"""Construye una malla con UV de las referencias, pesos y una acción editable.

Ejecutar con Blender 4.5 --background --factory-startup --python este_archivo.
No modifica los PNG de referencia. Las partes y los pesos quedan editables.
"""
from pathlib import Path
from math import pi, sin, cos
import json
import bpy
import numpy as np
from mathutils import Vector
from mathutils.geometry import tessellate_polygon
from collections import deque
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'eternalclash_godot/art/models/thiago'
SOURCE = ROOT / 'art_source/thiago'
REVIEW = ROOT / 'docs/art/thiago-v2/model-review'
for folder in (OUT, SOURCE, REVIEW):
    folder.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 16
scene.render.resolution_x = 720
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.view_settings.view_transform = 'Standard'
scene.world.color = (.13, .15, .2)
scene.render.film_transparent = False
scene.render.fps = 30
scene.frame_end = 150

sheet = bpy.data.images.load(str(ROOT / 'docs/art/thiago-v2/character-turnaround-draft.png'))
sheet.pack()
W, H = sheet.size
pixels = np.asarray(sheet.pixels[:]).reshape(H, W, 4)[::-1]
S = 535.0
CX, FLOOR, PROFILE, BACK = 188.0, 984.0, 519.0, 825.0

def coords(px, py, depth=0):
    return Vector(((px-CX)/S, depth, (FLOOR-py)/S))

def material(name, color=None, image=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    output = nodes.new('ShaderNodeOutputMaterial')
    emission = nodes.new('ShaderNodeEmission')
    emission.inputs['Strength'].default_value = 1
    if image:
        tex = nodes.new('ShaderNodeTexImage')
        tex.image = image
        tex.interpolation = 'Linear'
        mat.node_tree.links.new(tex.outputs['Color'], emission.inputs['Color'])
    else:
        # Tres bandas de color para volumen anime sin reflejo de plástico.
        mat.diffuse_color=(*color,1)
        geometry=nodes.new('ShaderNodeNewGeometry')
        dot=nodes.new('ShaderNodeVectorMath')
        dot.operation='DOT_PRODUCT'
        dot.inputs[1].default_value=(.35,-.65,.68)
        ramp=nodes.new('ShaderNodeValToRGB')
        ramp.color_ramp.interpolation='CONSTANT'
        ramp.color_ramp.elements[0].position=0
        ramp.color_ramp.elements[0].color=(.58,.58,.62,1)
        ramp.color_ramp.elements[1].position=.55
        ramp.color_ramp.elements[1].color=(1,1,1,1)
        mid=ramp.color_ramp.elements.new(.20)
        mid.color=(.82,.82,.86,1)
        multiply=nodes.new('ShaderNodeMixRGB')
        multiply.blend_type='MULTIPLY'
        multiply.inputs[0].default_value=1
        multiply.inputs[1].default_value=(*color,1)
        mat.node_tree.links.new(geometry.outputs['Normal'],dot.inputs[0])
        mat.node_tree.links.new(dot.outputs['Value'],ramp.inputs['Fac'])
        mat.node_tree.links.new(ramp.outputs['Color'],multiply.inputs[2])
        mat.node_tree.links.new(multiply.outputs[0],emission.inputs['Color'])
    mat.node_tree.links.new(emission.outputs[0], output.inputs['Surface'])
    return mat

paint = material('Thiago_PaintedAnime', image=sheet)
skin = material('Skin', (.95,.48,.18))
hair_mat = material('Hair', (.095,.055,.027))
dark = material('BootSole', (.025,.045,.075))
blue = material('KitBlue',(.002,.045,.31))
gold = material('KitGold',(1,.58,.02))
white = material('KitWhite',(.93,.95,1))
meshes = []

def bounds(py, lo, hi, edge=None):
    found = np.where(pixels[int(py),lo:hi,:3].min(axis=1)<.82)[0]
    if len(found)<2:
        return None
    if edge:
        groups=np.split(found,np.where(np.diff(found)>4)[0]+1)
        groups=[group for group in groups if len(group)>4]
        if groups:
            found=groups[0] if edge=='min' else groups[-1]
    return (float(found.min()+lo),float(found.max()+lo))

def make_mesh(name, verts, faces, uv_mode='project', mat=paint):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    data.materials.append(mat)
    for extra in [skin,blue,gold,white,dark]:
        data.materials.append(extra)
    uv = data.uv_layers.new(name='ReferenceProjection')
    for polygon in data.polygons:
        polygon.use_smooth = True
        mean_y = sum(verts[v][1] for v in polygon.vertices)/len(polygon.vertices)
        # La vista posterior invierte X; costura UV separada en los laterales.
        back = mean_y>0 and uv_mode!='front'
        mean_z=sum(verts[v][2] for v in polygon.vertices)/len(polygon.vertices)
        at_py=FLOOR-mean_z*S
        lateral=abs(polygon.normal.x)>.65
        if mat==paint:
            chosen=None
            if name.startswith('Arm'):
                chosen=blue if at_py<363 else gold if at_py<372 else skin
                if at_py<363 and not lateral and mean_y<-.02:
                    chosen=None
            elif name.startswith('Leg'):
                chosen=blue if at_py<646 else gold if at_py<653 else skin if at_py<722 else white if at_py<737 else gold if at_py<748 else white if at_py<757 else blue
            elif name.startswith('Boot'):
                chosen=dark
            elif name=='HeadFace' and (abs(sum(verts[v][0] for v in polygon.vertices)/len(polygon.vertices))>.080 or back):
                chosen=skin
            elif (name.startswith('Shirt') or name.startswith('Shorts')) and (lateral or back):
                chosen=blue
            if chosen:
                polygon.material_index=list(data.materials).index(chosen)
        for loop in polygon.loop_indices:
            x,y,z = verts[data.loops[loop].vertex_index]
            py = FLOOR-z*S
            px = BACK-x*S if back else CX+x*S
            if name=='HeadFace' and back:
                # Parte posterior de la cabeza, oculta bajo el pelo.
                px=190
                py=190
            # No proyectar papel blanco de la lámina sobre bordes de la malla.
            iy=max(0,min(H-1,int(py)))
            ix=max(0,min(W-1,int(px)))
            threshold=.12 if name=='HeadHairFront' else .94
            if pixels[iy,ix,:3].min()>threshold:
                found=None
                for radius in range(1,18):
                    left,right=max(0,ix-radius),min(W,ix+radius+1)
                    cutoff=.10 if name=='HeadHairFront' else .88
                    candidates=np.where(pixels[iy,left:right,:3].min(axis=1)<cutoff)[0]
                    if len(candidates):
                        found=float(candidates[np.argmin(abs(candidates+left-ix))]+left)
                        break
                if found is not None:
                    px=found
            uv.data[loop].uv = ((px+.5)/W, 1-(py+.5)/H)
    meshes.append(obj)
    return obj

def loft(name, rings, segments=40, mat=paint):
    # Cada sección describe centro X/Y/Z y radios frontal/lateral.
    verts, faces = [], []
    for x,y,z,rx,ry in rings:
        for i in range(segments):
            angle = i*2*pi/segments
            verts.append((x+rx*cos(angle),y+ry*sin(angle),z))
    for r in range(len(rings)-1):
        for i in range(segments):
            a = r*segments+i
            b = r*segments+(i+1)%segments
            faces.append((a,a+segments,b+segments,b))
    faces.extend([tuple(range(segments)),tuple((len(rings)-1)*segments+i for i in reversed(range(segments)))])
    return make_mesh(name,verts,faces,mat=mat)

def painted_loft(name, rows, region, depth, center_y=0, segments=40):
    rings = []
    for py in rows:
        lo, hi = region(py) if callable(region) else region
        edge=('min' if name.endswith('.R') else 'max') if name.startswith('Arm') and py>380 else None
        span = bounds(py,lo,hi,edge)
        if not span:
            continue
        left,right = span
        # Un píxel hacia dentro evita arrastrar el papel de la lámina al borde.
        x = ((left+right)/2-CX)/S
        radius = max(1,(right-left)/2-1)/S
        d = depth(py) if callable(depth) else depth
        cy = center_y(py) if callable(center_y) else center_y
        rings.append((x,cy,(FLOOR-py)/S,radius,d))
    return loft(name,rings,segments)

# Cuello y torso: anillos de quads con secciones anatómicas, no cilindros rígidos.
torso_rows = [(228,174,207,.035),(240,151,230,.045),(258,106,273,.062),
              (280,95,280,.074),(310,93,282,.078),(350,91,282,.079),
              (400,90,284,.077),(450,88,285,.073),(490,87,285,.071),
              (518,87,286,.072),(535,89,285,.074)]
loft('ShirtAndNeck', [(((l+r)/2-CX)/S,0,(FLOOR-py)/S,(r-l)/2/S,d) for py,l,r,d in torso_rows])
loft('ShortsPelvis',[(0,0,(FLOOR-py)/S,rx,ry) for py,rx,ry in [(512,.18,.077),(540,.19,.083),(565,.185,.087),(585,.172,.085)]])

for side,region in [('R',(0,181)),('L',(192,365))]:
    def leg_region(py, side=side):
        return (74,181) if side=='R' and py<615 else (192,300) if side=='L' and py<615 else ((0,181) if side=='R' else (192,365))
    painted_loft('Leg.'+side,range(563,908,8),leg_region,lambda py:.070 if py<655 else .049 if py<740 else .045)
    painted_loft('Boot.'+side,list(range(902,979,4))+[981],region,lambda py:.075 if py<925 else .12,lambda py:-.02 if py<925 else -.045)

for side,region in [('R',(0,104)),('L',(278,365))]:
    painted_loft('Arm.'+side,range(267,554,5),region,lambda py:.052 if py<355 else .032)
    sign=1 if side=='L' else -1
    wrist=bounds(550,*region,edge='min' if side=='R' else 'max')
    hand_x=((wrist[0]+wrist[1])/2-CX)/S
    loft('ArmPalm.'+side,[(hand_x,0,z,rx,ry) for z,rx,ry in [(.805,.026,.025),(.778,.034,.026),(.748,.032,.023),(.728,.026,.020)]],20,mat=skin)
    for finger in range(4):
        fx=hand_x+(finger-1.5)*.014
        length=[.046,.056,.052,.040][finger]
        loft('ArmFinger%d.'%finger+side,[(fx,0,.742,.008,.009),(fx,0,.72,.008,.009),(fx,-.005,.742-length,.006,.007),(fx,-.005,.738-length,.002,.003)],12,mat=skin)
    loft('ArmThumb.'+side,[(hand_x-sign*.029,-.002,.772,.012,.012),(hand_x-sign*.043,-.008,.750,.011,.011),(hand_x-sign*.043,-.010,.729,.006,.007)],12,mat=skin)

# Cabeza suave separada del cabello. Los mechones no se reconstruyen como
# secciones horizontales: eso producía salientes y discontinuidades al girar.
face_rows=[(108,147,234,.115),(120,133,248,.13),(140,125,254,.145),
           (160,125,254,.148),(180,129,250,.145),(196,141,239,.13),
           (209,158,223,.105),(219,175,207,.07),(226,179,203,.05)]
head=loft('HeadFace',[(((l+r)/2-CX)/S,0,(FLOOR-py)/S,(r-l)/2/S,d) for py,l,r,d in face_rows],64)
make_mesh('HeadNose',[(0,-.177,1.487),(-.012,-.137,1.498),(.012,-.137,1.498),(0,-.14,1.515)],[(0,1,2),(0,3,1),(0,2,3),(1,3,2)],mat=skin)
for side in [-1,1]:
    loft('HeadEar'+str(side),[(side*.117,-.005,1.55,.008,.015),(side*.126,-.003,1.53,.016,.025),(side*.124,-.005,1.49,.013,.020),(side*.114,-.008,1.475,.007,.011)],20,mat=skin)

# Caparazón de pelo con silueta explícita y volumen posterior. Frente con
# la pintura original de la lámina; laterales y reverso de color castaño.
def trace_hair():
    global hair_pixels
    rgb=pixels[:205,:365,:3]
    r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    mask=(r>g*1.15)&(g>b*1.08)&(r<.40)
    mask[:,:65]=False
    mask[:,315:]=False
    mask[195:]=False
    # Separar explícitamente el pelo de cejas/iris, que comparten su marrón.
    mask[151:,132:249]=False
    # Rellenar el grosor del contorno negro para mantener unidos los mechones.
    base=mask.copy()
    for dy in [-1,0,1]:
        for dx in [-1,0,1]:
            mask |= np.roll(np.roll(base,dy,axis=0),dx,axis=1)
    mask[151:,132:249]=False
    remaining=set(zip(*np.where(mask)))
    largest=set()
    while remaining:
        seed=remaining.pop()
        group={seed}
        queue=deque([seed])
        while queue:
            y,x=queue.popleft()
            for neighbour in [(y-1,x),(y+1,x),(y,x-1),(y,x+1)]:
                if neighbour in remaining:
                    remaining.remove(neighbour)
                    group.add(neighbour)
                    queue.append(neighbour)
        if len(group)>len(largest):
            largest=group
    edges={}
    for y,x in largest:
        for neighbour,a,b in [((y-1,x),(x,y),(x+1,y)),((y,x+1),(x+1,y),(x+1,y+1)),((y+1,x),(x+1,y+1),(x,y+1)),((y,x-1),(x,y+1),(x,y))]:
            if neighbour not in largest:
                edges.setdefault(a,[]).append(b)
    contours=[]
    while edges:
        start=next(iter(edges))
        current=start
        points=[]
        while True:
            points.append(current)
            options=edges.get(current)
            if not options:
                break
            nxt=options.pop()
            if not options:
                del edges[current]
            current=nxt
            if current==start:
                break
        contours.append(points)
    outline=max(contours,key=len)
    # Quitar vértices colineales; conserva entrantes y puntas de la silueta.
    simple=[]
    for i,p in enumerate(outline):
        before=outline[i-1]
        after=outline[(i+1)%len(outline)]
        if (p[0]-before[0],p[1]-before[1])!=(after[0]-p[0],after[1]-p[1]):
            simple.append(p)
    print('HAIR_CONTOUR',len(simple),len(largest))
    hair_pixels=largest
    return simple
hair_outline=trace_hair()
# Superficie de quads curvada sobre el volumen; conserva la pintura sin una
# tarjeta plana delante de la cabeza. Se omiten celdas fuera del pelo.
front_vertices=[]
front_faces=[]
vertex_map={}
def hair_vertex(px,py):
    key=(px,py)
    if key in vertex_map:
        return vertex_map[key]
    l,r=bounds(py,65,315) or (130,250)
    p,q=bounds(py,380,635) or (450,580)
    normalized=max(-1,min(1,(px-(l+r)/2)/max(1,(r-l)/2)))
    y=((p+q)/2-PROFILE)/S-(q-p)/2/S*max(0,1-normalized*normalized)**.5-.003
    idx=len(front_vertices)
    front_vertices.append(((px-CX)/S,y,(FLOOR-py)/S))
    vertex_map[key]=idx
    return idx
for py in range(17,194,2):
    for px in range(70,311,2):
        corners=[(px,py),(px+2,py),(px+2,py+2),(px,py+2)]
        if all((y,x) in hair_pixels for x,y in corners):
            front_faces.append(tuple(hair_vertex(x,y) for x,y in corners))
hair_front=make_mesh('HeadHairFront',front_vertices,front_faces,uv_mode='front')
import bmesh
bm=bmesh.new()
bm.from_mesh(hair_front.data)
for face in bm.faces:
    if face.normal.y>0:
        face.normal_flip()
bm.to_mesh(hair_front.data)
bm.free()
volume_rings=[]
for py in range(23,195,4):
    front=bounds(py,65,315)
    profile=bounds(py,380,635)
    if not front or not profile:
        continue
    l,r=front
    p,q=profile
    volume_rings.append((((l+r)/2-CX)/S,((p+q)/2-PROFILE)/S,(FLOOR-py)/S,(r-l)/2/S,(q-p)/2/S))
volume=loft('HeadHairVolume',volume_rings,64,mat=hair_mat)
import bmesh
bm=bmesh.new()
bm.from_mesh(volume.data)
remove=[f for f in bm.faces if f.normal.y<-.001]
bmesh.ops.delete(bm,geom=remove,context='FACES')
bm.to_mesh(volume.data)
bm.free()

# Esqueleto humano común. Los pesos se mezclan alrededor de cada articulación.
arm_data = bpy.data.armatures.new('EternalXI_Humanoid')
rig = bpy.data.objects.new('ThiagoRig',arm_data)
scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
bones = {}
def bone(name, head, tail, parent=None):
    b = arm_data.edit_bones.new(name)
    b.head,b.tail = head,tail
    if parent:
        b.parent = bones[parent]
    bones[name] = b
bone('Root',(0,0,0),(0,0,.15))
bone('Hips',(0,0,.76),(0,0,.89),'Root')
bone('Spine',(0,0,.89),(0,0,1.10),'Hips')
bone('Chest',(0,0,1.10),(0,0,1.34),'Spine')
bone('Neck',(0,0,1.34),(0,0,1.42),'Chest')
bone('Head',(0,0,1.42),(0,0,1.72),'Neck')
for suffix,sign in [('L',1),('R',-1)]:
    bone('UpperArm.'+suffix,(sign*.18,0,1.32),(sign*.235,0,1.04),'Chest')
    bone('Forearm.'+suffix,(sign*.235,0,1.04),(sign*.275,0,.79),'UpperArm.'+suffix)
    bone('Hand.'+suffix,(sign*.275,0,.79),(sign*.275,0,.71),'Forearm.'+suffix)
    bone('Thigh.'+suffix,(sign*.10,0,.79),(sign*.135,0,.50),'Hips')
    bone('Shin.'+suffix,(sign*.135,0,.50),(sign*.145,0,.15),'Thigh.'+suffix)
    bone('Foot.'+suffix,(sign*.145,0,.15),(sign*.145,-.16,.08),'Shin.'+suffix)
bpy.ops.object.mode_set(mode='OBJECT')

def blend_weights(z, upper, lower, joint_z, width=.055):
    factor = max(0,min(1,(z-joint_z+width)/(2*width)))
    return {upper:factor,lower:1-factor}

for obj in meshes:
    obj.parent = rig
    mod = obj.modifiers.new('HumanoidSkin','ARMATURE')
    mod.object = rig
    mod.use_deform_preserve_volume = True
    groups = {b.name:obj.vertex_groups.new(name=b.name) for b in arm_data.bones}
    for vertex in obj.data.vertices:
        x,y,z = vertex.co
        if obj.name.startswith('Head'):
            weights={'Head':1}
        elif obj.name.startswith('Arm'):
            suffix=obj.name[-1]
            weights = blend_weights(z,'UpperArm.'+suffix,'Forearm.'+suffix,1.04) if z>.85 else blend_weights(z,'Forearm.'+suffix,'Hand.'+suffix,.79,.025)
        elif obj.name.startswith('Leg') or obj.name.startswith('Boot'):
            suffix=obj.name[-1]
            weights=blend_weights(z,'Thigh.'+suffix,'Shin.'+suffix,.50) if z>.24 else blend_weights(z,'Shin.'+suffix,'Foot.'+suffix,.15,.035)
        elif obj.name.startswith('Shorts'):
            weights={'Hips':1}
        elif z>1.34:
            weights=blend_weights(z,'Head','Chest',1.38,.035)
        elif z>1.02:
            weights=blend_weights(z,'Chest','Spine',1.10,.08)
        else:
            weights=blend_weights(z,'Spine','Hips',.89,.06)
        for name,value in weights.items():
            if value>0:
                groups[name].add([vertex.index],value,'REPLACE')

# Acción editable con anticipación, recogida de pierna, contacto y recuperación.
from math import radians
poses = [
 (1,{}),
 (25,{'Chest':(5,0,-10),'UpperArm.L':(-10,0,-25),'UpperArm.R':(15,0,25)}),
 (50,{'Hips':(0,0,-15),'Chest':(18,0,-20),'Thigh.R':(-32,0,0),'Shin.R':(70,0,0),'UpperArm.L':(-40,0,-35),'UpperArm.R':(35,0,40)}),
 (68,{'Hips':(0,0,8),'Chest':(-8,0,18),'Thigh.R':(75,0,0),'Shin.R':(8,0,0),'UpperArm.L':(20,0,-60),'UpperArm.R':(-35,0,50)}),
 (82,{'Hips':(0,0,20),'Chest':(8,0,25),'Thigh.R':(100,0,0),'Shin.R':(24,0,0),'UpperArm.L':(35,0,-45),'UpperArm.R':(-45,0,40)}),
 (112,{'Chest':(0,0,10),'Thigh.R':(12,0,0),'UpperArm.L':(0,0,-20),'UpperArm.R':(0,0,20)}),
 (150,{})]
for frame, pose in poses:
    for pb in rig.pose.bones:
        pb.rotation_mode='XYZ'
        values=list(pose.get(pb.name,(0,0,0)))
        if pb.name=='Thigh.R':
            values[0] *= -1
        pb.rotation_euler=tuple(radians(v) for v in values)
        pb.keyframe_insert('rotation_euler',frame=frame,group=pb.name)
rig.animation_data.action.name='Disparo_Valestia'
scene.frame_set(1)

# Referencias editables en una colección aparte; no se exportan como geometría.
refs = bpy.data.collections.new('References_NotForExport')
scene.collection.children.link(refs)
ref = bpy.data.objects.new('OriginalTurnaround',None)
ref.empty_display_type='IMAGE'
ref.data=sheet
ref.empty_display_size=2.8
ref.hide_render=True
ref.hide_viewport=True
refs.objects.link(ref)

camera_data=bpy.data.cameras.new('ReviewCamera')
camera=bpy.data.objects.new('ReviewCamera',camera_data)
scene.collection.objects.link(camera)
scene.camera=camera
camera_data.type='ORTHO'
camera_data.ortho_scale=2.12
def point_camera(pos, target):
    camera.location=pos
    camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()

for name,pos in [('front',(0,-5,1.0)),('three-quarter',(2,-5,1.05)),('profile',(5,0,1.0)),('back',(0,5,1.0))]:
    point_camera(pos,(0,0,.90))
    scene.render.filepath=str(REVIEW/(name+'.png'))
    bpy.ops.render.render(write_still=True)

point_camera((1.3,-4,1.4),(0,0,1))
scene.frame_set(68)
scene.render.filepath=str(REVIEW/'kick.png')
bpy.ops.render.render(write_still=True)
scene.frame_set(1)

bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
for obj in meshes:
    obj.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'thiago.blend'))
# glTF no transporta la red de nodos toon de Blender. Exportar colores base
# explícitos: el motor puede aplicar sus bandas sobre esos colores sin blanco.
export_palette={}
for source_mat in [skin,hair_mat,dark,blue,gold,white]:
    export_mat=bpy.data.materials.new(source_mat.name+'_GLTF')
    export_mat.diffuse_color=source_mat.diffuse_color
    export_mat.use_nodes=True
    bsdf=export_mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value=source_mat.diffuse_color
    bsdf.inputs['Roughness'].default_value=1
    export_palette[source_mat.name]=export_mat
saved_slots={}
for obj in meshes:
    saved_slots[obj.name]=list(obj.data.materials)
    for idx,mat in enumerate(obj.data.materials):
        if mat.name in export_palette:
            obj.data.materials[idx]=export_palette[mat.name]
bpy.ops.export_scene.gltf(filepath=str(OUT/'thiago.glb'),export_format='GLB',use_selection=True,export_animations=True,export_skins=True,export_force_sampling=True,export_yup=True)
for obj in meshes:
    for idx,mat in enumerate(saved_slots[obj.name]):
        obj.data.materials[idx]=mat
manifest={'blender':bpy.app.version_string,'vertices':sum(len(o.data.vertices) for o in meshes),'mesh_objects':len(meshes),'bones':len(arm_data.bones),'action':'Disparo_Valestia','reference':'docs/art/thiago-v2/character-turnaround-draft.png','status':'work_in_progress_requires_visual_review'}
(SOURCE/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('THIAGO_MODEL',json.dumps(manifest))

if '--film' in sys.argv:
    # Ensayo, no secuencia final: cámara y balón siguen la acción del esqueleto.
    scene.render.resolution_x=540
    scene.render.resolution_y=960
    scene.cycles.samples=8
    scene.frame_end=150
    camera_data.type='PERSP'
    camera_data.lens=43
    camera.animation_data_clear()
    for frame,pos,target in [(1,(.06,-2.35,1.65),(0,0,1.51)),(23,(.08,-2.35,1.65),(0,0,1.51)),(39,(.25,-3.25,1.28),(0,0,.91)),(63,(.32,-3.4,1.12),(0,-.05,.92)),(72,(.37,-3.5,1.0),(0,-.1,.94)),(103,(.45,-3.6,1.2),(0,-.08,1.0)),(150,(.3,-3.45,1.3),(0,0,.95))]:
        point_camera(pos,target)
        camera.keyframe_insert('location',frame=frame)
        camera.keyframe_insert('rotation_euler',frame=frame)
    scene.frame_set(68)
    contact=rig.matrix_world@rig.pose.bones['Foot.R'].tail+Vector((0,-.09,0))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,radius=.09,location=(0,0,0))
    ball=bpy.context.object
    ball.name='ReviewBall'
    ball.data.materials.append(white)
    ball.data.materials.append(dark)
    for poly in ball.data.polygons:
        poly.material_index=1 if poly.index%17<3 else 0
        poly.use_smooth=True
    for frame,pos in [(1,(-.15,-.23,.09)),(45,(-.15,-.23,.09)),(63,tuple(contact+Vector((0,.08,-.06)))),(68,tuple(contact)),(90,tuple(contact+Vector((0,-6,1.3)))),(150,tuple(contact+Vector((0,-12,2.5))))]:
        ball.location=pos
        ball.rotation_euler=(frame*.08,frame*.12,frame*.06)
        ball.keyframe_insert('location',frame=frame)
        ball.keyframe_insert('rotation_euler',frame=frame)
    scene.render.image_settings.file_format='FFMPEG'
    scene.render.ffmpeg.format='MPEG4'
    scene.render.ffmpeg.codec='H264'
    scene.render.ffmpeg.constant_rate_factor='MEDIUM'
    scene.render.filepath=str(REVIEW/'valestia-motion-review.mp4')
    bpy.ops.render.render(animation=True)
