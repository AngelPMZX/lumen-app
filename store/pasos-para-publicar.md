# Pasos para publicar Lumen en Google Play

Lista para seguir de arriba abajo. Marca cada casilla al terminar.

## 1. Publicar las páginas legales (10 min)

- [ ] En GitHub: repo `lumen-app` → **Settings** → **Pages**.
- [ ] Source: **Deploy from a branch**, Branch: `main`, Folder: **`/docs`** → *Save*.
- [ ] Esperar 1-2 minutos y abrir https://angelpmzx.github.io/lumen-app/
- [ ] Revisar que abran bien:
      - https://angelpmzx.github.io/lumen-app/privacidad.html
      - https://angelpmzx.github.io/lumen-app/privacy.html
      - https://angelpmzx.github.io/lumen-app/terminos.html
      - https://angelpmzx.github.io/lumen-app/eliminar-cuenta.html

> Si más adelante cambias de hosting, actualiza `lib/core/constants/app_links.dart`.

## 2. Asegurar Firebase (20 min, sin código)

- [ ] **Authentication → Settings → Email enumeration protection: activar.**
- [ ] **Authentication → Settings → Password policy** (si aparece): mínimo 8, letras y números.
- [ ] **App Check**: registrar la app Android con **Play Integrity** y activar el
      cumplimiento (*enforce*) para Firestore. Sin esto, cualquiera con las llaves
      del `google-services.json` puede hablar con tu base de datos desde fuera.
- [ ] **Firestore → Reglas**: pegar el contenido de `firestore.rules` del repo y publicar.
- [ ] Revisar que el SHA-1 **de release** esté registrado, o Google Sign-In falla en
      la versión publicada (el de debug ya está).

## 3. Preparar el build de release (30 min)

- [ ] Confirmar que existe `android/key.properties` y el keystore
      `C:\Proyectos\keys\lumen-release.jks` (respaldo fuera de la máquina).
- [ ] Subir la versión si hace falta: `pubspec.yaml` → `version: 1.0.0+1`.
- [ ] Generar el bundle:
      ```powershell
      flutter clean; flutter pub get
      flutter build appbundle --release
      ```
      Sale en `build\app\outputs\bundle\release\app-release.aab`.
- [ ] Verificar la firma del APK equivalente:
      ```powershell
      flutter build apk --release
      apksigner verify --print-certs build\app\outputs\flutter-apk\app-release.apk
      ```
      Debe decir `CN=Angel Perez`, **no** `Android Debug`.
- [ ] Instalar ese APK en el celular y probar: registro nuevo, verificación de
      correo, arquetipo, login con Google, lección, diario, jardín y eliminar cuenta.

## 4. Crear la app en Play Console (1 h)

- [ ] Cuenta de desarrollador creada y verificada (25 USD, una sola vez; la
      verificación de identidad puede tardar días: hazla antes que nada).
- [ ] **Crear app**: nombre `Lumen: Gimnasio Emocional`, idioma predeterminado
      español (México), tipo **App**, **Gratuita**.
- [ ] **Ficha principal**: copiar de `store/ficha-play-es.md`.
- [ ] Agregar idioma **inglés (EE. UU.)** y copiar de `store/ficha-play-en.md`.
- [ ] Subir ícono 512×512 (`branding/icon_512.png`), gráfico de funciones
      1024×500 (`branding/feature_graphic_es.png`) y las 7 capturas de
      `store/screenshots/` en orden (ver `store/capturas-y-graficos.md`).
- [ ] **Seguridad de los datos**: seguir `store/seguridad-de-datos.md`.
- [ ] **Clasificación de contenido**: cuestionario IARC, respuestas en el mismo archivo.
- [ ] **Público objetivo**: 13 años en adelante. No marcar "dirigida a niños".
- [ ] **App de salud**: declarar que es bienestar general, no app médica.
- [ ] **Política de privacidad**: pegar la URL del paso 1.
- [ ] **Eliminación de cuenta**: pegar la URL de `eliminar-cuenta.html`.
- [ ] **Anuncios**: no contiene.

## 5. Probar antes de abrir al público

- [ ] Subir el `.aab` a **Prueba interna** y agregar tu correo como tester.
- [ ] Instalar desde el enlace de prueba (así se valida la firma de Play y
      Google Sign-In con el certificado de Play App Signing).
- [ ] **Importante**: al activar Play App Signing, Google genera un certificado
      nuevo. Copia su **SHA-1** desde Play Console → Configuración → Integridad de
      la app y **agrégalo en Firebase**, o Google Sign-In fallará solo en la
      versión descargada de Play.
- [ ] Probar el flujo completo otra vez desde esa instalación.

## 6. Publicar

- [ ] Pasar de prueba interna a **producción** (o a prueba cerrada primero si
      quieres feedback).
- [ ] Países: empezar por México y España, o todos.
- [ ] Enviar a revisión. La primera revisión suele tardar de 1 a 7 días.

## Después de publicar

- [ ] Revisar Crashlytics los primeros días.
- [ ] Contestar las reseñas (Play lo valora y la gente lo agradece).
- [ ] Reverificar las líneas de crisis cada ~6 meses (última: 2026-09-15).
- [ ] Antes de activar RevenueCat, volver a "Seguridad de los datos" y declarar
      las compras.
