# Backend — Supabase

Schema de PostgreSQL aplicado via migraciones en `supabase/migrations/`.

## Modelo de datos

| Tabla | Propósito | RF |
| --- | --- | --- |
| `profiles` | Perfil y rol (`cliente` / `mecanico`) de cada usuario de `auth.users` | RF1, RF2 |
| `servicios` | Catálogo de servicios del taller | RF6, RF7 |
| `reservas` | Reservas/órdenes con estado, vehículo y mecánico asignado | RF3, RF4 |
| `facturas` | Factura por reserva: subtotal, impuesto, total calculado, estado de pago | RF8 |
| `documentos` | Metadatos de PDFs generados (archivo en Supabase Storage, Fase 5) | RF5, RF9, RF10 |

## Seguridad (RLS)

- `profiles`: lectura/edición propia; el mecánico ve todos. Cambio de `rol` solo permitido a mecánicos (`guard_rol_change`).
- `servicios`: lectura pública de los activos; escritura solo mecánico.
- `reservas`: el cliente ve/edita solo las suyas mientras estén `pendiente` (puede cancelar); el mecánico gestiona todas.
- `facturas` / `documentos`: el cliente lee los de sus reservas; el mecánico todo.

## Registro

`handle_new_user` crea el `profile` automáticamente al registrarse un usuario, tomando `rol`, `nombre_completo` y `telefono` de `raw_user_meta_data` (cualquier valor distinto de `cliente`/`mecanico` cae a `cliente`).

## Datos iniciales

`supabase/seed.sql` — catálogo base de servicios (idempotente).
