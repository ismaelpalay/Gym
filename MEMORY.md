# MEMORY — ACME Fight & Fitness
Última actualización: 2026-06-16

---

## Estado actual del proyecto

- **Sitio web**: `marcaacme.vercel.app` — repo `ismaelpalay/Gym`, rama `claude/html-professional-webpage-XCwl4`
- **Panel admin**: `gym-admin-kappa-amber.vercel.app` — proyecto Vercel separado en `/Users/invitado/Desktop/gym-admin/`
- **Archivos principales**: `index.html` (~4600 líneas), `payment.html`, `faq.html`, `privacy.html`, `terminos.html`
- **Deploy**: `vercel --prod --yes --scope ismael-palay-s-projects` desde cada carpeta

---

## Planes y precios

| Plan | Precio | Periodo | Audiencia |
|---|---|---|---|
| FIGHT | $499 | por sesión | Adultos |
| CAMPEÓN | $2,999 | al mes | Adultos |
| ÉLITE | $3,999 | al mes | Adultos Premium |
| VALOR | $329 | por sesión | Niños |
| PROSPECTO | $2,799 | al mes | Niños |
| LEGADO ACME | $4,999 | al mes | Familiar |

**Duración de membresía** (para cálculo de `fecha_expiracion`):
- FIGHT / VALOR → sesión única → `fecha_expiracion = null`
- CAMPEÓN / ÉLITE / PROSPECTO / LEGADO ACME → 30 días

---

## Arquitectura de datos (Supabase)

### Flujo de datos

```
Web form (modal-membresia)
  └── INSERT leads  (estado: pendiente)
  └── INSERT registros_totales (tipo: 'membresia')

Web form (modal-clase)
  └── INSERT clases (estado: pendiente)
  └── INSERT registros_totales (tipo: 'clase')

Admin cobro en efectivo
  └── INSERT pagos_efectivo
  └── INSERT miembros  (ref_pago_id → pagos_efectivo.id)
  └── INSERT registros_totales (tipo: 'efectivo', ref_id → miembros.id)

Admin "Promover a Miembro"
  └── INSERT miembros (desde un lead)
  └── UPDATE registros_totales (ref_id → miembros.id)
  └── DELETE leads
```

### Tablas

```sql
-- LEADS — solo visitantes web que NO completaron pago
leads (id, created_at, nombre, email, pais_codigo, telefono, plan,
       fecha_inicio, experiencia, fuente, notas, nombre_padre, nombre_nino,
       estado [pendiente|contactado], descuento, precio_final)

-- MIEMBROS — pagantes reales (web promovidos + efectivo)
miembros (id, created_at, nombre, email, pais_codigo, telefono, plan,
          fecha_inicio, fecha_expiracion, estado [activo|inactivo],
          fuente, notas, ref_pago_id)

-- CLASES — reservas de sesión única
clases (id, created_at, nombre, email, pais_codigo, telefono, plan,
        fecha_preferida, primera_vez, condicion, fuente, notas,
        estado [pendiente|confirmado|asistio|no_asistio])

-- PAGOS EN EFECTIVO — registro financiero
pagos_efectivo (id, created_at, fecha_pago, nombre_cliente, pais_codigo,
                telefono, email, plan, monto, concepto, notas, registrado_por)

-- REGISTROS TOTALES — conteo global para dashboard
registros_totales (id, created_at, nombre, email, pais_codigo, telefono,
                   plan, tipo, estado, fuente, ref_id)
   -- ref_id → miembros.id (para sync de cobros en efectivo)
   -- tipo: 'membresia' | 'clase' | 'efectivo'
```

### Permisos

```sql
-- RLS deshabilitado en tablas con inserción pública
alter table leads            disable row level security;
alter table clases           disable row level security;
alter table miembros         disable row level security;
alter table registros_totales disable row level security;
grant insert on leads, clases to anon;
grant all on leads, clases, pagos_efectivo, miembros, registros_totales to authenticated;

-- pagos_efectivo con RLS solo para autenticados
alter table pagos_efectivo enable row level security;
create policy "auth_all" on pagos_efectivo as permissive for all to authenticated using (true) with check (true);

-- Realtime habilitado en todas las tablas
alter publication supabase_realtime add table miembros;
```

