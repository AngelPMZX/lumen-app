# Arte de marca de Lumen

Todo esto se **genera con código** (no son imágenes dibujadas a mano): el arte
vive en `tool/branding/brand_art.dart` y usa la misma Lumi de la app, así que el
ícono y la app nunca se ven distintos.

```powershell
# 1. Exportar los PNG a esta carpeta
flutter test tool/branding/generate_branding_test.dart

# 2. Instalarlos como íconos de Android, iOS y web
dart run flutter_launcher_icons
```

| Archivo | Para qué | Tamaño |
|---|---|---|
| `icon_512.png` | Ícono de la ficha de Google Play | 512×512, sin transparencia |
| `icon_1024.png` | Ícono base (iOS y el que usa flutter_launcher_icons) | 1024×1024 |
| `adaptive_foreground.png` | Capa de frente del ícono adaptativo de Android | 432×432, con transparencia |
| `adaptive_background.png` | Capa de fondo del ícono adaptativo | 432×432 |
| `adaptive_monochrome.png` | Ícono monocromo (Android 13+, íconos con el color del sistema) | 432×432 |
| `feature_graphic_es.png` | Gráfico de funciones de Play (ficha en español) | 1024×500 |
| `feature_graphic_en.png` | Gráfico de funciones de Play (ficha en inglés) | 1024×500 |

## Si quieres cambiar el ícono

Edita `tool/branding/brand_art.dart` (colores en `LumenBrand`, fondo en
`_IconBackgroundPainter`, resplandor y destellos en `_GlowPainter`) y vuelve a
correr los dos comandos de arriba. El tamaño de Lumi dentro del ícono es
`size * 0.52` en `LumenIcon`.
