"""Extrae fotogramas del vídeo renderizado para QA, sin modificarlo."""
from pathlib import Path
import json
import tempfile
import bpy

root=Path(__file__).resolve().parents[2]
film=root/'docs/art/thiago-v2/model-review/valestia-motion-review.mp4'
output=Path(tempfile.gettempdir())/'clash-thiago-film-review'
output.mkdir(exist_ok=True)
scene=bpy.context.scene
editor=scene.sequence_editor_create()
collection=editor.strips
strip=collection.new_movie('ThiagoReview',str(film),channel=1,frame_start=1)
scene.render.engine='CYCLES'
scene.cycles.samples=1
scene.render.resolution_x=540
scene.render.resolution_y=960
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.use_sequencer=True
scene.view_settings.view_transform='Standard'
for frame in [20,50,68,90,140]:
    scene.frame_set(frame)
    scene.render.filepath=str(output/f'frame-{frame:03}.png')
    bpy.ops.render.render(write_still=True)
print('THIAGO_FILM',json.dumps({'frames':strip.frame_duration,'width':strip.elements[0].orig_width,'height':strip.elements[0].orig_height,'review_frames':str(output)}))
assert strip.frame_duration==150
assert strip.elements[0].orig_width==540 and strip.elements[0].orig_height==960
