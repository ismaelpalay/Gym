# MEMORY — ACME Fight & Fitness

Archivo de memoria viva del proyecto. Se actualiza conforme evoluciona el sitio.
Última actualización: 2026-06-16

---

## Estado actual del proyecto

- **Sitio en producción**: Vercel, repo `ismaelpalay/Gym`, deploy automático en push a main.
- **Rama activa de trabajo**: `claude/html-professional-webpage-XCwl4`
- **Archivos principales**: `index.html` (~4600 líneas), `payment.html` (507), `faq.html` (1173)
- **Páginas auxiliares**: `privacy.html`, `terminos.html`
- **Panel admin**: `admin/index.html` — accesible en `/admin`

---

## Planes y precios actuales

| Plan | Precio | Periodo | Audiencia |
|---|---|---|---|
| FIGHT | $499 | por sesión | Adultos |
| CAMPEÓN | $2,999 | al mes | Adultos |
| ÉLITE | $3,999 | al mes | Adultos (Premium) |
| VALOR | $329 | por sesión | Niños |
| PROSPECTO | $2,799 | al mes | Niños |
| LEGADO ACME | $4,999 | al mes | Familiar |

El plan **LEGADO ACME** muestra campos extra en el modal (`#legado-fields`): nombre del niño, nombre del padre, notas.

---

## Integraciones

### EmailJS
- CDN: `@emailjs/browser@4`
- Constantes en `index.html` línea ~3523: `EMAILJS_PUBLIC_KEY`, `EMAILJS_SERVICE_ID`, `EMAILJS_TEMPLATE_ID`
- **Estado**: pendiente de configurar — valores actuales son placeholders `TU_..._AQUI`
- La bandera `EMAILJS_CONFIGURED` evita llamadas reales hasta que se llenen las keys
- Correo de pruebas hardcodeado: `ismaelemergencia.46@gmail.com`
- Variables del template: `to_name`, `to_email`, `bcc_to`, `plan_type`, `telefono`, `fecha_inicio`, `nombre_padre`, `nombre_nino`, `fuente`, `notas`, `año`

### Supabase
- **Estado**: ✅ Integrado
- **URL**: `https://gtucbxhcamowdrfxznot.supabase.co`
- **Anon key**: configurada en `index.html` y `admin/index.html` (hardcoded, es pública por diseño)
- CDN usado: `@supabase/supabase-js@2/dist/umd/supabase.js` — IMPORTANTE: usar siempre la ruta `/dist/umd/supabase.js`, sin ella se carga el módulo ESM que no expone el global `supabase` y falla con ReferenceError.
- **Tablas creadas**:
  - `leads` — membresías del formulario web
  - `clases` — reservas clase única del formulario web
  - `pagos_efectivo` — cobros manuales en efectivo desde admin
- **Permisos (GRANTs en Supabase)**:
  - `anon`: INSERT en `leads` y `clases`
  - `authenticated`: ALL en las 3 tablas
- **RLS**: deshabilitado en `leads` y `clases` (acceso controlado por GRANTs); `pagos_efectivo` con RLS habilitado solo para autenticados
- **NOTA CRÍTICA RLS**: Si en el futuro se necesita re-habilitar RLS en `leads`/`clases`, usar `as permissive for insert to public with check (true)` — NO usar `to anon`, causa error 42501 incluso con GRANTs correctos. Después de cualquier cambio de RLS, refrescar el schema cache en Supabase: Project Settings → API → Reload schema.
- **Realtime**: habilitado en las 3 tablas → el admin se actualiza en vivo sin recargar

### Vercel
- `vercel.json` configurado con URLs limpias, headers de seguridad, rewrites
- Rewrite `/admin` → `/admin/index.html` agregado

---

## Flujo de datos (formulario web → Supabase → Admin)

```
Usuario web llena modal-membresia o modal-clase
  └── submitForm() en index.html
        ├── sb.from('leads' | 'clases').insert(...)  → Supabase
        ├── sendWelcomeEmail(data)                   → EmailJS (pendiente config)
        └── window.open('payment.html?...')          → Página de pago

Supabase Realtime → admin/index.html
  └── tabla actualiza en vivo, toast de notificación aparece
```

---

## Panel de administración (`admin/index.html`)