### Función de expiración automática

```sql
create or replace function marcar_expirados()
returns void language sql as $$
  update miembros set estado = 'inactivo'
  where estado = 'activo' and fecha_expiracion is not null and fecha_expiracion < current_date;
  update registros_totales rt set estado = 'inactivo'
  from miembros m where rt.ref_id = m.id and m.estado = 'inactivo' and rt.estado != 'inactivo';
$$;
```
El admin llama `marcar_expirados()` en JS al iniciar (sin RPC, lo hace client-side comparando fechas).

---

## Panel de administración

**URL**: `gym-admin-kappa-amber.vercel.app`
**Auth**: Supabase email + contraseña + hCaptcha (site key: `532074d2-e8a0-441c-8fc2-2558ef007b90`)

### Pestañas

| Pestaña | Descripción |
|---|---|
| Dashboard | Stats: total registros, semana, miembros activos, leads pendientes, efectivo. Últimos 10 registros. |
| Leads Web | Solo visitas web sin pago completado (estado: pendiente/contactado). Botón "Promover a Miembro". |
| Miembros | Pagantes activos/inactivos con fecha de expiración. Botón QR de acceso. |
| Clases | Reservas de sesión única. Cambio de estado. |
| Cobros en Efectivo | Formulario manual → crea Miembro + pagos_efectivo + registros_totales. |

### Funcionalidades clave

- **Expiración automática**: al iniciar el admin, detecta miembros con `fecha_expiracion < hoy` y los pasa a `inactivo` (también actualiza `registros_totales`).
- **QR de acceso**: genera imagen QR via `api.qrserver.com` con datos del miembro. Imprimible.
- **Borrar en cascada**: eliminar cobro → borra miembro + registros_totales (via `ref_id`). Eliminar lead/clase → borra entrada en registros_totales por nombre+email+tipo.
- **Promover lead**: mueve lead a miembros, calcula `fecha_expiracion`, actualiza registros_totales.
- **Sync de estado**: cambiar estado de un miembro también actualiza `registros_totales.estado`.
- **Realtime**: todas las tablas actualizan el UI sin recargar.
- **Export CSV**: disponible en cada pestaña.

---

## Integraciones

### Supabase
- **URL**: `https://gtucbxhcamowdrfxznot.supabase.co`
- **CDN CRÍTICO**: siempre usar `/dist/umd/supabase.js` — sin esa ruta carga ESM y falla con ReferenceError.
- **RLS**: `leads` y `clases` con RLS deshabilitado. Si se reactiva, usar `as permissive for insert to public with check (true)` (NO `to anon`).

### EmailJS
- CDN `@emailjs/browser@4`, constantes en `index.html` aún con placeholders `TU_..._AQUI`
- Bandera `EMAILJS_CONFIGURED = false` evita llamadas reales
- Template vars: `to_name`, `to_email`, `bcc_to`, `plan_type`, `telefono`, `fecha_inicio`, `nombre_padre`, `nombre_nino`, `fuente`, `notas`, `año`

### Vercel
- Sitio web: `vercel.json` con cleanUrls, headers seguridad, rewrites (`/privacy`, `/terminos`, `/faq`, `/payment`)
- Admin: `vercel.json` separado con `X-Frame-Options: DENY`
- Deploy: `vercel --prod --yes --scope ismael-palay-s-projects`

---

## Variables CSS globales (index.html)

```css
--red: #E5001A   --red-l: #FF2030   --red-d: #AA0012
--gold: #C9A84C  --gold-l: #E0C06A
--bg: #060606    --card: #111111
--font-h: 'Oswald'   --font-b: 'Inter'
```

---

## Notas de diseño

- HTML/CSS/JS puro — sin framework ni bundler. Mantener así.
- Admin: sin emojis, iconos SVG inline con `stroke: currentColor`.
- Watermark logo al 4% de opacidad en el admin.
- Clases `.section` usan `padding: 110px 0` + `.fade-in` via IntersectionObserver con `data-delay="1-6"`.
- i18n ES/EN en index.html: objeto `DICT` + `data-i18n="clave"`. Cambiar siempre en `DICT`, no en HTML directo.
