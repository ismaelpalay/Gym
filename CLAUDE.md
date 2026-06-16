# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

**ACME Fight & Fitness** — sitio web de marketing para un gimnasio MMA premium en México. Diseño oscuro con acentos rojos y dorados.

## Stack

- HTML/CSS/JS puro — sin framework ni bundler
- **EmailJS** (CDN `@emailjs/browser@4`) para envío de correos de bienvenida desde el cliente
- **Supabase** para base de datos (leads, membresías, contactos) — cliente inicializado con `SUPABASE_URL` y `SUPABASE_ANON_KEY` en `.vercel/.env.production.local`
- **Vercel** para deploy (`vercel.json`: URLs limpias, headers de seguridad, rewrites)
- Repositorio GitHub: `ismaelpalay/Gym`

## Desarrollo local

```bash
# Ver en local (sin servidor)
open index.html

# Con servidor simple (para evitar restricciones CORS)
npx serve .

# Deploy automático al hacer push
git push origin main
```

## Arquitectura de index.html (4500+ líneas)

El archivo sigue el patrón: `<style>` global → HTML semántico → `<script>` al final.

**Secciones HTML en orden:** `#hero` → `#espacios` → `#membresias`/`#planes` → `#mapa` → `#clases` → `#recuperacion` → `#kids` → `.contact-bar` → `footer`

**Variables CSS globales** en `:root`:
- `--red: #E5001A` / `--red-l: #FF2030` / `--red-d: #AA0012` — rojo de marca
- `--gold: #C9A84C` / `--gold-l: #E0C06A` — dorado de marca
- `--bg: #060606` / `--card: #111111` — fondos
- `--font-h: 'Oswald'` / `--font-b: 'Inter'` — tipografías

**Bloques JS clave al final del archivo:**

1. **EmailJS** — constantes `EMAILJS_PUBLIC_KEY / SERVICE_ID / TEMPLATE_ID` (actualmente con placeholders `TU_..._AQUI`). La bandera `EMAILJS_CONFIGURED` evita llamadas reales hasta que se configuren. Función `sendWelcomeEmail(data)` envía correo de bienvenida con variables: `to_name`, `to_email`, `bcc_to`, `plan_type`, `telefono`, `fecha_inicio`, `nombre_padre`, `nombre_nino`, `fuente`, `notas`, `año`.

2. **Precios** — objeto `PLAN_PRICES` mapea nombres de plan a precio/periodo. Planes: `FIGHT` ($499/sesión), `CAMPEÓN` ($2,999/mes), `ÉLITE` ($3,999/mes), `VALOR` ($329/sesión, niños), `PROSPECTO` ($2,799/mes, niños), `LEGADO ACME` ($4,999/mes, familiar).

3. **Modales** — `openModal(id, plan?)` / `closeModal(id)`. Modal `modal-membresia` acepta plan preseleccionado. `toggleLegadoFields(plan)` muestra/oculta campos adicionales para el plan familiar.

4. **Formulario** — `submitForm(e, modalId)` recopila campos, llama a `sendWelcomeEmail()`, luego redirige a `payment.html` via `URLSearchParams` con nombre, plan y precio.

5. **Chatbot FAQ** — array `KB` (ES) y `KB_EN` (EN) con entradas `{keys, res, actions}`. `findMatch(query)` hace búsqueda por keywords. `FAQ_CHIPS` / `FAQ_CHIPS_EN` definen los botones de sugerencia.

6. **i18n ES/EN** — objeto `DICT` con claves `data-i18n` para todos los textos. `applyLang(lang)` actualiza `textContent` de elementos con `[data-i18n]` y `placeholder` de `[data-i18n-placeholder]`. `window.toggleLang()` alterna entre ES/EN y persiste en `localStorage`. `window.setChatbotLang(lang)` sincroniza el chatbot. Para añadir texto nuevo: agregar clave en `DICT.es` y `DICT.en`, y usar `data-i18n="clave"` en el HTML.

7. **Animaciones** — clase `.fade-in` con IntersectionObserver. Atributo `data-delay="N"` (1–6) añade `transition-delay`. Clase `.section` usa `padding: 110px 0`.

8. **Tabs de espacios** — `.tab-btn[data-tab]` filtra `.space-card[data-cat]`. Tabs del mapa: `.floor-tab` + `.floor-plan`.

## Patrones de interacción

- **Añadir una sección nueva**: Agregar el HTML con clase `.section` y `id`, agregar enlace en el `<nav>`, y agregar traducción ES/EN en `DICT` para cualquier texto visible.
- **Añadir plan nuevo**: Actualizar `PLAN_PRICES`, las tarjetas HTML en `#planes`, y el `<select>` del modal de membresía, y añadir entrada en el chatbot KB.
- **Cambiar texto** con i18n activo: modificar en `DICT.es` y `DICT.en`, no directamente en el HTML.

## Supabase (pendiente de implementar)

Tablas previstas:
- `leads` — registros del formulario de membresía
- `contactos` — mensajes de contacto
- `miembros` — miembros activos (para admin)

## Panel de administración (pendiente)

Ruta: `/admin` → `admin/index.html`. Autenticación: Supabase Auth (magic link o email/password).
