# Contargo Maps Server

This repository provides all information to set up a Contargo maps server containing [Open Source Routing Machine (OSRM)](https://github.com/Project-OSRM/) and [Nominatim](http://www.nominatim.org/) and use these services from [IRIS](https://github.com/Contargo/iris)

## OSRM

Install OSRM in version 5.19 following the instructions on [Building OSRM](https://github.com/Project-OSRM/osrm-backend/wiki/Building-OSRM).

Now OSRM is able to extract the road network from our [preprocessed map data](#map-data) with the [truck profile](./contargo_truck.lua).

Expose the OSRM service to "http://example.com/osrm" for example. So IRIS will be able to use OSRM as a service.

### Road restrictions in Germany

There are certain restrictions regarding which roads a truck is allowed to drive on in Germany depending on the aerial distance between start and end of a journey ([more information](https://www.buzer.de/gesetz/10526/a179871.htm)).
Therefore the map needs to be processed twice with different profiles (`profileLess75km` and `profileMore75km`). For each processed map an OSRM instance should be started. The [OSRM Profile Proxy](https://github.com/Contargo/osrm-profile-proxy) is used to proxy every routing request. It takes the requests, calculates the aerial distance between start and end location and proxies it to the correct OSRM instance with the correct profile.

That's why there are two profiles, one for a distance of less than 75km between start and end and the other one for more than 75km. Hence you need to perform the map processing twice. It's important that there is a `verkehrsverbot.lua` symlink to the respective profile (`profileLess75km` or `profileMore75km`) for each processing run. If you don't care about the differences in the less than 75km profile, one run is enough.

The `OSRM Profile Proxy` should be exposed to "http://example.com/osrm"

### Optional

If you want a GUI for OSRM you can install [OSRM Frontend](https://github.com/Project-OSRM/osrm-frontend).

## Nominatim

Install Nominatim v3.2.0 with the instructions provided at [Nominatim.org](http://www.nominatim.org/). Use the unprocessed OSM map data. If you use the processed data you will not have all information in your data container. You can download unprocessed osm map data from [Geofabrik](http://download.geofabrik.de/)

Recommended: PostgreSQL 9.3

Expose the Nominatim service to "http://example.com/nominatim" for example. So IRIS will be able to use Nominatim as a service.


## IRIS

IRIS can be downloaded [here](https://github.com/Contargo/iris).

To use your own maps server with OSRM and Nominatim from IRIS you have to change two properties located in the *application.properties*

* nominatim.base.url=http://example.com/nominatim/
* osrm.url=http://example.com/osrm/route/v1/driving

If you exposed OSRM and Nominatim correctly on the proposed urls described above than IRIS can use OSRM and Nominatim.

## Map Data

The processed map data for truck routing can be downloaded [here](http://maps.contargo.net/maps/). The map data is available in the [osm format](http://wiki.openstreetmap.org/wiki/OSM_XML). This format is human readable and can be versioned in a git repository. If you need this data in the [pbf format](http://wiki.openstreetmap.org/wiki/PBF_Format) you may convert it. That is very easy and you can find the description below.

## Convert

You can find all necessary information about converting at the [OpenStreetMap Wiki - OsmConvert](http://wiki.openstreetmap.org/wiki/Osmconvert)

### osm -> pbf

`osmconvert processed.osm -o=processed.osm.pbf`

### pbf -> osm

`osmconvert processed.osm.pbf -o=processed.osm`

## Licensing

Data/Maps Copyright 2015 [CONTARGO](http://www.contargo.net) and [OpenStreetMap Contributors](http://www.openstreetmap.org) | [Map tiles: Creative Commons BY-SA 2.0](http://creativecommons.org/licenses/by-sa/2.0/) [Data: ODbL 1.0](http://opendatacommons.org/licenses/odbl/)
