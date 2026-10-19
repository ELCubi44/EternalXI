"""Lee medidas de la referencia sin modificar sus píxeles."""
from pathlib import Path
import bpy
import numpy as np

root = Path(__file__).resolve().parents[2]
image = bpy.data.images.load(str(root / 'docs/art/thiago-v2/character-turnaround-draft.png'))
w, h = image.size
pixels = np.asarray(image.pixels[:]).reshape(h, w, 4)[::-1]
print('REFERENCE', w, h)
for row in [20, 50, 80, 110, 140, 160, 180, 200, 220, 240, 260, 280, 300, 340, 380, 420, 460, 500, 540, 580, 620, 660, 700, 740, 780, 820, 860, 900, 940, 980]:
    output = []
    for left, right in [(0, 365), (380, 635), (650, 980)]:
        foreground = np.where(pixels[row, left:right, :3].min(axis=1) < .82)[0]
        output.append((int(foreground.min()+left), int(foreground.max()+left)) if len(foreground) else None)
    print(row, output)
