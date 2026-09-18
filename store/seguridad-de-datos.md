# Seguridad de los datos (Play Console) — respuestas de Lumen

Play Console → Política → Contenido de la app → **Seguridad de los datos**.
Estas respuestas describen la app tal como está hoy (versión 1.0.0). **Si se agrega
una colección nueva o un SDK nuevo, hay que actualizar esta sección y este archivo.**

## Preguntas generales

| Pregunta | Respuesta |
|---|---|
| ¿La app recopila o comparte alguno de los tipos de datos requeridos? | **Sí** |
| ¿Todos los datos se cifran en tránsito? | **Sí** (TLS, Firebase) |
| ¿Ofreces una forma de solicitar la eliminación de los datos? | **Sí** → https://angelpmzx.github.io/lumen-app/eliminar-cuenta.html |
| ¿Los datos recopilados son obligatorios u opcionales? | Ver cada tipo abajo |
| ¿La app está dirigida a menores? | **No** (13+) |
| ¿Usas datos para publicidad o marketing? | **No** |
| ¿Vendes o compartes datos con terceros? | **No** (Firebase es proveedor/encargado, no "compartir" según Play) |

## Tipos de datos a declarar

### Información personal
| Tipo | ¿Se recopila? | ¿Se comparte? | Obligatorio | Propósito |
|---|---|---|---|---|
| Nombre | Sí | No | Obligatorio | Funciones de la app, gestión de la cuenta |
| Dirección de correo | Sí | No | Obligatorio | Funciones de la app, gestión de la cuenta |
| ID de usuario | Sí | No | Obligatorio | Funciones de la app, gestión de la cuenta |
| Otra info personal (edad, género, gustos, arquetipo) | Sí | No | **Opcional** | Personalización |

### Información de salud y bienestar físico
| Tipo | ¿Se recopila? | ¿Se comparte? | Obligatorio | Propósito |
|---|---|---|---|---|
| Información de salud (ánimo, diario emocional, hábitos, sesiones de respiración) | Sí | No | **Opcional** | Funciones de la app |

> Esta es la categoría clave: Play considera el registro de ánimo y el diario
> emocional **información de salud**. Declararla y explicarla en la política.

### Mensajes / contenido del usuario
| Tipo | ¿Se recopila? | ¿Se comparte? | Obligatorio | Propósito |
|---|---|---|---|---|
| Otro contenido generado por el usuario (entradas del diario, notas de hábitos, retos) | Sí | No | Opcional | Funciones de la app |

### Actividad en la app
| Tipo | ¿Se recopila? | ¿Se comparte? | Obligatorio | Propósito |
|---|---|---|---|---|
| Interacciones en la app (pantallas y acciones, anónimas) | Sí | No | Opcional | Estadísticas, funciones de la app |

### Registros y diagnóstico
| Tipo | ¿Se recopila? | ¿Se comparte? | Obligatorio | Propósito |
|---|---|---|---|---|
| Registros de fallos | Sí | No | Opcional | Estadísticas, funciones de la app |
| Diagnóstico (modelo de dispositivo, versión del sistema) | Sí | No | Opcional | Estadísticas |

### Lo que NO se recopila (dejar sin marcar)
Ubicación · Información financiera · Contactos · Calendario · Fotos y videos ·
Archivos y documentos · Audio · Historial de navegación · Historial de búsqueda ·
SMS o llamadas · ID de publicidad · Datos biométricos · Orientación sexual ·
Origen étnico · Creencias religiosas o políticas.

> Nota: la app pide **género** en el registro. Va declarado como "Otra información
> personal", es opcional y solo se usa para personalizar. No se usa para publicidad.

## Notas para el formulario

- **Propósito "Personalización"**: marcar solo en los datos del registro (edad, género, gustos).
- **Propósito "Publicidad o marketing"**: nunca.
- **"Los datos se pueden eliminar"**: sí, desde la app y por correo.
- **Cifrado en reposo**: Firestore cifra en reposo por defecto (se puede mencionar en la política, no hay campo propio).

## Clasificación de contenido (cuestionario IARC)

| Pregunta | Respuesta |
|---|---|
| Categoría | Utilidad, productividad, comunicación u otros → **Salud y bienestar** |
| ¿Violencia, sexo, lenguaje soez, drogas? | No a todo |
| ¿Contenido sobre salud mental o temas delicados? | **Sí**: la app habla de ansiedad, tristeza y autocuidado, y ofrece líneas de ayuda. No describe autolesión ni métodos. |
| ¿Los usuarios pueden interactuar entre sí o compartir contenido? | **No** hay chat ni comunidad. El usuario puede compartir **su propia tarjeta de ruta completada** usando el menú de compartir del sistema; no incluye datos personales ni de ánimo. |
| ¿Comparte ubicación con otros usuarios? | No |
| ¿Permite compras digitales? | No (hoy) |
| ¿Contiene publicidad? | No |

Resultado esperado: **Clasificación para todo público / PEGI 3–7 / ESRB Everyone**,
con el aviso de "temas de salud mental" si el cuestionario lo pregunta.

## Antes de enviar, revisar en la consola

1. **Firebase Auth → Settings → Email enumeration protection: activado.**
2. **Firebase App Check** con Play Integrity, para que solo la app real hable con Firestore.
3. **Reglas de Firestore publicadas** (copiar `firestore.rules` del repo).
4. En Play Console, sección **Aplicaciones de salud**: si pregunta, indicar que
   Lumen es bienestar general y **no** una app médica ni de diagnóstico.
