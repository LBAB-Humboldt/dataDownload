#Modificado de la función gbif del paquete dismo desarrollado por R. Hijmans.

gbif2<-function (genus=NULL, species = "", ext = NULL, cellid=NULL,geo = TRUE, sp = FALSE, 
                 removeZeros = TRUE, download = TRUE, getAlt = TRUE, ntries = 5, 
                 nrecs = 1000, start = 1, end = NULL, feedback = 3,
                 base="http://data.gbif.org/ws/rest/occurrence/")
{
  if (!require(XML)) {
    stop("You need to install the XML package to use this function")
  }
  gbifxmlToDataFrame <- function(s) {
    doc = xmlInternalTreeParse(s)
    nodes <- getNodeSet(doc, "//to:TaxonOccurrence")
    if (length(nodes) == 0) 
      return(data.frame())
    varNames <- c("continent", "country", "stateProvince", 
                  "county", "locality", "decimalLatitude", "decimalLongitude", 
                  "coordinateUncertaintyInMeters", "maximumElevationInMeters", 
                  "minimumElevationInMeters", "maximumDepthInMeters", 
                  "minimumDepthInMeters", "institutionCode", "collectionCode", 
                  "catalogNumber", "basisOfRecordString", "collector", 
                  "earliestDateCollected", "latestDateCollected", "gbifNotes")
    dims <- c(length(nodes), length(varNames))
    ans <- as.data.frame(replicate(dims[2], rep(as.character(NA), 
                                                dims[1]), simplify = FALSE), stringsAsFactors = FALSE)
    names(ans) <- varNames
    for (i in seq(length = dims[1])) {
      ans[i, ] <- xmlSApply(nodes[[i]], xmlValue)[varNames]
    }
    nodes <- getNodeSet(doc, "//to:Identification")
    varNames <- c("taxonName")
    dims = c(length(nodes), length(varNames))
    tax = as.data.frame(replicate(dims[2], rep(as.character(NA), 
                                               dims[1]), simplify = FALSE), stringsAsFactors = FALSE)
    names(tax) = varNames
    for (i in seq(length = dims[1])) {
      tax[i, ] = xmlSApply(nodes[[i]], xmlValue)[varNames]
    }
    cbind(tax, ans)
  }
  if (!is.null(ext)) {
    ex <- round(extent(ext), 5)
    ex <- paste("&minlatitude=", max(-90, ex@ymin), "&maxlatitude=", 
                min(90, ex@ymax), "&minlongitude=", max(-180, ex@xmin), 
                "&maxlongitude=", min(180, ex@xmax), sep = "")
  }
  else {
    ex <- NULL
  }
  if (sp) 
    geo <- TRUE
  if (geo) {
    cds <- "&coordinatestatus=true"
  }
  else {
    cds <- ""
  }	
  if(!is.null(genus)){
    genus <- trim(genus)
    species <- trim(species)
    gensp <- paste(genus, species)
    spec <- gsub("   ", " ", species)
    spec <- gsub("  ", " ", spec)
    spec <- gsub(" ", "%20", spec)
    spec <- paste(genus, "+", spec, sep = "")
    url <- paste(base, "count?scientificname=", spec, cds, ex,"&coordinateissues=false", 
                 sep = "")
  } else {
    gensp=cellid
    url <- paste(base, "count?cellid=",cellid,cds,"&coordinateissues=false",sep = "")
  }
  tries <- 0
  while (TRUE) {
    tries <- tries + 1
    if (tries > 10) {
      stop("GBIF server does not return a valid answer after 5 tries")
    }
    x <- try(readLines(url, warn = FALSE))
    if (class(x) != "try-error") 
      break
  }
  x <- x[grep("totalMatched", x)]
  n <- as.integer(unlist(strsplit(x, "\""))[2])
  if (!download) {
    return(n)
  }
  if (n == 0) {
    cat(gensp, ": no occurrences found\n")
    return(invisible(NULL))
  }
  else {
    if (feedback > 0) {
      cat(gensp, ":", n, "occurrences found\n")
      flush.console()
    }
  }
  ntries <- min(max(ntries, 1), 100)
  if (!download) {
    return(n)
  }
  nrecs <- min(max(nrecs, 1), 1000)
  iter <- n%/%nrecs
  breakout <- FALSE
  if (start > 1) {
    ss <- floor(start/nrecs)
  }
  else {
    ss <- 0
  }
  z <- NULL
  for (group in ss:iter) {
    start <- group * nrecs
    if (feedback > 1) {
      if (group == iter) {
        end <- n - 1
      }
      else {
        end <- start + nrecs - 1
      }
      if (group == ss) {
        cat(ss, "-", end + 1, sep = "")
      }
      else {
        cat("-", end + 1, sep = "")
      }
      if ((group > ss & group%%20 == 0) | group == iter) {
        cat("\n")
      }
      flush.console()
    }
    if(!is.null(genus)){
      aurl <- paste(base, "list?scientificname=", spec, "&mode=processed&format=darwin&startindex=", 
                    format(start, scientific = FALSE), cds, ex,"&coordinateissues=false",sep = "")
    } else {
      aurl <- paste(base, "list?cellid=", cellid, "&mode=processed&format=darwin&startindex=", 
                    format(start, scientific = FALSE), cds,"&coordinateissues=false", sep = "")
    }
    tries <- 0
    while (TRUE) {
      tries <- tries + 1
      if (tries > ntries) {
        warning("GBIF did not return the data in ", ntries)
        breakout <- TRUE
        break
      }
      zz <- try(gbifxmlToDataFrame(aurl))
      if (class(zz) != "try-error") 
        break
    }
    if (breakout) {
      break
    }
    else {
      z <- rbind(z, zz)
    }
  }
  d <- as.Date(Sys.time())
  z <- cbind(z, d)
  names(z) <- c("species", "continent", "country", "adm1", 
                "adm2", "locality", "lat", "lon", "coordUncertaintyM", 
                "maxElevationM", "minElevationM", "maxDepthM", "minDepthM", 
                "institution", "collection", "catalogNumber", "basisOfRecord", 
                "collector", "earliestDateCollected", "latestDateCollected", 
                "gbifNotes", "downloadDate")
  z[, "lon"] <- gsub(",", ".", z[, "lon"])
  z[, "lat"] <- gsub(",", ".", z[, "lat"])
  z[, "lon"] <- as.numeric(z[, "lon"])
  z[, "lat"] <- as.numeric(z[, "lat"])
  if (removeZeros) {
    i <- isTRUE(z[, "lon"] == 0 & z[, "lat"] == 0)
    if (geo) {
      z <- z[!i, ]
    }
    else {
      z[i, "lat"] <- NA
      z[i, "lon"] <- NA
    }
  }
  if (getAlt) {
    altfun <- function(x) {
      a <- mean(as.numeric(unlist(strsplit(gsub("-", " ", 
                                                gsub("m", "", (gsub(",", "", gsub("\"", "", x))))), 
                                           " ")), silent = TRUE), na.rm = TRUE)
      a[a == 0] <- NA
      mean(a, na.rm = TRUE)
    }
    if (feedback < 3) {
      w <- options("warn")
      options(warn = -1)
    }
    alt <- apply(z[, c("maxElevationM", "minElevationM", 
                       "maxDepthM", "minDepthM")], 1, FUN = altfun)
    if (feedback < 3) 
      options(warn = w)
    z <- cbind(z[, c("species", "continent", "country", "adm1", 
                     "adm2", "locality", "lat", "lon", "coordUncertaintyM")], 
               alt, z[, c("institution", "collection", "catalogNumber", 
                          "basisOfRecord", "collector", "earliestDateCollected", 
                          "latestDateCollected", "gbifNotes", "downloadDate", 
                          "maxElevationM", "minElevationM", "maxDepthM", 
                          "minDepthM")])
  }
  if (sp) {
    i <- z[!(is.na(z[, "lon"] | is.na(z[, "lat"]))), ]
    if (dim(z)[1] > 0) {
      coordinates(z) <- ~lon + lat
    }
  }
  return(z)
}