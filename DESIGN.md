# Política de diseño

Guía para mantener la shell visualmente coherente. Toda pieza nueva (popup,
widget de la barra, componente) debe seguir estas reglas; si algo no encaja,
se discute y se actualiza este documento antes de romperlas.

## 1. Principios

1. **GNOME/libadwaita primero.** La referencia visual es GNOME Shell 46+:
   superficies translúcidas, esquinas redondeadas, acento del sistema, iconos
   simbólicos monocromos. Ante la duda, "¿cómo lo haría GNOME?".
2. **El sistema manda.** Claro/oscuro y color de acento salen de gsettings
   (`Theme.qml`) en vivo. Nunca fijar un esquema ni un acento en un componente.
3. **Directo, no anidado.** Las acciones frecuentes van a un clic. Lo
   destructivo o poco frecuente (apagar, reiniciar…) va detrás de un
   despliegue, no en la vista principal.
4. **El estado se ve.** Todo control que represente un estado (Wi-Fi, flotante,
   fondo actual, workspace actual) lo muestra con el acento, y su texto
   secundario dice el estado en palabras ("Apagado", "Sin conexión").
5. **Pantalla chica.** La máquina de referencia es 1366×768. Ningún popup debe
   pasar de ~620 px de alto; las listas largas se desplazan (`Flickable`).

## 2. Tokens (`Theme.qml`)

Los colores, radios y fuentes **solo** se toman de `Theme`. No se escriben
colores hex en componentes, salvo las excepciones listadas abajo.

### Color

| Token | Uso |
|---|---|
| `fg` / `fgDim` | Texto e iconos principales / secundarios, etiquetas de sección |
| `accent` / `accentHover` | Estado activo/seleccionado (relleno) y su hover |
| `accentFg` | Texto e iconos sobre `accent` |
| `danger` | Acciones destructivas (Apagar, Cerrar ventana) — solo en icono/texto |
| `ok` | Confirmaciones/éxito |
| `barBg` / `popupBg` / `toastBg` | Fondo de barra, popups y toasts |
| `cardBg` / `cardHoverBg` | Superficie de tiles, botones y tarjetas **dentro** de un popup |
| `hoverBg` | Hover de filas planas (`ActionRow`, segmentos inactivos) |
| `activeBg` | Botón de la barra cuyo popup está abierto |
| `trackBg` | Riel de sliders y switches apagados |
| `border` | Borde de 1 px de popups y separadores |

Excepciones permitidas: `#ffffff` para knobs de slider/switch y texto sobre
imágenes; `#000000` con alfa para degradados/oscurecido sobre imágenes
(siempre vía `Theme.withAlpha`).

La transparencia/blur se ajusta solo con `barAlpha` y `popupAlpha`; el blur
real lo pone Hyprland.

> ⚠️ Ninguna propiedad puede empezar con `on` + mayúscula (`onAccent`): QML la
> interpreta como manejador de señal y el singleton entero deja de cargar.

### Radios

| Valor | Uso |
|---|---|
| `Theme.radius` (14) | Tarjeta del popup |
| `radius - 2` (12) | Tarjetas internas, tiles, vista previa |
| `radius - 4` (10) | Botones de la barra |
| `radius - 6` (8) | Filas, chips, miniaturas |
| `height / 2` | Píldoras: quick toggles, `IconButton`, `SegmentedControl`, badges |

### Tipografía

Fuente `Theme.fontFamily` (Adwaita Sans); `monoFontFamily` solo para código o
datos tabulares.

| Tamaño | Peso | Uso |
|---|---|---|
| 13 | Bold | Título de popup |
| 12 | DemiBold / Normal | Etiqueta principal de filas y toggles |
| 11 | Normal | Valores (%, hora), segmentos, chips |
| 10 | Normal | Subtítulo/estado, texto de ayuda |
| 10 | DemiBold, MAYÚSCULAS, +0.6 tracking | `SectionLabel` |

Porcentajes y números que cambian usan cifras tabulares (`font.features: { "tnum": 1 }`).

### Espaciado

- Padding interno de `PopupCard`: 12 px; separación entre bloques: 10 px.
- Gaps de grillas: 8 px (toggles, miniaturas), 6 px (tiles, chips).
- Icono ↔ texto en filas: 10 px. Márgenes laterales de filas: 10–16 px.
- Separadores (`Rectangle` de 1 px con `Theme.border`) solo cuando agrupar con
  tarjetas o `SectionLabel` no alcanza.

## 3. Componentes

Usar el existente antes de crear uno nuevo. Si se crea uno, va en
`components/`, con comentario de cabecera en español explicando qué es y dónde
se usa.

