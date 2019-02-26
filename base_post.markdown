<!---
Projecting spatial data in Python and R
-->

I use my blog as sort of a scholarly notebook. I often repeatedly do a task, and then can't find where I did it previously. One example is projecting crime data, so here are my notes on how to do that in python and R.

Commonly I want to take public crime data that is in spherical lat/lon coordinates and project it to some local projection. Most of the time so I can do simply euclidean geometry (like buffers within X feet, or distance to the nearest crime generator in meters). Sometimes you need to do the opposite -- if I have the projected data and I want to plot the points on a webmap it is easier to work with the lat/lon coordinates. As a note, if you import your map data and then your points are not on the map (or in a way off location), there is some sort of problem with the projection. 

I used to do this in ArcMap (toolbox -> Data Management -> Projections), but doing it these programs are faster. Here are examples of going back and forth for some Dallas coordinates. [Here is the data and code]() to replicate the post.

#Python 

In python there is a library `pyproj` that does all the work you need. It isn't part of the default python packages, so you will need to install it using pip or whatever. Basically you just need to define the to/from projections you want. Also it always returns the projected coordinates in meters, so if you want feet you need to do a conversions from meters to feet (or whatever unit you want). For below `p1` is the definition you want for lat/lon in webmaps (which is not a projection at all). To figure out your local projection though takes a little more work.

To figure out your local projection I typically use this online tool, [prj2epsg](http://prj2epsg.org/search). You can upload a `prj` file, which is the locally defined projection file for shapefiles. (It is plain text as well, so you can just open in a text editor and paste into that site as well.) It will then tell you want EPSG code corresponds to your projection.

Below illustrates putting it all together and going back and forth for an example area in Dallas. I tend to write the functions to take one record at a time for use in various workflows, but I am sure someone can write a vectorized version though that will take whole lists that is a better approach.

    import pyproj
    
    #These functions convert to/from Dallas projection
    #In feet to lat/lon
    p1 = pyproj.Proj(proj='latlong',datum='WGS84')
    p2 = pyproj.Proj(init='epsg:2276') #show how to figure this out, http://spatialreference.org/ref/epsg/ and http://prj2epsg.org/search 
    met_to_feet = 3.280839895 #http://www.meters-to-feet.com/
    
    #This converts Lat/Lon to projected coordinates
    def DallConvProj(Lat,Lon):
        #always returns in meters
        if abs(Lat) > 180 or abs(Lon) > 180:
            return (None,None)
        else:
            x,y = pyproj.transform(p1, p2, Lon, Lat)
            return (x*met_to_feet, y*met_to_feet)
    
    #This does the opposite, coverts projected to lat/lon
    def DallConvSph(X,Y):
    	if abs(X) < 2000000 or abs(Y) < 6000000:
    		return (None,None)
    	else:
    		Lon,Lat = pyproj.transform(p2, p1, X/met_to_feet, Y/met_to_feet)
    		return (Lon, Lat)
    
    #check coordinates
    x1 = -96.828295; y1 = 32.832521
    print DallConvProj(Lat=y1,Lon=x1)
    
    x2 = 2481939.934525765; y2 = 6989916.200679892
    print DallConvSph(X=x2, Y=y2)

#R

In R I use the library `proj4` to do the projections for point data. R can read in the projection data from a file as well using the `rgdal` library. 

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

The last plot function shows that the XY point is within the Dallas basemap for the projected boundary. But if you want to project the boundary file as well, you can use the `spTransform` function. Here I have a simple example of tacking the projected boundary file and transforming to lat/lon, so can be superimposed on a leaflet map. 

Additionally I show a trick I sometimes use for maps by transforming the boundary polygon to a polyline, as it provides easier styling options sometimes. 	

    #transform boundary to lat/lon
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
	
I have too much stuff in the blog queue at the moment, but hopefully I get some time to write up my notes on using leaflet maps in R soon. 