"""Valida el archivo editable y su GLB. No evalúa parecido ni calidad artística."""
from pathlib import Path
import json
import math
import struct
import bpy

root=Path(__file__).resolve().parents[2]
rig=bpy.data.objects.get('ThiagoRig')
assert rig is not None and rig.type=='ARMATURE'
assert len(rig.data.bones)==18
meshes=[obj for obj in bpy.data.objects if obj.type=='MESH' and obj.parent==rig]
assert len(meshes)>=20
vertices=0
for obj in meshes:
    assert any(mod.type=='ARMATURE' and mod.object==rig for mod in obj.modifiers),obj.name
    assert obj.data.uv_layers.active is not None,obj.name
    assert all(image.packed_file for image in bpy.data.images if image.source=='FILE' and image.name!='Render Result')
    for vertex in obj.data.vertices:
        assert all(math.isfinite(value) for value in vertex.co),obj.name
        total=sum(group.weight for group in vertex.groups)
        assert abs(total-1)<1e-5,(obj.name,vertex.index,total)
        assert 1<=len(vertex.groups)<=4
        vertices+=1
assert vertices<40000
action=rig.animation_data.action
assert action.name=='Disparo_Valestia'
scene=bpy.context.scene
scene.frame_set(1)
rest=rig.pose.bones['Thigh.R'].matrix.copy()
scene.frame_set(68)
delta=rig.pose.bones['Thigh.R'].matrix-rest
assert max(abs(value) for row in delta for value in row)>0.1
scene.frame_set(1)
binary=(root/'eternalclash_godot/art/models/thiago/thiago.glb').read_bytes()
assert binary[:4]==b'glTF'
length=struct.unpack_from('<I',binary,12)[0]
gltf=json.loads(binary[20:20+length])
assert len(gltf['skins'])==1
assert len(gltf['skins'][0]['joints'])==18
assert any(animation['name']=='Disparo_Valestia' for animation in gltf['animations'])
materials={material['name']:material for material in gltf['materials']}
for name in ['Skin_GLTF','KitBlue_GLTF','KitGold_GLTF','Hair_GLTF']:
    color=materials[name]['pbrMetallicRoughness']['baseColorFactor']
    assert color[:3]!=[1,1,1],(name,'color perdido en exportación')
assert all('uri' not in image for image in gltf['images']),'Texturas del GLB deben estar embebidas'
print(f'THIAGO_ASSET: {vertices} weighted vertices, {len(meshes)} meshes, 18 bones, animation, packed colors/textures; OK')
