#Funtion: 	nameValidation.R
#Purpose: 	validates scientific names from an input table using the Catalog of Life.
#Authors: 	Jorge Vel?squez & Camilo Moreno
#Date:		January 24, 2013

#Arguments: 	con - a MySQLConnection object, as produced by the function dbConnect.
          		#inTable - a data frame object with column names id, nombre, genero, epiteto especifico, in that order

#Returns: 	A data frame object with validation fields for each record in the input table.

#Usage:
#library(RMySQL)
#con <- dbConnect(dbDriver("MySQL"), user = "root",password="root",dbname = "col2012ac",host="localhost")
#cofTable2<-nameValidation(con,cofTable)

Notes: 		Requires previous instalation of Catalog of Life database and package RMySQL
		Documentation in: XXX

nameValidation<-function(con,inTable){
	dbSendQuery(con,"truncate tabla_trabajo")

	dbWriteTable(con,"gbif_sib",inTable,overwrite=TRUE)

	dbSendQuery(con,"update gbif_sib set epiteto_especifico = null where epiteto_especifico =\"NA\"")

	dbSendQuery(con,"update gbif_sib set epiteto_especifico = null where epiteto_especifico =\"\"")
	dbSendQuery(con,"update gbif_sib set genero = null where genero =\"\"")
	dbSendQuery(con,"delete  from gbif_sib where id = \"\"")
	dbSendQuery(con,"INSERT INTO  tabla_trabajo (id,nombre,genero,epiteto_especifico)  select  id,nombre,genero,epiteto_especifico from gbif_sib")

	dbSendQuery(con,"UPDATE Tabla_trabajo INNER JOIN CoL_sn_aceptados ON (Tabla_trabajo.genero = CoL_sn_aceptados.genus) AND (Tabla_trabajo.epiteto_especifico = CoL_sn_aceptados.species) SET Tabla_trabajo.autor_nombre_aceptado= col_sn_aceptados.author, Tabla_trabajo.es_aceptadoCoL = is_accepted_name, Tabla_trabajo.id_registro_CoL = col_sn_aceptados.id, Tabla_trabajo.id_familia_CoL = family_id, Tabla_trabajo.id_nombre_aceptado = accepted_species_id, Tabla_trabajo.genero_aceptado = genus, Tabla_trabajo.epiteto_aceptado = species WHERE (((CoL_sn_aceptados.infraspecies)=''))
")

	dbSendQuery(con,"UPDATE Tabla_trabajo INNER JOIN CoL_sn ON (Tabla_trabajo.genero = CoL_sn.genus) AND (Tabla_trabajo.epiteto_especifico = CoL_sn.species) SET Tabla_trabajo.es_aceptadoCoL = is_accepted_name, Tabla_trabajo.id_registro_CoL = col_sn.id, Tabla_trabajo.id_familia_CoL = family_id, Tabla_trabajo.id_nombre_aceptado = accepted_species_id WHERE Tabla_trabajo.es_aceptadoCoL is null AND CoL_sn.infraspecies=''
")

	dbSendQuery(con,"UPDATE Tabla_trabajo INNER JOIN CoL_sn_aceptados ON Tabla_trabajo.id_nombre_aceptado = CoL_sn_aceptados.id SET tabla_trabajo.id_familia_col= col_sn_aceptados.family_id, Tabla_trabajo.Autor_nombre_aceptado = CoL_sn_aceptados.author, Tabla_trabajo.genero_aceptado = CoL_sn_aceptados.genus, Tabla_trabajo.epiteto_aceptado = CoL_sn_aceptados.species where tabla_trabajo.es_aceptadocol = 2")

	dbSendQuery(con,"UPDATE Tabla_trabajo INNER JOIN CoL_familiesT ON Tabla_trabajo.id_familia_CoL = CoL_familiesT.id SET Tabla_trabajo.nombre_aceptado = concat_ws ('',genero_aceptado, epiteto_aceptado) , Tabla_trabajo.familia_CoL = col_familiest.family, Tabla_trabajo.orden_CoL = col_familiest.`order`, Tabla_trabajo.clase_CoL = col_familiest.class, Tabla_trabajo.phylum_CoL = col_familiest.phylum, Tabla_trabajo.reino_CoL = col_familiest.kingdom where tabla_trabajo.es_aceptadocol= 2 or tabla_trabajo.es_aceptadocol =1")

	outTable=dbGetQuery(con, "select *  from tabla_trabajo")
	return(outTable)
}

nameValidation2014 <- function(con,inTable){
  inTable <- data.frame(inTable)
  inTable$id <- as.numeric(as.character(inTable$id))
  
  inTable$nombre <- as.character(inTable$nombre)
  uniqueTable <- inTable[!duplicated(as.character(inTable$nombre)), ]
  
  dbSendQuery(con,"truncate tablatrabajo")
  dbWriteTable(con,"gbif_sib", data.frame(uniqueTable), overwrite=TRUE)
  dbSendQuery(con,"update gbif_sib set epiteto_especifico = null where epiteto_especifico =\"NA\"")
  dbSendQuery(con,"update gbif_sib set epiteto_especifico = null where epiteto_especifico =\"\"")
  dbSendQuery(con,"update gbif_sib set genero = null where genero =\"\"")
  dbSendQuery(con,"delete from gbif_sib where id = \"\"")
  dbSendQuery(con,"INSERT INTO tablatrabajo (row_names, id,nombre,genero,epiteto_especifico) select row_names,id,nombre,genero,epiteto_especifico from gbif_sib")
  
  dbSendQuery(con,"UPDATE tablatrabajo INNER JOIN _search_scientific ON (tablatrabajo.genero = _search_scientific.genus) AND (tablatrabajo.epiteto_especifico = _search_scientific.species) SET 
              tablatrabajo.es_aceptadoCoL = _search_scientific.status, 
              tablatrabajo.id_nombre_CoL = _search_scientific.id, 
              tablatrabajo.id_nombre_aceptado = _search_scientific.id, 
              tablatrabajo.genero_CoL = _search_scientific.genus, 
              tablatrabajo.epiteto_CoL = _search_scientific.species 
              WHERE ((( _search_scientific.infraspecies)=''))")
  
  dbSendQuery(con,"UPDATE tablatrabajo INNER JOIN sinonimos ON (tablatrabajo.id_nombre_CoL = sinonimos.original_id) SET
              tablatrabajo.id_nombre_aceptado = sinonimos.accepted_id 
              WHERE tablatrabajo.es_aceptadoCoL between 2 and 5")
  
  dbSendQuery(con,"UPDATE tablatrabajo INNER JOIN _species_details ON (tablatrabajo.id_nombre_aceptado = _species_details.species_id) SET
              tablatrabajo.autor_nombre_aceptado = _species_details.author, 
              
              tablatrabajo.reino_CoL = _species_details.kingdom_name,
              tablatrabajo.reino_id_CoL = _species_details.kingdom_id,
              tablatrabajo.reino_LSID_CoL = _species_details.kingdom_lsid,
              
              tablatrabajo.phylum_CoL = _species_details.phylum_name,
              tablatrabajo.phylum_id_CoL = _species_details.phylum_id,
              tablatrabajo.phylum_LSID_CoL = _species_details.phylum_lsid,
              
              tablatrabajo.clase_CoL = _species_details.class_name,
              tablatrabajo.clase_id_CoL = _species_details.class_id,
              tablatrabajo.clase_LSID_CoL = _species_details.class_lsid,
              
              tablatrabajo.orden_CoL = _species_details.order_name,
              tablatrabajo.orden_id_CoL = _species_details.order_id,
              tablatrabajo.orden_LSID_CoL = _species_details.order_lsid,
              
              tablatrabajo.familia_CoL = _species_details.family_name,
              tablatrabajo.familia_id_CoL = _species_details.family_id,
              tablatrabajo.familia_LSID_CoL = _species_details.family_lsid,
              
              tablatrabajo.genero_CoL = _species_details.genus_name,
              tablatrabajo.genero_id_CoL = _species_details.genus_id,
              tablatrabajo.genero_LSID_CoL = _species_details.genus_lsid,
              
              tablatrabajo.epiteto_CoL = _species_details.species_name,
              tablatrabajo.epiteto_id_CoL = _species_details.species_id,
              tablatrabajo.epiteto_LSID_CoL = _species_details.species_lsid,
              
              tablatrabajo.dbSource = _species_details.source_database_short_name, 
              tablatrabajo.dbSourceRelaseDate = _species_details.source_database_release_date, 
              tablatrabajo.dbSourceSpecialist = _species_details.specialist")

  outTable <- dbGetQuery(con, "select * from tablatrabajo")[, -c(1:2)]
  pos <- !is.na(outTable$es_aceptadoCoL)
  
  outTable$nombre_aceptado[pos] <- paste(outTable$genero_CoL[pos], outTable$epiteto_CoL[pos])
  colnames(outTable) <- gsub('Nombre', 'nombre', colnames(outTable))
  nombre <- data.frame(id = inTable[, 1], nombre = inTable[, 2])
  
  finalTable <- merge(nombre, outTable, all.x = T, by = 'nombre')
  finalTable <- finalTable[order(finalTable$id), ]
  pos.id <- grep('^id$', colnames(finalTable))
  finalTable <- cbind(id = finalTable$id, finalTable[, -c(pos.id)])
  rownames(finalTable) <- finalTable$id

  return(outTable)
}
