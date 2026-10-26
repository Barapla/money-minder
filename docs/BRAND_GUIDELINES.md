# Guía de uso del logo — MoneyMinder (FEAT-039)

## El logo

Una "M" blanca cuyo último trazo sube como flecha de tendencia (el dinero que crece), sobre un cuadrado redondeado con degradado morado. El logotipo (texto "MoneyMinder") **no** está dentro del SVG: se escribe en HTML junto al símbolo para que siga la tipografía de la app (Inter, bold) y la traducción `t('app_name')`.

| Color | Hex | Uso |
|---|---|---|
| Morado inicial (`purple-500`) | `#a855f7` | Esquina superior izquierda del degradado |
| Morado final | `#6d28d9` | Esquina inferior derecha del degradado |
| Símbolo | `#ffffff` | La "M" y la flecha |
| `theme-color` del navegador | `#7c3aed` | Barra del navegador en móvil / manifest |

## Archivos

| Archivo | Tamaño | Uso |
|---|---|---|
| `app/assets/images/logo.svg` | vectorial | **Principal.** Navbar, login y cualquier vista web (`image_tag 'logo.svg'`) |
| `app/assets/images/logo.png`, `logo@2x.png`, `logo@3x.png` | 32, 64, 96 px | Donde no se admite SVG (correos usan `logo@2x.png`) |
| `public/favicon.ico` | 16, 32, 48 px | Favicon clásico |
| `public/icon.svg` | vectorial | Favicon en navegadores modernos |
| `public/apple-touch-icon.png` (+ `-precomposed`) | 180 px | Ícono al agregar a inicio en iOS (sin esquinas: iOS aplica su propia máscara) |
| `public/icon-192.png`, `public/icon-512.png` | 192, 512 px | Android / `public/manifest.webmanifest` |
| `docs/brand/app-icon-1024.png` | 1024 px | Maestro para la app móvil (iOS `AppIcon.appiconset`, Android `mipmap-*`), sin esquinas |

Los favicons se declaran en un solo lugar: `app/views/shared/_favicons.html.erb`, renderizado por `layouts/application` y `layouts/auth_application`.

Los PNG se generan rasterizando el SVG (p. ej. con `@resvg/resvg-js`) y se reducen a paleta de 256 colores; el SVG se minifica con `svgo`. Si el SVG cambia, regenera **todos** los PNG desde él: nunca edites un PNG a mano.

## Tamaños mínimos

- Pantalla: **16 px** (favicon). Por debajo de 24 px la flecha pierde detalle; en interfaz usa 32 px o más (navbar: 32 px, login: 34 px).
- Correo: 28 px mostrados, usando `logo@2x.png` para pantallas retina.
- Impresión: 10 mm de lado.

## Espaciado

- Área de respeto alrededor del símbolo: **25 % de su lado** (8 px para el de 32 px). Ningún texto ni borde entra en esa zona.
- Separación entre símbolo y logotipo: entre 25 % y 35 % del lado del símbolo (`mr-3` en el navbar, `gap-[11px]` en login).

## Variantes

- **A color (única variante oficial):** el símbolo trae su propio fondo, así que funciona igual sobre el fondo oscuro de la app (`bunker-950`) y sobre el fondo claro de los correos. No hace falta una versión para fondo claro.
- **Cuadrado sin esquinas:** solo para íconos de sistema (apple-touch, app móvil), donde el sistema operativo recorta las esquinas.
- Monocromo: no existe por ahora. Si un medio lo exige (sello, grabado), usa la "M" y la flecha en un solo color sin el cuadrado de fondo.

## Accesibilidad

El símbolo siempre va junto al texto "MoneyMinder", por eso usa `alt: ''` (decorativo): un `alt` descriptivo haría que los lectores de pantalla repitieran "MoneyMinder MoneyMinder". Si alguna vez se usa el símbolo **solo**, pon `alt: 'MoneyMinder'`.

## Usos prohibidos

- Deformar el símbolo (estirar, aplastar, rotar).
- Cambiar los colores del degradado o la "M" por otro color que no sea blanco.
- Quitar el fondo morado y poner la "M" blanca sobre fondo claro.
- Agregar sombras, contornos, brillos o efectos 3D.
- Usar el emoji 💰 como logo (era el logo anterior).
- Volver a dibujar el logotipo en otra tipografía o meterlo dentro del SVG.
