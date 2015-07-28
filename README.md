# Maps

This repository provides all information to set up a Contargo maps server containing the [Open Source Routing Machine (OSRM)](https://github.com/Project-OSRM/) and [Nominatim](http://www.nominatim.org/) and use this services from [IRIS](https://github.com/Contargo/iris)

## OSRM

Install OSRM in version 4.4.0 for your operation system following the instructions on [Building OSRM](https://github.com/Project-OSRM/osrm-backend/wiki/Building-OSRM).

Now OSRM is able to extract the road network from our preprocessed map data with the truck profile to create the hierarchy to find the shortest path between two points on the map. All instructions are provided on [Running OSRM](https://github.com/Project-OSRM/osrm-backend/wiki/Running-OSRM)

Configuration of the OSRM service (osrm-routed) can be made by a configuration file. All configuration parameter are available under [OSRM routed](https://github.com/Project-OSRM/osrm-backend/wiki/osrm-routed.1)

Expose the OSRM service to "http://yourdomain.de/osrm" for example. So IRIS will be able to use OSRM as a service.

### Optional
If you want a GUI for OSRM you can install [OSRM Frontend](https://github.com/Project-OSRM/osrm-frontend). The OSRM Team is rewritting this frontend and added a new design under [OSRM Frontend v2](https://github.com/Project-OSRM/osrm-frontend-v2). You may test it, but be aware that the v2 is work in progress.


## Nominatim

Install Nominatim v2.3.0 with the instructions provided at [Nominatim.org](http://www.nominatim.org/). Use the unprocessed OSM map data. If you would use the processed data you will not have all information in your data container. You can download unprocessed osm map data from [Geofabrik](http://download.geofabrik.de/)

Recommended: PostgreSQL 9.3.5


## Map Data

This repository provides informationen about the processed map data for truck routing. The map data is available in the [osm format](http://wiki.openstreetmap.org/wiki/OSM_XML). This format is human readable and can be versioned in a git repository. If you need this data in the [pbf format](http://wiki.openstreetmap.org/wiki/PBF_Format) you may convert it. That is very easy and you can find the description below.

## Convert

You can find all necessary information about the converting at the [OpenStreetMap Wiki - OsmConvert](http://wiki.openstreetmap.org/wiki/Osmconvert)

### osm -> pbf

`osmconvert processed.osm -o=processed.osm.pbf`

### pbf -> osm

`osmconvert processed.osm.pbf -o=processed.osm`

## Licensing

Data/Maps Copyright 2015 [CONTARGO](http://www.contargo.net) and [OpenStreetMap Contributors](http://www.openstreetmap.org) | [Map tiles: Creative Commons BY-SA 2.0](http://creativecommons.org/licenses/by-sa/2.0/) [Data: ODbL 1.0](http://opendatacommons.org/licenses/odbl/)
