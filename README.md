# Maps

This repository provides informationen about the processed map data for truck routing. The map data  is available in the [osm format](http://wiki.openstreetmap.org/wiki/OSM_XML). This format is human readable and can be versioned in a git repository. If you need this data in the [pbf format](http://wiki.openstreetmap.org/wiki/PBF_Format) then you have to convert it. That is very easy and you can find the description below.

## Convert

You can find all necessary information about the converting at the [OpenStreetMap Wiki - OsmConvert](http://wiki.openstreetmap.org/wiki/Osmconvert)

### osm -> pbf

`osmconvert processed.osm -o=processed.osm.pbf`

### pbf -> osm

`osmconvert processed.osm.pbf -o=processed.osm`
