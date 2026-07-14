# Google Play Console � Eternal XI con chat de liga

Actualizaci�n por la funci�n **chat de liga** (mensajes de texto entre miembros de una liga privada).

**App:** Eternal XI � `es.eternalxi.app`  
**Enlaces legales (ya publicados):**
- Privacidad: https://eternalxi.com/privacy-policy.html
- Normas comunidad: https://eternalxi.com/community-guidelines.html
- Eliminaci�n cuenta: https://eternalxi.com/account-deletion.html
- T�rminos: https://eternalxi.com/terms-of-service.html

**Moderaci�n en app:** reportar mensaje + bloquear usuario (mantener pulsado). Revisi�n reactiva, no pre-moderaci�n.

---

## Ruta en Play Console

1. [Play Console](https://play.google.com/console) ? **Eternal XI**
2. Men� izquierdo: **Pol�tica y programas** ? **Contenido de la aplicaci�n**
3. Pesta�a **Completadas** ? **Gestionar** en cada declaraci�n que aplique (o **Requiere atenci�n** si Google pide actualizaci�n)

Declaraciones a revisar/actualizar por el chat:

| Declaraci�n | Acci�n |
|-------------|--------|
| **Clasificaci�n de contenido** (IARC) | Nuevo cuestionario |
| **P�blico objetivo y contenido** | Revisar edad + interacci�n |
| **Seguridad de los datos** | A�adir mensajes de chat |
| **ID de publicidad** | Sin cambio si no hay anuncios |
| **Acceso a la aplicaci�n** | Sin cambio |
| **Pol�tica de privacidad** | URL ya correcta |

---

## 1. Clasificaci�n de contenido (PEGI / IARC)

**Contenido de la aplicaci�n ? Clasificaci�n de contenido ? Gestionar ? Iniciar nuevo cuestionario**

Respuestas recomendadas para Eternal XI:

| Pregunta / tema | Respuesta | Motivo |
|-----------------|-----------|--------|
| Categor�a | **Deportes** o **Juegos ? Deportes** | Fantasy f�tbol |
| Violencia, sexo, drogas, lenguaje vulgar en contenido de la app | **No** | Solo datos deportivos simulados |
| Apuestas / juego con dinero real | **No** | Dinero y fichas son virtuales de liga |
| Interacci�n en l�nea / intercambio de contenido | **S�** | Chat de texto entre usuarios de la misma liga |
| Contenido generado por usuarios (UGC) | **S�** | Mensajes de texto en chat |
| �Todo el UGC est� moderado *antes* de publicarse? | **No** | Moderaci�n reactiva (reportar/bloquear) |
| Compartir ubicaci�n, fotos en chat | **No** | Chat solo texto |
| Compras in-app | **No** (si no hay) | � |

**Resultado esperado:** PEGI **12** o **16** en la UE (por interacci�n en l�nea / UGC), ESRB **Everyone** o **Teen** en EE.UU. Google mostrar� el rating IARC calculado; rev�salo en la vista previa antes de enviar.

> Si el cuestionario anterior se hizo **sin** chat, hay que enviar uno **nuevo** (obligatorio cuando cambian funciones).

---

## 2. P�blico objetivo y contenido

**Contenido de la aplicaci�n ? P�blico objetivo y contenido ? Gestionar**

| Campo | Valor |
|-------|--------|
| �Dirigida a ni�os? | **No** (no est� dise�ada principalmente para menores de 13) |
| Grupos de edad objetivo | **13-15, 16-17, 18+** (marcar los que apliquen; **no** menores de 13) |
| �Atrae a ni�os? | **No** |
| Interacci�n entre usuarios | **S�** � chat de liga entre participantes |
| Contenido generado por usuarios | **S�** � mensajes de texto |
| Enlace normas comunidad | https://eternalxi.com/community-guidelines.html |

**Pol�tica Familias:** no aplica si no diriges la app a menores.

---

## 3. Seguridad de los datos

**Contenido de la aplicaci�n ? Seguridad de los datos ? Gestionar**

### Paso 2 � Recogida y seguridad

| Pregunta | Respuesta |
|----------|-----------|
| �Recoge o comparte datos? | **S�** |
| �Cifrado en tr�nsito? | **S�** (HTTPS) |
| Creaci�n de cuenta | **Nombre de usuario y contrase�a** |
| URL eliminaci�n cuenta | https://eternalxi.com/account-deletion.html |
| �Eliminar datos sin borrar cuenta? | **No** (o **S�** si en el futuro a�ades borrado parcial) |

### Paso 3 � Tipos de datos (marcar y configurar)

**Informaci�n personal** (ya parcialmente declarado):
- Direcci�n de correo electr�nico � recogido, obligatorio, finalidad: cuenta
- Nombre � recogido (nickname), obligatorio
- Fotos � recogido, **opcional** (foto de perfil)
- Fecha de nacimiento � recogido, obligatorio (verificaci�n 13+)

**Mensajes** (NUEVO por chat):
- **Otros mensajes en la aplicaci�n** � **S�**
  - Recogidos: **S�**
  - Compartidos: **No** (solo miembros de la liga v�a tu servidor, no terceros publicitarios)
  - Finalidad: **Funcionalidad de la aplicaci�n** / comunicaci�n entre usuarios
  - Opcional: **No** (el chat es parte de la liga; el usuario puede no escribir, pero la funci�n existe)

**Actividad en la aplicaci�n**:
- Interacciones en la aplicaci�n � **S�** (datos de juego, ligas, mercado)
- Otro contenido generado por el usuario � **S�** (mensajes de chat)

**Identificadores**:
- ID de usuario � **S�**
- ID de dispositivo u otros (FCM push) � **S�**

**No marcar** (la app no usa): ubicaci�n, contactos, SMS, archivos del dispositivo, audio, calendario, informaci�n financiera real.

### Paso 4 � Uso y gesti�n

Para cada tipo marcado:
- **No se venden datos**
- **El usuario puede solicitar eliminaci�n** (eliminar cuenta)
- Conservaci�n: mientras la cuenta est� activa; mensajes de chat en servidor seg�n pol�tica de privacidad

### Paso 5 � Enviar

Revisar vista previa de la ficha Play Store y **Enviar**.

---

## 4. Control parental / PEGI en la ficha

- El **PEGI** lo asigna IARC seg�n el cuestionario; no se edita manualmente.
- **Control parental de Google Play** filtra apps por clasificaci�n; con interacci�n en l�nea suele mostrarse **PEGI 12+** o similar en Europa.
- En la descripci�n de la tienda puedes a�adir (opcional): *"Incluye chat de texto entre miembros de liga. Edad m�nima 13 a�os."*

---

## 5. Checklist r�pido post-chat

- [ ] Nuevo cuestionario IARC enviado
- [ ] P�blico objetivo: no menores de 13, interacci�n S�
- [ ] Seguridad de datos: tipo **Mensajes** + UGC declarados
- [ ] URLs legales accesibles (comprobar en navegador)
- [ ] Nueva release en Play con el build que incluye chat (si a�n no est� publicada)

---

## 6. Contacto IARC / apelaciones

Email IARC: el que usaste en el cuestionario original.  
Soporte app: eternalxi@eternalxi.com

---

*�ltima actualizaci�n: julio 2026 � chat de liga Eternal XI*
