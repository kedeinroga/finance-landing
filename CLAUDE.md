# Chapa Landing — guía para Claude

Landing de marketing de Chapa (finanzas para Perú). Sitio **estático** en Astro 5, desplegado en
Cloudflare Pages al apex `https://chapa.money`. Su trabajo es **vender**: convertir visitas en
registros en `https://app.chapa.money/welcome`. Público: 30–60 años en Perú, usuarios de Yape/Plin.

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
- `src/components/` — Header, Hero (demo CSS-only), Features (`#captura`), AudienceSplit
  (`#para-quien`), HowItWorks (`#como-funciona`), PlanComparison (`#planes`), CTA, Footer.
  La home compone en ese orden; el nav usa anchors a esos `id`.
- `src/styles/tokens.css` — paleta Chapa portada de `chapa-app/src/presentation/constants/theme.ts`
  (**no se reinventa**) + capa editorial propia intencional: papel `--paper #faf7f1`, tipografías
  Fraunces + Instrument Sans. `global.css` — reset + utilitarias (`.container`, `.btn-*`, `.pill`,
  `[data-reveal]`).
- `public/_headers` — CSP y security headers: **sin recursos externos nuevos** (scripts, fuentes,
  imágenes remotas) sin revisar la CSP.

## Reglas

- Cero JS en cliente por defecto; agregarlo requiere justificación explícita.
- Solo tokens de `tokens.css` — no hex hardcodeados (hay drift histórico pendiente de limpiar;
  el plan de alineación de marca vive en el workspace privado del mantenedor).
- Contraste AA calculado para pares texto/fondo nuevos; animaciones con `prefers-reduced-motion`.
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
