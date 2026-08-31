---
description: Cierra el trabajo actual: estado, CURRENT_STATUS, comprobaciones, commit, rama y PR sin force-push
---

# /cerrar-trabajo

Identifica la raíz Git actual. No mezcles archivos de otro proyecto.

## Pasos

1. `git status` y `git diff`. Resume los cambios reales.
2. Actualiza `docs/CURRENT_STATUS.md` con lo hecho, lo pendiente y la fecha.
3. Ejecuta las comprobaciones **documentadas** en este repo (`npm test`, `npm run lint`, `flutter test`, `mvn test`, etc.). No inventes comandos.
4. Comprueba nombres de secretos (no leas contenidos):
   - Windows: `mac-mini-setup/scripts/windows/Test-NoSecrets.ps1`
   - macOS: `mac-mini-setup/scripts/macos/test-no-secrets.sh`
5. Si hay secretos en el diff, detente.
6. Propón un commit descriptivo (por qué, no un listado de archivos). Pide confirmación si hace falta.
7. Sube una **rama de trabajo**. No hagas force-push. No subas APKs ni `.env`.
8. Crea pull request con `gh pr create` cuando no sea un fast-forward trivial ya acordado sobre la rama principal.
9. Si el usuario tiene regla de deploy y hubo cambios de API, ejecuta `scripts/deploy-server.ps1` solo si existe.

Prohibido: `git push --force`, `git reset`, `git clean`, aplicar stashes.
