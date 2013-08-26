###Introduccion

GBIF (Global Biodiversity Information Facility; www.gbif.org) y el SIB (Sistema de Informacion sobre Biodiversidad de Colombia; http://www.sibcolombia.net) son las fuentes de información más importantes sobre registros de la biodiversidad de Colombia. Aunque los registros de especies particulares pueden ser fácilmente consultados y descargados por medio de los portales de datos de dichas iniciativas, un máximo de 250.000 registros pueden ser descargados de los portales de datos. Esto supone que no es posible a través de los portales de datos de GBIF y SIB descargar toda la información disponible en áreas extensas como Colombia, donde a Marzo de 2013 había 1'626.079 registros georeferenciados en GBIF y 240.456 registros georeferenciados en SIB.

Con el fin de facilitar la descarga y consolidación de los datos de biodiversidad disponibles en GBIF y SIB hemos creado un script de R que automatiza la tarea de descargar datos de dichas fuentes para cualquier región geográfica del mundo. Nuestro script descarga los datos usando los servicios REST de GBIF y SIB para todas las celdas GBIF (cuadricula de 1° x 1°) que se intersectan con el área de interés, la cual es definida por un polígono provisto en formato shapefile. Específicamente, nuestro script de descarga (updateGSDB.R) procede de la siguiente manera:

 1. Identificación de código de celdas GBIF a descargar
 2. Descarga de datos de GBIF por celdas a directorio local
 3. Descarga de datos de SIB por celdas a directorio local
 5. Integración de los datos de GBIF y SIB
 6. Filtrado de los datos al área de interés
 7. Identificación de duplicados del SIB en GBIF. En la actualidad, todos los datos de instituciones colombianas registradas en el SIB que se encuentren en GBIF son marcados como duplicados.

Adicionalmente, la taxonomía de los registros presentes en GBIF y SIB no siempre es válida. Para determinar cuáles nombres presentes en dichas bases de datos son válidos desarrollamos un segundo script de R (nameValidation.R) que consulta en una base de datos local de Catalogue of Life la validez del nombre, por medio de consultas construidas en SQL. El programa devuelve una matriz con el estado del nombre (valido, sinónimo valido o invalido) y la  taxonomía  completa del nombre consultado.   

Para correr los scripts de descarga y validación taxonómica es necesario instalar los siguientes componentes:

 1. R. Versión 2.15.2 o superior. Este puede ser descargado directamente de http://cran.r-project.org/
 2. MySQL (instrucciones abajo)
 3. RTools (instrucciones abajo)
 4. Paquetes de R: RmySQL, raster, sp, XML. Los paquetes de R, con excepción de RMySQL (ver abajo) son instalados desde la consola de R mediante el comando install.packages("nombre del paquete") (e.g. install.packages("raster"))

###Instrucciones de instalación de RMySQL en Windows 7  
RMySQL es un paquete de R que permite hacer consultas a bases de datos construidas en MySQL. Este paquete es necesario para la verificación de la taxonomía de GBIF. Para su instalación siga los siguientes pasos:

 1. Descargue e instale la versión más reciente de MySQL Community Server apropiada para su sistema en http://dev.mysql.com/downloads/mysql/5.5.html  (Por ejemplo: mysql-5.5.30-winx64.msi). Escoja la configuración "Typical" para la instalación y acepte al final de la instalación ir al asistente de configuración. En el asistente de configuración asegúrese de que las opciones de la ventana "MySQL Server Instance Configuration" coincidan con las de la figura abajo. ![mysql](https://lh4.googleusercontent.com/-CLZYLeTlXss/UUOMnjk6hvI/AAAAAAAAACU/zAWHU98lbpA/s552/mysql.png)
 2. En el menú de inicio busque y abra "Editar variables de entorno del sistema". Oprima el botón de "Variables de entorno". En la sección "Variables del sistema" busque la variable Path y oprima el botón "Editar" (ver figura abajo). Asegürese que la ruta a la carpeta con los archivos de MySQL (e.g. C:\Program Files\MySQL\MySQL Server 5.5)  este en el Path. De lo contrario, añadala. ![envVars](https://lh4.googleusercontent.com/-tVq7BewYEhU/UUOMnrtOfTI/AAAAAAAAACQ/gIpZ3iy8LIc/s501/variables+entorno.png)
 3. De nuevo en la ventana "Variables de entorno", haga clic en el botón "Nueva" abajo del cuadro de "Variables del sistema". En "Nombre de la variable" escriba MYSQL_HOME y en "Valor de la variable" escriba la ruta que contiene los archivos de la instalación de MySQL (e.g. C:\Program Files\MySQL\MySQL Server 5.5). 
 4. Ahora abra el explorador de Windows y vaya a la carpeta lib de su instalación de MySQL (e.g. C:\Program Files\MySQL\MySQL Server 5.5\lib). Copie el archivo libmysql.dll y péguelo en la carpeta bin (C:\Program Files\MySQL\MySQL Server 5.5\bin).
 5. Descargue la versión de Rtools (http://cran.r-project.org/bin/windows/Rtools/) adecuada para la versión de R presente en su sistema. Ejemplo: para la versión 2.15.2 de R descargue Rtools 3.0.
 6. Instale Rtools aceptando las opciones de configuración por defecto. Cuando llegue a la ventana "Seleccione las tareas adicionales" asegúrese de seleccionar las dos casillas. Esto agregara Rtools a la variable de entorno Path. Si ud. ignora este paso deberá agregar Rtools manualmente a Path (e.g. C:\Rtools\bin y C:\Rtools\gcc-4.6.3).
 7. Abra R e ingrese el comando: install.packages('RMySQL',type='source'). Esto deberá concluir la instalación de RMySQL.

Más información
http://www.r-bloggers.com/installing-the-rmysql-package-on-windows-7/

###Instrucciones de instalación de base de datos Catalogue of Life
 1. Abra el programa MySQL 5.5 Command Line Client
 2. Ingrese la contraseña utilizada en la instalación de MySQL. 
 3. Para crear la base de datos Catalogue of Life, escriba el comando create database col2012ac; (incluyendo el punto y coma).  Puede verificar que la base de datos fue agregada escribiendo el comando show databases;
 4. Obtenga una copia de la base de datos de Catalogue of Life en el laboratorio de biogeografía. Cópiela a una ubicación permanente en su PC.
 5. Para indexar la base de datos de Catalogue of Life en MySQL, abra el programa cmd.exe (en Windows 7 lo puede buscar en el menú de inicio) e ingrese cmd mysql -u root -p col2012ac < d:data/bases/col2012ac.sql, cambiando la última porción del comando con la ruta completa del archivo de Catalogue of Life (col2012ac.sql).

###Ejemplo de sesión de descarga y verificación taxonómica de registros

En R, cargue los scripts desde un directorio local:

    source("D:/Datos/gbif_sib/updateGSDB.R")
    source("D:/Datos/gbif_sib/gbif2.R")
    source("D:/Datos/gbif_sib/nameValidation.R")

Lea o descargue un archivo shapefile que defina los límites de su área de estudio:

    #Para cargar su propio shapefile
    library(rgdal)
    co<-readOGR("D:/Datos/BaseLayers","colombia") # Lea shapefile
    #Para descargar de internet un shapefile de pais y cargarlo en R
    library(dismo)
    co<-getData("GADM",country="CO",level=0) 

Descargue datos de GBIF y SIB

    db<-updateGSDB(root,co)
    #En caso de error (e.g. servidor ocupado) el comando updateGSDB emitira un objeto resume que sera guardado con el nombre db
    #Para continuar descargando los datos despues de un error:
    db<-updateGSDB(root,co,resume=TRUE,db)

Corra la validación taxonómica

    #Conectese a la base de datos de Catalogue of Life
    library(RMySQL)
    con <- dbConnect(dbDriver("MySQL"), user = "root",password="root",dbname = "col2012ac",host="localhost") #Cambie este comando ingresando el nombre de usuario y password asociado con su instalaci�n de MySQL
    #Genere la tabla de id, nombre,genero y especie (cofTable)
    species<-db$db$species #The first four lines take the first two strings in the field species and assign them to genus and spp, respectively
    genus<-sapply(species,function(x) strsplit(x," ")[[1]][1],USE.NAMES=FALSE)
    spp<-sapply(species,function(x) strsplit(x," ")[[1]][2],USE.NAMES=FALSE)
    nombre=paste(genus,spp) 
    cofTable<-data.frame(id=1:length(species),nombre=nombre,genero=genus,epiteto_especifico=spp)
    #Realice la verificaci�n de nombres con Catalogue of Life.
    cofTable2<-nameValidation(con,cofTable)
