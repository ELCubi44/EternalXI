# Desarrollo — Eternal XI

## Flutter

Desde `eternalxi_front/README.md`:

```
cd eternalxi_front
flutter pub get
flutter run
```

Móvil habitual (requiere `.local/deploy.env`): `scripts/run-mobile.ps1`.

## API / tests

En `docs/CLASH_QA.md` y contratos:

```
cd eternalxi_api_back
mvn test -Dtest=ClashClaimServiceTest,ClashSaveServiceTest
```

Deploy:

```powershell
powershell -File scripts/deploy-server.ps1
```

## Play

Scripts en `scripts/build_play_release.ps1`, `scripts/publish_play_closed.ps1`, `scripts/check_play_release_ready.ps1`.
