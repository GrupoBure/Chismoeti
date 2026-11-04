-- CHISMOETI SEMANAL | INSTALACIÓN DE EDICIÓN 01
-- Ejecutar una sola vez desde Supabase SQL Editor (rol postgres).
-- No modifica 'perfiles', 'admins', 'cools' ni los contactos.
BEGIN;

CREATE TABLE IF NOT EXISTS public.resumenes_semanales (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 titulo text NOT NULL,
 semana_inicio date NOT NULL UNIQUE,
 semana_fin date NOT NULL,
 contenido jsonb NOT NULL DEFAULT '{}'::jsonb,
 publicado boolean NOT NULL DEFAULT false,
 created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.resumenes_semanales ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.resumenes_semanales FROM anon;
GRANT SELECT ON TABLE public.resumenes_semanales TO authenticated;

DROP POLICY IF EXISTS "Chismoeti resumen: leer solo con perfil" ON public.resumenes_semanales;
CREATE POLICY "Chismoeti resumen: leer solo con perfil"
ON public.resumenes_semanales FOR SELECT TO authenticated
USING (
 publicado = true
 AND EXISTS (
   SELECT 1 FROM public.perfiles p
   WHERE p.user_id = (SELECT auth.uid())
 )
);

-- Ninguna política pública ni anónima de lectura.

INSERT INTO public.resumenes_semanales
(titulo,semana_inicio,semana_fin,publicado,contenido)
VALUES (
 'El Chismoeti Semanal · Edición 01',
 DATE '2026-10-26',
 DATE '2026-11-01',
 true,
 $edicion$
{
 "numero":"01",
 "intro":"A ver, generación: uno se desconecta tantito y cuando vuelve ya tienen 3,494 mensajes, más de mil stickers y hasta planes de reencuentro. 😂 Hubo recuerdos de la secu, películas pa' no dormir, pláticas de ayudar a otros y ofrendas de Día de Muertos. Ahí les va el chisme para que no anden preguntando qué pasó.",
 "estadisticas":[
  {"valor":"3,494","etiqueta":"Mensajes de participantes"},
  {"valor":"1,144","etiqueta":"Stickers"},
  {"valor":"23","etiqueta":"Fotografías adjuntas"},
  {"valor":"29 oct.","etiqueta":"Día más movido"}
 ],
 "secciones":[
  {"titulo":"📚 Los traumas... digo, los recuerdos de la secu","texto":"Empezamos hablando de los aplicados de cada salón y terminamos sacando los expedientes de los talleres: carpintería, contabilidad, máquinas y hasta los profes que nos traían cortitos. También salió el tema de quién le ayudaba a quién con los exámenes. La memoria ya anda haciendo horas extra. 😂"},
  {"titulo":"🎬 Recomendaciones para no dormir","texto":"Entre martes y miércoles se armó el cineclub. Salió Los otros, el terror psicológico, comedias y hasta animación stop motion. Para unos era noche de película y para otros la excusa perfecta para seguir pegados al WhatsApp. 🍿"},
  {"titulo":"🥂 Mucho «hay que vernos»… ¿pero quién organiza?","texto":"Salieron las fiestas de antes, las pulquerías y los recuerdos que unos cuentan y otros seguramente preferirían borrar. 🤣 También volvió a sonar el 15 de noviembre. Ganas hay, eso que ni qué; ahora falta que los planes no se queden viviendo eternamente en el WhatsApp."},
  {"titulo":"🤝 Y no todo fue echar desmadre","texto":"El viernes salió una propuesta que merece aplauso: organizarnos para apoyar a personas que esperan afuera de hospitales. Se habló de enero, cuando baja la ayuda de temporada. En la encuesta había 20 votos a favor y ninguno en contra al momento de exportar el chat. Entre tanta carrilla, también hay banda con ganas de hacer algo chido. 💚"},
  {"titulo":"🕯️ Entre catrinas, ofrendas y recuerdos","texto":"Para cerrar la semana llegaron las fotos de ofrendas, las catrinas y recuerdos de quienes ya no están. Hasta las comidas favoritas salieron en la plática. Se puso bonito el ambiente: este grupo no es puro sticker y carrilla."},
  {"titulo":"📱 Y sí, también salió Chismoeti","texto":"Se volvió a compartir la página y a recordar que llenen sus perfiles. Porque con tantos apodos y tantos años encima, ya hace falta una ficha técnica para saber quién es quién. 😂"}
 ],
 "premios":[
  {"titulo":"🎭 CAZM — «Sigue queriendo llamar la atención»","texto":"Pasan los años, cambian las modas, se nos va la memoria… pero CAZM sigue queriendo llamar la atención. 🤣 ¡Denle su reflector, hombre! Carrilla editorial propuesta por un compañero, no una estadística ni un diagnóstico."},
  {"titulo":"🏅 El día que se les soltó el dedo","texto":"Jueves 29 de octubre: 1,094 mensajes. ¿Ustedes trabajan o nomás andan contando sus historias? 😂"},
  {"titulo":"🏅 Campeonato nacional de stickers","texto":"1,144 stickers compartidos. Si esto fuera deporte olímpico, ya estaríamos peleando medalla."}
 ],
 "galeria":[
  {"ruta":"edicion-01/IMG-20261030-WA0067.jpg","descripcion":"Foto escolar compartida durante la búsqueda de excompañeros, 30 de octubre."},
  {"ruta":"edicion-01/IMG-20261027-WA0064.jpg","descripcion":"Recomendación de cine compartida la noche del 27 de octubre."},
  {"ruta":"edicion-01/IMG-20261030-WA0035.jpg","descripcion":"Festival de Día de Muertos en Chapultepec, compartido el 30 de octubre."},
  {"ruta":"edicion-01/IMG-20261030-WA0036.jpg","descripcion":"Otra actividad cultural compartida el mismo día."},
  {"ruta":"edicion-01/IMG-20261029-WA0599.jpg","descripcion":"Recuerdo de convivencia compartido el 29 de octubre."}
 ],
 "cierre":"La semana en números: 26 oct. 349 · 27 oct. 665 · 28 oct. 359 · 29 oct. 1,094 · 30 oct. 609 · 31 oct. 299 · 1 nov. 119. Datos calculados del ZIP exportado; no es una estadística oficial de WhatsApp."
}
 $edicion$::jsonb
)
ON CONFLICT (semana_inicio)
DO UPDATE SET
 titulo = EXCLUDED.titulo,
 semana_fin = EXCLUDED.semana_fin,
 contenido = EXCLUDED.contenido,
 publicado = EXCLUDED.publicado;

-- Bucket privado: NO es un enlace público de Dropbox ni GitHub.
INSERT INTO storage.buckets (id, name, public)
VALUES ('chismoeti_semanal','chismoeti_semanal',false)
ON CONFLICT (id) DO UPDATE SET public=false;

DROP POLICY IF EXISTS "Chismoeti semanal: fotos solo compañeros" ON storage.objects;
CREATE POLICY "Chismoeti semanal: fotos solo compañeros"
ON storage.objects FOR SELECT TO authenticated
USING (
 bucket_id = 'chismoeti_semanal'
 AND EXISTS (
  SELECT 1 FROM public.perfiles p
  WHERE p.user_id = (SELECT auth.uid())
 )
);

DROP POLICY IF EXISTS "Chismoeti semanal: solo admin sube" ON storage.objects;
CREATE POLICY "Chismoeti semanal: solo admin sube"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
 bucket_id = 'chismoeti_semanal'
 AND EXISTS (
  SELECT 1 FROM public.admins a
  WHERE a.user_id = (SELECT auth.uid())
 )
);

DROP POLICY IF EXISTS "Chismoeti semanal: solo admin reemplaza" ON storage.objects;
CREATE POLICY "Chismoeti semanal: solo admin reemplaza"
ON storage.objects FOR UPDATE TO authenticated
USING (
 bucket_id = 'chismoeti_semanal'
 AND EXISTS (
  SELECT 1 FROM public.admins a
  WHERE a.user_id = (SELECT auth.uid())
 )
)
WITH CHECK (
 bucket_id = 'chismoeti_semanal'
 AND EXISTS (
  SELECT 1 FROM public.admins a
  WHERE a.user_id = (SELECT auth.uid())
 )
);

COMMIT;

-- Comprobación: la edición existe y el bucket no es público.
SELECT semana_inicio, titulo, publicado
FROM public.resumenes_semanales
WHERE semana_inicio = '2026-10-26';
SELECT id, public FROM storage.buckets WHERE id='chismoeti_semanal';
