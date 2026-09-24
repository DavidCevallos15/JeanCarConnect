# JeanCarConnect

**JeanCar Connect** es una aplicación web para la gestión de un taller mecánico: clientes que reservan servicios, mecánicos que administran catálogo y órdenes, y facturación con generación de PDF.

## Stack

- **Frontend:** React + Vite + TypeScript (deploy en Vercel)
- **Backend:** Supabase (PostgreSQL + Auth + RLS + Storage)
- **Documentos:** Generación de PDF para reservas y facturas

## Módulos funcionales

| Módulo | Descripción |
| --- | --- |
| Autenticación | Login/registro con roles Cliente y Mecánico (Supabase Auth) |
| Catálogo | CRUD de servicios del taller (solo mecánico) |
| Reservas / Órdenes | Crear, editar y seguir el estado de reservas (cliente y mecánico) |
| Documentos | PDF de reserva/factura, almacenados en Supabase Storage |
| Facturación | Cálculo automático, registro de pagos, marcar factura pagada |

## Plan de implementación

Ver [docs/Plan.md](docs/Plan.md) — 10 fases (~5-6 semanas a medio tiempo): setup, backend core, auth, catálogo, reservas, documentos, facturación, QA, deploy y entrega.
