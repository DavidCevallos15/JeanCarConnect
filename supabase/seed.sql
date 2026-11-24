-- Datos iniciales del catálogo de servicios (idempotente)
insert into public.servicios (nombre, descripcion, precio_base, duracion_min) values
  ('Cambio de aceite y filtro', 'Aceite sintético o semisintético, filtro nuevo y revisión de niveles.', 35.00, 45),
  ('Alineación y balanceo', 'Alineación computarizada de las 4 ruedas y balanceo.', 45.00, 60),
  ('Revisión y cambio de frenos', 'Inspección de pastillas, discos y líquido; cambio de pastillas incluido.', 60.00, 90),
  ('Diagnóstico general', 'Revisión completa del vehículo con reporte de hallazgos.', 20.00, 30),
  ('Cambio de llantas', 'Desmontaje, montaje y balanceo de 4 llantas.', 30.00, 45),
  ('Mantenimiento de suspensión', 'Revisión de amortiguadores, bujes y terminales.', 80.00, 120)
on conflict do nothing;
