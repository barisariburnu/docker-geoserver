#!/bin/bash

# Create folder if not exists

function create_dir() {
    GEOSERVER_DATA_DIR=$1

    if [[ ! -d ${GEOSERVER_DATA_DIR} ]]; then
        echo "Creating" ${GEOSERVER_DATA_DIR} "directory"
        mkdir -p ${GEOSERVER_DATA_DIR}
    else
        echo ${GEOSERVER_DATA_DIR} "exists - skipping creation"
    fi
}

##############################//##############################

# Function used to download the specified files from sourceforge

function download_url() {
    if curl --output /dev/null --silent --head --fail "$1";
    then
        echo "URL exists: $1"
        wget --progress=bar:force:noscroll -c --no-check-certificate "$1" -O "$2"
    else
        echo "URL does not exists: $1"
    fi
}

##############################//##############################

create_dir /tmp/resources/lib/
create_dir /tmp/resources/extensions/

##############################//##############################

# Download Geoserver Extensions

array=( \
    geoserver-${GEOSERVER_VERSION}-vectortiles-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-css-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-csw-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-wps-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-printing-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-libjpeg-turbo-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-control-flow-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-pyramid-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-gdal-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-sldservice-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-monitor-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-importer-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-charts-plugin.zip \
    geoserver-${GEOSERVER_VERSION}-oracle-plugin.zip
)

for i in "${array[@]}"
do
    url="https://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}/extensions/${i}/download"
    download_url ${url} "/tmp/resources/extensions/${i}"
done

##############################//##############################

# Install libjpeg-turbo for that specific geoserver {GEOSERVER_VERSION}

filename="libjpeg-turbo-official_2.0.3_amd64.deb"

if [[ ! -f "/tmp/resources/lib/${filename}" ]]; 
then
    url="https://sourceforge.net/projects/libjpeg-turbo/files/2.0.3/${filename}/download"
    download_url ${url} "/tmp/resources/lib/${filename}"
fi;

dpkg -i "/tmp/resources/lib/${filename}"

# The Geospatial Data Abstraction Library is a computer software library 
# for reading and writing raster and vector geospatial data formats

array=( \
    "http://demo.geo-solutions.it/share/github/imageio-ext/releases/1.1.X/1.1.15/native/gdal/gdal-data.zip" \
    "http://demo.geo-solutions.it/share/github/imageio-ext/releases/1.1.X/1.1.15/native/gdal/linux/gdal192-Ubuntu12-gcc4.6.3-x86_64.tar.gz"
)

for url in "${array[@]}"
do
    IFS='/' read -ra filename <<< ${url}
    download_url ${url} "/tmp/resources/lib/${filename}"
done

##############################//##############################

# Extract Files

if ls /tmp/resources/lib/*gdal*.tar.gz > /dev/null 2>&1; 
then
    create_dir /usr/local/gdal_data && create_dir /usr/local/gdal_native_libs; \
    unzip /tmp/resources/lib/gdal-data.zip -d /usr/local/gdal_data && \
    mv /usr/local/gdal_data/gdal-data/* /usr/local/gdal_data && rm -rf /usr/local/gdal_data/gdal-data && \
    tar xzf /tmp/resources/lib/gdal192-Ubuntu12-gcc4.6.3-x86_64.tar.gz -C /usr/local/gdal_native_libs; \
fi;

if ls /tmp/resources/extensions/*.zip > /dev/null 2>&1; 
then
    for p in /tmp/resources/extensions/*.zip;
    do
        unzip -o $p -d /tmp/extensions \
        && mv /tmp/extensions/*.jar "${GEOSERVER_DIR}/WEB-INF/lib"
    done
fi

##############################//##############################

# Install Marlin render

if [[ ! -f "${GEOSERVER_DIR}/WEB-INF/lib/marlin-sun-java2d.jar" ]]; 
then
    url="https://github.com/bourgesl/marlin-renderer/releases/download/v0_9_4_2/marlin-0.9.4.2-Unsafe-sun-java2d.jar"
    download_url ${url} "${GEOSERVER_DIR}/WEB-INF/lib/marlin-sun-java2d.jar"    
fi

if [[ ! -f ${GEOSERVER_DIR}/WEB-INF/lib/marlin.jar ]]; 
then
    url="https://github.com/bourgesl/marlin-renderer/releases/download/v0_9_4_2/marlin-0.9.4.2-Unsafe.jar"
    download_url ${url} "${GEOSERVER_DIR}/WEB-INF/lib/marlin.jar"  
fi

##############################//##############################

# Delete resources after installation

rm -rf /tmp/resources