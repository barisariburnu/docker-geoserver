#!/bin/sh

BUGFIX=0
MINOR=16
MAJOR=2

# Build Geoserver
echo "Building GeoServer using the specified version"

docker build --build-arg GEOSERVER_VERSION=${MAJOR}.${MINOR}.${BUGFIX} -t barisariburnu/docker-geoserver:${MAJOR}.${MINOR}.${BUGFIX} .

echo "Geoserver installation complete using the specified version"