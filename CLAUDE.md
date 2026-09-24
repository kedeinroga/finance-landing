# Chapa Landing — guía para Claude

Landing de marketing de Chapa (finanzas para Perú). Sitio **estático** en Astro 5, desplegado en
Cloudflare Pages en `https://landing-finance.kedein.com`. Es una vitrina pública (SEO): el registro
y el billing están apagados en producción, así que el único CTA es "Iniciar sesión" →
`https://finance.kedein.com/login`. Público: 30–60 años en Perú, usuarios de Yape/Plin.

## Stack

| Capa | Tecnología |
|---|---|
| Framework | Astro 5, `output: 'static'` (sin adapter SSR) |
| UI | Componentes `.astro` + CSS plano — sin Tailwind, sin CSS-in-JS, sin framework |
| Íconos | `astro-icon` + `@iconify-json/lucide` (SVG inline en build, cero JS cliente) |
| SEO | Meta + Open Graph en `BaseLayout.astro`; `@astrojs/sitemap` (excluye `/terms`, `/privacy`) |
| Tipos | TypeScript estricto; `astro check` corre dentro de `npm run build` |
| Deploy | Cloudflare Pages vía GitHub Actions (prod-only: merge a `main` = producción) |

## Estructura

- `src/pages/` — `index.astro` (home), `terms.astro` y `privacy.astro` (**noindex**, layout `LegalPage.astro`).
- `src/components/` — la home compone en este orden: Header, Hero (`#top`, réplica estática de la
  app), FactsStrip (`#hechos`), Features (`#captura`), ProductShowcase (`#analiza-tu-plata`),
  Capabilities (`#funciones`), PersonaBands (`#para-quien`), Privacy (`#privacidad`), HowItWorks
  (`#como-funciona`), CTA, Footer y MobileCtaBar (barra fija solo en móvil, fuera de `<main>`).
  El nav solo enlaza `#captura`, `#funciones` y `#para-quien`.
- `src/styles/tokens.css` — paleta Chapa portada de `chapa-app/src/presentation/constants/theme.ts`
  (**no se reinventa**) + capa editorial propia intencional: fondo `--surface` blanco, tinta
  `--ink`, tipografías Fraunces (display) + Plus Jakarta Sans (cuerpo). `global.css` — reset +
  utilitarias (`.container`, `.btn-*`, `.eyebrow`, `.tag-beta`, `[data-reveal]`, foco visible).
- `public/_headers` — CSP y security headers: **sin recursos externos nuevos** (scripts, fuentes,
  imágenes remotas) sin revisar la CSP.

## Reglas

- Cero JS en cliente por defecto (el único es `public/reveal.js`); agregarlo requiere justificación
  explícita. Las animaciones ligadas a scroll se hacen en CSS (`animation-timeline`) dentro de
  `@supports`, con fallback estático.
- Solo tokens de `tokens.css` — no hex hardcodeados (la única excepción es el `theme-color` de
  `BaseLayout.astro`, que un `<meta>` no puede leer de una variable CSS).
- Contraste AA calculado para pares texto/fondo nuevos; animaciones con `prefers-reduced-motion`;
  el foco visible global usa `--primary`, que no se ve sobre fondos azul/verde/oscuros: los
  controles nuevos sobre esas superficies necesitan su propio aro.
- Copy en español (Perú); código e identificadores en inglés.
- Verificación (sin tests ni linter): `npm run build` (0 errores) + pase visual `npm run dev` a
  375/768/1280px + consola sin violaciones CSP.

## Comandos

```bash
npm run dev        # http://localhost:4321
npm run build      # astro check + astro build → dist/
npm run preview    # sirve dist/ para validar antes de deploy
```

Los documentos de planes y estándares destilados **no están versionados en este repo** (viven en
el workspace privado del mantenedor); si una referencia a un `.md` no existe en tu entorno, ignórala.
