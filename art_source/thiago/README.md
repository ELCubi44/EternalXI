# Thiago — modelo en desarrollo

Actualizado: 2026-10-19. **No aprobado para sustituir el arte del juego.**

- `thiago.blend`: editable Blender 4.5.3, con referencia empaquetada, mallas, materiales de tres bandas, pesos, 18 huesos y acción `Disparo_Valestia`.
- `manifest.json`: medidas generadas del activo. No significa que haya superado la revisión artística.
- GLB: `eternalclash_godot/art/models/thiago/thiago.glb`, con skin/animación y texturas embebidas. Las redes toon específicas de Blender se sustituyen por colores base compatibles al exportar. El GLB no contiene automáticamente el sombreado toon de Blender.
- Renders/vídeo: `docs/art/thiago-v2/model-review/`. Son material de revisión de una reconstrucción, no una cinemática final del juego.

## Reconstruir y comprobar

Desde la raíz del repositorio:

```powershell
./scripts/build_thiago_art.ps1
./scripts/build_thiago_art.ps1 -Film
```

Requiere Blender 4.5 y Godot 4.7.2. Se pueden indicar `-BlenderPath` y `-GodotPath`. El script resuelve la ruta física de Blender porque la virtualización de LocalAppData en la aplicación de escritorio impedía al cargador de Windows encontrar `blender.crt`.

Blender portátil se obtuvo del directorio oficial `https://download.blender.org/release/Blender4.5/`, versión 4.5.3 Windows x64, y se verificó contra `blender-4.5.3.sha256`. Herramientas y descargas se mantienen fuera del repositorio. No se modifica la configuración de seguridad de Windows.

La reconstrucción conserva los píxeles de las referencias. Se construyen superficies y UV a partir de medidas/proyección de la lámina, una superficie curva para la pintura frontal del pelo, piezas de manos y una jerarquía con pesos mezclados. **Este procedimiento todavía no genera un modelo anime terminado ni una topología facial de producción.**

La validación de Blender comprueba geometría finita, pesos normalizados, influencias acotadas, acción, colores exportados y texturas empaquetadas. `tests/test_thiago_import.gd` comprueba la importación real en Godot y cambios de pose de huesos. No valida parecido, deformación anatómica correcta o diversión.

## Estado visual y trabajo pendiente

El frontal conserva más rasgos de la ilustración, pero siguen apareciendo discontinuidades de UV en pelo/mejillas y el perfil no reproduce todavía su silueta. La transición cuello/cara, hombros, muñecas, rodillas y calzado necesita modelado y acabado. No hay controles faciales ni expresiones animadas.

El vídeo `valestia-motion-review.mp4` tiene 150 fotogramas, 30 FPS, 540×960 y 5 segundos. Muestra un ensayo de patada, cámara y balón para detectar problemas. No tiene la coreografía, puesta en escena, efectos o calidad del vídeo que pidió el usuario. Se han inspeccionado fotogramas decodificados del propio MP4, incluidos preparación, contacto y recuperación; no es una secuencia de ilustraciones fijas.

El activo está **excluido de la exportación Android** mediante `export_presets.cfg` y no se carga desde la interfaz ni desde los partidos. La APK instalada conserva 0.4. No se modifica el progreso del usuario ni los clientes Flutter/API.

Siguiente paso artístico: rehacer las zonas problemáticas con topología/UV adecuadas, establecer una malla facial con expresiones y comprobar otra vez frontal/perfil/tres cuartos. Solo después adaptar la coreografía completa y evaluar en Android. No confundir pasar la prueba de importación con alcanzar la calidad solicitada.
