-- Chismoeti Blog: entradas independientes por semana; privacidad real con RLS.
-- Ejecutar en Supabase SQL Editor. No modifica tablas de perfiles, contactos o admins.
BEGIN;
CREATE TABLE IF NOT EXISTS public.chismoeti_blog_posts (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 fecha date NOT NULL,
 semana_inicio date NOT NULL,
 titulo text NOT NULL,
 categoria text NOT NULL DEFAULT 'chisme',
 texto text NOT NULL,
 publicado boolean NOT NULL DEFAULT false,
 orden integer NOT NULL DEFAULT 0,
 creado timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT blog_fecha_titulo_unique UNIQUE(fecha,titulo)
);
ALTER TABLE public.chismoeti_blog_posts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.chismoeti_blog_posts FROM anon;
GRANT SELECT ON public.chismoeti_blog_posts TO authenticated;
DROP POLICY IF EXISTS "Blog solo companeros vinculados" ON public.chismoeti_blog_posts;
CREATE POLICY "Blog solo companeros vinculados" ON public.chismoeti_blog_posts FOR SELECT TO authenticated
USING (publicado AND EXISTS(SELECT 1 FROM public.perfiles p WHERE p.user_id=(SELECT auth.uid())));
INSERT INTO public.chismoeti_blog_posts(fecha,semana_inicio,titulo,categoria,texto,publicado,orden) VALUES
('2026-10-07', '2026-10-05', 'El regreso de los que juraban no volver a saber de la secu', 'reencuentros', 'Apenas se estaba armando el grupo y ya había encuesta: ¿peda hasta ver el amanecer o pícnic con etiqueta? La primera opción arrancó ganando por 12 votos contra 4. Entre saludos, apodos y gente diciendo «¿tú en qué grupo ibas?», el WhatsApp empezó a revivir la generación E-6. Hubo compañeros conectándose desde otros estados y hasta del extranjero.

Y para quien llegaba tarde y no sabía quién era quién, el 7 de octubre apareció Chismoeti. Porque no estábamos para leer 800 mensajes sólo para ubicar al del taller de enfrente. 😂', true, 0),
('2026-10-08', '2026-10-05', 'El expediente secreto de los talleres (y la memoria que ya no coopera)', 'recuerdos', 'Volvieron las historias de Secretariado, Contabilidad y Máquinas y Herramientas. Que si la máquina de escribir, que si aquel profe, que si la credencial, que si a quién encontraste después de tantos años. Entre varios intentaron reconstruir nombres, caras y amistades, con la misma certeza de siempre: «me acuerdo perfecto… bueno, más o menos». 🤣

También salieron compañeros que viven lejos y el gusto genuino de volver a encontrar a la banda.', true, 1),
('2026-10-13', '2026-10-12', 'Máquinas de escribir, talleres y la secu que no perdona', 'recuerdos', 'El taller de Secretariado regresó con el ruido de las máquinas de escribir y los dedos congelados. Alma Nayelli recordó las horas de teclear hojas enteras y repetirlas; varios también revivieron el tema de Contabilidad y Máquinas y Herramientas, incluyendo el susto que provocó una bata demasiado grande cerca de un torno.

Ahora los hijos se sorprenden de que sus papás escriban rápido sin mirar el teclado. Pues claro: esos dedos salieron de la escuela con entrenamiento militar. 😂', true, 2),
('2026-10-15', '2026-10-12', 'Se puso fecha: ¡al Parque Tezozómoc, generación!', 'reencuentros', 'Marvin anunció una primera reunión tranquila para el domingo 15 de noviembre a las 11 de la mañana en el Parque Tezozómoc. La idea era llevar algo para compartir y volver a reconocernos en persona antes de aventarnos a una reunión más fiestera en diciembre.

Ya saben cómo es esto: organizarse en WhatsApp es fácil; lograr que todos lleguen a la misma hora será la verdadera prueba de supervivencia. 🧺', true, 3),
('2026-10-21', '2026-10-19', '¿A qué se dedica la banda? Se abrió la bolsa de trabajo del chisme', 'vida', 'El 21 de octubre la plática se puso interesante: salieron historias de quienes trabajan en cocina y catering, diseño, capacitación, asesoría, comercios y otros oficios. Después de tantos años, nos enteramos de a qué se dedica cada quien y cómo se las ha ingeniado para salir adelante.

También surgió una idea muy de la generación: apoyar el negocio de una compañera y armar una prereunión en su cafetería. Porque si vamos a gastar en café, que al menos el chisme deje algo entre amigos. ☕', true, 4),
('2026-10-22', '2026-10-19', 'El día que WhatsApp casi pidió vacaciones', 'recuerdos', 'El jueves 22 hubo un bombardeo de mensajes: llegaron más compañeros, nuevas presentaciones y una reconstrucción colectiva de amistades, grupos y anécdotas. Algunos apenas podían ponerse al corriente.

Entre el entusiasmo por reencontrarse y las bromas que sólo entienden quienes estuvieron ahí, el grupo demostró que después de tantos años todavía nos sobra conversación.', true, 5),
('2026-10-27', '2026-10-26', '¿Secretariado o Contabilidad? El taller que todavía nos persigue', 'recuerdos', 'Se armó otra ronda de recuerdos de talleres: hubo quien hubiera preferido Dibujo, quien se aburría con la teoría y quien reconoció que el certificado técnico sí le sirvió en sus primeros trabajos. Los de Secretariado recordaron aquellas máquinas durísimas; otros hablaron de lo pesadas que eran las tareas.

Y luego llegó la frase inevitable: «ahora entiendo el estrés de los maestros». Los años no pasan de gratis, cabrones. 😂', true, 6),
('2026-10-29', '2026-10-26', 'Un café, tantitos mensajes… ¡y ya van treinta y cinco!', 'chisme', 'Marvin contó que revisó el teléfono mientras tomaba café: al principio nada, y al terminar ya tenía 35 mensajes nuevos. Jorge dijo que hasta en una capacitación lo habían visto feo por estar pendiente del chismecito.

El jueves 29 fue el día más movido de esa semana. Por algo el resumen necesitaba su propio blog: no hay pulgar humano que aguante tanto scroll. 🤣', true, 7),
('2026-10-30', '2026-10-26', 'Y no todo fue carrilla: una propuesta para ayudar', 'comunidad', 'Entre stickers y bromas, el viernes salió una propuesta muy chida: organizar apoyo para personas que esperan afuera de hospitales. También se habló de hacerlo en enero, cuando suele haber menos iniciativas que en diciembre. La encuesta compartida en el chat llevaba 20 votos a favor y ninguno en contra.

A veces debajo de todo el desmadre sale lo mejor de esta generación. ❤️', true, 8),
('2026-10-31', '2026-10-26', 'Cine, ofrendas y recuerdos de los que ya no están', 'vida', 'Durante la semana se compartieron películas, recomendaciones de terror psicológico y actividades culturales. Al llegar Día de Muertos aparecieron fotos de ofrendas, eventos y recuerdos familiares.

La conversación cambió de tono: menos carrilla por un momento y más cariño por las personas que siguen presentes en la memoria. 🕯️', true, 9),
('2026-11-02', '2026-11-02', 'El admin ya tuvo reencuentros… ¿y apenas nos enteramos?', 'chisme', 'Marvin contó que ya había tenido encuentros con compañeros del grupo, incluido Oliver, y que había salido con Karla. Ivonne soltó que también se había reencontrado con alguien… pero se guardó el nombre. Por supuesto, el grupo pidió explicaciones y evidencias inmediatamente. 🤣

Al final resultó que ya había más reencuentros de los que varios imaginaban. Y aquí uno esperando al 15 de noviembre como si fuera el estreno oficial.', true, 10),
('2026-11-03', '2026-11-02', 'Antes y después: las fotos que nos van a exhibir a todos', 'fotos', 'Empezaron a circular recuerdos, fotos de otras épocas y la idea de hacer una dinámica de «antes y ahora» con nombre y grupo. Algunos prometieron buscar discos duros y álbumes viejos; otros confesaron que no encuentran ni una foto de aquellos ayeres.

También hubo invitación a una actividad de serigrafía el 21 de noviembre. Total: apenas empezó la semana y ya tenemos material para otra edición. 📸', true, 11)
ON CONFLICT(fecha,titulo) DO UPDATE SET texto=EXCLUDED.texto,categoria=EXCLUDED.categoria,publicado=EXCLUDED.publicado,orden=EXCLUDED.orden;

CREATE TABLE IF NOT EXISTS public.chismoeti_blog_imagenes (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 post_id uuid NOT NULL REFERENCES public.chismoeti_blog_posts(id) ON DELETE CASCADE,
 ruta text NOT NULL UNIQUE,
 pie text NOT NULL DEFAULT '',
 creado timestamptz DEFAULT now()
);
ALTER TABLE public.chismoeti_blog_imagenes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.chismoeti_blog_imagenes FROM anon;
GRANT SELECT,INSERT ON public.chismoeti_blog_imagenes TO authenticated;
DROP POLICY IF EXISTS "Fotos blog lectura registrados" ON public.chismoeti_blog_imagenes;
CREATE POLICY "Fotos blog lectura registrados" ON public.chismoeti_blog_imagenes FOR SELECT TO authenticated
USING(EXISTS(SELECT 1 FROM public.perfiles p WHERE p.user_id=(SELECT auth.uid())));
DROP POLICY IF EXISTS "Fotos blog insercion administradores" ON public.chismoeti_blog_imagenes;
CREATE POLICY "Fotos blog insercion administradores" ON public.chismoeti_blog_imagenes FOR INSERT TO authenticated
WITH CHECK(EXISTS(SELECT 1 FROM public.admins a WHERE a.user_id=(SELECT auth.uid())));
INSERT INTO storage.buckets(id,name,public) VALUES('chismoeti_semanal','chismoeti_semanal',false)
ON CONFLICT(id) DO UPDATE SET public=false;
DROP POLICY IF EXISTS "Chismoeti blog fotos ver" ON storage.objects;
CREATE POLICY "Chismoeti blog fotos ver" ON storage.objects FOR SELECT TO authenticated
USING(bucket_id='chismoeti_semanal' AND EXISTS(SELECT 1 FROM public.perfiles p WHERE p.user_id=(SELECT auth.uid())));
DROP POLICY IF EXISTS "Chismoeti blog fotos subir" ON storage.objects;
CREATE POLICY "Chismoeti blog fotos subir" ON storage.objects FOR INSERT TO authenticated
WITH CHECK(bucket_id='chismoeti_semanal' AND EXISTS(SELECT 1 FROM public.admins a WHERE a.user_id=(SELECT auth.uid())));
COMMIT;
SELECT semana_inicio,count(*) AS entradas FROM public.chismoeti_blog_posts GROUP BY semana_inicio ORDER BY semana_inicio;