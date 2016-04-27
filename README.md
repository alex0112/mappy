# mappy
Quick program to turn Delorme Street atlas plus draw files into KML files for use in google maps.

## Usage:
`perl mappy.pl inputfile.txt outputfile.kml`

## Example:


	BEGIN POLY
	40.644178,-74.161223
	40.641818,-74.143576
	40.643535,-74.134298
	40.643878,-74.125925
	40.648084,-74.109972
	40.644178,-74.161223
	END

Becomes:
	
	<?xml version='1.0' encoding='UTF-8'?><kml xmlns='http://www.opengis.net/kml/2.2'><Document><name>NAME GOES HERE.</name><description><![CDATA[LAYER NAME GOES HERE]]></description><Folder><name>Auto Generated Layer From Delorme</name>
	<Placemark><Polygon><outerBoundaryIs><LinearRing><tessellate>1</tessellate>
	<coordinates>
	-74.161223,40.644178,0
	-74.143576,40.641818,0                                                
	-74.134298,40.643535,0
	-74.125925,40.643878,0
	-74.109972,40.648084,0
	-74.161223,40.644178,0   
	-74.161223,40.644178,0
	</coordinates></LinearRing>
	</outerBoundaryIs>
	</Polygon>
	</Placemark>
	</Folder></Document></kml>
	
	
