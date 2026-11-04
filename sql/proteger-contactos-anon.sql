-- CHISMOETI · Protección de datos de contacto
-- Ejecutar en Supabase > SQL Editor DESPUÉS de revisar los privilegios existentes.
-- No cambia datos, no borra perfiles, no toca políticas de escritura.
-- Objetivo: un visitante con rol anon puede consultar perfiles, pero NO teléfono/correo.

BEGIN;

-- Retirar acceso de lectura de TODA la tabla al rol anónimo.
REVOKE SELECT ON TABLE public.perfiles FROM anon;

-- Permitir sólo las columnas que deben seguir siendo públicas.
GRANT SELECT (
  id, created_at, user_id,
  nombre, apodo, grupo, ubicacion,
  despues_secundaria, trabajo, familia, hobbies, dato_curioso,
  chismografo, foto_url, fotos_extra
) ON TABLE public.perfiles TO anon;

COMMIT;

-- COMPROBACIÓN (debe devolver false, false, true):
SELECT
  has_column_privilege('anon','public.perfiles','telefono','SELECT') AS anon_lee_telefono,
  has_column_privilege('anon','public.perfiles','correo','SELECT') AS anon_lee_correo,
  has_column_privilege('anon','public.perfiles','nombre','SELECT') AS anon_lee_nombre;

-- IMPORTANTE:
-- (1) Esto no reemplaza las políticas RLS existentes.
-- (2) El rol authenticated puede tener acceso a contactos según sus permisos
--     y políticas actuales. Para exigir PERFIL REGISTRADO en servidor hay que
--     inspeccionar y adaptar esas políticas; no asumir que la sesión basta.
-- (3) Si la tabla tiene GRANT SELECT a PUBLIC u otros roles heredados,
--     revísalos antes de considerar completa la protección.
