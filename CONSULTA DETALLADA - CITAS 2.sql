select * into #citas from citas with(nolock) 
--where convert(date,fecha)  between '2023/10/19' and '2023/10/19' 
		create nonclustered index idx_cita on #citas(id)      
		select * into #programacion_medico_detalle from programacion_medico_detalle  with(nolock)  where IdCita in (select id from #citas)
			
		  SELECT  ci.nombre_tipo_examen as nombre_tipo_examen,  convert(varchar,DATEDIFF(day,convert(date,ci.fecha_solicitud),convert(date,ci.fecha)))+' dias' as Oportunidad,
	convert(varchar,DATEDIFF(minute,convert(datetime,convert(varchar,ci.fecha_confirmacion)+' '+ci.hora_confirmacion),hc.fecha_ing))+' Minutos' as OportunidadEspera,
	isnull(isnull(hc.fecha_ing,paraclinico.fecha_estado_res),ci.fechaMarcarAtendida) as FechaAtencion,
	convert(varchar,ci.fecha_confirmacion)+' '+ci.hora_confirmacion as FechaConfirma,
	convert(varchar,DATEDIFF(day,convert(date,ci.fecha_solicitud),convert(date,ci.fecha)))+' dias' as Oportunidad,ci.motivo_cancela, fc.nombre as tipodecita,u.nombre as usuario, ref.descripcion as referencia,ref_new.cups,ref_new.nombreve,
	CONVERT(varchar(max),CASE WHEN ISNULL(sp.telefono,'')='' THEN  (SELECT STUFF((SELECT ', ' + numero 
		from telefonos_usuarios 
		where autoid=PACI.autoid
		for xml path('')),1,1,''))  ELSE SP.TELEFONO END) as tel,
	sp.full_name,sp.num_id,sp.tipo_id,cont.nombre as empre,smed.nombre as nomMed,convert(date,ci.fecha_solicitud) as fecha_solicitud,
			ci.fecha_usuario_desea_cita,
			CASE WHEN(ci.estado='CC') THEN 'Confirmada' ELSE 
			CASE WHEN(ci.estado='C') THEN 'Cancelada' ELSE
			CASE WHEN(ci.estado='A') THEN 'Atendida' ELSE 
			CASE WHEN(ci.estado='P' AND convert(date,ci.fecha) >=convert(date,GETDATE())) THEN 'Por confirmar' ELSE 
			CASE WHEN(ci.estado='P' AND convert(date,ci.fecha) < convert(date,GETDATE())) THEN 'Incumplida' 
			END END END END END AS estado,CASE WHEN(ci.Adicional=1) THEN '(Adicional)' ELSE '' END AS tipoCita
			,ci.estado as abrEstado
			,ci.id as Id_Cita
			,sasu.nombre AS nomAsunto,CONVERT(DATE,ci.fecha) AS 
			fecha_asignacion,ci.hora,ci.meridiano,ci.estudio,smuni.nombre as MunicipioPcte,
			ISNULL(smaes.prefijo,'')+''+CONVERT(varchar(max),smaes.nro_factura)	as nro_factura,
			ISNULL(smaes.vlr_neto,0) as vlr_neto, esp.nombre as especialidad
			,0 recibo,0 as VlrRecibo,PACI.DIRECCION,ba.nombres,'' as DescRecibo,ci.observacion,
			CASE WHEN(DatePart(WeekDay, prog.Fecha)=1) THEN prog.txtDom  
						WHEN(DatePart(WeekDay, prog.Fecha)=2) THEN prog.txtLun  
						WHEN(DatePart(WeekDay, prog.Fecha)=3) THEN prog.txtMar 
						WHEN(DatePart(WeekDay, prog.Fecha)=4) THEN prog.txtMie 
						WHEN(DatePart(WeekDay, prog.Fecha)=5) THEN prog.txtJue 
						WHEN(DatePart(WeekDay, prog.Fecha)=6) THEN prog.txtVie 
						WHEN(DatePart(WeekDay, prog.Fecha)=7) THEN prog.txtSab
						WHEN(DatePart(WeekDay, prog.Fecha)=7) THEN prog.txtSab 
						END
					 AS etiqueta
			,hc.acompanante
			,hc.telefono_acompanante
			,procs_asunto.codProcedimiento
			,procs_asunto.nomProcedimiento
			,case when sasu.EsPrimeraVez =1 then 'PRIMERA VEZ' WHEN sasu.EsPrimeraVez =0 THEN 'CONTROL' END tipo_asunto
			FROM #citas ci
			outer apply( select pmd.Fecha,pm.txtDom,pm.txtLun,pm.txtMar, pm.txtMie, pm.txtJue,pm.txtVie, pm.txtSab  
			from #programacion_medico_detalle pmd 
			inner join programacion_medico pm on pm.id=pmd.IdProgramacionMedico
			where pmd.IdCita=ci.id) prog
			LEFT JOIN sis_maes smaes ON smaes.con_estudio=ci.estudio
			LEFT JOIN hcingres hc on hc.con_estudio=ci.estudio
			LEFT JOIN sis_paci as paci ON paci.autoid = ci.autoid
			outer apply(select top 1 fecha_estado_res from sis_deta_temp sdt where sdt.estudio=ci.estudio) paraclinico
		  LEFT JOIN  FormaSolicitudCitas AS fc ON fc.id = ci.formaSolicitud
		  LEFT JOIN usuario as u on u.cedula = ci.cod_user_asigna_cita			
			LEFT JOIN relgrup rg ON smaes.nro_factura=rg.factura and rg.Prefijo=smaes.Prefijo
			outer apply(select top(1) v.*,p.nombreve from contratos as co,citas_procedimientos_referencias,variables_internas as v,sis_manual as manuales,sis_proc as p where idCita = ci.id and v.id = IdReferencia and p.codigo = CodProcedimiento  and co.codigo = ci.contrato and co.[manual] = manuales.codigo and manuales.tipo = p.tipo) as ref 
			outer apply(select top(1) p.cups,p.nombreve from contratos as co,citas_procedimientos,sis_manual as manuales,sis_proc as p where id_Cita = ci.id  and p.codigo = id_Procedimiento and co.codigo = ci.contrato and co.[manual] = manuales.codigo and manuales.tipo = p.tipo) as ref_new 
			outer apply (select top 1 nombre,EsPrimeraVez from sis_asunto where id=ci.asunto) sasu
			outer apply (select top 1 codProcedimiento,nomProcedimiento 
				from citas_procedimientos_asuntos cpa 
				inner join sis_proc  sp on sp.codigo = cpa.codProcedimiento and sp.tipo = cpa.TipoManual
				where cpa.idCita = ci.id and sp.rips = 'AC') as procs_asunto
			--LEFT JOIN pagos pag ON pag.con_estudio=smaes.con_estudio and pag.activo=1,
			,sis_empre,contratos as cont,
			pacientesView sp
			LEFT JOIN departamentos dep on dep.codigo=sp.cod_dep
			LEFT JOIN sis_muni smuni ON smuni.codigo=sp.cod_muni and smuni.id_dep=dep.codigo
			LEFT JOIN sis_barrios ba on ba.codigo=sp.barrio and ba.municipio=smuni.codigo and ba.dept=dep.codigo			
			,dbo.sis_medi smed LEFT JOIN sis_especialidades as Esp ON Esp.codigo = smed.especialidad--,sis_asunto sasu
			WHERE
			sp.autoid=ci.autoid
			AND sis_empre.codigo = ci.empresa
			AND ci.cod_medi=smed.codigo
			AND cont.codigo =ci.contrato
			and ci.estado = 'P'

			AND ci.fecha >= GETDATE()

			--and sp.num_id = '23114749'
			--and sp.tipo_id = 'CC'
			
			 
	

			
			and (ci.id_sede='' or '' = '')
			--AND sasu.id=ci.asunto 
			  -- and smed.codigo=77   
			   order by CONVERT(datetime,convert(varchar(255),CONVERT(DATE,ci.fecha),111)+' '+ci.hora +' '+ci.meridiano) asc

DROP TABLE #citas
DROP TABLE #programacion_medico_detalle

--select * from citas where estado='p'