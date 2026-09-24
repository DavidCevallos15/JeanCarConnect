# Plan completo del proyecto

Plan de implementación (backend + frontend + despliegue + entrega) para JEANCAR CONNECT — expande el roadmap resumido de Documentación técnica en fases con tareas concretas.

## Fases

| Fase | Objetivo | Entregable técnico | Módulos RF | Duración |
| --- | --- | --- | --- | --- |
| 0. Setup | Repo + infra | Repo React+Vite+TS, proyecto Supabase, CI básico, `.env` | Base | 2 días |
| 1. Backend core | Schema + Auth | Migraciones SQL, tablas, RLS, Supabase Auth configurado | RF1, RF2 (base) | 3-4 días |
| 2. Frontend auth | Cuentas | Login/registro Cliente y Mecánico, rutas protegidas | RF1, RF2 | 3-4 días |
| 3. Catálogo | Servicios | CRUD servicios (RLS backend + UI mecánico) | RF6, RF7 | 3-4 días |
| 4. Reservas | Reservas/órdenes | Backend estado + triggers, UI crear/editar, vista cliente y mecánico | RF3, RF4 | 5-7 días |
| 5. Documentos | PDF | Generación PDF reserva/factura, bucket Storage | RF5, RF9, RF10 | 3-4 días |
| 6. Facturación | Pagos y facturas | Cálculo automático backend, UI registrar pago, marcar pagada | RF8 | 4-5 días |
| 7. QA | Pruebas | Pruebas con usuarios cliente/mecánico, validación RLS, checklist de aceptación | Todos | 3 días |
| 8. Deploy | Producción | Deploy Vercel + Supabase prod, dominio, variables de entorno | — | 1-2 días |
| 9. Entrega | Handoff | Capacitación a la compañera/mecánico, manual corto de uso, entrega de credenciales | — | 1-2 días |

**Total: \~5-6 semanas trabajando medio tiempo.**

## Dependencias y paralelización

- Fase 1 (backend) es prerrequisito de todo lo demás — Devin puede correrla independiente mientras David arma el scaffold del Fase 0 en frontend.
- Fases 2-6 son secuenciales en solitario; si David suma a alguien más, Fase 3 (catálogo) puede correr en paralelo con el cierre de Fase 2.
- Fase 7 (QA) requiere que las Fases 1-6 estén cerradas — no arranca antes.
- Fase 9 (entrega) depende de que la compañera confirme el reencuadre "Shop Management System" vs. "CRM/ERP" (pendiente en el comentario de la pestaña Documentación técnica).

## Riesgos a vigilar

- Si el artículo científico ya está enviado/publicado, la Fase 9 se reduce a entrega técnica — sin tocar terminología del paper.
- El escáner Autel del taller no está en el alcance (RF no lo cubre) — no asumir integración con él en ninguna fase.
