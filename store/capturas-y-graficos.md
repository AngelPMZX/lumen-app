# Capturas y gráficos para Play

Requisitos de Google Play (agosto 2026) y un plan concreto para Lumen.

## Lo que pide Play

| Elemento | Requisito | Estado |
|---|---|---|
| Ícono de la app | 512×512 PNG de 32 bits, sin transparencia | pendiente |
| Gráfico de funciones (feature graphic) | 1024×500 PNG o JPG, sin transparencia | pendiente |
| Capturas de teléfono | Mínimo 2, máximo 8. Entre 320 y 3840 px por lado, proporción máx. 2:1 | pendiente |
| Capturas de tablet de 7" y 10" | Opcionales, pero mejoran la ficha | opcional |
| Video (YouTube) | Opcional | opcional |

Tamaño recomendado para las capturas de teléfono: **1080×2400** (es la proporción
del celular de prueba y se ve bien en la ficha).

## Las 8 capturas propuestas (en este orden)

1. **Home** con la racha encendida y el cielo del atardecer.
   Texto: *«Tu día, en un vistazo»*
2. **Lección** en un paso de mito/realidad o de práctica guiada.
   Texto: *«90 lecciones cortas, sin sermones»*
3. **Diario** escribiendo con la pregunta del día.
   Texto: *«Tu diario, solo tuyo»*
4. **Respiración** en plena inhalación, con Lumi debajo del orbe.
   Texto: *«Respira con Lumi»*
5. **Jardín** con el cerezo adulto y la burbuja de cosecha lista.
   Texto: *«Tu jardín crece cuando te cuidas»*
6. **Medallas** con la vitrina y varias en oro.
   Texto: *«Mira todo lo que llevas»*
7. **Resumen semanal** con el ánimo dominante y un patrón.
   Texto: *«Tu semana, en claro»*
8. **Ayuda en crisis**.
   Texto: *«Ayuda gratis, siempre a un toque»*

Consejos:
- Usa una cuenta de prueba con datos bonitos (racha de 12, jardín con 4-5 plantas,
  medallas ganadas): las capturas vacías se ven tristes.
- Mismo modo (claro u oscuro) en todas, o alterna a propósito 4 y 4.
- El texto encima de la captura va en la imagen (Play no lo pone solo): tipografía
  Poppins, fondo con el degradado de la pantalla, mucho aire.
- Haz también la versión en inglés si vas a publicar la ficha en inglés.

## Cómo tomarlas

```powershell
# Con el celular conectado por USB y depuración activada
adb exec-out screencap -p > captura1.png

# O desde un emulador de Android Studio (Pixel 6, 1080x2400)
flutter run --release
```

En Xiaomi, `adb install` está bloqueado pero `adb exec-out screencap` sí funciona.

## Ícono

- Base: Lumi (la gotita de luz) sobre un degradado verde de la app
  (`#10B981` → `#047857`), sin texto.
- Exporta 512×512 PNG sin transparencia para la ficha y regenera los íconos de la
  app con `flutter_launcher_icons` o desde Android Studio (Image Asset).
- Evita poner el nombre dentro del ícono: Play ya lo muestra al lado.

## Gráfico de funciones (1024×500)

Propuesta: fondo con el cielo del atardecer de la app, Lumi a la izquierda, a la
derecha el texto **«Lumen · Tu gimnasio emocional»** y debajo, pequeñito,
«lecciones · diario · respiración · jardín». Sin capturas dentro (Play las recorta).
