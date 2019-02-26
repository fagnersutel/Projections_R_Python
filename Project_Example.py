import pyproj

#These functions convert to/from Dallas projection
#In feet to lat/lon
p1 = pyproj.Proj(proj='latlong',datum='WGS84')
p2 = pyproj.Proj(init='epsg:2276') #show how to figure this out, http://spatialreference.org/ref/epsg/
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