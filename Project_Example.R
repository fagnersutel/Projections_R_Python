library(proj4)
library(rgdal)

#read in projection from shapefile
MyDir <- "C:\\Users\\axw161530\\Dropbox\\Documents\\BLOG\\Projections_R_Python"
setwd(MyDir)
DalBound <- readOGR(dsn="DallasBoundary_Proj.shp",layer="DallasBoundary_Proj")
DalProj <- proj4string(DalBound)


ProjData <- data.frame(x=c(2481939.934525765),
                       y=c(6989916.200679892),
					   lat=c(32.832521),
					   lon=c(-96.828295))

   
LatLon <- proj4::project(as.matrix(ProjData[,c('x','y')]), proj=DalProj, inverse=TRUE)
#check to see if true
cbind(ProjData[,c('lon','lat')],as.data.frame(LatLon))

XYFeet <- proj4::project(as.matrix(ProjData[,c('lon','lat')]), proj=DalProj)
cbind(ProjData[,c('x','y')],XYFeet)


plot(DalBound)
points(ProjData$x,ProjData$y,col='red',pch=19,cex=2)

#trasform boundary to lat/lon
DalLatLon <- spTransform(DalBound,CRS("+init=epsg:4326") )
plot(DalLatLon)
points(ProjData$lon,ProjData$lat,col='red',pch=19,cex=2)

#Leaflet useful for boundaries to be lines instead of areas
DallLine <- as(DalLatLon, 'SpatialLines')
library(leaflet)

BaseMapDallas <- leaflet() %>%
  addProviderTiles(providers$OpenStreetMap, group = "Open Street Map") %>%
  addProviderTiles(providers$CartoDB.Positron, group = "CartoDB Lite") %>%
  addPolylines(data=DallLine, color='black', weight=4, group="Dallas Boundary Lines") %>%
  addPolygons(data=DalLatLon,color = "#1717A1", weight = 1, smoothFactor = 0.5,
              opacity = 1.0, fillOpacity = 0.5, group="Dallas Boundary Area") %>%
  addLayersControl(baseGroups = c("Open Street Map","CartoDB Lite"),
                   overlayGroups = c("Dallas Boundary Area","Dallas Boundary Lines"),
	               options = layersControlOptions(collapsed = FALSE)) %>%
                   hideGroup("Dallas Boundary Lines")	

				  
BaseMapDallas