ARG IMAGE_VERSION=9-jdk11
ARG DEBIAN_FRONTEND=noninteractive

FROM tomcat:${IMAGE_VERSION}

LABEL maintainer="Barış Arıburnu <barisariburnu@gmail.com>"

## Geoserver environments
ENV GEOSERVER_VERSION 2.16.0
ENV GEOSERVER_DIR /usr/local/geoserver
ENV GEOSERVER_DATA_DIR /var/local/geoserver/data
ENV GEOSERVER_PLUG_DIR /var/local/geoserver/extensions
ENV INITIAL_MEMORY 768M
ENV MAXIMUM_MEMORY 1560M
ENV COMMUNITY_MODULES true

# Tomcat environment
ENV CATALINA_OPTS "-server -Djava.awt.headless=true \
    -Xrs -XX:PerfDataSamplingInterval=500 \
    -Dorg.geotools.referencing.forceXY=true -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseParallelGC -XX:NewRatio=2 \
    -XX:+CMSClassUnloadingEnabled -Dfile.encoding=UTF8 -Duser.timezone=GMT -Djavax.servlet.request.encoding=UTF-8 \
    -Djavax.servlet.response.encoding=UTF-8 -Duser.timezone=GMT -Dorg.geotools.shapefile.datetime=true \
    -Dorg.geotools.shapefile.datetime=true -Ds3.properties.location=${GEOSERVER_DATA_DIR}/s3.properties \
    -Xbootclasspath/a:${GEOSERVER_DIR}/WEB-INF/lib/marlin.jar \
    -Dsun.java2d.renderer=org.marlin.pisces.PiscesRenderingEngine \
	-Xms${INITIAL_MEMORY} -Xmx${MAXIMUM_MEMORY} -XX:NewSize=48m \
    -Doracle.jdbc.timezoneAsRegion=false -DGEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR}"

# Microsoft fonts
RUN echo "deb http://httpredir.debian.org/debian stretch contrib" >> /etc/apt/sources.list
RUN set -x \
	&& apt-get update \
	&& apt-get install -yq ttf-mscorefonts-installer \
	&& rm -rf /var/lib/apt/lists/*

# Create folders
RUN mkdir -p ${GEOSERVER_DIR} \
    && mkdir -p ${GEOSERVER_DATA_DIR} \
    && mkdir -p  ${GEOSERVER_PLUG_DIR}

WORKDIR ${GEOSERVER_DIR}

ADD resources/geoserver-2.16.0-war.zip .

RUN wget --progress=bar:force:noscroll -c --no-check-certificate http://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}/geoserver-${GEOSERVER_VERSION}-war.zip \
	&& unzip geoserver-${GEOSERVER_VERSION}-war.zip \
	&& unzip geoserver.war \
    && mv data/* ${GEOSERVER_DATA_DIR} \
	&& rm -rf geoserver-${GEOSERVER_VERSION}-war.zip geoserver.war target *.txt

# Enable CORS
RUN sed -i '\:</web-app>:i\
    <filter>\n\
        <filter-name>CorsFilter</filter-name>\n\
        <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>\n\
        <init-param>\n\
            <param-name>cors.allowed.origins</param-name>\n\
            <param-value>*</param-value>\n\
        </init-param>\n\
        <init-param>\n\
            <param-name>cors.allowed.methods</param-name>\n\
            <param-value>GET,POST,HEAD,OPTIONS,PUT</param-value>\n\
        </init-param>\n\
    </filter>\n\
    <filter-mapping>\n\
        <filter-name>CorsFilter</filter-name>\n\
        <url-pattern>/*</url-pattern>\n\
    </filter-mapping>' ${GEOSERVER_DIR}/WEB-INF/web.xml

# Create tomcat user to avoid root access. 
RUN addgroup --gid 1099 tomcat && useradd -m -u 1099 -g tomcat tomcat \
    && chown -R tomcat:tomcat . \
    && chown -R tomcat:tomcat ${GEOSERVER_DATA_DIR} \
    && chown -R tomcat:tomcat ${GEOSERVER_DIR}

# Add configurations
ADD resources/geoserver.xml ${CATALINA_HOME}/conf/Catalina/localhost/geoserver.xml
ADD resources/controlflow.properties ${GEOSERVER_DATA_DIR}
ADD resources/*.jar ${GEOSERVER_PLUG_DIR}/
ADD scripts/*.sh /usr/local/bin/

RUN setup.sh

ENTRYPOINT [ "entrypoint.sh" ]

EXPOSE 8080