- **Ruta**: `/admin` (rewrite en vercel.json)
- **Auth**: Supabase Auth email + contraseña. Crear usuario en Supabase → Authentication → Users → Add user.
- **Diseño**: tema oscuro brand (--bg #060606, --red, --gold), Google Fonts Oswald/Inter, iconos SVG inline (sin emojis), watermark con `logo.svg` al 4% de opacidad.
- **Funcionalidades**:
  - Login / logout con sesión persistente (Supabase maneja cookies)
  - Dashboard: 5 stat cards (total leads, esta semana, activos, clases, efectivo recaudado) + tabla de últimos 10 registros combinados
  - Tab Membresías: tabla con búsqueda/filtros, modal detalle con editar teléfono, cambiar estado (pendiente → contactado → activo → inactivo), aplicar descuento % con cálculo de precio final
  - Tab Clases: tabla con búsqueda/filtros, modal detalle con editar teléfono, cambiar estado (pendiente → confirmado → asistio → no_asistio)
  - Tab Cobros en Efectivo: formulario para registrar cobros manuales, tabla con total acumulado, eliminar registros
  - Export CSV en cada sección (con BOM UTF-8 para Excel)
  - Realtime: INSERT/UPDATE/DELETE en las 3 tablas se reflejan sin recargar

---

## Schema SQL de Supabase (referencia)

```sql
-- Tablas
create table leads (id uuid primary key default gen_random_uuid(), created_at timestamptz default now(), nombre text, email text, pais_codigo text, telefono text, plan text, fecha_inicio date, experiencia text, fuente text, notas text, nombre_padre text, nombre_nino text, estado text default 'pendiente', descuento integer default 0, precio_final numeric);
create table clases (id uuid primary key default gen_random_uuid(), created_at timestamptz default now(), nombre text, email text, pais_codigo text, telefono text, plan text, fecha_preferida date, primera_vez text, condicion text, fuente text, notas text, estado text default 'pendiente');
create table pagos_efectivo (id uuid primary key default gen_random_uuid(), created_at timestamptz default now(), fecha_pago date default current_date, nombre_cliente text, plan text, monto numeric, concepto text, registrado_por text, notas text);

-- Permisos
alter table leads  disable row level security;
alter table clases disable row level security;
grant insert on leads, clases to anon;
grant all on leads, clases, pagos_efectivo to authenticated;
alter table pagos_efectivo enable row level security;
create policy "auth_all" on pagos_efectivo as permissive for all to authenticated using (true) with check (true);
```

---

## Secciones de index.html (en orden DOM)

| ID | Nombre visible |
|---|---|
| `#inicio` | Hero |
| `#espacios` | Espacios / Instalaciones |
| `#mapa` | Mapa de planta (tabs por piso) |
| `#planes` | Membresías (tabs adultos / niños / familiar) |
| `#clases` | Clases |
| `#recuperacion` | Recuperación |
| `#kids` | Zona Niños & Familia |
| `.contact-bar` | Barra de contacto |
| `footer` | Footer |

---

## Modales en index.html

| ID modal | Propósito |
|---|---|
| `modal-membresia` | Inscripción a membresía → guarda en `leads` |
| `modal-clase` | Reservar clase única → guarda en `clases` |

Flujo `submitForm()`: INSERT Supabase → sendWelcomeEmail() → redirect payment.html (solo membresías).

---

## i18n (ES / EN)

- Objeto `DICT` en `index.html` con claves `es` y `en`
- `data-i18n="clave"` en HTML para texto, `data-i18n-placeholder="clave"` para placeholders
- `applyLang(lang)` aplica idioma; `window.toggleLang()` alterna y persiste en `localStorage`
- Chatbot: `KB` (ES) y `KB_EN` (EN), chips: `FAQ_CHIPS` / `FAQ_CHIPS_EN`

---

## Variables CSS globales

```css
--red: #E5001A   --red-l: #FF2030   --red-d: #AA0012
--gold: #C9A84C  --gold-l: #E0C06A
--bg: #060606    --card: #111111
--font-h: 'Oswald'   --font-b: 'Inter'
```

---

## Historial de cambios importantes

| Fecha | Cambio |
|---|---|
| 2026-06-16 | Admin panel: watermark logo, emojis → iconos SVG profesionales |
| 2026-06-16 | Backend Supabase completo + `admin/index.html` creado |
| 2026-06-16 | Creación de MEMORY.md |
| ~2026-06 | `vercel.json` agregado para deploy en Vercel |
| ~2026-06 | Zona Niños: eliminado mini octágono, renombrada zona de padres |
| ~2026-06 | Plan LEGADO ACME actualizado, formulario y flujo de correo/pago |
| ~2026-06 | Rediseño completo sección planes con tabs de audiencia |
| ~2026-06 | Switch ES/EN implementado en todas las páginas |

---

## Notas y decisiones de diseño

- El sitio es **HTML/CSS/JS puro**, sin framework ni bundler. Mantenerlo así salvo decisión explícita.
- Toda clase `.section` usa `padding: 110px 0` y animaciones `.fade-in` via IntersectionObserver con `data-delay="1-6"`.
- El scroll personalizado usa curva `easeInOutCubic` a 950ms, con offset de navbar.
- Logos en círculos con borde gold/red (border-radius 50%).
- El chatbot se cierra al hacer clic fuera de él.
- El panel admin NO usa emojis — iconos SVG inline con `stroke: currentColor`.
