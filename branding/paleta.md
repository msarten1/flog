# Flog · identidad visual

Inspiración: Hole19 / Golf GameBook (verde profundo, tarjetas claras, tipografía grande, navegación inferior).

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| `fondo` | `#F4F6F2` | `#0B1F17` | Fondo de pantalla |
| `superficie` | `#FFFFFF` | `#14291F` | Tarjetas |
| `verde900` | `#0F3D2E` | `#0F3D2E` | Cabeceras, bottom nav, botones primarios |
| `verde700` | `#1B5E46` | `#2A7A5C` | Primario, enlaces |
| `lima` | `#B6E388` | `#B6E388` | Acento: "Nuevo", CTA sobre verde |
| `dorado` | `#C9A227` | `#D9B85A` | Federación / Nacional |
| `azul` | `#2F6FB0` | `#6FA3DE` | Circuito |
| `texto` | `#121A14` | `#EEF3EC` | Texto principal |
| `textoSuave` | `#5B6B60` | `#A7B5AB` | Metadatos |
| `linea` | `#DCE3DA` | `#24392F` | Bordes |
| `aviso` | `#E2572B` | `#FF7A50` | Cambios, cancelaciones |

Tipografía: **Sora** 700 para títulos y cifras, **Inter** 400/500/600 para cuerpo.
Radio de tarjeta 16 px, chips tipo píldora, botones de 52 px de alto.

## Logo

`logo.svg`: casilla de calendario (con anillas lima) y una bandera de green
clavada en el hoyo. `icon-foreground.svg` es la capa frontal del icono
adaptativo de Android (fondo `#0F3D2E` sólido). `wordmark.svg` combina icono
y nombre.

Exportar a PNG (necesita `rsvg-convert`, `brew install librsvg`):

```bash
rsvg-convert -w 1024 branding/logo.svg            > branding/export/icon-1024.png
rsvg-convert -w 1024 branding/icon-foreground.svg > branding/export/icon-foreground-1024.png
rsvg-convert -w 1200 branding/icon-foreground.svg > branding/export/splash-1200.png
```
