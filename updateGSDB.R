#Function update GBIF & SIB database
#Purpose: Download all data with coordinates for Colombia from GBIF and SIB databases.
#         
#Author: Jorge Velásquez
#Last modified: 23/1/2013
#Arguments: root - path to empty folder where database will be downloaded.
#           co - SpatialPolygonsDataFrame object of area of interest
#           save objs 
#Returns: db - a dataframe with all GBIF and SIB data
#         isDuplicate - a vector indicating whether a particular record is a duplicate (1) or not (0)

#Usage:   root<-"D:/Datos/gbif_sib/gbif/"
#         co<-getData("GADM",country="CO",level=0,download=TRUE,path=root)
#         db<-updateGSDB(root,co)
#
#Note:    Requires R packages raster, sp and XML

updateGSDB<-function(root,co,resume=FALSE,resumeObj){
  #STEP O: LOAD LIBRARIES AND SET WORKSPACE
  library(raster)
  library(sp)
  library(XML)
  pathGBIF<-paste(root,"/gbif",sep="")
  pathSIB<-paste(root,"/sib",sep="")
  
  dir.create(pathGBIF, showWarnings = FALSE,recursive=T)
  dir.create(pathSIB, showWarnings = FALSE,recursive=T)

  #Get GBIF gridcell IDs within AOI
  a<-matrix(0:64799,nrow=180,ncol=360,byrow=TRUE)
  c<-a[nrow(a):1,]
  gbifWorld<-raster(c,xmn=-180,xmx=180,ymn=-90,ymx=90,crs= "+proj=longlat +datum=WGS84")
  rm(a,c)
  co_raster<-rasterize(co,gbifWorld,getCover=T,background=0)
  gb_cellids<-Which(co_raster>0,cells=TRUE)
  xy_cellids<-xyFromCell(co_raster,gb_cellids)
  cellids<-extract(gbifWorld,xy_cellids) #GBIF cells that overlap with Colombia
  rm(co_raster,gb_cellids,xy_cellids)
  cellobjs<-paste("c",cellids,sep="")
  
  start1=1
  start2=1
  step1=TRUE
  step2=TRUE
  
  if(resume){
    step1=resumeObj$step1
    step2=resumeObj$step2
    if(step1){
      start1=resumeObj$errorIter
      start2=1
    }
    if(step2){
      start2=resumeObj$errorIter
    }
  }
  
  #STEP 1:GET DATA FROM GBIF
  if(step1){
    gbif<-dwnData(cellids,start=start1,path=pathGBIF,base="http://data.gbif.org/ws/rest/occurrence/")
    if(gbif$isError){
      print("Stopping execution of updateGSDB. Use resume=TRUE to continue")
      return(c(gbif,step1=TRUE,step2=TRUE))
    }
  }
  
  #STEP 2: GET DATA FROM SIB COLOMBIA
  if(step2){
    sib<-dwnData(cellids,start=start2,path=pathSIB,base="http://data.sibcolombia.net/ws/rest/occurrence/")
    if(sib$isError){
      print("Stopping execution of updateGSDB. Use resume=TRUE to continue")
      return(c(sib,step1=FALSE,step2=TRUE))
    }
  }
  
  #Read gbif tables and concatenate them in a single file
  z<-NULL
  for(i in 1:length(cellobjs)){
    print(paste0(cellobjs[i],".txt"))
    if(!file.exists(paste0(pathGBIF,"/",cellobjs[i],".txt"))){#Skips empty files
      next}
    inFile<-read.table(paste0(pathGBIF,"/",cellobjs[i],".txt"),header=TRUE,as.is=TRUE)
    z<-rbind(z,inFile)
  }
  rm(i,inFile)
  
  #Read sib tables and concatenate them into a single file
  w<-NULL
  for(i in 1:length(cellobjs)){
    print(paste0(cellobjs[i],".txt")) 
    if(!file.exists(paste0(pathSIB,"/",cellobjs[i],".txt"))){#Skips empty files
      next}
    inFile<-read.table(paste0(pathSIB,"/",cellobjs[i],".txt"),header=TRUE,as.is=TRUE)
    w<-rbind(w,inFile)
  }
  rm(i,inFile)

  #Filter z and w by limits of AOI
  filterAOI<-function(dt,aoi){
    dt_aoi<-data.frame(lon=dt$lon,lat=dt$lat)
    coordinates(dt_aoi)=~lon+lat
    projection(dt_aoi)<-projection(aoi)
    ind<-overlay(dt_aoi,aoi)
    return(dt[-is.na(ind),])
  }
  zFilt<-filterAOI(z,co)
  wFilt<-filterAOI(w,co)
  
  #ID records of colombian institutions from GBIF
  
  isDup<-rep(0,nrow(zFilt))
  colIns<-unique(wFilt$institution)
  
  for(i in 1:length(colIns)){
    ind<-which(zFilt$institution==colIns[i])
    isDup[ind]=1
  }
  rm(ind)
       
  #Merge GBIF and SIB
  zw<-rbind(zFilt,wFilt)
  isDup<-c(isDup,rep(0,nrow(wFilt)))
  
  #Return data
  return(list(db=zw,isDuplicate=isDup))
}

dwnData<-function(cellids,start=1,path,base){
  for(iter in start:length(cellids)){
    print(paste("Working on cell",cellids[iter]))
    print(base)
    out<-tryCatch(gbif2(cellid=cellids[iter],base=base),
              error=function(e){
                errorIter=iter
                print(paste0("Code stopped at cell ",cellids[iter]))
                return(errorIter)
              })
    if(is.data.frame(out)){
      write.table(out,paste(path,"/c",cellids[iter],".txt",sep=""),row.names=FALSE)
      next
    } 
    if(is.null(out)){
      next
    } else {
      return(list(isError=TRUE,errorIter=out))
    }
    }
  return(list(isError=FALSE))
}