| Componente | Cuándo usarlo |
|---|---|
| `PopupCard` | Base de todo popup anclado a la barra (`align`: left/center/right) |
| `BarButton` | Cualquier botón de la barra; `active` cuando su popup está abierto |
| `QuickToggle` | Encender/apagar una función del sistema (grilla de 2 columnas) |
| `TileButton` | Acción o estado sobre un objeto (ventana); grilla de 3 columnas |
| `IconButton` | Acción secundaria solo-icono en cabeceras; `checked` si despliega algo |
| `SliderRow` | Valor continuo 0–1; el icono es clickeable (mute) y acepta rueda |
| `SegmentedControl` | Elegir una opción entre 2–4 excluyentes |
| `ChipButton` | Opción compacta en grilla (workspaces, flechas); `dot` = tiene contenido |
| `ActionRow` | Ítem de menú con texto (menú de energía, acciones con etiqueta larga) |
| `SectionLabel` | Encabezado de un grupo dentro de un popup |
| `SymbolicIcon` | Todo icono monocromo; nunca `Image` directo para iconos |

### Anatomía de un popup

```
┌ PopupCard ─────────────────────────┐
│ Cabecera: título/contexto + IconButtons │
│ (despliegue opcional)              │
│ Contenido principal                │
│ SECTION LABEL                      │
│ Controles agrupados                │
└────────────────────────────────────┘
```

- La cabecera da contexto (qué ventana, cuántas imágenes, batería) y aloja
  las acciones secundarias a la derecha.
- Lo más usado arriba; lo destructivo al final o desplegable.
- Estado vacío explícito: icono atenuado + una línea que diga qué hacer.

## 4. Estados e interacción

| Estado | Tratamiento |
|---|---|
| Normal | `cardBg` (o transparente en filas planas) |
| Hover | `cardHoverBg` / `hoverBg`; `accentHover` si está activo |
| Presionado | `scale` 0.94–0.97, 90 ms `OutCubic` |
| Activo / seleccionado | Relleno `accent`, contenido `accentFg`, peso DemiBold |
| Deshabilitado | `opacity: 0.4`; se deshabilita, no se oculta, si el usuario debe saber que existe |
| Destructivo | Icono/texto `danger`, nunca relleno rojo |

- Todo elemento clickeable lleva `cursorShape: Qt.PointingHandCursor`.
- Los controles son **controlados**: emiten `toggled(value)`/`clicked()` y no
  pisan su propio `checked`; el valor real vuelve por binding desde el
  servicio (Networking, Bluetooth, Hyprland…).
- Después de una acción sobre Hyprland se refresca el estado (~150 ms) para
  que la UI refleje la realidad y no una suposición.
- Al cerrarse un popup se resetean sus estados transitorios (despliegues,
  hover).
- Para hover sobre áreas con hijos interactivos, `HoverHandler` en vez de
  `MouseArea`.

## 5. Movimiento

| Qué | Duración | Curva |
|---|---|---|
| Hover / cambio de color | 100–120 ms | lineal |
| Opacidad (habilitar, cargar imagen) | 100–150 ms | lineal |
| Presión (scale) | 90 ms | `OutCubic` |
| Switch / knob | 140 ms | `OutCubic` |
| Despliegue (altura) | 160 ms | `OutCubic` |
| Apertura de popup | 140 ms fade + 180 ms desliz. 6 px | `OutCubic` |

Nada supera 200 ms. Sin rebotes ni animaciones de cierre que retrasen la
interacción.

## 6. Iconos

- Tema activo: **Phosphor** (`//@ pragma IconTheme Phosphor`), que hereda de
  **Adwaita** para los nombres que no mapea.
- Usar nombres freedesktop `*-symbolic`. Antes de usar uno nuevo, verificar que
  exista en alguno de los dos temas:
  ```sh
  find -L /etc/profiles/per-user/$USER/share/icons/{Phosphor,Adwaita} -name 'NOMBRE-symbolic.svg'
  ```
- Cuidado con iconos de barra de título de Adwaita (`window-maximize`,
  `window-restore`): se dibujan diminutos. Preferir alternativas
  (`zoom-fit-best`, `focus-windows`).
- Iconos propios: SVG simbólico en `assets/`, pasado por `iconSource`.
- Tamaños: 15 px (barra, por defecto), 16 px (quick toggles), 18 px (tiles),
  11–14 px (badges, chips), 32 px (estados vacíos).

## 7. Texto

- Interfaz en **español**, en minúscula de oración ("Cerrar sesión", no
  "Cerrar Sesión").
- Etiquetas cortas (1–2 palabras); el detalle va en el subtítulo.
- El subtítulo describe el estado, no repite la etiqueta.
- Textos que pueden desbordar llevan `elide: Text.ElideRight`.
- Comentarios del código también en español, explicando el *por qué*.

## 8. Verificación

Antes de dar por terminado un cambio visual:

1. Cargar la config sin errores: `qs -p .` y revisar el log (ignorar el aviso
   de zona horaria y el del servidor de notificaciones duplicado).
2. Revisar el popup en **oscuro y claro**, y con el acento cambiado.
3. Comprobar que entra en 1366×768 y que los estados vacío/deshabilitado se
   ven bien.
4. Para capturar un popup sin clickear: copiar la config a un directorio
   temporal, inicializar `PopupManager.current` con el nombre del popup,
   lanzarla con `timeout` y tomar la captura con `grim`.
