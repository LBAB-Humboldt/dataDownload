= Introducci�n =

GBIF (Global Biodiversity Information Facility; www.gbif.org) y el SIB (Sistema de Informaci�n sobre Biodiversidad de Colombia; http://www.sibcolombia.net) son las fuentes de informaci�n m�s importantes sobre registros de la biodiversidad de Colombia. Aunque los registros de especies particulares pueden ser f�cilmente consultados y descargados por medio de los portales de datos de dichas iniciativas, un m�ximo de 250.000 registros pueden ser descargados de los portales de datos. Esto supone que no es posible a trav�s de los portales de datos de GBIF y SIB descargar toda la informaci�n disponible en �reas extensas como Colombia, donde a Marzo de 2013 hab�a 1�626.079 registros georeferenciados en GBIF y 240.456 registros georeferenciados en SIB.

Con el fin de facilitar la descarga y consolidaci�n de los datos de biodiversidad disponibles en GBIF y SIB hemos creado un script de R que automatiza la tarea de descargar datos de dichas fuentes para cualquier regi�n geogr�fica del mundo. Nuestro script descarga los datos usando los servicios REST de GBIF y SIB para todas las celdas GBIF (cuadricula de 1� x 1�) que se intersectan con el �rea de inter�s, la cual es definida por un pol�gono provisto en formato shapefile. Espec�ficamente, nuestro script de descarga (updateGSDB2.R) procede de la siguiente manera:

 # Identificaci�n de c�digo de celdas GBIF a descargar
 # Descarga de datos de GBIF por celdas a directorio local
 # Descarga de datos de SIB por celdas a directorio local
 # Integraci�n de los datos de GBIF y SIB
 # Filtrado de los datos al �rea de inter�s
 # Identificaci�n de duplicados del SIB en GBIF. En la actualidad, todos los datos de instituciones colombianas registradas en el SIB que se encuentren en GBIF son marcados como duplicados.

Adicionalmente, la taxonom�a de los registros presentes en GBIF y SIB no siempre es v�lida. Para determinar cu�les nombres presentes en dichas bases de datos son v�lidos desarrollamos un segundo script de R (nameValidation.R) que consulta en una base de datos local de Catalogue of Life la validez del nombre, por medio de consultas construidas en SQL. El programa devuelve una matriz con el estado del nombre (valido, sin�nimo valido o invalido) y la taxonom�a completa del nombre consultado.   

Para correr los scripts de descarga y validaci�n taxon�mica es necesario instalar los siguientes componentes:

 # R. Versi�n 2.15.2 o superior. Este puede ser descargado directamente de http://cran.r-project.org/
 # MySQL (instrucciones abajo)
 # RTools (instrucciones abajo)
 # Paquetes de R: RmySQL, raster, sp, XML. Los paquetes de R, con excepci�n de RMySQL (ver abajo) son instalados desde la consola de R mediante el comando install.packages(�nombre del paquete�) (e.g. install.packages(�raster�))

= Instrucciones de instalaci�n de RMySQL en Windows 7 = 
RMySQL es un paquete de R que permite hacer consultas a bases de datos construidas en MySQL. Este paquete es necesario para la verificaci�n de la taxonom�a de GBIF. Para su instalaci�n siga los siguientes pasos:

 # Descargue e instale la versi�n m�s reciente de MySQL Community Server apropiada para su sistema en http://dev.mysql.com/downloads/mysql/5.5.html  (Por ejemplo: mysql-5.5.30-winx64.msi). Escoja la configuraci�n "Typical" para la instalaci�n y acepte al final de la instalaci�n ir al asistente de configuraci�n. En el asistente de configuraci�n aseg�rese de que las opciones de la ventana �MySQL Server Instance Configuration� coincidan con las de la figura abajo. https://lh4.googleusercontent.com/-CLZYLeTlXss/UUOMnjk6hvI/AAAAAAAAACU/zAWHU98lbpA/s552/mysql.png
 # En el men� de inicio busque y abra �Editar variables de entorno del sistema�. Oprima el bot�n de �Variables de entorno�. En la secci�n �Variables del sistema� busque la variable Path y oprima el bot�n �Editar� (ver figura abajo). Aseg�rese que la ruta a la carpeta con los archivos de MySQL (e.g. C:\Program Files\MySQL\MySQL Server 5.5)  este en el Path. De lo contrario, a�adala. https://lh4.googleusercontent.com/-tVq7BewYEhU/UUOMnrtOfTI/AAAAAAAAACQ/gIpZ3iy8LIc/s501/variables+entorno.png
 # De nuevo en la ventana �Variables de entorno�, haga clic en el bot�n �Nueva� abajo del cuadro de �Variables del sistema�. En �Nombre de la variable� escriba MYSQL_HOME y en �Valor de la variable� escriba la ruta que contiene los archivos de la instalaci�n de MySQL (e.g. C:\Program Files\MySQL\MySQL Server 5.5). 
 # Ahora abra el explorador de Windows y vaya a la carpeta lib de su instalaci�n de MySQL (e.g. C:\Program Files\MySQL\MySQL Server 5.5\lib). Copie el archivo libmysql.dll y p�guelo en la carpeta bin (C:\Program Files\MySQL\MySQL Server 5.5\bin).
 # Descargue la versi�n de Rtools (http://cran.r-project.org/bin/windows/Rtools/) adecuada para la versi�n de R presente en su sistema. Ejemplo: para la versi�n 2.15.2 de R descargue Rtools 3.0.
 # Instale Rtools aceptando las opciones de configuraci�n por defecto. Cuando llegue a la ventana �Seleccione las tareas adicionales� aseg�rese de seleccionar las dos casillas. Esto agregara Rtools a la variable de entorno Path. Si ud. ignora este paso deber� agregar Rtools manualmente a Path (e.g. C:\Rtools\bin y C:\Rtools\gcc-4.6.3).
 # Abra R e ingrese el comando: install.packages('RMySQL',type='source'). Esto deber� concluir la instalaci�n de RMySQL.

M�s informaci�n:
http://www.r-bloggers.com/installing-the-rmysql-package-on-windows-7/

= Instrucciones de instalaci�n de base de datos Catalogue of Life =
 # Abra el programa MySQL 5.5 Command Line Client
 # Ingrese la contrase�a utilizada en la instalaci�n de MySQL. 
 # Para crear la base de datos Catalogue of Life, escriba el comando create database col2012ac; (incluyendo el punto y coma).  Puede verificar que la base de datos fue agregada escribiendo el comando show databases;
 # Obtenga una copia de la base de datos de Catalogue of Life en el laboratorio de biogeograf�a. C�piela a una ubicaci�n permanente en su PC.
 # Para indexar la base de datos de Catalogue of Life en MySQL, abra el programa cmd.exe (en Windows 7 lo puede buscar en el men� de inicio) e ingrese cmd mysql -u root -p col2012ac < d:data/bases/col2012ac.sql, cambiando la �ltima porci�n del comando con la ruta completa del archivo de Catalogue of Life (col2012ac.sql).

= Ejemplo de sesi�n de descarga y verificaci�n taxon�mica de registros =

En R, cargue los scripts desde un directorio local:
{{{
source("D:/Datos/gbif_sib/updateGSDB.R")
source("D:/Datos/gbif_sib/gbif2.R")
source("D:/Datos/gbif_sib/nameValidation.R")
}}}
Lea o descargue un archivo shapefile que defina los l�mites de su �rea de estudio:
{{{
#Para cargar su propio shapefile
library(rgdal)
co<-readOGR("D:/Datos/BaseLayers","colombia") # Lea shapefile

#Para descargar de internet un shapefile de pais y cargarlo en R
library(dismo)
co<-getData("GADM",country="CO",level=0) 
}}}
Descargue datos de GBIF y SIB
{{{
db<-updateGSDB(root,co)

#En caso de error (e.g. servidor ocupado) el comando updateGSDB emitira un objeto resume que sera guardado con el nombre db
#Para continuar descargando los datos despues de un error:

db<-updateGSDB(root,co,resume=TRUE,db)
}}}
Corra la validaci�n taxon�mica
{{{
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
}}}