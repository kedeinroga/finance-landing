# chapa-landing

Landing de marketing de Chapa. Sitio estático en **Astro**, desplegado en Cloudflare Pages en
`https://landing-finance.kedein.com` (proyecto `finance-landing`). Repo separado de `finance-app`
(la app, en `finance.kedein.com`) y de `finance-api` (backend, en `finance-api.kedein.com`).

## Stack

- [Astro](https://docs.astro.build/) 5, salida estática (`output: 'static'`, sin adapter SSR).
- Sin framework de UI: componentes `.astro` + CSS plano (sin Tailwind ni CSS-in-JS).
- `@astrojs/sitemap` para `sitemap-index.xml` (excluye `/terms` y `/privacy`, ver más abajo).
- `astro-icon` + `@iconify-json/lucide` para los íconos de `Hero`, `Features`, `Capabilities`, `ProductShowcase` y `PersonaBands` — se
  renderizan como SVG inline en build, cero JS en cliente y cero requests extra.
- TypeScript estricto (`astro/tsconfigs/strict`); `astro check` corre como parte de `build`.

## Setup

```bash
npm install
npm run dev       # http://localhost:4321 con hot reload
```

## Comandos

```bash
npm run dev        # servidor de desarrollo
npm run build      # astro check (type-check) + astro build → dist/
npm run preview    # sirve dist/ ya buildeado, para validar antes de deploy
```

No hay test runner ni linter configurado todavía — la verificación es `npm run build` (debe salir
"0 errors") + revisión visual con `npm run dev`.

## Estructura

```
src/
├── layouts/
│   └── BaseLayout.astro     # <html>/<head>, fuentes Google Fonts, meta SEO + Open Graph
├── components/
│   ├── Header.astro         # nav sticky: logo + anchors (#captura/#funciones/#para-quien) + CTA
│   ├── Hero.astro           # h1 + CTA sobre gradiente azul y réplica estática de Home Individuo (id="top")
│   ├── FactsStrip.astro     # franja de 3 hechos verificables (id="hechos")
│   ├── Features.astro       # "Cómo captura" — 4 formas de registrar, rejilla asimétrica (id="captura")
│   ├── ProductShowcase.astro # "Analiza tu plata" — copy + réplicas de Análisis y Balance de la caja (id="analiza-tu-plata")
│   ├── Capabilities.astro   # "Funciones" — lista de 10 capacidades de la app, con marca Beta (id="funciones")
│   ├── PersonaBands.astro   # bandas Individuo (azul) y Emprendedor (verde) con recorte de producto (id="para-quien")
│   ├── Privacy.astro        # 3 tarjetas de privacidad; carrusel scroll-snap con puntos en móvil (id="privacidad")
│   ├── HowItWorks.astro     # 3 pasos numerados (id="como-funciona")
│   ├── CTA.astro            # llamada a la acción final
│   ├── Footer.astro         # logo + links a /terms y /privacy (propias de este sitio) + copyright
│   ├── MobileCtaBar.astro   # barra fija "Iniciar sesión" solo en móvil; aparece al salir del hero
│   └── LegalPage.astro      # layout compartido por terms.astro/privacy.astro (lista de
│                              secciones título/cuerpo)
├── pages/
│   ├── index.astro          # home; compone los componentes de arriba en orden
│   ├── terms.astro           # /terms — noindex (ver "Contenido legal" más abajo)
│   └── privacy.astro         # /privacy — noindex (ver "Contenido legal" más abajo)
└── styles/
    ├── tokens.css            # variables CSS: paleta Chapa + capa editorial (surface/ink/fuentes)
    └── global.css            # reset + utilitarias (.container, .btn-*, .eyebrow, .tag-beta, [data-reveal], foco visible)
public/
├── logo.png                  # copiado de chapa-app/assets/icon.png
├── favicon.png                # copiado de chapa-app/assets/favicon.png
├── reveal.js                  # IntersectionObserver para [data-reveal] (script externo, no inline —
│                               lo exige el script-src 'self' de _headers)
├── _headers                   # headers de seguridad para Cloudflare Pages (HSTS, CSP, ...)
└── robots.txt
```

Cada sección de la página es un componente Astro independiente con su propio `<style>` con scope
(Astro lo aísla por componente automáticamente). Para agregar una sección nueva: crear el
componente en `src/components/`, importarlo en `src/pages/index.astro`, darle un `id` si va en el
nav, y usar las variables de `tokens.css` en vez de literales.

**Animaciones:** los elementos con `data-reveal` empiezan en `opacity:0` y `reveal.js` les agrega
`is-visible` vía `IntersectionObserver` cuando entran al viewport — si agregas contenido nuevo que
deba revelarse al hacer scroll, ponle el atributo `data-reveal` (opcional `style="transition-delay:
0.1s"` para escalonar varios). Dos comportamientos ligados a scroll son CSS puro, sin JS, con
`animation-timeline` dentro de `@supports` y fallback estático: la barra móvil (`MobileCtaBar`, que
se liga a la `view-timeline` `--hero-exit` declarada en `Hero.astro` y expuesta con
`timeline-scope` en `body`) y los puntos del carrusel de `Privacy`. El Hero no tiene animación
propia.

## Branding — fuente de verdad

El diseño **se copia** desde `chapa-app`, no se comparte código (son stacks distintos: Astro vs.
Expo/RN). Si la marca cambia ahí, hay que portar el cambio a mano:

- **Azul `#1565C0` es LA marca**: botones (`.btn-primary`), hero del demo, gradiente de CTA y
  `theme-color`. Consistente con correos y dashboard/auth pages de la app. `--primary-deep
  #0D3D73` es el único azul oscuro (`--primary-dark #1976D2` era drift sin uso real, eliminado).
- **Verde `--money #065A38` / `--money-light #E8F5EE`** es el acento semántico de dinero y del
  perfil emprendedor — portado de `primaryDark`/`primaryLight` de `theme.ts`. El nombre es
  intencionalmente distinto de `--primary-light` (que en esta landing es un tinte azul, no verde):
  divergencia de nombre documentada, no un error.
- **Grises alineados a la app**: `--text-secondary #555555` (paridad con la app). `--text-muted
  #6E6E6E` es más oscuro que el `#8A8A8A` de la app a propósito: aquí el muted se usa en texto de
  11–13px sobre el fondo papel, y `#8A8A8A` da ~3.2:1 (falla AA); `#6E6E6E` da ~4.7:1 (pasa).
- **Tokens de color/spacing/radius**: `chapa-app/src/presentation/constants/theme.ts` → portados a
  `src/styles/tokens.css`. Colores de Yape/Plin también vienen de ahí (`--yape #742F86`, `--plin
  #00B0FF`) y se usan en los demos de la landing.
- **Los demos CSS deben espejar la UI shippeada**: el Hero (`.replica-card` en `Hero.astro`)
  replica el Home Individuo del dashboard v2 de la app, y `ProductShowcase`/`PersonaBands` replican
  las pantallas de Análisis y Mi Caja. Son bloques estáticos `aria-hidden` con cifras y nombres
  ficticios; dentro de ellos se usa `--font-sans` y `--surface-tint` (el `--surface` de la app).
  Si cambia esa UI en la app, hay que portar el cambio a mano.
- **Patrones visuales heredados** (gradiente, card, botones de la app): tomados de las
  páginas HTML de verify-email/reset-password en `chapa-api/Caddyfile`.
- **Tagline oficial**: "Tu dinero, todo en un lugar".
- **Assets**: `public/logo.png` y `public/favicon.png` son copias directas de
  `chapa-app/assets/icon.png` y `favicon.png`. Si cambia el ícono de la app, recopiarlos.

**Capa editorial propia de esta landing (no existe en la app):** la app usa tipografía de sistema
sin marca; para la landing se eligió una dirección "editorial fintech" — serif `Fraunces` para
headlines + `Plus Jakarta Sans` para cuerpo (cargadas desde Google Fonts en `BaseLayout.astro`).
El fondo cálido `--paper` de la versión anterior se retiró con el rediseño v2: hoy el fondo es
`--surface` (blanco), alineado con la app. Si se decide unificar tipografía landing/app en el
futuro, es una decisión de marca a tomar explícitamente, no una deuda técnica.

**Contenido que NO se inventa:** no hay testimonios (Chapa no tiene usuarios públicos todavía — en
su lugar hay una franja de hechos verificables, "Para quién" y una sección de privacidad, en vez de
fabricar nombres/citas). No hay sección de planes ni precios: el registro y el billing están
apagados en producción, así que la landing solo ofrece iniciar sesión. Si se reabren, hay que
restaurar la sección de planes desde el historial de git (`PlanComparison.astro`) y volver a agregar
un CTA de alta.

## Contenido legal (`/terms`, `/privacy`)

El copy de estas dos páginas viene de `chapa-app/app/(auth)/terms.tsx` y
`chapa-api/PRIVACY_POLICY_DRAFT.md` — y **ambas fuentes se auto-marcan como borrador sin revisión
legal** (la segunda literalmente se titula "BORRADOR — NO PUBLICAR SIN REVISIÓN LEGAL" y tiene
campos `<RAZÓN SOCIAL>`, `<RUC>`, `<DOMICILIO LEGAL>`, `<CORREO DE CONTACTO>`, `<N° REGISTRO ANPD>`
sin completar). Decisión original (2026-06-30): publicar con un banner de "documento informativo,
pendiente de revisión legal". **Decisión vigente (2026-09-18):** el banner se quitó a pedido del
mantenedor (el único usuario actual es él mismo). Se mantiene lo demás:

- **Sin inventar** los datos de identificación de la empresa (razón social, RUC, domicilio, registro
  ANPD) ni un correo de contacto — el copy dice que el canal de contacto todavía no existe.
- Con `noindex, nofollow` (`<BaseLayout noindex>`) y excluidas de `sitemap-index.xml`
  (`astro.config.mjs` → `sitemap({ filter: ... })`), para no indexar contenido incompleto mientras
  sigue siendo accesible por link directo desde el footer.

**Antes de abrir el registro a usuarios reales:** completar `terms.astro`/`privacy.astro` con el
texto definitivo revisado por asesoría legal (razón social, RUC, domicilio, correo de contacto
real) y recién ahí quitar `noindex` + el filtro del sitemap.

## Convenciones

- Identificadores y comentarios en **inglés**, copy de la UI en **español** (igual que `chapa-app`).
- Sin literales de color/spacing sueltos en los `<style>` — usar las variables de `tokens.css`
  (`var(--primary)`, `var(--space-lg)`, etc.).
- El único CTA de auth es "Iniciar sesión" → `https://finance.kedein.com/login`; no hay link de
  registro (registro cerrado). No se autentica nada acá. `/terms` y `/privacy` sí son propias de este
  sitio (ver sección de arriba).
- Esta landing **no** importa nada de `chapa-app` ni `chapa-api` — es un sitio estático
  independiente, sin llamadas a la API salvo los links de los CTAs.

## Deploy

Cloudflare Pages, preset "Astro" (`npm run build`, output `dist/`), proyecto `finance-landing`,
dominio `landing-finance.kedein.com`. El hostname debe ser de primer nivel bajo `kedein.com` (guion,
no punto): Universal SSL gratuito no cubre un segundo nivel. Despliega por GitHub Actions
(`.github/workflows/deploy.yml`): push a `main` = producción; PR = preview `*.pages.dev`.
