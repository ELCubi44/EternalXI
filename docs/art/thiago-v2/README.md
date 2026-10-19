# Thiago: dirección artística revisada

Fecha inicial: 2026-10-15. Actualizado: 2026-10-19. Estado: desarrollo visual y modelo en curso, sin aprobación artística ni animación final terminada.

El usuario ha rechazado las figuras rígidas y las animaciones de la demo 0.4: no se parecen al retrato ni alcanzan el estilo de la referencia. No continuar ese acabado como solución artística final.

Referencia de animación facilitada por el usuario: https://www.youtube.com/watch?v=sIJTPFxqYFI — All Special Techniques inazuma eleven GO Galaxy (Hissatsu technique). Se han inspeccionado fragmentos en el navegador, no los 33 minutos completos. Usar como referencia de ritmo, actuación, planos y lenguaje audiovisual, no copiar sus personajes o recursos.

## Autoridad visual

La ilustración original `eternalclash_godot/art/portraits/434.png` define la identidad: cara, ojos, pelo y su silueta, edad aparente, proporciones anime, equipación, escudo y brazalete. Las imágenes generadas no sustituyen esa autoridad y pueden contener desviaciones que corregir. Ningún cuerpo de piezas geométricas ni cabeza genérica se acepta como equivalente al personaje de la ilustración.

## Archivos

- `character-turnaround-draft.png`: propuesta de cuerpo completo con frente, perfil, espalda y detalle de cara. Las partes no visibles en el original (espalda, pantalón, piernas y botas) son extrapolaciones. Revisar continuidad de todos los detalles entre vistas antes de modelar.
- `valestia-keyframes-draft.png`: cuatro imágenes clave propuestas para concentración, preparación/contacto, impacto y trayectoria. Son ilustraciones fijas de dirección visual, no fotogramas consecutivos suficientes para animación fluida ni una animación 3D.
- `prompts.md`: instrucciones usadas con la herramienta integrada de generación de imágenes. Sin API externa adicional ni claves.

## Producción pendiente

1. Ajustar el diseño de cuerpo completo hasta conservar la identidad y establecer detalles comunes entre vistas.
2. Crear un modelo anime con una malla orgánica y topología adecuada, cara/cabello/ropa fieles, texturas y sombreado cel. Verificar frontal, perfil y tres cuartos contra la ilustración antes de animarlo. Una hoja de vistas generada no es ese modelo.
3. Preparar un esqueleto común, pesos y controles de expresiones. Comprobar deformación de hombros, caderas, codos y rodillas; otras complexiones pueden necesitar adaptación.
4. Animar coreografía propia con anticipación, contacto del pie con el balón, impulso y recuperación; cámaras y efectos sincronizados. El storyboard no sustituye ese trabajo ni garantiza que las poses se puedan interpolar directamente.
5. En Godot, aplicar la técnica al modelo compatible del jugador. Verificar otra identidad con la misma coreografía y conservar las reglas de técnicas aprendidas.
6. Exportar/probar en Android y medir carga/FPS/memoria. No declarar una calidad equivalente a la referencia por tener una escena que funciona o por superar tests.

En la revisión inicial del 15 no se había creado un modelo ni vídeo. El 19 se continúa con un editable Blender, GLB con pesos y ensayo de movimiento de cinco segundos. Están en `art_source/thiago/` y `model-review/`, con comprobación de importación en Godot. **No superan todavía la revisión visual**: hay defectos de proyección del pelo/cara y falta acabar perfil, anatomía y expresiones. No se reemplaza la APK ni se consideran equivalentes al vídeo de referencia. Ver `art_source/thiago/README.md` para reconstrucción, pruebas y límites.
