select paci.nombrecompleto as nomnre_paciente
, convert(date,fecha) as fecha_cita
,citas.hora 
,citas.meridiano
, smd.nombre as Medico
, sis_especialidades.nombre as Especialidad
,asunto.nombre as Asunto_cita
, citas.id as Id_cita 
,sede.Nombre as sede
,CONVERT(varchar(max),CASE WHEN ISNULL(paci.telefono,'')='' THEN  (SELECT STUFF((SELECT ', ' + numero 
		from telefonos_usuarios 
		where autoid=paci.autoid
		for xml path('')),1,1,''))  ELSE paci.TELEFONO END) as Telefono

from citas 

LEFT JOIN sis_medi as smd on smd.codigo = citas.cod_medi 
LEFT JOIN sis_especialidades ON sis_especialidades.codigo = smd.especialidad
LEFT JOIN sis_paci as paci ON paci.autoid = citas.autoid
LEFT JOIN puntoAtencion as sede ON sede.id = citas.id_sede
LEFT JOIN sis_asunto as asunto ON asunto.id = citas.asunto
where  citas.estado = 'p'
and asunto.activo = '1'
AND citas.fecha >= GETDATE()

--and paci.tipo_id = 'CC'
--and paci.num_id = '23114749'




