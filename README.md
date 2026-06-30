# chapa-landing

Landing de marketing de Chapa. Sitio estático en **Astro**, desplegado en Cloudflare Pages al
apex `https://chapa.money`. Repo separado de `chapa-app` (la app Expo, en `app.chapa.money`) y de
`chapa-api` (backend, en `api.chapa.money`).

## Stack

- [Astro](https://docs.astro.build/) 5, salida estática (`output: 'static'`, sin adapter SSR).
- Sin framework de UI: componentes `.astro` + CSS plano (sin Tailwind ni CSS-in-JS).
- `@astrojs/sitemap` para `sitemap-index.xml` (excluye `/terms` y `/privacy`, ver más abajo).
- `astro-icon` + `@iconify-json/lucide` para los íconos de `Features.astro` — se renderizan como SVG
  inline en build, cero JS en cliente y cero requests extra.
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
│   ├── Header.astro         # nav sticky: logo + anchors (#captura/#para-quien/#planes) + CTAs
│   ├── Hero.astro           # headline, demo CSS-only "notificación → registro" (sin JS)
│   ├── Features.astro       # "Cómo captura" — grid de 4 tarjetas (id="captura")
│   ├── AudienceSplit.astro  # Individuo vs. Emprendedor, dos columnas (id="para-quien")
│   ├── HowItWorks.astro     # 3 pasos numerados (id="como-funciona")
│   ├── PlanComparison.astro # Free vs. Pro, sin precio público (id="planes")
│   ├── CTA.astro            # llamada a la acción final
│   ├── Footer.astro         # logo + links a /terms y /privacy (propias de este sitio) + copyright
│   └── LegalPage.astro      # layout compartido por terms.astro/privacy.astro (banner de borrador +
│                              lista de secciones título/cuerpo)
├── pages/
│   ├── index.astro          # home; compone los componentes de arriba en orden
│   ├── terms.astro           # /terms — noindex (ver "Contenido legal" más abajo)
│   └── privacy.astro         # /privacy — noindex (ver "Contenido legal" más abajo)
└── styles/
    ├── tokens.css            # variables CSS: paleta Chapa + capa editorial (paper/ink/fuentes)
    └── global.css            # reset + utilitarias (.container, .btn-*, .pill, [data-reveal])
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
0.1s"` para escalonar varios). El demo del hero (notificación → fila del registro) es CSS puro
(`@keyframes notif-cycle` / `row-cycle` en `Hero.astro`), no depende de JS ni de scroll.

## Branding — fuente de verdad

El diseño **se copia** desde `chapa-app`, no se comparte código (son stacks distintos: Astro vs.
Expo/RN). Si la marca cambia ahí, hay que portar el cambio a mano:

- **Tokens de color/spacing/radius**: `chapa-app/src/presentation/constants/theme.ts` → portados a
  `src/styles/tokens.css`. Primario `#1565C0` (azul, consistente con correos y dashboard — no el
  verde `primaryDark` de la app, que es inconsistencia conocida). Colores de Yape/Plin también
  vienen de ahí (`--yape #742F86`, `--plin #00B0FF`) y se usan en los demos de la landing.
- **Patrones visuales heredados** (gradiente, card, botones de `app.chapa.money`): tomados de las
  páginas HTML de verify-email/reset-password en `chapa-api/Caddyfile`.
- **Tagline oficial**: "Tu dinero, todo en un lugar".
- **Assets**: `public/logo.png` y `public/favicon.png` son copias directas de
  `chapa-app/assets/icon.png` y `favicon.png`. Si cambia el ícono de la app, recopiarlos.

**Capa editorial propia de esta landing (no existe en la app):** la app usa tipografía de sistema
sin marca; para la landing se eligió una dirección "editorial fintech" — serif `Fraunces` para
headlines + `Instrument Sans` para cuerpo (cargadas desde Google Fonts en `BaseLayout.astro`), y un
fondo cálido `--paper: #FAF7F1` en vez de blanco clínico, para diferenciar la landing de marketing
del dashboard funcional sin romper la identidad de color. Si se decide unificar tipografía
landing/app en el futuro, es una decisión de marca a tomar explícitamente, no una deuda técnica.

**Contenido que NO se inventa:** no hay testimonios (Chapa no tiene usuarios públicos todavía — la
sección de Clever que los usa como inspiración se mapeó a un diferenciador real, "Para quién", en
vez de fabricar nombres/citas) ni precio público de Pro (activación es manual hoy, sin pasarela de
pago — `PlanComparison.astro` compara features Free/Pro sin número de S/, Pro queda "Próximamente").
Si esto cambia, actualizar ahí con datos reales, no con placeholders.

## Contenido legal (`/terms`, `/privacy`)

El copy de estas dos páginas viene de `chapa-app/app/(auth)/terms.tsx` y
`chapa-api/PRIVACY_POLICY_DRAFT.md` — y **ambas fuentes se auto-marcan como borrador sin revisión
legal** (la segunda literalmente se titula "BORRADOR — NO PUBLICAR SIN REVISIÓN LEGAL" y tiene
campos `<RAZÓN SOCIAL>`, `<RUC>`, `<DOMICILIO LEGAL>`, `<CORREO DE CONTACTO>`, `<N° REGISTRO ANPD>`
sin completar). Decisión tomada con el usuario (2026-06-30): publicar igual, pero:

- Con un banner visible (`LegalPage.astro` → `.legal-notice`) que dice explícitamente "documento
  informativo, pendiente de revisión legal" y que faltan los datos de identificación de la empresa.
- **Sin inventar** esos datos ni un correo de contacto — donde la fuente original tenía
  `legal@chapa.money (ficticio)`, el copy dice ahora que el canal de contacto todavía no existe.
- Con `noindex, nofollow` (`<BaseLayout noindex>`) y excluidas de `sitemap-index.xml`
  (`astro.config.mjs` → `sitemap({ filter: ... })`), para no indexar contenido que sabemos
  incompleto mientras sigue siendo accesible por link directo desde el footer.

**Cuando haya revisión legal real:** completar `terms.astro`/`privacy.astro` con el texto
definitivo (razón social, RUC, domicilio, correo de contacto real), quitar el banner de
`LegalPage.astro` y quitar `noindex` + el filtro del sitemap. No hacer ninguno de esos cambios a
medias (ej. quitar el banner pero dejar placeholders) — el estado "borrador" debe ser visible
mientras exista.

## Convenciones

- Identificadores y comentarios en **inglés**, copy de la UI en **español** (igual que `chapa-app`).
- Sin literales de color/spacing sueltos en los `<style>` — usar las variables de `tokens.css`
  (`var(--primary)`, `var(--space-lg)`, etc.).
- Los CTAs y links de auth (`/login`, `/register`) apuntan siempre a `app.chapa.money`. No se
  autentica nada acá. `/terms` y `/privacy` sí son propias de este sitio (ver sección de arriba).
- Esta landing **no** importa nada de `chapa-app` ni `chapa-api` — es un sitio estático
  independiente, sin llamadas a la API salvo los links de los CTAs.

## Deploy

Cloudflare Pages, preset "Astro" (`npm run build`, output `dist/`), dominio apex `chapa.money`.
