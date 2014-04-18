#Funtion: 	nameValidation.R
#Purpose: 	validates scientific names from an input table using the Catalog of Life.
#Authors: 	Jorge Velásquez & Camilo Moreno
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


