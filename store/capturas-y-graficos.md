# Capturas y gráficos para Play

Requisitos de Google Play (agosto 2026) y un plan concreto para Lumen.

## Lo que pide Play

| Elemento | Requisito | Estado |
|---|---|---|
| Ícono de la app | 512×512 PNG de 32 bits, sin transparencia | **listo** → `branding/icon_512.png` |
| Gráfico de funciones (feature graphic) | 1024×500 PNG o JPG, sin transparencia | **listo** → `branding/feature_graphic_es.png` (y `_en`) |
| Capturas de teléfono | Mínimo 2, máximo 8. Entre 320 y 3840 px por lado, proporción máx. 2:1 | **listas** → `store/screenshots/` (7 a 1080×2160) |
| Capturas de tablet de 7" y 10" | Opcionales, pero mejoran la ficha | opcional |
| Video (YouTube) | Opcional | opcional |

Las nuestras van a **1080×2160**: es justo el máximo 2:1 que acepta Play y se ve
bien tanto en la ficha como en los resultados de búsqueda.

## Las 7 capturas (hechas)

Están en `store/screenshots/`, a **1080×2160 px** (proporción exacta 2:1, el
máximo que acepta Play), con el texto ya dibujado encima:

| Archivo | Pantalla | Texto |
|---|---|---|
| `01_home.png` | Home con racha de 12 y check-in de ánimo | *Tu día, en un vistazo* |
| `02_garden.png` | Jardín con el cerezo adulto y una cosecha lista | *Tu jardín crece cuando te cuidas* |
| `03_breathing.png` | Respiración en plena inhalación, con Lumi debajo | *Respira con Lumi* |
| `04_diary.png` | Diario estilo cuaderno con una entrada | *Tu diario, solo tuyo* |
| `05_medals.png` | Vitrina de medallas, 14 de 22 | *Mira todo lo que llevas* |
| `06_summary.png` | Resumen semanal con un patrón personal | *Tu semana, en claro* |
| `07_crisis.png` | Ayuda en crisis | *Ayuda gratis, siempre a un toque* |

Súbelas en ese orden: Play muestra las primeras dos en los resultados de
búsqueda, así que el Home y el jardín van al frente.

## Cómo se rehacen

No se toman del teléfono: se **dibujan con código**, así que si cambia el diseño
se regeneran en un minuto y nunca traen datos reales de nadie.

```powershell
# Todas (cada una en su propio proceso: varias seguidas salen en blanco)
flutter test tool/store/store_shots_test.dart --name '^01_home$'
flutter test tool/store/store_shots_test.dart --name '^02_garden$'
# ... y así con 03_breathing, 04_diary, 05_medals, 06_summary, 07_crisis
```

- `tool/store/store_shot.dart` es el marco (degradado, título y el "teléfono").
- `tool/store/store_shots_test.dart` arma cada escena con datos de ejemplo.
- Carga Segoe UI, Segoe UI Emoji y los iconos de Material del SDK: sin eso los
  textos, emojis e iconos salen como cuadritos.
- `scroll:` baja el contenido unos píxeles antes de capturar, para que el recorte
  de abajo caiga dentro de una tarjeta y no a media palabra.
- Para la ficha en inglés: cambiar `startLocale` a `en` y los textos de `title`
  y `subtitle`, y guardar en `store/screenshots/en/`.

## Ícono y gráfico de funciones

Ya están hechos y se generan con código (ver `branding/README.md`):

```powershell
flutter test tool/branding/generate_branding_test.dart   # exporta los PNG
dart run flutter_launcher_icons                          # los instala en la app
```

- Ficha de Play: sube `branding/icon_512.png` y `branding/feature_graphic_es.png`
  (usa `feature_graphic_en.png` en la ficha en inglés).
- El ícono de la app en el teléfono ya quedó instalado (Android adaptativo con
  capa monocroma para Android 13+, iOS y web).
