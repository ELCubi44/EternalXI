---
description: Actualiza el repositorio Git actual con fetch y pull --ff-only solo si es seguro
---

# /actualizar-proyecto

Identifica automáticamente la raíz Git del workspace actual.

## Pasos (en este orden)

1. `git status`. Si hay cambios locales o untracked, **detenerse** e informar. No stashes, no descartar.
2. `git fetch --prune`.
3. Calcular adelantado / atrasado / divergente / detached.
4. Solo si el árbol está **limpio**, hay upstream y el remoto está **adelantado** (local atrasado, sin divergencia): `git pull --ff-only`.
5. En cualquier otro caso, parar. No rebase, merge, reset ni force-push.

Scripts:

- Windows: `mac-mini-setup/scripts/windows/Update-Project.ps1 -Path <repo>`
- macOS: `mac-mini-setup/scripts/macos/update-project.sh <repo>`

Si el repo está en `config/exclude-repos.json` (copia local, repo viejo), no lo actualices.
