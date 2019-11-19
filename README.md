# docker-geoserver
This will build a docker image based on tomcat that runs geoserver.

## Features

* Built on top of [Docker's official tomcat image](https://hub.docker.com/_/tomcat/).
* Running tomcat process as non-root user.
* Separate GEOSERVER_DATA_DIR location (on /var/local/geoserver).
* Configurable extensions.
* Injectable UID and GID for better mounted volume management.
* [CORS ready](http://enable-cors.org/server_tomcat.html).
* Taken care of [JVM Options](http://docs.geoserver.org/latest/en/user/production/container.html).
* Automatic installation of [Microsoft Core Fonts](http://www.microsoft.com/typography/fonts/web.aspx) for better labelling compatibility.

## Getting the image

There are various ways to get the image onto your system:

The preferred way (but using most bandwidth for the initial image) is to get our docker trusted build like this:

```shell
docker pull barisariburnu/docker-geoserver
```

### To build yourself with a local checkout using the build script:

Edit the build script to change the following variables:

- The variables below represent the latest stable release you need to build. i.e 2.16.0

   ```text
   BUGFIX=0
   MINOR=16
   MAJOR=2
   ```

```shell
git clone git://github.com/barisariburnu/docker-geoserver
cd docker-geoserver
./scripts/build.sh
```

Ensure that you look at the build script to see what other build arguments you can include whilst building your image.

If you do not intend to jump between versions you need to specify that in the build script.

### Custom GEOSERVER_DATA_DIR

Run as a service, exposing port 8080 and using a hosted GEOSERVER_DATA_DIR:

```bash
docker run -d -p 8080:8080 -v ${PWD}/data_dir:/var/local/geoserver/data barisariburnu/docker-geoserver
```

### Custom UID and GID

The tomcat user uid and gid can be customized with `CUSTOM_UID` and `CUSTOM_GID` environment variables, so that the mounted data_dir and exts_dir are accessible by both geoserver and a given host user. Usage example:

```bash
docker run -d -p 8080:8080 -e CUSTOM_UID=$(id -u) -e CUSTOM_GID=$(id -g) barisariburnu/docker-geoserver
```

### Custom extensions

To add extensions to your GeoServer installation, provide a directory with the unzipped extensions separated by directories (one directory per extension):

```bash
docker run -d -p 8080:8080 -v ${PWD}/exts_dir:/var/local/geoserver/extensions barisariburnu/docker-geoserver
```

> **Warning**: The `.jar` files contained in the extensions directory will be copied to the `WEB-INF/lib` directory of the GeoServer installation. Make sure to include only `.jar` files from trusted sources to avoid security risks.

### Building with plugins

Inspect setup.sh to confirm which plugins you want to include in the build process, then add them in their respective sections in the script.

You should ensure that the plugins match the version for the GeoServer WAR zip file.

## Run (manual docker commands)

You can also use the following environment variables to pass arguments to GeoServer:

* `GEOSERVER_VERSION=<geoserver version>`
* `GEOSERVER_DIR=<PATH>`
* `GEOSERVER_DATA_DIR=<PATH>`
* Tomcat properties:

  * You can change the variables based on [geoserver container considerations](http://docs.geoserver.org/stable/en/user/production/container.html)  These arguments operate on the `-Xms` and `-Xmx` options of the Java Virtual Machine
  * `INITIAL_MEMORY=<size>` : Initial Memory that Java can allocate, default `2G`
  * `MAXIMUM_MEMORY=<size>` : Maximum Memory that Java can allocate, default `4G`

## Storing data on the host rather than the container.

Docker volumes can be used to persist your data.

If you need to use geoserver data directory that contains sample examples and configurations download it from [geonode](http://build.geonode.org/geoserver/latest/) site as indicated below:

```shell

# Example - ${GEOSERVER_VERSION} is the geoserver version i.e 2.13.0
wget http://build.geonode.org/geoserver/latest/data-2.13.x.zip
unzip data-2.13.x.zip -d ~/geoserver_data
cp scripts/controlflow.properties ~/geoserver_data
chmod -R a+rwx ~/geoserver_data
docker run -d -p 8580:8080 --name "geoserver" -v $HOME/geoserver_data:/var/local/geoserver/data barisariburnu/docker-geoserver:${GEOSERVER_VERSION}
```

Create an empty data directory to use to persist your data.

```shell
mkdir -p ~/geoserver_data && chmod -R a+rwx ~/geoserver_data
docker run -d -v $HOME/geoserver_data:/var/local/geoserver/data barisariburnu/docker-geoserver
```

### Control flow properties

The control flow module is installed by default and it is used to manage request in geoserver. In order to customise it based on your resources and use case read the instructions from [documentation](http://docs.geoserver.org/latest/en/user/extensions/controlflow/index.html). Modify the file scripts/controlflow.properties before building the image.