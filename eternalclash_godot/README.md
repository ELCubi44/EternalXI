# Eternal Clash — primera prueba Android

Proyecto independiente en Godot 4.7.2 / GDScript. El cliente Flutter y la API Spring originales no se sustituyen.

## Jugar

La app se llama **Eternal Clash Prueba**, identificador `es.eternalxi.clash.prototype`. No requiere cuenta ni conexión y puede coexistir con `es.eternalxi.app`.

- Inicio → Jugar partido: Eternal XI contra Bastion Adler, 7v7 táctico.
- Pase y regate avanzan hasta el área y cargan energía. El pase hace circular el balón entre los seis jugadores de campo.
- En el área se puede tirar o gastar 30 de energía en una supertécnica. La interfaz muestra su probabilidad antes de jugar.
- Replegar recupera 20 de energía y reduce el riesgo del ataque rival.
- Se termina con tres goles de uno de los equipos o tras 18 acciones; 100 monedas por victoria, 50 por empate/derrota.
- Equipo permite sustituir cartas y elegir capitán (+6 puntos de probabilidad). Portería solo admite porteros; las otras posiciones son libres en esta demo.
- Cartas permite mejorar por 50 × nivel monedas, hasta nivel 10. Los atributos del poseedor influyen en las probabilidades; portero y defensores influyen en el riesgo rival. No se puede entrenar/cambiar equipo durante el partido.
- El partido se guarda después de cada acción y puede continuarse desde Inicio al reabrir.

Se entregan las 19 cartas N de Eternal XI. Los 19 personajes de Adler actúan como catálogo rival; su formación de siete es fija. Todos los retratos necesarios están empaquetados localmente.

## Alcance de esta demo

Reglas nuevas y simplificadas, no una conversión exacta del motor Dart. Ataques rivales, defensa y paradas automáticos; sin selección manual de defensor. El capitán es la primera bonificación de equipo, todavía sin enlaces entre personajes o categorías. Sin historia jugable, gacha, adquisición de cartas, rarezas R/SR, pagos, PvP, sonido ni sincronización con la API. Las monedas y partidas son exclusivas de la demo y no se importan a Flutter. Los efectos actuales son transiciones y retratos, no cinemáticas definitivas de técnicas.

## Desarrollo y compilación

Abrir `project.godot` con Godot 4.7.2 estándar y pulsar F6/F5 según escena/proyecto. Renderer Compatibility, orientación vertical, diseño base 720×1600 y APK arm64.

Configurar en Godot Editor Settings → Export → Android el SDK Android y JDK 17. Instalar export templates **4.7.2.stable**; requiere `android_debug.apk` y `android_release.apk`. En la máquina inicial se usó el SDK de `%LOCALAPPDATA%/Android/Sdk` y su build-tools 36.0.0. No se usan keystores de producción.

Desde la raíz del repositorio:

```powershell
./scripts/build_clash_godot.ps1
# Para instalar en un dispositivo autorizado:
./scripts/build_clash_godot.ps1 -Install -DeviceId '<id de adb devices>'
```

Si el editor está en otra ruta, añadir `-GodotPath`. El script importa recursos, ejecuta ambos tests, exporta una APK debug e instala solo cuando se solicita. Los APK/idsig y cachés no se versionan. La descarga inicial del motor se verificó con SHA512-SUMS oficial.

Pruebas sin dispositivo:

```powershell
& '<Godot_console.exe>' --headless --path eternalclash_godot --script tests/test_game.gd
& '<Godot_console.exe>' --headless --path eternalclash_godot --script tests/test_ui.gd
```

El primer test simula 200 partidos y comprueba acciones ilegales, energía, límites de partido, recompensa única, entrenamiento, guardado, recuperación de backup y continuidad RNG. El segundo carga cinco pantallas más el selector de formación y comprueba ancho y cabecera en el viewport base.

Para reexportar cartas conservando IDs: `./scripts/export_clash_godot_content.ps1`. Solo con `-RefreshPortraits` vuelve a descargar imágenes del backend y optimizarlas a 360×480. Requiere Windows/System.Drawing. Los fondos, escudos y logo se copiaron del original; el logo se normalizó a PNG 512×512 porque su copia inicial no era importable en Godot.

## Guardado

`user://clash_profile_v1.json`, con esquema 1, copia `.bak` y archivo temporal antes de reemplazar. Incluye semilla y estado RNG como texto para evitar pérdida de precisión en JSON. No usar el guardado local como economía segura de un juego competitivo/comercial.

## Primera comprobación en móvil

ZTE A7050, Android/ARM64 y Mali-G57: instalación, arranque, partido completo, recompensa y reanudación comprobados. Ver `docs/CURRENT_STATUS.md` para el resultado final de la sesión. No se ha medido todavía FPS, consumo o compatibilidad en otros teléfonos.

Capturas reales del teléfono: [Inicio](../docs/images/clash_godot/home.png), [partido](../docs/images/clash_godot/match.png), [colección](../docs/images/clash_godot/cards.png), [formación](../docs/images/clash_godot/team.png) y [resultado](../docs/images/clash_godot/result.png).
